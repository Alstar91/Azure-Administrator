<#
.SYNOPSIS
Deploys an Internal Standard Load Balancer with HTTP (80).

.DESCRIPTION
Creates:
- Internal Load Balancer (Private IP)
- Backend Pool
- HTTP Health Probe
- HTTP Load Balancing Rule
- Attaches VMs to backend pool

NOTE:
Used behind Application Gateway for internal traffic distribution.
#>

# Ensure Azure Login

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

$resourceGroup        = "rg-networking"
$appResourceGroup     = "rg-prod-infrastructure"
$location             = "westeurope"

$vnetName             = "vnet-lab"
$subnetName           = "AppSubnet"

$lbName               = "lb-internal-app"
$frontendName         = "lb-internal-frontend"
$backendPoolName      = "app-backend-pool"

$probeName            = "http-probe"
$ruleName             = "http-rule"

$privateIP            = "10.0.1.10"

$appVmNames           = @("app-vm-01","app-vm-02")

# =========================================

# Validate Resource Group

# =========================================

$rg = Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue
if (-not $rg) {
    Write-Host "Resource group not found." -ForegroundColor Red
    return
}

# =========================================

# Get VNet and Subnet

# =========================================

$vnet = Get-AzVirtualNetwork `
    -Name $vnetName `
    -ResourceGroupName $resourceGroup `
    -ErrorAction SilentlyContinue

if (-not $vnet) {
    Write-Host "Virtual Network not found." -ForegroundColor Red
    return
}

$subnet = Get-AzVirtualNetworkSubnetConfig `
    -Name $subnetName `
    -VirtualNetwork $vnet

# =========================================

# Frontend Config (Private IP)

# =========================================

$frontendIP = New-AzLoadBalancerFrontendIpConfig `
    -Name $frontendName `
    -SubnetId $subnet.Id `
    -PrivateIpAddress $privateIP

# =========================================

# Backend Pool

# =========================================

$backendPool = New-AzLoadBalancerBackendAddressPoolConfig `
    -Name $backendPoolName

# =========================================

# HTTP Probe

# =========================================

$probe = New-AzLoadBalancerProbeConfig `
    -Name $probeName `
    -Protocol Tcp `
    -Port 80 `
    -IntervalInSeconds 5 `
    -ProbeCount 1

# =========================================

# HTTP Rule

# =========================================

$rule = New-AzLoadBalancerRuleConfig `
    -Name $ruleName `
    -FrontendIpConfiguration $frontendIP `
    -BackendAddressPool $backendPool `
    -Probe $probe `
    -Protocol Tcp `
    -FrontendPort 80 `
    -BackendPort 80 `
    -IdleTimeoutInMinutes 4 `
    -LoadDistribution Default

# =========================================

# Create Internal Load Balancer

# =========================================

$lb = Get-AzLoadBalancer `
    -Name $lbName `
    -ResourceGroupName $resourceGroup `
    -ErrorAction SilentlyContinue

if (-not $lb) {

    $lb = New-AzLoadBalancer `
        -ResourceGroupName $resourceGroup `
        -Name $lbName `
        -Location $location `
        -Sku Standard `
        -FrontendIpConfiguration $frontendIP `
        -BackendAddressPool $backendPool `
        -Probe $probe `
        -LoadBalancingRule $rule

    Write-Host "Internal Load Balancer created."
}
else {
    Write-Host "Internal Load Balancer already exists."
}

# =========================================

# Attach VMs to Backend Pool

# =========================================

foreach ($vmName in $appVmNames) {

    $vm = Get-AzVM `
        -Name $vmName `
        -ResourceGroupName $appResourceGroup

    $nicId = $vm.NetworkProfile.NetworkInterfaces[0].Id
    $nic = Get-AzNetworkInterface -ResourceId $nicId

    $nic.IpConfigurations[0].LoadBalancerBackendAddressPools = @(
        $lb.BackendAddressPools[0]
    )

    Set-AzNetworkInterface -NetworkInterface $nic

    Write-Host "$vmName added to backend pool."
}

Write-Host "Internal Load Balancer setup completed successfully."
