# Virtual Machine Architecture – Azure Infra Lab

## 1. Virtual Machine Deployment Overview

The infrastructure deploys multiple virtual machines configured for **high availability and secure network placement** inside the Azure virtual network.

The environment uses an **Availability Set** to distribute virtual machines across fault and update domains, improving reliability and resilience.

All virtual machines are deployed **without public IP addresses**, ensuring that access is restricted to the internal network and controlled through subnet-level security.

**Resource Group**

```
rg-prod-infrastructure
```

**Region**

```
westeurope
```

**Virtual Network**

```
vnet-lab
```

---

## 2. High Availability Strategy

The architecture uses an **Availability Set** to improve the availability of application workloads.

**Availability Set**

```
availset-app
```

### Availability Set Configuration

| Setting | Value |
|------|------|
| Fault Domains | 2 |
| Update Domains | 5 |
| SKU | Aligned |

### Why Availability Sets?

* Protect workloads from **hardware failures**
* Protect against **planned maintenance events**
* Ensure application instances are distributed across physical infrastructure
* Improve uptime for production workloads

This ensures that application services remain available even during infrastructure maintenance or failures.

---

## 3. Application Tier Deployment

The application layer consists of **two Linux virtual machines** deployed inside the **AppSubnet**.

**Virtual Machines**

```
app-vm-01
app-vm-02
```

**Operating System**

```
Ubuntu 22.04 LTS
```

**VM Size**

```
Standard_D2s_v3
```

**Subnet**

```
AppSubnet (10.0.1.0/24)
```

### Purpose

* Host application services
* Run backend APIs
* Execute microservices workloads
* Process application requests

### Benefits

* Horizontal scalability with multiple application instances
* High availability through availability set placement
* Secure internal network connectivity
* Isolation from database and management layers

---

## 4. Database Tier Deployment

The data layer contains a **single Windows-based database server**.

**Virtual Machine**

```
db-vm-01
```

**Operating System**

```
Windows Server 2022 Datacenter
```

**VM Size**

```
Standard_D2s_v3
```

**Subnet**

```
DBSubnet (10.0.2.0/24)
```

### Purpose

* Host relational database workloads
* Provide persistent storage for applications
* Manage structured data services

### Benefits

* Isolated database tier for improved security
* Controlled inbound access from application layer
* Protection of sensitive data workloads

---

## 5. Network Placement Model

All virtual machines are deployed within the **enterprise virtual network** to enable secure internal communication.

```
vnet-lab
│
├── AppSubnet
│     ├── app-vm-01
│     └── app-vm-02
│
└── DBSubnet
      └── db-vm-01
```

This architecture enforces separation between:

* Application servers
* Database servers
* Administrative management layer

---

## 6. Security Considerations

The virtual machine deployment follows several enterprise security practices.

Security controls include:

* No public IP addresses assigned to virtual machines
* Subnet-level network security group enforcement
* Internal network communication only
* Controlled administrative access paths

These measures help:

* Reduce the external attack surface
* Prevent unauthorized inbound connections
* Secure sensitive infrastructure workloads

---

## 7. Cost Optimization Strategy

To control costs within the lab environment, **automatic VM shutdown** is configured.

**Auto Shutdown Time**

```
19:00 (7:00 PM)
```

This configuration ensures:

* Virtual machines automatically stop during non-working hours
* Reduced compute costs for lab environments
* Efficient resource utilization

The following virtual machines are included in the shutdown schedule:

```
app-vm-01
app-vm-02
db-vm-01
```

---

## 8. Enterprise Architecture Alignment

This virtual machine architecture follows key enterprise cloud design principles:

* High availability through availability sets
* Network segmentation between application and data layers
* Secure internal-only network communication
* Controlled administrative access
* Cost-efficient lab operations

---
