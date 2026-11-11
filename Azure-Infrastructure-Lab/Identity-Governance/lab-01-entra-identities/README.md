# Lab 01 – Manage Microsoft Entra ID Identities   ✅ 2/2

Official instructions: [LAB_01-Manage_Entra_ID_Identities](https://github.com/MicrosoftLearning/AZ-104-MicrosoftAzureAdministrator/blob/master/Instructions/Labs/LAB_01-Manage_Entra_ID_Identities.md)

**Prerequisite:** Microsoft Graph PowerShell SDK

| # | Task | Status | Script / Notes |
|---|---|---|---|
| 1 | Create and configure user accounts | ✅ | `deploy-entra-identity.ps1` (Microsoft Graph PowerShell) |
| 2 | Create groups and add members | ✅ | `deploy-entra-identity.ps1` |

## Scripts

- `deploy-entra-identity.ps1`
- `clean-entra-identity.ps1`

## Notes

- `deploy-entra-identity.ps1` – also creates an app registration, service principal and client secret (beyond the lab)
- `clean-entra-identity.ps1` – removes everything created
