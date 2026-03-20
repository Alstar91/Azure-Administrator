<#
.SYNOPSIS
Adds HTTPS support (port 443) to existing Load Balancer.

.DESCRIPTION
- Adds HTTPS health probe
- Adds HTTPS load balancing rule
- Reuses existing backend pool and frontend IP

NOTE:
SSL termination must be configured on VM (nginx).
#>

# =========================================

# Ensure Azure Login

# =========================================

Connect-AzAccount -UseDeviceAuthentication

# =========================================

# Variables

# =========================================

$resourceGroup = "rg-networking"
$lbName        = "lb-app"

$httpsProbeName = "https-probe"
$httpsRuleName  = "https-rule"

# =========================================

# Get Load Balancer

# =========================================

$lb = Get-AzLoadBalancer `
    -Name $lbName `
    -ResourceGroupName $resourceGroup

if (-not $lb) {
    Write-Host "Load Balancer not found." -ForegroundColor Red
    return
}

# =========================================

# Create HTTPS Health Probe

# =========================================

if (-not ($lb.Probes | Where-Object { $_.Name -eq $httpsProbeName })) {

    $httpsProbe = New-AzLoadBalancerProbeConfig `
        -Name $httpsProbeName `
        -Protocol Tcp `
        -Port 443 `
        -IntervalInSeconds 5 `
        -ProbeCount 2

    $lb.Probes.Add($httpsProbe)

    Write-Host "HTTPS probe created."
}
else {
    Write-Host "HTTPS probe already exists."
}

# =========================================

# Create HTTPS Load Balancing Rule

# =========================================

if (-not ($lb.LoadBalancingRules | Where-Object { $_.Name -eq $httpsRuleName })) {

    $frontend = $lb.FrontendIpConfigurations[0]
    $backend  = $lb.BackendAddressPools[0]
    $probe    = $lb.Probes | Where-Object { $_.Name -eq $httpsProbeName }

    $httpsRule = New-AzLoadBalancerRuleConfig `
        -Name $httpsRuleName `
        -FrontendIpConfiguration $frontend `
        -BackendAddressPool $backend `
        -Probe $probe `
        -Protocol Tcp `
        -FrontendPort 443 `
        -BackendPort 443 `
        -IdleTimeoutInMinutes 4 `
        -LoadDistribution Default

    $lb.LoadBalancingRules.Add($httpsRule)

    Write-Host "HTTPS rule created."
}
else {
    Write-Host "HTTPS rule already exists."
}

# =========================================

# Apply Changes

# =========================================

Set-AzLoadBalancer -LoadBalancer $lb

Write-Host "HTTPS configuration applied successfully."
