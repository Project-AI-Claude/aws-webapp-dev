# Project: aws-webapp-dev

## Context
Modular Terraform project provisioning a standard 3-tier web application environment on AWS in `us-east-1`. Intended for the `dev` environment with multi-AZ capability across all tiers.

## Stack
- **Cloud**: AWS (us-east-1)
- **IaC**: Terraform >= 1.5.0, AWS provider ~> 5.40
- **Language**: HCL
- **OS**: Windows 11 (PowerShell primary shell)

## Architecture

### Network Layout
- 1 VPC (`10.0.0.0/16`)
- 3 public subnets across us-east-1a/b/c — ALB, NAT Gateway
- 3 private app subnets across us-east-1a/b/c — EC2 app tier
- 3 private DB subnets across us-east-1a/b/c — Aurora RDS (no internet route)
- 1 NAT Gateway (single, in public subnet 1) — app tier outbound only
- DB subnets have an isolated route table with no default route

### Modules
| Module | Path | Purpose |
|---|---|---|
| `vpc` | `modules/vpc` | VPC, all subnets, IGW, NAT GW, route tables |
| `security_groups` | `modules/security_groups` | ALB-SG, App-SG, DB-SG with least-privilege rules |
| `alb` | `modules/alb` | Internet-facing ALB, target group, HTTP/HTTPS listeners |
| `waf` | `modules/waf` | WAFv2 Web ACL (regional), ALB association, CloudWatch logs |
| `ec2` | `modules/ec2` | 3 app EC2 instances (1 per AZ), IAM role, SSM agent |
| `rds` | `modules/rds` | Aurora PostgreSQL 15 cluster, writer + reader instances |

### Security Group Rules
- **ALB-SG**: inbound 80/443 from `0.0.0.0/0`; outbound unrestricted
- **App-SG**: inbound 80/443/8080 from ALB-SG only; outbound unrestricted (for NAT)
- **DB-SG**: inbound 5432 from App-SG only; outbound to App-SG only

### WAF Rules (in priority order)
1. AWSManagedRulesCommonRuleSet
2. AWSManagedRulesKnownBadInputsRuleSet
3. AWSManagedRulesSQLiRuleSet
4. Rate limit — block IPs exceeding 2000 requests per 5 minutes

## Conventions
- **Naming**: `{environment}-{client_name}-{resource}` (e.g. `dev-acmecorp-vpc`)
- **Tags**: all resources tagged via provider `default_tags` with `environment`, `client`, `managed-by-terraform`
- **Sensitive values**: `db_master_password` is `sensitive = true`; never commit `terraform.tfvars`
- **IMDSv2**: enforced on all EC2 instances (`http_tokens = required`)
- **RDS**: `publicly_accessible = false` on all instances; final snapshot enabled

## Key Variables
| Variable | Default | Notes |
|---|---|---|
| `aws_region` | `us-east-1` | Do not change without updating AZ list |
| `environment` | `dev` | Used in all resource names |
| `client_name` | — | Required; no default |
| `ec2_ami` | — | Required; must be a valid AMI in us-east-1 |
| `db_master_password` | — | Required; sensitive |
| `alb_certificate_arn` | `null` | Set to enable HTTPS; HTTP redirects to HTTPS when set |

## Outputs
After `terraform apply`, these outputs are available:

```
vpc_name, internet_gateway_name, nat_gateway_name
alb_name, alb_dns_name
waf_web_acl_name
ec2_instance_names   # map: app-1/2/3 → name
rds_cluster_identifier, rds_cluster_endpoint, rds_reader_endpoint
```

## Deployment
```bash
cd aws-webapp-dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set client_name, ec2_ami, db_master_password at minimum
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## What NOT to Do
- Do not add internet routes to the DB subnet route table
- Do not set `publicly_accessible = true` on any RDS instance
- Do not commit `terraform.tfvars` — it is in `.gitignore`
- Do not pass passwords as plain variables in CI — use AWS Secrets Manager or a secrets injection tool
- Do not use `count` for modules; each module is a singleton by design
