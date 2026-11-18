<#
.SYNOPSIS
Creates the az104-mg1 management group and moves the subscription under it.

.DESCRIPTION
Lab 02a - Task 1: Implement Management Groups

- Validates prerequisites (module, login, subscription, group ID)
- Creates management group az104-mg1 under the Tenant Root Group
- Moves the current subscription into az104-mg1
- Displays the resulting hierarchy for verification

Role assignments and policies applied to az104-mg1 are inherited
by every subscription inside it (used in Task 2 and in lab-02b).

Idempotent: skips the group or the move if already done.

NOTE:
- Requires the Az.Resources module.
- A newly created management group can take a few minutes to
  appear in the portal.
#>

# =========================================

# Ensure Az.Resources Module

# =========================================

if (-not (Get-Module Az.Resources -ListAvailable)) {
    Write-Host "Az.Resources module not found ❌" -ForegroundColor Red
    Write-Host "Reason: management group cmdlets (New-AzManagementGroup etc.) come from Az.Resources."
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
    Write-Host "Reason: no Azure session is available, so nothing can be created."
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

$managementGroupId          = "az104-mg1"
$managementGroupDisplayName = "az104-mg1"

$tenantId = $subscription.TenantId    # Tenant Root Group ID = Tenant ID

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
        "requireAuthorizationForGroupCreation|HierarchySettings" {
            return "Your tenant only allows management group creation by users with write access on the Tenant Root Group " +
                   "(Management groups > Settings > 'Require write permissions for creating new management groups')."
        }
        "Conflict|already exists|is already in use" {
            return "The ID is already used by another management group in this tenant, possibly one you cannot see. " +
                   "Choose a different management group ID."
        }
        "InvalidManagementGroupName|BadRequest|invalid" {
            return "Azure rejected the request as invalid. Check the management group ID and the subscription ID."
        }
        "NotFound|could not be found" {
            return "The target was not found. A newly created management group can take a few minutes to become available; " +
                   "wait and re-run the script (completed steps will be skipped)."
        }
        default {
            return $message
        }
    }
}

# =========================================

# Validate Management Group ID

# =========================================

# Rules: up to 90 characters; letters, digits, - _ ( ) . only; cannot end with a period

if ($managementGroupId -notmatch '^[A-Za-z0-9\-_\(\)\.]{1,90}$' -or $managementGroupId.EndsWith(".")) {
    Write-Host "Management group ID '$managementGroupId' is invalid ❌" -ForegroundColor Red
    Write-Host "Reason: IDs must be 1-90 characters using letters, digits, - _ ( ) . and cannot end with a period."
    return
}

if ($managementGroupId -eq $tenantId) {
    Write-Host "Management group ID '$managementGroupId' is invalid ❌" -ForegroundColor Red
    Write-Host "Reason: this ID belongs to the Tenant Root Group."
    return
}

# =========================================

# Create Management Group

# =========================================

$managementGroup = Get-AzManagementGroup `
    -GroupName $managementGroupId `
    -ErrorAction SilentlyContinue

if (-not $managementGroup) {
    try {
        # No ParentId: new groups are created under the Tenant Root Group by default
        $managementGroup = New-AzManagementGroup -ErrorAction Stop `
            -GroupName $managementGroupId `
            -DisplayName $managementGroupDisplayName

        Write-Host "Management group '$managementGroupId' created." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to create management group '$managementGroupId' ❌" -ForegroundColor Red
        Write-Host "Reason:" (Get-FailureReason $_)
        return
    }
}
else {
    Write-Host "Management group '$managementGroupId' already exists. Skipping creation."
}

# =========================================

# Move Subscription into Management Group

# =========================================

if ($subscription.State -ne "Enabled") {
    Write-Host "Subscription '$($subscription.Name)' cannot be moved ❌" -ForegroundColor Red
    Write-Host "Reason: subscription state is '$($subscription.State)'; only Enabled subscriptions can be moved."
    return
}

$managementGroup = Get-AzManagementGroup `
    -GroupName $managementGroupId `
    -Expand `
    -ErrorAction SilentlyContinue

if (-not $managementGroup) {
    Write-Host "Management group '$managementGroupId' is not readable yet ❌" -ForegroundColor Red
    Write-Host "Reason: a newly created group can take a few minutes to become available. Wait and re-run the script."
    return
}

$alreadyMember = $managementGroup.Children |
    Where-Object { $_.Type -like "*subscription*" -and $_.Id -like "*$($subscription.Id)" }

if (-not $alreadyMember) {
    try {
        New-AzManagementGroupSubscription -ErrorAction Stop `
            -GroupName $managementGroupId `
            -SubscriptionId $subscription.Id

        Write-Host "Subscription '$($subscription.Name)' moved to '$managementGroupId'." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to move subscription to '$managementGroupId' ❌" -ForegroundColor Red
        Write-Host "Reason:" (Get-FailureReason $_)
        Write-Host "Note: moving a subscription requires Owner on the subscription and write access on the target management group."
        return
    }
}
else {
    Write-Host "Subscription already in '$managementGroupId'. Skipping move."
}

# =========================================

# Verify Hierarchy

# =========================================

$managementGroup = Get-AzManagementGroup `
    -GroupName $managementGroupId `
    -Expand

Write-Host ""
Write-Host "Hierarchy:" -ForegroundColor Cyan
Write-Host "Tenant Root Group ($tenantId)"
Write-Host "└── $($managementGroup.DisplayName) ($($managementGroup.Name))"

foreach ($child in $managementGroup.Children) {
    Write-Host "    └── $($child.DisplayName) [$($child.Type)]"
}

# =========================================

# Done

# =========================================

Write-Host ""
Write-Host "Management group configuration completed successfully."
