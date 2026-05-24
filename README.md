# AWS K3s Highly Available Platform (aws-k3s-ha-platform)
This project demonstrates building infrastructure for a highly available Kubernetes environment in AWS. The infrastructure is configured using Ansible for a reproducible infrastructure setup.

## Problem Statement
Provisioning and configuring a system of virtual machines to provide a highly available and scalable Kubernetes infrastructure is a complex task that warrants an comprehensive documentation and reproducibility. Using Infrastructure as Code (IaC) thru Terraform and Ansible, the complex configuration can be version controlled and reprovisioned if needed.

## Architecture

**Subnet Layout**
|Subnet|Nodes|Internet Access|
|---|---|---|
|Public|Bastion Host, NAT Gateway|Direct via Internet Gateway|
|Private|All other 11 nodes|Outbound NAT Gateway|

**Subnet CIDR**
|Subnet|Range|
|---|---|
|VPC|10.16.16.0/24|
|Public|10.16.16.0/26|
|Private|10.16.16.64/26|
|Bastion|Public Subnet|
|NAT Gateway|Public Subnet|
|All other nodes|Private Subnet|

**Availability Zone**
|Node|Accessibility Zone|
|---|---|
|All nodes|ap-southeast-1|

**Security Group Rules**
|Node|Inbound|Source|
|---|---|---|
|Bastion|22|0.0.0.0/0|
|HAproxy|6443|Private Subnet|
|k3s Master||HAproxy SG, Masters SG|
|k3s Worker||k3s Master SG|
|Postgres||k3s Master SG|
|All private nodes|22|Bastion|

![architecture diagram placeholder](docu/image.png)

**Stack:**
| Layer | Tool |
|---|---|
|Cloud Provider|AWS|
|Infrastructure|Terraform|
|Configuration Management|Ansible|
|Container Orchestration|K3S|
|Database|PostgreSQL|
|High Availability|HAproxy+KeepAlived|
|Database Synchronization|Patroni|

**AWS Resources:**
| Type | Resource | Purpose |
|---|---|---|
| Compute | EC2 (Amazon Linux 2023) | k3s master, k3s worker, HAProxy, and PostgreSQL nodes |
| Networking | VPC | Isolated network for all cluster nodes |
| Networking | Subnet | Subnetwork for node placement |
| Networking | Route Table | Routes traffic within the VPC and to the internet |
| Networking | Internet Gateway | Enables outbound internet access for public subnets |
| Networking | NAT Gateway | Outbound internet for nodes in the private subnet during provisioning |
| Networking | Security Group | Controls inbound/outbound traffic per node group |
| Security | Key Pair | SSH access to EC2 instances |
| Storage | S3 | Terraform remote state storage |
| Database | DynamoDB | Terraform state locking |

## Project Structure
```
.
├── README.md
├── ansible
│   ├── ansible.cfg
│   ├── group_vars
│   ├── host_vars
│   ├── inventory
│   ├── playbooks
│   │   ├── common.yaml
│   │   ├── ha.yaml
│   │   ├── k3s.yaml
│   │   ├── postgres.yaml
│   │   └── site.yaml
│   └── roles
│       ├── common
│       ├── etcd
│       ├── haproxy
│       ├── k3s_master
│       ├── k3s_worker
│       ├── keepalived
│       ├── patroni
│       └── postgres
└── terraform
    ├── backend.tf
    ├── compute
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── main.tf
    ├── networking
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── outputs.tf
    └── variables.tf
```

## Prerequisites
Before spinning up this infrastructure, the following MUST be already set-up
1. S3 bucket in AWS
2. DynamoDB table in AWS
3. `backend.tf` configured to use the S3 bucket and DynamoDB table

## How to Deploy
1. *to be updated*

## How to Destroy
1. To destroy the infrastructure, cd into `./terraform`
2. Run `terraform destroy -auto-approve`

## Design Decisions
| Decision | Why |
|---|---|
| 3 k3s masters, 3 PostgreSQL nodes | Both k3s embedded etcd and Patroni's etcd require quorum. 3 nodes tolerates 1 failure; 2 nodes cannot achieve quorum. |
| k3s over full Kubernetes | Lightweight and fast to provision. Sufficient for demonstrating a production-grade HA control plane without the operational overhead of full K8s. |
| Terraform backend provisioned manually | S3 bucket and DynamoDB table cannot be managed by the same Terraform config that uses them for state. Manual creation is the required for this set-up. |
| HAProxy + Keepalived for VIP | Two HAProxy nodes share a floating VIP via Keepalived. Workers and external clients connect to the VIP, which routes to whichever master is active. Two nodes is the minimum for HA failover. |
| etcd and Patroni co-located on PostgreSQL nodes | Patroni's reference architecture places etcd on the same nodes. A separate etcd cluster would add 3 instances with no advantage for this set-up. |
| Amazon Linux 2023 | Current AWS-supported standard and integrates natively with AWS services. Replaces AL2 (EOL). |
| Ansible roles over flat playbooks | Each component (haproxy, patroni, k3s, etc.) has its own tasks, templates, handlers, and vars. Roles provide structure and separation of concerns across a multi-node deployment. |
|Bastion Host Pattern| A Bastion Host will be assigned in the public subnet and will serve as a jump server from the internet into the infrastructure. This adds a layer of protection and lessens the surface of attack.
|NAT Gateway| Having a NAT gateway gives access to nodes in the private subnet. Although it is a paid service, it will be minimal with a destroy-after-validation workflow |
|Availability Zone| This project aims to demonstrate Infrastructure as Code. To keep configuration simple, everything will be stored in a single AZ (ap-southeast-1)|

## Key Learnings
-
-

## Recommendations
- for a true highly available set-up, nodes must be assigned in different availability zones

# Commit Message Convention

This repository follows the Conventional Commits specification to keep commit history
clear, consistent, and easy to review.

Format:
type(scope): short description

| Type | When to use |
|------|-------------|
| `feat` | Adding new infrastructure or resource |
| `fix` | Fixing broken config or resource |
| `docs` | README, comments, documentation |
| `chore` | gitignore, formatting, file cleanup |
| `refactor` | Restructuring code without changing behavior |

Examples:
- feat(vpc): add base VPC with CIDR
- fix(route-table): associate public subnet
- docs(readme): document architecture