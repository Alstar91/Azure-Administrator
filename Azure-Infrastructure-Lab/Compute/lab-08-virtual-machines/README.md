# Lab 08 – Manage Virtual Machines   🟡 1.5/5

Official instructions: [LAB_08-Manage_Virtual_Machines](https://github.com/MicrosoftLearning/AZ-104-MicrosoftAzureAdministrator/blob/master/Instructions/Labs/LAB_08-Manage_Virtual_Machines.md)

**Prerequisite:** lab-04 `create-virtual-network.ps1` (vnet-lab, AppSubnet, DBSubnet)

| # | Task | Status | Script / Notes |
|---|---|---|---|
| 1 | Deploy zone-resilient VMs | 🟡 | `deploy-availabilityset-vms.ps1` uses an Availability Set, not availability zones |
| 2 | Manage compute and storage scaling (resize, data disks) | ❌ |  |
| 3 | Create and configure VM Scale Sets | ❌ |  |
| 4 | Scale VM Scale Sets | ❌ |  |
| 5 | Create a VM using Azure PowerShell / CLI | ✅ | `deploy-availabilityset-vms.ps1` |

## Scripts

- `deploy-availabilityset-vms.ps1`

## Notes

- These VMs are also the backend for lab-05 and lab-06
