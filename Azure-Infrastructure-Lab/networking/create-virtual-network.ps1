<#
.SYNOPSIS
Creates an virtual network with segmented subnets.

.DESCRIPTION
Deploys a Virtual Network named vnet-lab inside the
rg-networking resource group.

The VNet uses address space 10.0.0.0/16 and contains three subnets:

AppSubnet   - Application layer
DBSubnet    - Database layer
MgmtSubnet  - Management / Bastion access

Creates the VNet only if it does not already exist.
#>

# Ensure connection

Connect-AzAccount -UseDeviceAuthentication

# ================================

# Global Variables

# ================================

$location      = "westeurope"
$resourceGroup = "rg-networking"
$vnetName      = "vnet-lab"
$addressSpace  = "10.0.0.0/16"

# ================================

# Subnet Configuration

# ================================

$appSubnet = New-AzVirtualNetworkSubnetConfig `    -Name "AppSubnet"`
-AddressPrefix "10.0.1.0/24"

$dbSubnet = New-AzVirtualNetworkSubnetConfig `    -Name "DBSubnet"`
-AddressPrefix "10.0.2.0/24"

$mgmtSubnet = New-AzVirtualNetworkSubnetConfig `    -Name "MgmtSubnet"`
-AddressPrefix "10.0.3.0/24"

# ================================

# Create Virtual Network

# ================================

if (-not (Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup -ErrorAction SilentlyContinue)) {

New-AzVirtualNetwork `
    -Name $vnetName `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -AddressPrefix $addressSpace `
    -Subnet $appSubnet, $dbSubnet, $mgmtSubnet

Write-Host "Virtual Network created successfully."

}
else {
Write-Host "Virtual Network already exists. Skipping creation."
}
