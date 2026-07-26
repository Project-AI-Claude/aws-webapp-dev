# AWS 3-Tier Web App - Terraform

> Modular, production-ready Infrastructure-as-Code for a secure, multi-AZ 3-tier web application on AWS (`us-east-1`), built with Terraform and Claude Code.

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-844FBA?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/AWS%20Provider-~%3E5.40-FF9900?logo=amazonaws&logoColor=white)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](#license)

📊 **[View the interactive architecture presentation →](presentation.html)**

---

## Overview

| | |
|---|---|
| **Terraform Modules** | 6 |
| **Availability Zones** | 3 |
| **Subnets** | 9 |
| **Tiers** | 3 (Public · App · Data) |
| **Resources on Apply** | ~45 |
| **Apply Time** | ~8–12 minutes |

This project provisions a complete, defence-in-depth 3-tier architecture: **WAF → Application Load Balancer → EC2 App Tier → Aurora PostgreSQL**, spread across three Availability Zones for high availability, with strict security-group-to-security-group isolation between every tier.

---

## Architecture

```
Internet
   │
   ▼
🛡️  WAFv2 (Regional)  — OWASP + Known Bad Inputs + SQLi + Rate Limiting
   │
   ▼  Internet Gateway
┌─────────────────────────────────────────────┐
│  Public Subnets × 3 AZ                       │
│  ⚖️  Application Load Balancer               │
│  🔀  NAT Gateway     🌐  Internet Gateway     │
└─────────────────────────────────────────────┘
   │  ALB-SG → App-SG (80 / 443 / 8080 only)
   ▼
┌─────────────────────────────────────────────┐
│  App Subnets × 3 AZ                          │
│  🖥️  EC2 app-1 (1a) · app-2 (1b) · app-3 (1c) │
└─────────────────────────────────────────────┘
   │  App-SG → DB-SG (5432 only) · no internet route
   ▼
┌─────────────────────────────────────────────┐
│  DB Subnets × 3 AZ                           │
│  🗄️  Aurora PostgreSQL 15 — Writer + Reader  │
│  🔒  Isolated route table (no default route) │
└─────────────────────────────────────────────┘
```

---

## Module Structure

| Module | Description | Key Detail |
|---|---|---|
| **`vpc`** | VPC, 9 subnets, IGW, NAT Gateway, 3 route tables with least-privilege routing | `10.0.0.0/16` |
| **`security_groups`** | ALB-SG, App-SG, DB-SG — each references the upstream SG, no CIDR-based rules | Least privilege |
| **`alb`** | Internet-facing ALB, target group with health checks, HTTP→HTTPS redirect when a cert is provided | TLS 1.3 |
| **`waf`** | WAFv2 Regional ACL with 3 AWS managed rule sets + custom rate limiting; CloudWatch logs (30-day retention) | Rate: 2,000 req / 5 min |
| **`ec2`** | 3 app instances (1 per AZ), IMDSv2 enforced, SSM agent, IAM instance profile, encrypted gp3 EBS | `t3.medium` |
| **`rds`** | Aurora PostgreSQL 15 cluster (writer + reader), encrypted storage, Performance Insights, final snapshot on destroy | Multi-AZ |

Each module is self-contained with its own `variables.tf`, `main.tf`, and `outputs.tf`.

---

## Network Design

### Subnet Layout

| Subnet | CIDR | AZ | Tier |
|---|---|---|---|
| `public-1` | `10.0.0.0/24` | 1a | Public |
| `public-2` | `10.0.1.0/24` | 1b | Public |
| `public-3` | `10.0.2.0/24` | 1c | Public |
| `app-1` | `10.0.10.0/24` | 1a | App |
| `app-2` | `10.0.11.0/24` | 1b | App |
| `app-3` | `10.0.12.0/24` | 1c | App |
| `db-1` | `10.0.20.0/24` | 1a | DB |
| `db-2` | `10.0.21.0/24` | 1b | DB |
| `db-3` | `10.0.22.0/24` | 1c | DB |

### Route Tables

| Route Table | Default Route | Used By |
|---|---|---|
| `public-rt` | → IGW | 3 public subnets |
| `private-rt` | → NAT GW | 3 app subnets |
| `db-rt` | *None* | 3 DB subnets |

### Key Design Decisions

- DB subnets have **no default route** — zero internet exposure
- Single NAT Gateway in AZ-1 (cost-optimised for dev)
- ALB spans all 3 public subnets for high availability
- Each app EC2 instance runs in its own AZ for fault isolation
- DNS hostnames and DNS support enabled on the VPC

---

## Security Groups

SG-to-SG references only — **no CIDR-based rules between tiers**.

**`dev-client-alb-sg`**
| Port | Direction | Source/Dest | Action |
|---|---|---|---|
| 80 | Inbound | `0.0.0.0/0` | ALLOW |
| 443 | Inbound | `0.0.0.0/0` | ALLOW |
| All | Outbound | `0.0.0.0/0` | ALLOW |

**`dev-client-app-sg`**
| Port | Direction | Source/Dest | Action |
|---|---|---|---|
| 80 / 443 / 8080 | Inbound | ALB-SG only | ALLOW |
| All | Outbound | `0.0.0.0/0` (NAT) | ALLOW |

**`dev-client-db-sg`**
| Port | Direction | Source/Dest | Action |
|---|---|---|---|
| 5432 | Inbound | App-SG only | ALLOW |
| All | Inbound | `0.0.0.0/0` | DENY (implicit) |
| All | Outbound | App-SG only | ALLOW |

---

## WAF Configuration

WAFv2 **Regional** Web ACL, attached directly to the ALB, with CloudWatch logging enabled.

| Priority | Rule Set | Protects Against |
|---|---|---|
| 1 | `AWSManagedRulesCommonRuleSet` | OWASP Top 10 |
| 2 | `AWSManagedRulesKnownBadInputsRuleSet` | Log4Shell, SSRF, malformed payloads |
| 3 | `AWSManagedRulesSQLiRuleSet` | SQL injection |
| 4 | `RateLimitRule` (custom) | DDoS / brute force — 2,000 req / 5 min per IP |

- Default action: `ALLOW` (rules block matching traffic)
- CloudWatch Log Group: `aws-waf-logs-{prefix}`, 30-day retention
- Sampled requests + per-rule metrics enabled for alerting

> 💡 To add corporate IP allowlisting, insert a priority-0 rule with `action: allow` before the managed rule sets.

---

## Security Hardening

**Compute (EC2)**
- IMDSv2 enforced (`http_tokens = required`)
- Encrypted gp3 root volumes
- SSM Session Manager only — no SSH port open
- Least-privilege IAM instance profile
- No public IPs on app instances

**Database (Aurora)**
- Cluster-level storage encryption
- `publicly_accessible = false` on all instances
- DB subnets have no internet route
- 7-day automated backup retention, final snapshot on destroy
- PostgreSQL logs exported to CloudWatch

**Network**
- SG-to-SG references only — no CIDR rules between tiers
- Isolated DB route table (no default route)
- HTTPS redirect when an ACM certificate is provided
- TLS 1.3 policy on the HTTPS listener
- WAF SQLi/OWASP rules enforced before traffic reaches the ALB

**Secrets & IaC**
- `terraform.tfvars` excluded via `.gitignore`
- DB password variable marked `sensitive = true`
- Consistent tagging via provider `default_tags`
- No hardcoded credentials anywhere in code
- **Production recommendation:** move the DB password to AWS Secrets Manager

---

## Project Structure

```
aws-webapp-dev/
├── versions.tf
├── variables.tf
├── main.tf
├── outputs.tf
├── terraform.tfvars.example
├── CLAUDE.md
├── .gitignore
└── modules/
    ├── vpc/
    ├── security_groups/
    ├── alb/
    ├── waf/
    ├── ec2/
    └── rds/
```

---

## Getting Started

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.5`
- AWS account + credentials configured (`aws configure` or environment variables)
- AWS provider `~> 5.40` (downloaded automatically on `init`)

### Deploy

```bash
# 1. Configure variables
cp terraform.tfvars.example terraform.tfvars
# then edit terraform.tfvars — set client_name, ec2_ami, db_master_password, etc.

# 2. Initialize Terraform and all 6 child modules
terraform init

# 3. Review the plan (~45 resources)
terraform plan -out=tfplan

# 4. Apply
terraform apply tfplan
# ~8–12 minutes — the Aurora cluster takes the longest. Outputs print on completion.
```

### Tear Down

```bash
terraform destroy
```
A final Aurora snapshot is taken automatically before deletion.

---

## Outputs

After `terraform apply` (example: `environment=dev`, `client=acmecorp`):

| Category | Output | Example Value |
|---|---|---|
| Network | `vpc_name` | `dev-acmecorp-vpc` |
| Network | `internet_gateway_name` | `dev-acmecorp-igw` |
| Network | `nat_gateway_name` | `dev-acmecorp-nat-gw` |
| Load Balancer / WAF | `alb_name` | `dev-acmecorp-alb` |
| Load Balancer / WAF | `alb_dns_name` | `dev-acmecorp-alb-xxx.us-east-1.elb...` |
| Load Balancer / WAF | `waf_web_acl_name` | `dev-acmecorp-waf-acl` |
| EC2 | app-1 / app-2 / app-3 | `dev-acmecorp-app-ec2-{1,2,3}` |
| Aurora RDS | `cluster_identifier` | `dev-acmecorp-aurora-cluster` |
| Aurora RDS | writer / reader instance | `dev-acmecorp-aurora-writer` / `-reader` |

---

## Presentation

An interactive, self-contained slide deck walking through the full architecture, module breakdown, network design, security groups, WAF config, hardening measures, outputs, and deployment steps is included at [`presentation.html`](presentation.html) — just open it in a browser and use the arrow keys or on-screen nav to navigate.

---

## License

MIT — see `LICENSE` for details.

---

<p align="center">Built with Terraform · Provisioned on AWS · Generated with <a href="https://claude.com/claude-code">Claude Code</a></p>
