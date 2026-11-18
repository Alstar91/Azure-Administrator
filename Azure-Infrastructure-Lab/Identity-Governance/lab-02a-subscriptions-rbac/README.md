# Lab 02a – Manage Subscriptions and RBAC   🟡 2/4

Official instructions: [LAB_02a_Manage_Subscriptions_and_RBAC_Entra](https://github.com/MicrosoftLearning/AZ-104-MicrosoftAzureAdministrator/blob/master/Instructions/Labs/LAB_02a_Manage_Subscriptions_and_RBAC_Entra.md)

**Prerequisite:** Lab 01 groups; resource groups from lab-02b `create-resource-groups.ps1`

| # | Task | Status | Script / Notes |
|---|---|---|---|
| 1 | Implement management groups | ✅ | `deploy-management-groups.ps1` (creates `az104-mg1`, moves subscription into it) |
| 2 | Review and assign a built-in Azure role | ✅ | `deploy-rbac.ps1` (Reader at subscription, Contributor per RG) |
| 3 | Create a custom RBAC role | ❌ |  |
| 4 | Monitor role assignments with the Activity Log | ❌ |  |

## Scripts

- `deploy-management-groups.ps1`
- `clean-management-groups.ps1` – moves the subscription back to the Tenant Root Group and deletes `az104-mg1`
- `deploy-rbac.ps1`

## Run order

1. `deploy-management-groups.ps1`
2. `deploy-rbac.ps1`
