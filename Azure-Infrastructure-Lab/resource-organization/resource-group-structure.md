# Resource Group Structure – Azure Infra Lab

## 1. Environment Separation Strategy

The infrastructure is divided into separate resource groups based on environment:

- rg-prod-infrastructure
- rg-nonprod-infrastructure
- rg-networking
- rg-monitoring

### Why Environment Separation Matters

Environment isolation ensures:

- Reduced blast radius
- Controlled RBAC access
- Cost tracking per environment
- Safer change management
- Clear lifecycle boundaries

Production resources must never share the same resource group as non-production workloads.

---

## 2. Shared Networking Resource Group

A dedicated networking resource group exists to host:

- Virtual Networks
- Subnets
- Network Security Groups
- Route Tables
- Private DNS Zones

### Why Separate Networking?

- Centralized control
- Easier governance
- Supports hub-spoke topology
- Enables cross-environment peering
- Aligns with enterprise landing zone principles

---

## 3. Resource Locks Strategy

Production resource groups have:

- Lock Type: CanNotDelete
- Lock Name: protect-prod

### Why Locks Only on Production?

Production requires:

- High availability
- Change control
- Risk mitigation

Non-production environments are intentionally left unlocked to allow flexibility during development and testing.

---

## 4. Tagging Taxonomy

All resource groups follow standardized tagging:

| Tag Name      | Purpose |
|--------------|----------|
| Environment  | Identifies environment (Prod / NonProd / Shared) |
| Owner        | Accountable engineer or team |
| Project      | Project identifier |
| Layer        | Infra / App / Monitoring |
| CreatedOn    | Resource creation date |
| CostCenter   | Billing and financial tracking |

### Tagging Objectives

- Cost Management reporting
- Policy enforcement
- Governance compliance
- Automation filtering
- Audit traceability

---

## 5. Governance Principles Applied

- Naming convention standardization
- Environment isolation
- Production resource protection
- Tag-driven cost visibility
- Operational readiness mindset
