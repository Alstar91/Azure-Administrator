# Lab 04 – Implement Virtual Networking   🟡 1.5/4

Official instructions: [LAB_04-Implement_Virtual_Networking](https://github.com/MicrosoftLearning/AZ-104-MicrosoftAzureAdministrator/blob/master/Instructions/Labs/LAB_04-Implement_Virtual_Networking.md)

**Prerequisite:** lab-02b `create-resource-groups.ps1` (rg-networking)

| # | Task | Status | Script / Notes |
|---|---|---|---|
| 1 | Create a virtual network with subnets | ✅ | `create-virtual-network.ps1` (PowerShell instead of portal) |
| 2 | Create a virtual network and subnets using a template | ❌ |  |
| 3 | Configure communication between an ASG and an NSG | 🟡 | `create-network-security-groups.ps1` – NSGs done, ASG still to do |
| 4 | Configure public and private Azure DNS zones | ❌ |  |

## Scripts

- `create-virtual-network.ps1`
- `create-network-security-groups.ps1`

## Notes

- Run order: `create-virtual-network.ps1` → `create-network-security-groups.ps1`
