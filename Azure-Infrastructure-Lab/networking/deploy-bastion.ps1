<#
.SYNOPSIS
Creates Azure Bastion host for secure VM access.

.DESCRIPTION
Deploys Azure Bastion inside the shared networking resource group.
Provides secure RDP/SSH access to VMs without exposing public IPs.

Implements enterprise security best practices:
- No public IPs on VMs
- Centralized secure access
- Uses AzureBastionSubnet
#>

# Ensure Azure login
Connect-AzAccount -UseDeviceAuthentication

# ================================
# Global Variables
# ================================

$resourceGroup = "rg-networking"
$location      = "westeurope"

$vnetName      = "vnet-lab"
$bastionName   = "bastion-host"
$publicIpName  = "bastion-ip"

# ================================
# Validate Resource Group
# ================================

$rg = Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue

if (-not $rg) {
    Write-Host "Resource group $resourceGroup does not exist." -ForegroundColor Red
    return
}

# ================================
# Get Virtual Network
# ================================

$vnet = Get-AzVirtualNetwork `
    -Name $vnetName `
    -ResourceGroupName $resourceGroup `
    -ErrorAction SilentlyContinue

if (-not $vnet) {
    Write-Host "Virtual network $vnetName not found." -ForegroundColor Red
    return
}

# ================================
# Ensure AzureBastionSubnet Exists
# ================================

$subnetName = "AzureBastionSubnet"

$subnet = Get-AzVirtualNetworkSubnetConfig `
    -Name $subnetName `
    -VirtualNetwork $vnet `
    -ErrorAction SilentlyContinue

if (-not $subnet) {

    Add-AzVirtualNetworkSubnetConfig `
        -Name $subnetName `
        -AddressPrefix "10.0.4.0/27" `
        -VirtualNetwork $vnet

    $vnet | Set-AzVirtualNetwork

    Write-Host "AzureBastionSubnet created."
}
else {
    Write-Host "AzureBastionSubnet already exists."
}

# ================================
# Create Public IP for Bastion
# ================================

$publicIp = Get-AzPublicIpAddress `
    -Name $publicIpName `
    -ResourceGroupName $resourceGroup `
    -ErrorAction SilentlyContinue

if (-not $publicIp) {

    $publicIp = New-AzPublicIpAddress `
        -Name $publicIpName `
        -ResourceGroupName $resourceGroup `
        -Location $location `
        -AllocationMethod Static `
        -Sku Standard

    Write-Host "Public IP created for Bastion."
}
else {
    Write-Host "Public IP already exists."
}

# ================================
# Create Bastion Host
# ================================

if (-not (Get-AzBastion -Name $bastionName -ResourceGroupName $resourceGroup -ErrorAction SilentlyContinue)) {

    $subnet = Get-AzVirtualNetworkSubnetConfig `
        -Name "AzureBastionSubnet" `
        -VirtualNetwork $vnet

    New-AzBastion `
        -Name $bastionName `
        -ResourceGroupName $resourceGroup `
        -PublicIpAddress $publicIp `
        -VirtualNetwork $vnet

    Write-Host "Azure Bastion deployed successfully."
}
else {
    Write-Host "Azure Bastion already exists."
}
