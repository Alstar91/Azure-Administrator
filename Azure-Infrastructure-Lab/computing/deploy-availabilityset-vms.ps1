<#
.SYNOPSIS
Deploys virtual machines with high availability.

.DESCRIPTION
Creates an Availability Set and deploys:

* Two Linux application servers
* One Windows database server

All VMs are placed inside the virtual network
with no public IPs and subnet-level security.

Also enables auto-shutdown to control lab costs.

#>

# Ensure Azure login

Connect-AzAccount -UseDeviceAuthentication

# =========================================

# Global Variables

# =========================================

$resourceGroup = "rg-prod-infrastructure"
$networkResourceGroup = "rg-networking"
$location      = "westeurope"

$vnetName = "vnet-lab"
$appSubnetName = "AppSubnet"
$dbSubnetName  = "DBSubnet"

$availabilitySetName = "availset-app"

$vmSize = "Standard_D2s_v3"

$adminUser = "azureadmin"
$autoShutdownTime = "1900"

# =========================================

# Validate Resource Group

# =========================================

$rg = Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue

if (-not $rg) {
Write-Host "Resource group $resourceGroup does not exist." -ForegroundColor Red
return
}

# =========================================

# Get VNet and Subnets

# =========================================

$vnet = Get-AzVirtualNetwork `
    -Name $vnetName `
    -ResourceGroupName $networkResourceGroup `
    -ErrorAction SilentlyContinue

if (-not $vnet) {
    Write-Host "Virtual Network $vnetName not found in $networkResourceGroup" -ForegroundColor Red
    return
}

$appSubnet = Get-AzVirtualNetworkSubnetConfig `
-Name $appSubnetName `
-VirtualNetwork $vnet

$dbSubnet = Get-AzVirtualNetworkSubnetConfig `
-Name $dbSubnetName `
-VirtualNetwork $vnet

# =========================================

# Create Availability Set

# =========================================

if (-not (Get-AzAvailabilitySet `
-ResourceGroupName $resourceGroup `
-Name $availabilitySetName `
-ErrorAction SilentlyContinue)) {

New-AzAvailabilitySet `
    -Location $location `
    -Name $availabilitySetName `
    -ResourceGroupName $resourceGroup `
    -Sku aligned `
    -PlatformFaultDomainCount 2 `
    -PlatformUpdateDomainCount 5

Write-Host "Availability Set created."

}
else {
Write-Host "Availability Set already exists."
}

# =========================================

# Helper Function to Create Linux VM

# =========================================

function Create-LinuxVM {

param($vmName,$subnet)

$nic = New-AzNetworkInterface `
-Name "$vmName-nic" `
-ResourceGroupName $resourceGroup `
-Location $location `
-SubnetId $subnet.Id

$cred = Get-Credential -Message "Enter credentials for $vmName"

$vmConfig = New-AzVMConfig `
-VMName $vmName `
-VMSize $vmSize `
-AvailabilitySetId (Get-AzAvailabilitySet -ResourceGroupName $resourceGroup -Name $availabilitySetName).Id

$vmConfig = Set-AzVMOperatingSystem `
-VM $vmConfig `
-Linux `
-ComputerName $vmName `
-Credential $cred

$vmConfig = Set-AzVMSourceImage `
-VM $vmConfig `
-PublisherName Canonical `
-Offer ubuntu-22_04-lts `
-Skus server `
-Version latest

$vmConfig = Add-AzVMNetworkInterface `
-VM $vmConfig `
-Id $nic.Id

New-AzVM `
-ResourceGroupName $resourceGroup `
-Location $location `
-VM $vmConfig

Write-Host "$vmName created."

}

# =========================================

# Create App Servers

# =========================================

Create-LinuxVM "app-vm-01" $appSubnet
Create-LinuxVM "app-vm-02" $appSubnet

# =========================================

# Create Windows DB VM

# =========================================

$nic = New-AzNetworkInterface `
-Name "db-vm-01-nic" `
-ResourceGroupName $resourceGroup `
-Location $location `
-SubnetId $dbSubnet.Id

$cred = Get-Credential -Message "Enter credentials for db-vm-01"

$vmConfig = New-AzVMConfig `
-VMName "db-vm-01" `
-VMSize $vmSize

$vmConfig = Set-AzVMOperatingSystem `
-VM $vmConfig `
-Windows `
-ComputerName "db-vm-01" `
-Credential $cred `
-ProvisionVMAgent `
-EnableAutoUpdate

$vmConfig = Set-AzVMSourceImage `
-VM $vmConfig `
-PublisherName MicrosoftWindowsServer `
-Offer WindowsServer `
-Skus 2022-Datacenter `
-Version latest

$vmConfig = Add-AzVMNetworkInterface `
-VM $vmConfig `
-Id $nic.Id

New-AzVM `
-ResourceGroupName $resourceGroup `
-Location $location `
-VM $vmConfig

Write-Host "Database VM created."

# =========================================

# Enable Auto Shutdown

# =========================================

$vmList = "app-vm-01","app-vm-02","db-vm-01"

foreach ($vm in $vmList) {

    az vm auto-shutdown `
        --resource-group rg-prod-infrastructure `
        --name $vm `
        --time 1900 `
        --timezone "GMT Standard Time"

Write-Host "Auto shutdown enabled for $vm"

}
