<#
.SYNOPSIS
Moves the subscription back to the Tenant Root Group and deletes az104-mg1.

.DESCRIPTION
Reverses deploy-management-groups.ps1:

- Moves the subscription out of az104-mg1 (back to the Tenant Root Group)
- Removes any role assignments made directly on az104-mg1
- Deletes the az104-mg1 management group

A management group can only be deleted once it has no child
subscriptions or management groups.

NOTE:
Requires the Az.Resources module.
#>

# =========================================

# Ensure Azure Login

# =========================================

if (-not (Get-AzContext)) {
    Connect-AzAccount -UseDeviceAuthentication | Out-Null
}

$subscription = Get-AzSubscription | Select-Object -First 1

if (-not $subscription) {
    Write-Host "Subscription not found." -ForegroundColor Red
    return
}

Set-AzContext -SubscriptionId $subscription.Id | Out-Null

Write-Host "Using Subscription:" $subscription.Name

# =========================================

# Global Variables

# =========================================

$managementGroupId = "az104-mg1"

# =========================================

# Check Management Group Exists

# =========================================

$managementGroup = Get-AzManagementGroup `
    -GroupName $managementGroupId `
    -Expand `
    -ErrorAction SilentlyContinue

if (-not $managementGroup) {
    Write-Host "Management group '$managementGroupId' not found. Nothing to clean up."
    return
}

# =========================================

# Move Subscriptions Back to Tenant Root Group

# =========================================

$childSubscriptions = $managementGroup.Children |
    Where-Object { $_.Type -like "*subscription*" }

foreach ($child in $childSubscriptions) {
    try {
        Remove-AzManagementGroupSubscription -ErrorAction Stop `
            -GroupName $managementGroupId `
            -SubscriptionId ($child.Id -split '/')[-1]

        Write-Host "Subscription '$($child.DisplayName)' moved back to Tenant Root Group."
    }
    catch {
        Write-Host "Failed to move subscription '$($child.DisplayName)' ❌" -ForegroundColor Red
        Write-Host $_.Exception.Message
        return
    }
}

# =========================================

# Remove Role Assignments on the Management Group

# =========================================

$managementGroupScope = "/providers/Microsoft.Management/managementGroups/$managementGroupId"

$roleAssignments = Get-AzRoleAssignment -Scope $managementGroupScope |
    Where-Object { $_.Scope -eq $managementGroupScope }

foreach ($assignment in $roleAssignments) {
    $assignment | Remove-AzRoleAssignment -ErrorAction Continue | Out-Null

    Write-Host "Removed $($assignment.RoleDefinitionName) for $($assignment.DisplayName)"
}

# =========================================

# Delete Management Group

# =========================================

$remainingChildren = (Get-AzManagementGroup -GroupName $managementGroupId -Expand).Children

if ($remainingChildren) {
    Write-Host "Management group still has children. Remove them first ❌" -ForegroundColor Red
    $remainingChildren | ForEach-Object { Write-Host " - $($_.DisplayName) [$($_.Type)]" }
    return
}

try {
    Remove-AzManagementGroup -GroupName $managementGroupId -ErrorAction Stop | Out-Null
    Write-Host "Management group '$managementGroupId' deleted." -ForegroundColor Green
}
catch {
    Write-Host "Failed to delete management group '$managementGroupId' ❌" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

# =========================================

# Done

# =========================================

Write-Host "Management group cleanup completed."
