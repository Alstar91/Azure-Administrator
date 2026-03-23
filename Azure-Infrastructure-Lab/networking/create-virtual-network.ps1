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

$subscription = Get-AzSubscription | Select-Object -First 1

if (-not $subscription) {
    Write-Host "Subscription Not Found." -ForegroundColor Red
    return
}

# Create Service Principal
$servicePrincipal = az ad sp create-for-rbac `
  --name "my-sp" `
  --role "Contributor" `
  --scopes "/subscriptions/$($subscription.Id)" | ConvertFrom-Json

# Assign variables
$clientId = $servicePrincipal.appId
$clientSecret = $servicePrincipal.password
$tenantId = $servicePrincipal.tenant
$subscriptionId = $subscription.Id

# Set environment variables
$env:AZURE_CLIENT_ID = $clientId
$env:AZURE_CLIENT_SECRET = $clientSecret
$env:AZURE_TENANT_ID = $tenantId
$env:AZURE_SUBSCRIPTION_ID = $subscriptionId

# Create credential
$securePassword = ConvertTo-SecureString $clientSecret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($clientId, $securePassword)

# Login using Service Principal
Connect-AzAccount -ServicePrincipal -Credential $credential -Tenant $tenantId

# Set subscription context
Set-AzContext -SubscriptionId $subscriptionId

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
-AddressPrefix "10.0.3.0/27"

# ================================

# Check Resource Group Exists

# ================================

$rg = Get-AzResourceGroup `
        -Name $resourceGroup `
        -ErrorAction SilentlyContinue

if (-not $rg) {

    Write-Host "Resource Group '$resourceGroup' does not exist. Cannot create Virtual Network." -ForegroundColor Red
}

else {

    # ================================
    
    # Check if Virtual Network Exists
    
    # ================================

    $vnet = Get-AzVirtualNetwork `
                -Name $vnetName `
                -ResourceGroupName $resourceGroup `
                -ErrorAction SilentlyContinue

    if (-not $vnet) {

        New-AzVirtualNetwork `
            -Name $vnetName `
            -ResourceGroupName $resourceGroup `
            -Location $location `
            -AddressPrefix $addressSpace `
            -Subnet $appSubnet, $dbSubnet, $mgmtSubnet

        Write-Host "Virtual Network created successfully." -ForegroundColor Green
    }
    else {

        Write-Host "Virtual Network already exists. Skipping creation." -ForegroundColor Yellow
    }

}
