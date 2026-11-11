# Bastion Secure Access – Azure Infra Lab

## 1. Overview

Azure Bastion is deployed to provide **secure, browser-based access** to virtual machines without exposing them to the public internet.

This implementation follows **enterprise security best practices** by eliminating public IPs on VMs and centralizing access through a managed service.

---

## 2. Deployment Configuration

Azure Bastion is deployed using the following configuration:

| Setting | Value |
|--------|------|
| Resource Group | rg-networking |
| Virtual Network | vnet-lab |
| Bastion Name | bastion-host |
| Public IP | bastion-ip |
| Region | westeurope |

---

## 3. Network Architecture

```plaintext
Internet
   │
   ▼
Bastion (Public Entry Point)
   │
   ▼
Virtual Network: vnet-lab
│
├── AzureBastionSubnet   (Managed by Azure)
├── AppSubnet            (app-vm-01, app-vm-02)
├── DBSubnet             (db-vm-01)
└── MgmtSubnet           (Admin / Jumpbox)
```

---

## 4. AzureBastionSubnet Requirements

Azure Bastion requires a dedicated subnet with strict constraints:

| Requirement | Value |
|------------|------|
| Subnet Name | AzureBastionSubnet (mandatory) |
| Address Range | /27 minimum |
| Example CIDR | 10.0.4.0/27 |

### Important Notes

- Cannot reuse existing subnets (e.g., MgmtSubnet)
- Must be isolated for Azure-managed operations
- Required for Bastion deployment

---

## 5. Public IP Configuration

A Standard SKU Public IP is created for Bastion:

- Name: `bastion-ip`
- Allocation: Static
- SKU: Standard

### Why Standard SKU?

- Required for Azure Bastion
- Provides improved reliability and security
- Supports zone-redundant architecture

---

## 6. Security Model

This design enforces a **zero public exposure model**.

### Key Principles

- No public IPs on application or database VMs
- All administrative access routed through Bastion
- Secure RDP/SSH over HTTPS (port 443)
- Centralized access control point

---

## 7. NSG Considerations

| Subnet | NSG Required |
|-------|-------------|
| AzureBastionSubnet | ❌ No |
| AppSubnet | ✅ Yes |
| DBSubnet | ✅ Yes |
| MgmtSubnet | ✅ Yes |

### Important

Do NOT associate an NSG with `AzureBastionSubnet`.

Azure manages required traffic internally. Applying NSG may break connectivity.

---

## 8. Design Benefits

This architecture provides:

- Secure remote access without public exposure
- Centralized access control
- Reduced attack surface
- Simplified operations (no jumpbox required)
- Fully managed platform service

---

## 9. Enterprise Alignment

This setup aligns with:

- Zero Trust principles
- Least privilege access
- Network segmentation
- Secure administrative access patterns

---

## 10. Future Enhancements

This design can be extended with:

- Internal Load Balancer for application tier
- NSG rules for App ↔ DB traffic control
- Azure Firewall for deep packet inspection
- Private Endpoints for PaaS services

---
