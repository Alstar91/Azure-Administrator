<#
.SYNOPSIS
Applies production protection lock.

.DESCRIPTION
Checks if the production resource group exists.
If it exists, verifies whether the lock is already present.
Applies CanNotDelete lock only if missing.
#>

# Ensure connection
Connect-AzAccount -UseDeviceAuthentication

# ================================
# Global Variables
# ================================

$owner      = "Aashish"
$prodRgName = "rg-prod-infrastructure"
$lockName   = "protect-prod"
$lockLevel  = "CanNotDelete"

# ================================
# Validate Resource Group
# ================================

$rg = Get-AzResourceGroup -Name $prodRgName -ErrorAction SilentlyContinue

if ($rg) {

    Write-Host "Resource Group exists. Checking for existing lock..."

    # Check if lock already exists
    $existingLock = Get-AzResourceLock `
        -ResourceGroupName $prodRgName `
        -LockName $lockName `
        -ErrorAction SilentlyContinue

    if ($existingLock) {
        Write-Host "Lock already exists. No action required."
    }
    else {
        Write-Host "Applying CanNotDelete lock..."
        
        New-AzResourceLock `
            -ResourceGroupName $prodRgName `
            -LockName $lockName `
            -LockLevel $lockLevel

        Write-Host "Lock applied successfully."
    }

}
else {
    Write-Host "Resource Group does not exist. Lock not applied."
}
