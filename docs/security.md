# Security Model

## No Public IPs on Workloads
VM/VMSS has no public IP. All admin access is via Azure Bastion.

## Secure Ingress
Application Gateway (WAF) is the only public entry point. Backend pool is private VMSS.

## Controlled Egress
All outbound traffic from workload subnet is routed to Azure Firewall using forced tunneling (UDR).

## Network Segmentation
Separate subnets for App Gateway and workloads. NSGs restrict inbound to minimum required.

## Identity (planned Day 4/5)
Use Managed Identity for workload access to Azure resources.
Key Vault will store secrets; no plaintext secrets in code.
