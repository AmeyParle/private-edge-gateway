# Enterprise Azure Private Application Platform

## Overview
A production-style Azure platform using hub–spoke networking, centralized egress inspection (Azure Firewall), secure admin access (Bastion), and WAF-based ingress (Application Gateway). App workload runs privately on VMSS.

## Architecture
- Hub–Spoke topology
- Azure Firewall + forced tunneling (UDR)
- Bastion-only administration (no public IPs on workloads)
- Application Gateway (WAF) ingress to private VMSS
- Nginx reverse proxy + upstream dependency (whoami)

## Security Model
- No public IPs for VM/VMSS
- Least privilege + scoped RBAC (documented)
- Planned Key Vault + Managed Identity (Day 5)

## Operations
- Planned Log Analytics + alerts
- Incident simulations + RCA docs

## Repo Structure
- infra/ (Terraform)
- docs/ (design + runbooks + incidents)
- app/ (nginx config)
