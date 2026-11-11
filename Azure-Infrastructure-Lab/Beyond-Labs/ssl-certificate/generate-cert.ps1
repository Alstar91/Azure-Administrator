<#
.SYNOPSIS
Generates SSL certificate using OpenSSL and optionally converts to PFX.

.DESCRIPTION
Prompts user for certificate details and executes OpenSSL commands.
Supports optional PFX export.
#>

# =========================================

# Check OpenSSL Availability

# =========================================

if (-not (Get-Command openssl -ErrorAction SilentlyContinue)) {
    Write-Host "❌ OpenSSL is not installed or not in PATH." -ForegroundColor Red
    return
}

# =========================================

# Collect User Inputs

# =========================================

Write-Host "🔐 Certificate Details Input" -ForegroundColor Cyan

$country  = Read-Host "Country Code (e.g., IE)"
$state    = Read-Host "State (e.g., Dublin)"
$city     = Read-Host "City (e.g., Dublin)"
$org      = Read-Host "Organization (e.g., InfraLab)"
$orgUnit  = Read-Host "Organizational Unit (e.g., IT)"
$common   = Read-Host "Common Name (FQDN e.g., appgw.westeurope.cloudapp.azure.com)"

$keyOut   = Read-Host "Private Key Output File (e.g., appgw.key)"
$crtOut   = Read-Host "Certificate Output File (e.g., appgw.crt)"

# =========================================

# Build Subject String

# =========================================

$subject = "/C=$country/ST=$state/L=$city/O=$org/OU=$orgUnit/CN=$common"

# =========================================

# Generate Certificate

# =========================================

Write-Host "`n🚀 Generating certificate..." -ForegroundColor Yellow

$opensslCmd = @"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 `
-keyout $keyOut `
-out $crtOut `
-subj "$subject"
"@

Invoke-Expression $opensslCmd

Write-Host "✅ Certificate and key generated successfully." -ForegroundColor Green

# =========================================

# Ask for PFX Conversion

# =========================================

$convertToPfx = Read-Host "`nDo you want to convert to PFX? (yes/no)"

if ($convertToPfx -eq "yes") {

    $pfxOut = Read-Host "Enter PFX Output File (e.g., appgw.pfx)"
    $pfxPassword = Read-Host "Enter PFX Password" -AsSecureString

    # Convert SecureString to plain text
    $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($pfxPassword)
    )

    Write-Host "`n🔄 Converting to PFX..." -ForegroundColor Yellow

    $pfxCmd = @"
openssl pkcs12 -export `
-out $pfxOut `
-inkey $keyOut `
-in $crtOut `
-password pass:$plainPassword
"@

    Invoke-Expression $pfxCmd

    Write-Host "✅ PFX file created successfully." -ForegroundColor Green
}
else {
    Write-Host "ℹ️ Skipping PFX conversion." -ForegroundColor Cyan
}

Write-Host "`n🎉 Process completed." -ForegroundColor Green
