<#
.SYNOPSIS
Deploys a Public Standard Load Balancer with backend pool, health probe, and rule.

.DESCRIPTION
Creates:
- Public IP
- Load Balancer
- Backend Pool (with app VMs)
- Health Probe (HTTP)
- Load Balancing Rule

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
$vnetName             = "vnet-lab"

$lbName               = "lb-app"
$frontendName         = "lb-frontend"
$publicIpName         = "lb-public-ip"
$backendPoolName      = "app-backend-pool"
$probeName            = "http-probe"
$ruleName             = "http-rule"

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
# Create Frontend Config
# =========================================

$frontendIP = New-AzLoadBalancerFrontendIpConfig `
    -Name $frontendName `
    -PublicIpAddress $pip

# =========================================
# Create Backend Pool
# =========================================

$backendPool = New-AzLoadBalancerBackendAddressPoolConfig `
    -Name $backendPoolName

# =========================================
# Create Health Probe
# =========================================

$probe = New-AzLoadBalancerProbeConfig `
    -Name $probeName `
    -Protocol Http `
    -Port 80 `
    -RequestPath "/" `
    -IntervalInSeconds 5 `
    -ProbeCount 2

# =========================================
# Create Load Balancer Rule
# =========================================

$lbrule = New-AzLoadBalancerRuleConfig `
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
        -Probe $probe `
        -LoadBalancingRule $lbrule

    Write-Host "Load Balancer created."
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

    # Attach backend pool
    $nic.IpConfigurations[0].LoadBalancerBackendAddressPools = @(
        $lb.BackendAddressPools[0]
    )

    Set-AzNetworkInterface -NetworkInterface $nic

    Write-Host "$vmName added to backend pool."
}

Write-Host "Load Balancer setup completed successfully."
