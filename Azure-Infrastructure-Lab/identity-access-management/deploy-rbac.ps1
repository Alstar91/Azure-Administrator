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

$resourceGroupNonProd = "rg-nonprod-infrastructure"
$resourceGroupProd    = "rg-prod-infrastructure"

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

# Helper: Validate Scope

# =========================================

function Get-ScopeIfExists {
    param (
        [string]$ResourceGroupName
    )

    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue

    if (-not $rg) {
        Write-Host "Resource group '$ResourceGroupName' NOT FOUND ❌" -ForegroundColor Red
        return $null
    }

    return "/subscriptions/$($subscription.Id)/resourceGroups/$ResourceGroupName"
}

# =========================================

# Helper Function (Idempotent Role Assignment)

# =========================================

function Assign-RoleIfNotExists {
    param (
        [string]$ObjectId,
        [string]$Role,
        [string]$Scope
    )

    if (-not $Scope) {
        Write-Host "Skipping role assignment due to invalid scope." -ForegroundColor Yellow
        return
    }

    $existing = Get-AzRoleAssignment `
        -ObjectId $ObjectId `
        -RoleDefinitionName $Role `
        -Scope $Scope `
        -ErrorAction SilentlyContinue

    if (-not $existing) {
        try {
            New-AzRoleAssignment `
                -ObjectId $ObjectId `
                -RoleDefinitionName $Role `
                -Scope $Scope

            Write-Host "Assigned $Role at $Scope"
        }
        catch {
            Write-Host "Failed to assign $Role at $Scope ❌" -ForegroundColor Red
            Write-Host $_.Exception.Message
        }
    }
    else {
        Write-Host "$Role already exists at $Scope"
    }
}

# =========================================

# Resolve Scopes

# =========================================

$subscriptionScope = "/subscriptions/$($subscription.Id)"
$nonProdScope = Get-ScopeIfExists $resourceGroupNonProd
$prodScope    = Get-ScopeIfExists $resourceGroupProd

# =========================================

# Subscription Level (Reader for Developers)

# =========================================

Assign-RoleIfNotExists `
    -ObjectId $appDevelopersGroup.Id `
    -Role "Reader" `
    -Scope $subscriptionScope

# =========================================

# Non-Prod Resource Group (Contributor for Developers)

# =========================================

Assign-RoleIfNotExists `
    -ObjectId $appDevelopersGroup.Id `
    -Role "Contributor" `
    -Scope $nonProdScope

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
