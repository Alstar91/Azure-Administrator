<#
.SYNOPSIS
Creates production, non-production, networking, and monitoring resource groups
with standardized enterprise tags.

.DESCRIPTION
Implements environment separation aligned with Azure governance
best practices for AZ-104.
#>

# Ensure connection
Connect-AzAccount

# ================================
# Global Variables
# ================================

$location = "westeurope"
$owner    = "Aashish"
$project  = "InfraLab"
$createdOn = (Get-Date).ToString("yyyy-MM-dd")

# ================================
# Production Resource Group
# ================================

$prodTags = @{
    Environment = "Production"
    Owner       = $owner
    Project     = $project
    CreatedOn   = $createdOn
    CostCenter  = "CloudLearning"
}

New-AzResourceGroup `
    -Name "rg-prod-infrastructure" `
    -Location $location `
    -Tag $prodTags


# ================================
# Non-Production Resource Group
# ================================

$nonprodTags = @{
    Environment = "NonProduction"
    Owner       = $owner
    Project     = $project
    CreatedOn   = $createdOn
}

New-AzResourceGroup `
    -Name "rg-nonprod-infrastructure" `
    -Location $location `
    -Tag $nonprodTags


# ================================
# Shared Networking Resource Group
# ================================

$networkingTags = @{
    Environment = "Shared"
    Layer       = "Networking"
    Owner       = $owner
    Project     = $project
    CreatedOn   = $createdOn
}

New-AzResourceGroup `
    -Name "rg-networking" `
    -Location $location `
    -Tag $networkingTags


# ================================
# Shared Monitoring Resource Group
# ================================

$monitoringTags = @{
    Environment = "Shared"
    Layer       = "Monitoring"
    Owner       = $owner
    Project     = $project
    CreatedOn   = $createdOn
}

New-AzResourceGroup `
    -Name "rg-monitoring" `
    -Location $location `
    -Tag $monitoringTags
