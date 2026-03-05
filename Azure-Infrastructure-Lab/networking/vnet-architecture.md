# Virtual Network Architecture – Azure Infra Lab

## 1. Virtual Network Overview

The infrastructure uses a dedicated enterprise virtual network to provide secure network segmentation and controlled communication between application layers.

**Virtual Network**

```
vnet-lab
```

**Address Space**

```
10.0.0.0/16
```

### Why a /16 Address Space?

* Supports **65,536 private IP addresses**
* Allows future subnet expansion
* Prevents early network exhaustion
* Aligns with enterprise network planning practices

---

## 2. Subnet Segmentation Strategy

The virtual network is segmented into multiple subnets to isolate different workload tiers.

### App Subnet

**Name**

```
AppSubnet
```

**CIDR**

```
10.0.1.0/24
```

**Purpose**

* Application servers
* Backend APIs
* Microservices workloads
* Container workloads

**Benefits**

* Separates application tier from other layers
* Enables subnet-level security policies
* Supports independent scaling

---

### Database Subnet

**Name**

```
DBSubnet
```

**CIDR**

```
10.0.2.0/24
```

**Purpose**

* Database virtual machines
* Managed database services
* Data storage workloads

**Benefits**

* Strong data-layer isolation
* Enables strict inbound access rules
* Supports database security boundaries

---

### Management Subnet

**Name**

```
MgmtSubnet
```

**CIDR**

```
10.0.3.0/24
```

**Purpose**

* Azure Bastion
* Administrative access tools
* Jumpbox virtual machines

**Benefits**

* Centralized administrative access
* Prevents direct public exposure of workloads
* Enables secure operational management

---

## 3. Network Layer Isolation Model

The architecture follows a layered network design:

```
vnet-lab (10.0.0.0/16)
│
├── AppSubnet      (10.0.1.0/24)
│
├── DBSubnet       (10.0.2.0/24)
│
└── MgmtSubnet     (10.0.3.0/24)
```

This design enforces separation between:

* Application layer
* Data layer
* Administrative access layer

---

## 4. Security Considerations

The network architecture is designed to support enterprise security practices.

Security capabilities include:

* Network Security Groups (NSGs) applied to subnets
* Controlled inbound and outbound traffic rules
* Bastion-based secure administrative access
* Elimination of direct public IP exposure for internal services

This ensures:

* Reduced attack surface
* Controlled east-west traffic
* Secure administrative access paths

---

## 5. Enterprise Architecture Alignment

This virtual network architecture follows key enterprise cloud design principles:

* Layered network segmentation
* Dedicated management access layer
* Future-ready address space allocation
* Secure workload isolation
* Support for hub-spoke networking expansion

These practices align with **Azure landing zone architecture and enterprise infrastructure governance**.

---
