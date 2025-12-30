# Architecture

## Topology
- Hub–Spoke VNets with VNet peering
- Centralized security services in Hub (Firewall, Bastion)
- Workloads in Spoke (App Gateway, VMSS)

## Address Space
### Hub VNet: 10.0.0.0/16
- AzureBastionSubnet: 10.0.10.0/27
- AzureFirewallSubnet: 10.0.20.0/26

### Spoke VNet: 10.1.0.0/16
- appgw-subnet: 10.1.10.0/24
- app-subnet: 10.1.1.0/24

## Traffic Flow
### Ingress
Internet → App Gateway (WAF) → private VMSS (Nginx)

### East-West
App Gateway to VMSS only (NSG restricted)

### Egress (forced tunneling)
VMSS → UDR 0.0.0.0/0 → Azure Firewall → Internet

## App Pattern
VMSS runs Nginx reverse proxy with upstream dependency (whoami) to create realistic failure modes (502) for monitoring/incident work.
