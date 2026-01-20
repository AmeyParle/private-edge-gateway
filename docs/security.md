# Security Model

This project follows a **secure edge gateway pattern** with strict separation between public ingress and private workloads.

---

## No Public IPs on Workloads

- VM Scale Set instances have **no public IP addresses**
- Workloads are reachable **only via Application Gateway**
- Administrative access is performed using **Azure Bastion**
- Direct SSH/RDP exposure is avoided

---

## Secure Ingress

- **Azure Application Gateway (WAF_v2)** is the only public-facing component
- Web Application Firewall enabled in **Detection mode**
- Backend pool consists of private VM Scale Set instances
- Health probes ensure traffic is sent only to healthy backends

---

## Controlled Egress

- Outbound traffic from the application subnet is routed through **Azure Firewall**
- **User Defined Route (0.0.0.0/0)** forces egress via firewall
- Firewall application rules restrict outbound destinations (e.g., OS package repositories)

---

## Network Segmentation

- Separate subnets for:
  - Application Gateway
  - Application workloads (VMSS)
- Network Security Groups restrict inbound traffic to:
  - Application Gateway → Application subnet only
- Lateral movement between subnets is minimized

---

## Identity & Secrets

- Infrastructure uses **Azure Managed Identity** where applicable
- No credentials or secrets are stored in source code
- Key Vault integration is planned for future enhancements