<#
.SYNOPSIS
Creates the az104-mg1 management group and moves the subscription under it.

.DESCRIPTION
Lab 02a - Task 1: Implement Management Groups

- Creates management group az104-mg1 under the Tenant Root Group
- Moves the current subscription into az104-mg1
- Displays the resulting hierarchy for verification

Role assignments and policies applied to az104-mg1 are inherited
by every subscription inside it (used in Task 2 and in lab-02b).

Idempotent: skips the group or the move if already done.

NOTE:
- Requires the Az.Resources module.
- If you get permission errors, open Microsoft Entra ID > Properties >
  "Access management for Azure resources", set it to Yes, then sign
  out and back in (as described in the official lab).
- A newly created management group can take a few minutes to
  appear in the portal.
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

$managementGroupId          = "az104-mg1"
$managementGroupDisplayName = "az104-mg1"

$tenantId = $subscription.TenantId    # Tenant Root Group ID = Tenant ID

# =========================================

# Create Management Group

# =========================================

$managementGroup = Get-AzManagementGroup `
    -GroupName $managementGroupId `
    -ErrorAction SilentlyContinue

if (-not $managementGroup) {
    try {
        $managementGroup = New-AzManagementGroup -ErrorAction Stop `
            -GroupName $managementGroupId `
            -DisplayName $managementGroupDisplayName `
            -ParentId "/providers/Microsoft.Management/managementGroups/$tenantId"

        Write-Host "Management group '$managementGroupId' created." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to create management group '$managementGroupId' ❌" -ForegroundColor Red
        Write-Host $_.Exception.Message
        return
    }
}
else {
    Write-Host "Management group '$managementGroupId' already exists. Skipping creation."
}

# =========================================

# Move Subscription into Management Group

# =========================================

$managementGroup = Get-AzManagementGroup `
    -GroupName $managementGroupId `
    -Expand

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
        Write-Host $_.Exception.Message
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
