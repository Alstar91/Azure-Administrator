<#
.SYNOPSIS
Creates production, non-production, networking, and monitoring resource groups
with standardized enterprise tags.

.DESCRIPTION
Implements environment separation aligned with Azure governance
best practices for AZ-104.
Creates resource groups only if they do not already exist.
#>

# Ensure connection
Connect-AzAccount -UseDeviceAuthentication

# ================================
# Global Variables
# ================================

$location  = "westeurope"
$owner     = "Aashish"
$project   = "InfraLab"
$createdOn = (Get-Date).ToString("yyyy-MM-dd")

# ================================
# Production Resource Group
# ================================

$prodRgName = "rg-prod-infrastructure"

$prodTags = @{
    Environment = "Production"
    Owner       = $owner
    Project     = $project
    CreatedOn   = $createdOn
    CostCenter  = "CloudLearning"
}

if (-not (Get-AzResourceGroup -Name $prodRgName -ErrorAction SilentlyContinue)) {

    New-AzResourceGroup `
        -Name $prodRgName `
        -Location $location `
        -Tag $prodTags

    Write-Host "Production Resource Group created."
}
else {
    Write-Host "Production Resource Group already exists. Skipping creation."
}

# ================================
# Non-Production Resource Group
# ================================

$nonProdRgName = "rg-nonprod-infrastructure"

$nonprodTags = @{
    Environment = "NonProduction"
    Owner       = $owner
    Project     = $project
    CreatedOn   = $createdOn
}

if (-not (Get-AzResourceGroup -Name $nonProdRgName -ErrorAction SilentlyContinue)) {

    New-AzResourceGroup `
        -Name $nonProdRgName `
        -Location $location `
        -Tag $nonprodTags

    Write-Host "Non-Production Resource Group created."
}
else {
    Write-Host "Non-Production Resource Group already exists. Skipping creation."
}

# ================================
# Shared Networking Resource Group
# ================================

$networkRgName = "rg-networking"

$networkingTags = @{
    Environment = "Shared"
    Layer       = "Networking"
    Owner       = $owner
    Project     = $project
    CreatedOn   = $createdOn
}

if (-not (Get-AzResourceGroup -Name $networkRgName -ErrorAction SilentlyContinue)) {

    New-AzResourceGroup `
        -Name $networkRgName `
        -Location $location `
        -Tag $networkingTags

    Write-Host "Networking Resource Group created."
}
else {
    Write-Host "Networking Resource Group already exists. Skipping creation."
}

# ================================
# Shared Monitoring Resource Group
# ================================

$monitoringRgName = "rg-monitoring"

$monitoringTags = @{
    Environment = "Shared"
    Layer       = "Monitoring"
    Owner       = $owner
    Project     = $project
    CreatedOn   = $createdOn
}

if (-not (Get-AzResourceGroup -Name $monitoringRgName -ErrorAction SilentlyContinue)) {

    New-AzResourceGroup `
        -Name $monitoringRgName `
        -Location $location `
        -Tag $monitoringTags

    Write-Host "Monitoring Resource Group created."
}
else {
    Write-Host "Monitoring Resource Group already exists. Skipping creation."
}
