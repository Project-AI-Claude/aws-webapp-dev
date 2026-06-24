variable "name_prefix" {
  description = "Prefix for all resource names (environment-client)"
  type        = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "app_subnet_cidrs" {
  type = list(string)
}

variable "db_subnet_cidrs" {
  type = list(string)
}

variable "availability_zones" {
  type = list(string)
}
