<#
.SYNOPSIS
Deploys an Application Gateway with HTTPS (SSL termination).

.DESCRIPTION
Creates:
- Dedicated App Gateway Subnet
- Public IP
- Application Gateway (Standard_v2)
- HTTPS Listener (443)
- Backend Pool (Internal Load Balancer)
- Routing Rule

NOTE:
Routes traffic to Internal Load Balancer (10.0.1.10)
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

$resourceGroup   = "rg-networking"
$location        = "westeurope"

$vnetName        = "vnet-lab"
$subnetName      = "AppGatewaySubnet"

$appGatewayName  = "app-gateway"
$publicIpName    = "app-gateway-ip"

$backendIP       = "10.0.1.10"   # Internal Load Balancer IP

$frontendName    = "app-gateway-frontend"
$frontendPortName= "https-port"

$backendPoolName = "app-gateway-backend-pool"
$httpSettingName = "app-gateway-http-setting"
$listenerName    = "app-gateway-https-listener"
$ruleName        = "app-gateway-http-rule"

$certName        = "ssl-cert"
$certPath        = "C:\certs\cert.pfx"   # UPDATE PATH
$certPassword    = "password"            # UPDATE PASSWORD

# =========================================

# Validate Resource Group

# =========================================

$rg = Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue
if (-not $rg) {
    Write-Host "Resource group not found." -ForegroundColor Red
    return
}

# =========================================

# Get Virtual Network

# =========================================

$vnet = Get-AzVirtualNetwork `
    -Name $vnetName `
    -ResourceGroupName $resourceGroup `
    -ErrorAction SilentlyContinue

if (-not $vnet) {
    Write-Host "Virtual Network not found." -ForegroundColor Red
    return
}

# =========================================

# Ensure App Gateway Subnet Exists

# =========================================

$subnet = Get-AzVirtualNetworkSubnetConfig `
    -Name $subnetName `
    -VirtualNetwork $vnet `
    -ErrorAction SilentlyContinue

if (-not $subnet) {

    Add-AzVirtualNetworkSubnetConfig `
        -Name $subnetName `
        -AddressPrefix "10.0.5.0/24" `
        -VirtualNetwork $vnet

    $vnet | Set-AzVirtualNetwork

    # Refresh VNet
    $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup

    $subnet = Get-AzVirtualNetworkSubnetConfig `
        -Name $subnetName `
        -VirtualNetwork $vnet

    Write-Host "Application Gateway subnet created."
}
else {
    Write-Host "Application Gateway subnet already exists."
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

# Check if App Gateway Exists

# =========================================

$appGw = Get-AzApplicationGateway `
    -Name $appGatewayName `
    -ResourceGroupName $resourceGroup `
    -ErrorAction SilentlyContinue

if ($appGw) {
    Write-Host "Application Gateway already exists. Skipping..."
    return
}

# =========================================

# SSL Certificate

# =========================================

$securePassword = ConvertTo-SecureString $certPassword -AsPlainText -Force

$sslCert = New-AzApplicationGatewaySslCertificate `
    -Name $certName `
    -CertificateFile $certPath `
    -Password $securePassword

# =========================================

# Frontend Config

# =========================================

$frontendIP = New-AzApplicationGatewayFrontendIPConfig `
    -Name $frontendName `
    -PublicIPAddress $pip

$frontendPort = New-AzApplicationGatewayFrontendPort `
    -Name $frontendPortName `
    -Port 443

# =========================================

# Backend Pool (ILB)

# =========================================

$backendPool = New-AzApplicationGatewayBackendAddressPool `
    -Name $backendPoolName `
    -BackendIPAddresses $backendIP

# =========================================

# HTTP Settings

# =========================================

$httpSettings = New-AzApplicationGatewayBackendHttpSettings `
    -Name $httpSettingName `
    -Port 80 `
    -Protocol Http `
    -CookieBasedAffinity Disabled

# =========================================

# HTTPS Listener

# =========================================

$listener = New-AzApplicationGatewayHttpListener `
    -Name $listenerName `
    -Protocol Https `
    -FrontendIPConfiguration $frontendIP `
    -FrontendPort $frontendPort `
    -SslCertificate $sslCert

# =========================================

# Routing Rule

# =========================================

$rule = New-AzApplicationGatewayRequestRoutingRule `
    -Name $ruleName `
    -RuleType Basic `
    -HttpListener $listener `
    -BackendAddressPool $backendPool `
    -BackendHttpSettings $httpSettings

# =========================================

# Create Application Gateway

# =========================================

New-AzApplicationGateway `
    -Name $appGatewayName `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -BackendAddressPools $backendPool `
    -BackendHttpSettingsCollection $httpSettings `
    -FrontendIpConfigurations $frontendIP `
    -GatewayIpConfigurations (New-AzApplicationGatewayIPConfiguration `
        -Name "app-gateway-ipconfig" `
        -Subnet $subnet) `
    -FrontendPorts $frontendPort `
    -HttpListeners $listener `
    -RequestRoutingRules $rule `
    -SslCertificates $sslCert `
    -Sku Standard_v2 `
    -Capacity 2

Write-Host "Application Gateway setup completed successfully."
