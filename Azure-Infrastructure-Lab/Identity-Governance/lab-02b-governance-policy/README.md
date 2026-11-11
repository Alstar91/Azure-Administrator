# Lab 02b – Manage Governance via Azure Policy   🟡 2/4

Official instructions: [LAB_02b-Manage_Governance_via_Azure_Policy](https://github.com/MicrosoftLearning/AZ-104-MicrosoftAzureAdministrator/blob/master/Instructions/Labs/LAB_02b-Manage_Governance_via_Azure_Policy.md)

**Prerequisite:** None – **run `create-resource-groups.ps1` first; every other lab depends on these resource groups**

| # | Task | Status | Script / Notes |
|---|---|---|---|
| 1 | Assign tags | ✅ | `create-resource-groups.ps1` (tags set at RG creation) |
| 2 | Enforce tagging via an Azure Policy | ❌ |  |
| 3 | Apply tagging via an Azure Policy | ❌ |  |
| 4 | Configure and test resource locks | ✅ | `apply-resource-locks.ps1` (CanNotDelete on prod) |

## Scripts

- `create-resource-groups.ps1`
- `list-resource-groups.ps1`
- `apply-resource-locks.ps1`
