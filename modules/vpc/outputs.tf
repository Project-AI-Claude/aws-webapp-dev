output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_name" {
  value = "${var.name_prefix}-vpc"
}

output "internet_gateway_id" {
  value = aws_internet_gateway.this.id
}

output "internet_gateway_name" {
  value = "${var.name_prefix}-igw"
}

output "nat_gateway_id" {
  value = aws_nat_gateway.this.id
}

output "nat_gateway_name" {
  value = "${var.name_prefix}-nat-gw"
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  value = aws_subnet.app[*].id
}

output "db_subnet_ids" {
  value = aws_subnet.db[*].id
}
