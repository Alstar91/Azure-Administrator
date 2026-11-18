<#
.SYNOPSIS
Moves the subscription back to the Tenant Root Group and deletes az104-mg1.

.DESCRIPTION
Reverses deploy-management-groups.ps1:

- Validates prerequisites (module, login, subscription)
- Moves subscriptions out of az104-mg1 (back to the Tenant Root Group)
- Removes role assignments made directly on az104-mg1
- Deletes the az104-mg1 management group

A management group can only be deleted once it has no child
subscriptions or management groups.

Idempotent: exits cleanly if the group no longer exists.

NOTE:
Requires the Az.Resources module.
#>

# =========================================

# Ensure Az.Resources Module

# =========================================

if (-not (Get-Module Az.Resources -ListAvailable)) {
    Write-Host "Az.Resources module not found ❌" -ForegroundColor Red
    Write-Host "Reason: management group cmdlets (Remove-AzManagementGroup etc.) come from Az.Resources."
    Write-Host "Fix: Install-Module Az -Scope CurrentUser -Repository PSGallery"
    return
}

# =========================================

# Ensure Azure Login

# =========================================

if (-not (Get-AzContext)) {
    Connect-AzAccount -UseDeviceAuthentication | Out-Null
}

if (-not (Get-AzContext)) {
    Write-Host "Azure login failed ❌" -ForegroundColor Red
    Write-Host "Reason: no Azure session is available, so nothing can be removed."
    return
}

$subscription = Get-AzSubscription | Select-Object -First 1

if (-not $subscription) {
    Write-Host "Subscription not found ❌" -ForegroundColor Red
    Write-Host "Reason: the signed-in account has no access to any subscription."
    return
}

Set-AzContext -SubscriptionId $subscription.Id | Out-Null

Write-Host "Using Subscription:" $subscription.Name

# =========================================

# Global Variables

# =========================================

$managementGroupId    = "az104-mg1"
$managementGroupScope = "/providers/Microsoft.Management/managementGroups/$managementGroupId"

# =========================================

# Helper: Explain Failure Reason

# =========================================

function Get-FailureReason {
    param (
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    $message = $ErrorRecord.Exception.Message

    switch -Regex ($message) {
        "AuthorizationFailed|does not have authorization|Forbidden|403" {
            return "Your account does not have permission for this action. " +
                   "Ask for Owner or Management Group Contributor at this scope, or in Microsoft Entra ID > Properties " +
                   "set 'Access management for Azure resources' to Yes, then sign out and back in."
        }
        "has children|ManagementGroupHasChildren|not empty" {
            return "The management group still contains subscriptions or child management groups. Move or delete them first."
        }
        "NotFound|could not be found" {
            return "The target was not found; it may already have been removed."
        }
        default {
            return $message
        }
    }
}

# =========================================

# Check Management Group Exists

# =========================================

$managementGroup = Get-AzManagementGroup `
    -GroupName $managementGroupId `
    -Expand `
    -ErrorAction SilentlyContinue

if (-not $managementGroup) {
    Write-Host "Management group '$managementGroupId' not found. Nothing to clean up."
    Write-Host "Note: if you expected it to exist, your account may not have read access to it."
    return
}

# =========================================

# Move Subscriptions Back to Tenant Root Group

# =========================================

$childSubscriptions = $managementGroup.Children |
    Where-Object { $_.Type -like "*subscription*" }

if (-not $childSubscriptions) {
    Write-Host "No subscriptions in '$managementGroupId'. Skipping move."
}

foreach ($child in $childSubscriptions) {
    try {
        Remove-AzManagementGroupSubscription -ErrorAction Stop `
            -GroupName $managementGroupId `
            -SubscriptionId ($child.Id -split '/')[-1]

        Write-Host "Subscription '$($child.DisplayName)' moved back to Tenant Root Group."
    }
    catch {
        Write-Host "Failed to move subscription '$($child.DisplayName)' ❌" -ForegroundColor Red
        Write-Host "Reason:" (Get-FailureReason $_)
        Write-Host "Note: moving a subscription requires Owner on the subscription."
        return
    }
}

# =========================================

# Remove Role Assignments on the Management Group

# =========================================

$roleAssignments = Get-AzRoleAssignment -Scope $managementGroupScope -ErrorAction SilentlyContinue |
    Where-Object { $_.Scope -eq $managementGroupScope }

if (-not $roleAssignments) {
    Write-Host "No role assignments directly on '$managementGroupId'. Skipping removal."
}

foreach ($assignment in $roleAssignments) {
    try {
        $assignment | Remove-AzRoleAssignment -ErrorAction Stop | Out-Null
        Write-Host "Removed $($assignment.RoleDefinitionName) for $($assignment.DisplayName)"
    }
    catch {
        Write-Host "Failed to remove $($assignment.RoleDefinitionName) for $($assignment.DisplayName) ❌" -ForegroundColor Red
        Write-Host "Reason:" (Get-FailureReason $_)
    }
}

# =========================================

# Delete Management Group

# =========================================

$remainingChildren = (Get-AzManagementGroup -GroupName $managementGroupId -Expand).Children

if ($remainingChildren) {
    Write-Host "Management group '$managementGroupId' cannot be deleted ❌" -ForegroundColor Red
    Write-Host "Reason: it still has children. Move or delete these first:"
    $remainingChildren | ForEach-Object { Write-Host " - $($_.DisplayName) [$($_.Type)]" }
    return
}

try {
    Remove-AzManagementGroup -GroupName $managementGroupId -ErrorAction Stop | Out-Null
    Write-Host "Management group '$managementGroupId' deleted." -ForegroundColor Green
}
catch {
    Write-Host "Failed to delete management group '$managementGroupId' ❌" -ForegroundColor Red
    Write-Host "Reason:" (Get-FailureReason $_)
    return
}

# =========================================

# Done

# =========================================

Write-Host "Management group cleanup completed."
