output "cluster_identifier" {
  value = aws_rds_cluster.this.cluster_identifier
}

output "cluster_endpoint" {
  description = "Writer endpoint"
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "Reader endpoint"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "cluster_arn" {
  value = aws_rds_cluster.this.arn
}

output "writer_instance_id" {
  value = aws_rds_cluster_instance.writer.id
}

output "reader_instance_id" {
  value = aws_rds_cluster_instance.reader.id
}
