# Lab 06 – Implement Network Traffic Management   🟡 2.5/3

Official instructions: [LAB_06-Implement_Network_Traffic_Management](https://github.com/MicrosoftLearning/AZ-104-MicrosoftAzureAdministrator/blob/master/Instructions/Labs/LAB_06-Implement_Network_Traffic_Management.md)

**Prerequisite:** lab-04 VNet, lab-08 VMs

| # | Task | Status | Script / Notes |
|---|---|---|---|
| 1 | Provision the infrastructure | ✅ | Uses lab-08 VMs |
| 2 | Configure an Azure Load Balancer | ✅ | `deploy-load-balancer.ps1` (public, HTTP + HTTPS) |
| 3 | Configure an Azure Application Gateway | 🟡 | `create-app-gateway.ps1` – SSL done; lab's path-based routing (`/image/*`, `/video/*`) still to do |

## Scripts

- `deploy-load-balancer.ps1`
- `create-app-gateway.ps1`
