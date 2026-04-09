<#
.SYNOPSIS
Deploys Microsoft Entra ID users, groups, and service principal.

.DESCRIPTION
- Creates users (admin + developer)
- Creates security groups
- Assigns users to groups
- Creates app registration
- Creates service principal
- Generates client secret

NOTE:
Requires Microsoft Graph PowerShell SDK.
#>

# =========================================

# Ensure Microsoft Graph Connection

# =========================================

$module = Get-Module Microsoft.Graph -ListAvailable

if (-not $module) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force
} else {
    Write-Host "Microsoft.Graph already available." -ForegroundColor Green
}

Import-Module Microsoft.Graph

Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All","Application.ReadWrite.All","Directory.ReadWrite.All"

$context = Get-MgContext
if (-not $context) {
    Write-Host "Graph connection failed." -ForegroundColor Red
    return
}

Write-Host "Connected to tenant:" $context.TenantId

# =========================================

# Global Variables

# =========================================

$tenantDomain = "aashishchavan91gmail.onmicrosoft.com"

$appAdminUPN = "app-admin-user@$tenantDomain"
$appDevUPN   = "app-dev-user@$tenantDomain"

$appName     = "app-backend-service"

# =========================================

# Password Profile

# =========================================

$passwordProfile = @{
    Password = "TempP@ss123!"
    ForceChangePasswordNextSignIn = $true
}

# =========================================

# Create Users

# =========================================

$appAdminUser = Get-MgUser -Filter "userPrincipalName eq '$appAdminUPN'" -ErrorAction SilentlyContinue

if (-not $appAdminUser) {

    $appAdminUser = New-MgUser `
        -DisplayName "App Admin User" `
        -UserPrincipalName $appAdminUPN `
        -MailNickname "appadminuser" `
        -AccountEnabled `
        -PasswordProfile $passwordProfile

    Write-Host "App Admin user created."
}
else {
    Write-Host "App Admin user already exists."
}

$appDevUser = Get-MgUser -Filter "userPrincipalName eq '$appDevUPN'" -ErrorAction SilentlyContinue

if (-not $appDevUser) {

    $appDevUser = New-MgUser `
        -DisplayName "App Dev User" `
        -UserPrincipalName $appDevUPN `
        -MailNickname "appdevuser" `
        -AccountEnabled `
        -PasswordProfile $passwordProfile

    Write-Host "App Dev user created."
}
else {
    Write-Host "App Dev user already exists."
}

# =========================================

# Create Groups

# =========================================

$appAdminGroupName = "app-admins"
$appAdminsGroup = Get-MgGroup -Filter "displayName eq '$appAdminGroupName'" -ErrorAction SilentlyContinue

if (-not $appAdminsGroup) {

    $appAdminsGroup = New-MgGroup `
        -DisplayName $appAdminGroupName `
        -MailEnabled:$false `
        -MailNickname "appadmins" `
        -SecurityEnabled

    Write-Host "app-admins group created."
}
else {
    Write-Host "app-admins group already exists."
}

$appDevelopersGroupName = "app-developers"
$appDevelopersGroup = Get-MgGroup -Filter "displayName eq '$appDevelopersGroupName'" -ErrorAction SilentlyContinue

if (-not $appDevelopersGroup) {

    $appDevelopersGroup = New-MgGroup `
        -DisplayName $appDevelopersGroupName `
        -MailEnabled:$false `
        -MailNickname "appdevelopers" `
        -SecurityEnabled

    Write-Host "app-developers group created."
}
else {
    Write-Host "app-developers group already exists."
}

# =========================================

# Add Users to Groups

# =========================================

New-MgGroupMember `
    -GroupId $appAdminsGroup.Id `
    -DirectoryObjectId $appAdminUser.Id `
    -ErrorAction SilentlyContinue

New-MgGroupMember `
    -GroupId $appDevelopersGroup.Id `
    -DirectoryObjectId $appDevUser.Id `
    -ErrorAction SilentlyContinue

Write-Host "Users assigned to groups."

# =========================================

# Create App Registration

# =========================================

$app = Get-MgApplication -Filter "displayName eq '$appName'" -ErrorAction SilentlyContinue

if (-not $app) {

    $app = New-MgApplication `
        -DisplayName $appName `
        -SignInAudience "AzureADMyOrg"

    Write-Host "App Registration created."
}
else {
    Write-Host "App Registration already exists."
}

# =========================================

# Create Service Principal

# =========================================

$sp = Get-MgServicePrincipal -Filter "appId eq '$($app.AppId)'" -ErrorAction SilentlyContinue

if (-not $sp) {

    $sp = New-MgServicePrincipal `
        -AppId $app.AppId

    Write-Host "Service Principal created."
}
else {
    Write-Host "Service Principal already exists."
}

# =========================================

# Create Client Secret

# =========================================

$secret = Add-MgApplicationPassword `
    -ApplicationId $app.Id `
    -PasswordCredential @{
        DisplayName = "app-secret"
    }

Write-Host "========================================="
Write-Host "Client Secret (SAVE THIS SECURELY):"
Write-Host $secret.SecretText
Write-Host "========================================="

Write-Host "Entra ID setup completed successfully!"

Write-Host "==== USERS ===="
Get-MgUser -Filter "userPrincipalName eq '$appAdminUPN'" |
Select DisplayName, UserPrincipalName

Write-Host "==== GROUPS ===="
Get-MgGroup -Filter "startsWith(displayName,'app-')" |
Select DisplayName

Write-Host "==== APPLICATION ===="
Get-MgApplication -Filter "displayName eq '$appName'" |
Select DisplayName, AppId

Write-Host "==== SERVICE PRINCIPAL ===="
Get-MgServicePrincipal -Filter "displayName eq '$appName'" |
Select DisplayName, AppId
