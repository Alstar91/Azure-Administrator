<#
.SYNOPSIS
Creates Network Security Groups and applies Zero Trust rules.

.DESCRIPTION
Validates resource group and VNet existence before creating NSGs.
Uses loops and configuration arrays to deploy NSGs and rules
for App, DB, and Management tiers.
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

$location      = "westeurope"
$resourceGroup = "rg-networking"
$vnetName      = "vnet-lab"

# =========================================

# Validate Resource Group

# =========================================

$rg = Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue

if (-not $rg) {
    Write-Host "Resource Group $resourceGroup does not exist. Exiting script."
    return
}

# =========================================

# Validate Virtual Network

# =========================================

$vnet = Get-AzVirtualNetwork `
        -Name $vnetName `
        -ResourceGroupName $resourceGroup `
        -ErrorAction SilentlyContinue

if (-not $vnet) {
    Write-Host "Virtual Network $vnetName does not exist. Exiting script."
    return
}

Write-Host "Resource Group and VNet validated."

# =========================================

# NSG Configuration

# =========================================

$nsgConfigs = @(
    @{
        Name   = "nsg-app"
        Subnet = "AppSubnet"
        Prefix = "10.0.1.0/24"
        Rules  = @(
            @{
                Name     = "AllowAzureLoadBalancerHTTP"
                Source   = "AzureLoadBalancer"
                Port     = "80"
                Priority = 100
            },
            @{
                Name     = "AllowHTTPInternet"
                Source   = "Internet"
                Port     = "80"
                Priority = 110
            },
            @{
                Name     = "AllowHTTPSInternet"
                Source   = "Internet"
                Port     = "443"
                Priority = 120
            }
        )
    },

    @{
        Name   = "nsg-db"
        Subnet = "DBSubnet"
        Prefix = "10.0.2.0/24"
        Rules  = @(
            @{
                Name     = "allow-sql-from-app"
                Source   = "10.0.1.0/24"
                Port     = "1433"
                Priority = 100
            }
        )
    },

    @{
        Name   = "nsg-mgmt"
        Subnet = "MgmtSubnet"
        Prefix = "10.0.3.0/24"
        Rules  = @(
            @{
                Name     = "allow-bastion"
                Source   = "*"
                Port     = "22"
                Priority = 100
            }
        )
    }
)

# =========================================

# Create NSGs and Rules

# =========================================

foreach ($config in $nsgConfigs) {

    $nsg = Get-AzNetworkSecurityGroup `
           -Name $config.Name `
           -ResourceGroupName $resourceGroup `
           -ErrorAction SilentlyContinue

    if (-not $nsg) {

        Write-Host "Creating NSG:" $config.Name

        $nsg = New-AzNetworkSecurityGroup `
               -Name $config.Name `
               -ResourceGroupName $resourceGroup `
               -Location $location
    }
    else {
        Write-Host "NSG already exists:" $config.Name
    }

    foreach ($rule in $config.Rules) {

        $ruleConfig = New-AzNetworkSecurityRuleConfig `
            -Name $rule.Name `
            -Access Allow `
            -Protocol Tcp `
            -Direction Inbound `
            -Priority $rule.Priority `
            -SourceAddressPrefix $rule.Source `
            -SourcePortRange "*" `
            -DestinationAddressPrefix "*" `
            -DestinationPortRange $rule.Port

        $nsg.SecurityRules.Add($ruleConfig)

        if (-not ($nsg.SecurityRules | Where-Object { $_.Name -eq $rule.Name })) {
            $nsg.SecurityRules.Add($ruleConfig)
        }
        else {
            Write-Host "Rule already exists:" $rule.Name
        }
    }

    Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg
}

Write-Host "Security rules configured."

# =========================================

# Attach NSGs to Subnets

# =========================================

foreach ($config in $nsgConfigs) {

    $nsg = Get-AzNetworkSecurityGroup `
           -Name $config.Name `
           -ResourceGroupName $resourceGroup

    Write-Host "Associating" $config.Name "with subnet" $config.Subnet

    Set-AzVirtualNetworkSubnetConfig `
        -Name $config.Subnet `
        -VirtualNetwork $vnet `
        -AddressPrefix $config.Prefix `
        -NetworkSecurityGroup $nsg
}

Set-AzVirtualNetwork -VirtualNetwork $vnet

Write-Host "NSGs successfully associated with subnets."
