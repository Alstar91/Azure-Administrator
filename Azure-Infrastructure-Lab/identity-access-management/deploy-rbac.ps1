<#
.SYNOPSIS
Assigns RBAC roles to Entra ID groups across subscription and resource groups.

.DESCRIPTION
- Assigns Reader at subscription level to developers
- Assigns Contributor to non-prod resource group
- Assigns Reader to prod resource group (developers)
- Assigns Contributor to prod resource group (admins)

Implements least privilege + environment segregation.
#>

# =========================================

# Ensure Azure Login

# =========================================

$subscription = Get-AzSubscription | Select-Object -First 1

if (-not $subscription) {
    Write-Host "Subscription not found." -ForegroundColor Red
    return
}

Connect-AzAccount -UseDeviceAuthentication
Set-AzContext -SubscriptionId $subscription.Id

Write-Host "Using Subscription:" $subscription.Name

# =========================================

# Global Variables

# =========================================

$resourceGroupNonProd = "rg-nonprod-infra"
$resourceGroupProd    = "rg-prod-infra"

$appAdminsGroupName     = "app-admins"
$appDevelopersGroupName = "app-developers"

# =========================================

# Get Entra ID Groups

# =========================================

$appAdminsGroup = Get-AzADGroup -DisplayName $appAdminsGroupName
$appDevelopersGroup = Get-AzADGroup -DisplayName $appDevelopersGroupName

if (-not $appAdminsGroup -or -not $appDevelopersGroup) {
    Write-Host "Required groups not found." -ForegroundColor Red
    return
}

Write-Host "Groups resolved successfully."

# =========================================

# Helper Function (Idempotent Role Assignment)

# =========================================

function Assign-RoleIfNotExists {
    param (
        [string]$ObjectId,
        [string]$Role,
        [string]$Scope
    )

    $existing = Get-AzRoleAssignment `
        -ObjectId $ObjectId `
        -RoleDefinitionName $Role `
        -Scope $Scope `
        -ErrorAction SilentlyContinue

    if (-not $existing) {

        New-AzRoleAssignment `
            -ObjectId $ObjectId `
            -RoleDefinitionName $Role `
            -Scope $Scope

        Write-Host "Assigned $Role at $Scope"
    }
    else {
        Write-Host "$Role already exists at $Scope"
    }
}

# =========================================

# Subscription Level (Reader for Developers)

# =========================================

$subscriptionScope = "/subscriptions/$($subscription.Id)"

Assign-RoleIfNotExists `
    -ObjectId $appDevelopersGroup.Id `
    -Role "Reader" `
    -Scope $subscriptionScope

# =========================================

# Non-Prod Resource Group (Contributor for Developers)

# =========================================

$nonProdScope = "/subscriptions/$($subscription.Id)/resourceGroups/$resourceGroupNonProd"

Assign-RoleIfNotExists `
    -ObjectId $appDevelopersGroup.Id `
    -Role "Contributor" `
    -Scope $nonProdScope

# =========================================

# Prod Resource Group (Reader for Developers)

# =========================================

$prodScope = "/subscriptions/$($subscription.Id)/resourceGroups/$resourceGroupProd"

Assign-RoleIfNotExists `
    -ObjectId $appDevelopersGroup.Id `
    -Role "Reader" `
    -Scope $prodScope

# =========================================

# Prod Resource Group (Contributor for Admins)

# =========================================

Assign-RoleIfNotExists `
    -ObjectId $appAdminsGroup.Id `
    -Role "Contributor" `
    -Scope $prodScope

# =========================================

# Done

# =========================================

Write-Host "RBAC configuration completed successfully."
