# =========================================
# Cleanup Entra ID Resources
# =========================================


# =========================================
# Ensure Microsoft Graph Module
# =========================================

if (-not (Get-Module Microsoft.Graph -ListAvailable)) {
    Write-Host "Microsoft.Graph module not found. Installing..." -ForegroundColor Yellow
    
    Install-Module Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force
    
    Write-Host "Microsoft.Graph module installed successfully." -ForegroundColor Green
}

# Import module (safe even if already loaded)
Import-Module Microsoft.Graph

# Ensure Graph connection
Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All","Application.ReadWrite.All","Directory.ReadWrite.All"

# Variables
$tenantDomain = "aashishchavan91gmail.onmicrosoft.com"  
$appAdminUPN = "app-admin-user@$tenantDomain"
$appDevUPN   = "app-dev-user@$tenantDomain"
$appName     = "app-backend-service"

# =========================================
# Delete Users
# =========================================

$appAdminUser = Get-MgUser -Filter "userPrincipalName eq '$appAdminUPN'" -ErrorAction SilentlyContinue
if ($appAdminUser) {
    Remove-MgUser -UserId $appAdminUser.Id
    Write-Host "Deleted App Admin user."
}

$appDevUser = Get-MgUser -Filter "userPrincipalName eq '$appDevUPN'" -ErrorAction SilentlyContinue
if ($appDevUser) {
    Remove-MgUser -UserId $appDevUser.Id
    Write-Host "Deleted App Dev user."
}

# =========================================
# Delete Groups
# =========================================

$appAdminsGroup = Get-MgGroup -Filter "displayName eq 'app-admins'" -ErrorAction SilentlyContinue
if ($appAdminsGroup) {
    Remove-MgGroup -GroupId $appAdminsGroup.Id
    Write-Host "Deleted app-admins group."
}

$appDevelopersGroup = Get-MgGroup -Filter "displayName eq 'app-developers'" -ErrorAction SilentlyContinue
if ($appDevelopersGroup) {
    Remove-MgGroup -GroupId $appDevelopersGroup.Id
    Write-Host "Deleted app-developers group."
}

# =========================================
# Delete Service Principal
# =========================================

$app = Get-MgApplication -Filter "displayName eq '$appName'" -ErrorAction SilentlyContinue

if ($app) {

    $sp = Get-MgServicePrincipal -Filter "appId eq '$($app.AppId)'" -ErrorAction SilentlyContinue

    if ($sp) {
        Remove-MgServicePrincipal -ServicePrincipalId $sp.Id
        Write-Host "Deleted Service Principal."
    }

    # =========================================
    # Delete App Registration
    # =========================================

    Remove-MgApplication -ApplicationId $app.Id
    Write-Host "Deleted App Registration."
}

Write-Host "Cleanup completed successfully."
