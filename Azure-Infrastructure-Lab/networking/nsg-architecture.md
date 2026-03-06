# Network Security Architecture – Azure Infra Lab

## 1. Network Security Overview

The infrastructure uses **Azure Network Security Groups (NSGs)** to enforce secure communication boundaries between application layers inside the virtual network.

Each subnet is protected with a dedicated NSG to control **inbound and outbound traffic**, ensuring only approved network communication is allowed.

**Network Security Groups**

```
nsg-app
nsg-db
nsg-mgmt
```

These security groups are attached at the **subnet level**, allowing centralized enforcement of security policies across the infrastructure.

---

## 2. NSG Segmentation Strategy

The network security architecture separates security controls by workload tier to enforce strict access policies and reduce lateral movement between services.

### Application Tier NSG

**Name**

```
nsg-app
```

**Associated Subnet**

```
AppSubnet
```

**Allowed Traffic**

```
TCP 80 (HTTP)
Source: Any
```

**Purpose**

* Accept incoming HTTP requests
* Serve application and API workloads
* Receive traffic routed from load balancers or gateways

**Benefits**

* Restricts application access to required service ports
* Prevents unauthorized inbound network connections
* Reduces exposure of backend services

---

### Database Tier NSG

**Name**

```
nsg-db
```

**Associated Subnet**

```
DBSubnet
```

**Allowed Traffic**

```
TCP 1433 (SQL)
Source: 10.0.1.0/24
```

**Purpose**

* Allow database access only from the application tier
* Support SQL Server workloads
* Secure backend data services

**Benefits**

* Prevents direct external access to databases
* Enforces application-to-database communication model
* Protects sensitive data services from unauthorized access

---

### Management Tier NSG

**Name**

```
nsg-mgmt
```

**Associated Subnet**

```
MgmtSubnet
```

**Allowed Traffic**

```
TCP 22 (SSH)
```

**Purpose**

* Enable administrative access to infrastructure resources
* Support Azure Bastion or management tools
* Allow secure operational access to servers

**Benefits**

* Centralized operational access
* Prevents direct public exposure of production servers
* Enables secure administration of cloud infrastructure

---

## 3. Network Security Isolation Model

The NSG architecture follows a layered network protection model.

```
vnet-lab
│
├── AppSubnet
│      └── nsg-app
│
├── DBSubnet
│      └── nsg-db
│
└── MgmtSubnet
       └── nsg-mgmt
```

This design enforces separation between:

* Application services
* Database services
* Administrative management layer

---

## 4. Security Enforcement Model

Azure Network Security Groups operate using a **default deny model**.

This means:

* Only explicitly allowed traffic is permitted
* All other inbound traffic is automatically denied

Security controls implemented include:

* Subnet-level network security policies
* Controlled inbound service access
* Restricted database connectivity
* Secure administrative access paths

These controls reduce:

* Unauthorized network access
* Lateral movement between services
* Exposure of sensitive infrastructure components

---

## 5. Zero Trust Networking Principles

The network architecture follows **Zero Trust security principles**, where no communication is trusted by default.

Security characteristics include:

* Explicitly allowing only required traffic
* Blocking all unspecified inbound connections
* Restricting database access to the application tier
* Using a dedicated management subnet for operational access

This approach ensures:

* Minimal attack surface
* Strong service isolation
* Controlled workload communication

---

## 6. Enterprise Architecture Alignment

The NSG security model aligns with enterprise cloud security best practices.

Key architectural principles implemented include:

* Tier-based network segmentation
* Principle of least privilege
* Secure workload isolation
* Controlled east-west network traffic
* Centralized administrative access

---
