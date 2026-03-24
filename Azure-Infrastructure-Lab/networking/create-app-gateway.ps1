<#
.SYNOPSIS
Deploys Application Gateway with auto-generated SSL certificate.

.DESCRIPTION
- Creates Public IP with DNS
- Generates SSL cert using OpenSSL
- Converts to PFX
- Deploys Application Gateway
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

$backendIP       = "10.0.1.10"

$frontendName    = "app-gateway-frontend"
$frontendPortName= "https-port"

$backendPoolName = "app-gateway-backend-pool"
$httpSettingName = "app-gateway-http-setting"
$listenerName    = "app-gateway-https-listener"
$ruleName        = "app-gateway-http-rule"

$certName        = "ssl-cert"

# Paths (cross-platform safe)
$basePath = Get-Location
$keyPath  = Join-Path $basePath "appgw.key"
$crtPath  = Join-Path $basePath "appgw.crt"
$pfxPath  = Join-Path $basePath "appgw.pfx"

# =========================================

# Validate OpenSSL

# =========================================

if (-not (Get-Command openssl -ErrorAction SilentlyContinue)) {
    Write-Host "OpenSSL not found. Install it first." -ForegroundColor Red
    return
}

# =========================================

# Prompt for PFX Password

# =========================================

$certPasswordSecure = Read-Host "Enter PFX Password" -AsSecureString

$certPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($certPasswordSecure)
)

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

# Create Public IP with DNS

# =========================================

$dnsLabel = Read-Host "Enter DNS label (default: webapp$(Get-Random))"
if (-not $dnsLabel) {
    $dnsLabel = "webapp$(Get-Random)"
}

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
        -Sku Standard `
        -DomainNameLabel $dnsLabel

    Write-Host "Public IP created with DNS label."
}
else {
    Write-Host "Public IP already exists."
}

$fqdn = $pip.DnsSettings.Fqdn
Write-Host "FQDN:" $fqdn

# =========================================

# Generate Certificate (OpenSSL)

# =========================================

$subject = "/C=IE/ST=Dublin/L=Dublin/O=Infrastructure/OU=Brooklyn/CN=$fqdn"

Write-Host "Generating SSL certificate..."

openssl req -x509 -nodes -days 365 -newkey rsa:2048 `
-keyout $keyPath `
-out $crtPath `
-subj "$subject"

# =========================================

# Convert to PFX

# =========================================

Write-Host "Creating PFX..."

openssl pkcs12 -export `
-out $pfxPath `
-inkey $keyPath `
-in $crtPath `
-password pass:$certPasswordPlain

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

# SSL Certificate Object

# =========================================

$sslCert = New-AzApplicationGatewaySslCertificate `
    -Name $certName `
    -CertificateFile $pfxPath `
    -Password $certPasswordSecure

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

# Backend Pool

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

$sku = New-AzApplicationGatewaySku `
    -Name "Standard_v2" `
    -Tier "Standard_v2" `
    -Capacity 2

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
    -Sku $sku

Write-Host "Application Gateway deployed successfully!"
Write-Host "Access URL: https://$fqdn"
