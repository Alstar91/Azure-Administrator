<#
.SYNOPSIS
Creates and configures a NAT Gateway for outbound internet access.

.DESCRIPTION
Creates a NAT Gateway with a static public IP and associates it
with specified subnets to enable secure outbound connectivity
without exposing VMs to the public internet.
#>

# Ensure connection

$subscription = Get-AzSubscription | Select-Object -First 1

if (-not $subscription) {
    Write-Host "Subscription Not Found." -ForegroundColor Red
    return
}

Connect-AzAccount -Identity

Set-AzContext -SubscriptionId $subscription.Id

# =========================================
# Global Variables
# =========================================

$resourceGroup = "rg-networking"
$location      = "westeurope"

$vnetName      = "vnet-lab"
$natGatewayName = "nat-gateway"
$publicIpName   = "nat-gateway-public-ip"

$subnetsToAttach = @("AppSubnet", "DBSubnet")

# =========================================
# Validate Resource Group
# =========================================

$rg = Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue

if (-not $rg) {
    Write-Host "Resource Group $resourceGroup does not exist. Exiting." -ForegroundColor Red
    return
}

# =========================================
# Create Public IP for NAT Gateway
# =========================================

$publicIp = Get-AzPublicIpAddress `
    -Name $publicIpName `
    -ResourceGroupName $resourceGroup `
    -ErrorAction SilentlyContinue

if (-not $publicIp) {

    Write-Host "Creating Public IP for NAT Gateway..."

    $publicIp = New-AzPublicIpAddress `
        -Name $publicIpName `
        -ResourceGroupName $resourceGroup `
        -Location $location `
        -AllocationMethod Static `
        -Sku Standard

    Write-Host "Public IP created."
}
else {
    Write-Host "Public IP already exists."
}

# =========================================
# Create NAT Gateway
# =========================================

$natGateway = Get-AzNatGateway `
    -Name $natGatewayName `
    -ResourceGroupName $resourceGroup `
    -ErrorAction SilentlyContinue

if (-not $natGateway) {

    Write-Host "Creating NAT Gateway..."

    $natGateway = New-AzNatGateway `
        -Name $natGatewayName `
        -ResourceGroupName $resourceGroup `
        -Location $location `
        -Sku Standard `
        -IdleTimeoutInMinutes 10 `
        -PublicIpAddress $publicIp

    Write-Host "NAT Gateway created."
}
else {
    Write-Host "NAT Gateway already exists."
}

# =========================================
# Get Virtual Network
# =========================================

$vnet = Get-AzVirtualNetwork `
    -Name $vnetName `
    -ResourceGroupName $resourceGroup `
    -ErrorAction SilentlyContinue

if (-not $vnet) {
    Write-Host "Virtual Network not found. Exiting." -ForegroundColor Red
    return
}

# =========================================
# Attach NAT Gateway to Subnets
# =========================================

foreach ($subnetName in $subnetsToAttach) {

    $subnet = $vnet.Subnets | Where-Object { $_.Name -eq $subnetName }

    if ($subnet) {

        Write-Host "Associating NAT Gateway with subnet: $subnetName"

        $subnet.NatGateway = $natGateway
    }
    else {
        Write-Host "Subnet $subnetName not found." -ForegroundColor Yellow
    }
}

# Apply changes
Set-AzVirtualNetwork -VirtualNetwork $vnet

Write-Host "NAT Gateway successfully associated with subnets."
