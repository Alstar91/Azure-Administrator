<#
.SYNOPSIS
Lists all resource groups in current subscription.

.DESCRIPTION
Displays resource groups in table format for verification.
Shows active subscription context before listing.
#>

# Ensure connection
Connect-AzAccount

# ================================
# Get Current Subscription Context
# ================================

$context = Get-AzContext

Write-Host "Current Subscription:" $context.Subscription.Name
Write-Host "Subscription ID:" $context.Subscription.Id
Write-Host "---------------------------------------------"

# ================================
# List Resource Groups
# ================================

Get-AzResourceGroup |
    Select-Object ResourceGroupName, Location, ProvisioningState |
    Format-Table -AutoSize
