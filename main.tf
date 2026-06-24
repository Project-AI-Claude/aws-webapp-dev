locals {
  name_prefix = "${var.environment}-${var.client_name}"
}

module "vpc" {
  source = "./modules/vpc"

  name_prefix         = local.name_prefix
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  app_subnet_cidrs    = var.app_subnet_cidrs
  db_subnet_cidrs     = var.db_subnet_cidrs
  availability_zones  = var.availability_zones
}

module "security_groups" {
  source = "./modules/security_groups"

  name_prefix = local.name_prefix
  vpc_id      = module.vpc.vpc_id
}

module "alb" {
  source = "./modules/alb"

  name_prefix        = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  alb_sg_id          = module.security_groups.alb_sg_id
  certificate_arn    = var.alb_certificate_arn
}

module "waf" {
  source = "./modules/waf"

  name_prefix = local.name_prefix
  alb_arn     = module.alb.alb_arn
}

module "ec2" {
  source = "./modules/ec2"

  name_prefix       = local.name_prefix
  app_subnet_ids    = module.vpc.app_subnet_ids
  app_sg_id         = module.security_groups.app_sg_id
  ami_id            = var.ec2_ami
  instance_type     = var.ec2_instance_type
  key_name          = var.ec2_key_name
  target_group_arn  = module.alb.target_group_arn
}

module "rds" {
  source = "./modules/rds"

  name_prefix        = local.name_prefix
  db_subnet_ids      = module.vpc.db_subnet_ids
  db_sg_id           = module.security_groups.db_sg_id
  master_username    = var.db_master_username
  master_password    = var.db_master_password
  instance_class     = var.db_instance_class
  availability_zones = var.availability_zones
}
