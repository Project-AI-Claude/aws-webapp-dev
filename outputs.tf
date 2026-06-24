output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_name" {
  description = "VPC name"
  value       = module.vpc.vpc_name
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = module.vpc.internet_gateway_id
}

output "internet_gateway_name" {
  description = "Internet Gateway name"
  value       = module.vpc.internet_gateway_name
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = module.vpc.nat_gateway_id
}

output "nat_gateway_name" {
  description = "NAT Gateway name"
  value       = module.vpc.nat_gateway_name
}

output "alb_arn" {
  description = "Application Load Balancer ARN"
  value       = module.alb.alb_arn
}

output "alb_name" {
  description = "Application Load Balancer name"
  value       = module.alb.alb_name
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.alb.alb_dns_name
}

output "waf_web_acl_name" {
  description = "WAF Web ACL name"
  value       = module.waf.web_acl_name
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = module.waf.web_acl_arn
}

output "ec2_instance_ids" {
  description = "Map of AZ to EC2 instance ID"
  value       = module.ec2.instance_ids
}

output "ec2_instance_names" {
  description = "Map of AZ to EC2 instance name"
  value       = module.ec2.instance_names
}

output "rds_cluster_identifier" {
  description = "Aurora RDS cluster identifier"
  value       = module.rds.cluster_identifier
}

output "rds_cluster_endpoint" {
  description = "Aurora RDS writer endpoint"
  value       = module.rds.cluster_endpoint
}

output "rds_reader_endpoint" {
  description = "Aurora RDS reader endpoint"
  value       = module.rds.reader_endpoint
}
