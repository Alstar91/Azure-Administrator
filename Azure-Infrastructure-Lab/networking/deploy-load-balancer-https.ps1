<#
.SYNOPSIS
Deploys a Public Standard Load Balancer with HTTP (80) and HTTPS (443).

.DESCRIPTION
Creates:
- Public IP
- Load Balancer
- Backend Pool
- HTTP + HTTPS Health Probes
- HTTP + HTTPS Load Balancing Rules
- Attaches VMs to backend pool

NOTE:
HTTPS requires nginx SSL configuration on VMs.
#>

# =========================================

# Ensure Azure Login

# =========================================

Connect-AzAccount -UseDeviceAuthentication

# =========================================

# Global Variables

# =========================================

$resourceGroup        = "rg-networking"
$location             = "westeurope"

$lbName               = "lb-app"
$frontendName         = "lb-frontend"
$publicIpName         = "lb-public-ip"
$backendPoolName      = "app-backend-pool"

$httpProbeName        = "http-probe"
$httpsProbeName       = "https-probe"

$httpRuleName         = "http-rule"
$httpsRuleName        = "https-rule"

$appVmNames           = @("app-vm-01","app-vm-02")
$appVmResourceGroup   = "rg-prod-infrastructure"

# =========================================

# Validate Resource Group

# =========================================

$rg = Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue
if (-not $rg) {
    Write-Host "Resource group not found." -ForegroundColor Red
    return
}

# =========================================

# Create Public IP

# =========================================

$pip = Get-AzPublicIpAddress `
    -Name $publicIpName `
    -ResourceGroupName $resourceGroup `
    -ErrorAction SilentlyContinue

if (-not $pip) {
    $pip = New-AzPublicIpAddress `
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

# Frontend Config

# =========================================

$frontendIP = New-AzLoadBalancerFrontendIpConfig `
    -Name $frontendName `
    -PublicIpAddress $pip

# =========================================

# Backend Pool

# =========================================

$backendPool = New-AzLoadBalancerBackendAddressPoolConfig `
    -Name $backendPoolName

# =========================================

# HTTP Probe

# =========================================

$httpProbe = New-AzLoadBalancerProbeConfig `
    -Name $httpProbeName `
    -Protocol Http `
    -Port 80 `
    -RequestPath "/" `
    -IntervalInSeconds 5 `
    -ProbeCount 1

# =========================================

# HTTPS Probe

# =========================================

$httpsProbe = New-AzLoadBalancerProbeConfig `
    -Name $httpsProbeName `
    -Protocol Https `
    -Port 443 `
    -RequestPath "/" `
    -IntervalInSeconds 5 `
    -ProbeCount 1

# =========================================

# HTTP Rule

# =========================================

$httpRule = New-AzLoadBalancerRuleConfig `
    -Name $httpRuleName `
    -FrontendIpConfiguration $frontendIP `
    -BackendAddressPool $backendPool `
    -Probe $httpProbe `
    -Protocol Tcp `
    -FrontendPort 80 `
    -BackendPort 80 `
    -IdleTimeoutInMinutes 4 `
    -LoadDistribution Default

# =========================================

# HTTPS Rule

# =========================================

$httpsRule = New-AzLoadBalancerRuleConfig `
    -Name $httpsRuleName `
    -FrontendIpConfiguration $frontendIP `
    -BackendAddressPool $backendPool `
    -Probe $httpsProbe `
    -Protocol Tcp `
    -FrontendPort 443 `
    -BackendPort 443 `
    -IdleTimeoutInMinutes 4 `
    -LoadDistribution Default

# =========================================

# Create Load Balancer

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
        -Probe $httpProbe, $httpsProbe `
        -LoadBalancingRule $httpRule, $httpsRule

    Write-Host "Load Balancer with HTTP & HTTPS created."
}
else {
    Write-Host "Load Balancer already exists."
}

# =========================================

# Attach VMs to Backend Pool

# =========================================

foreach ($vmName in $appVmNames) {

    $vm = Get-AzVM `
        -Name $vmName `
        -ResourceGroupName $appVmResourceGroup

    $nicId = $vm.NetworkProfile.NetworkInterfaces[0].Id
    $nic = Get-AzNetworkInterface -ResourceId $nicId

    $nic.IpConfigurations[0].LoadBalancerBackendAddressPools = @(
        $lb.BackendAddressPools[0]
    )

    Set-AzNetworkInterface -NetworkInterface $nic

    Write-Host "$vmName added to backend pool."
}

Write-Host "Load Balancer (HTTP + HTTPS) setup completed successfully."
