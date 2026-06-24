output "instance_ids" {
  value = { for i, inst in aws_instance.app : "app-${i + 1}" => inst.id }
}

output "instance_names" {
  value = { for i, inst in aws_instance.app : "app-${i + 1}" => inst.tags["Name"] }
}

output "instance_private_ips" {
  value = { for i, inst in aws_instance.app : "app-${i + 1}" => inst.private_ip }
}
