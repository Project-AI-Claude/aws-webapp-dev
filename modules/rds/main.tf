resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "${var.name_prefix}-db-subnet-group"
  }
}

resource "aws_rds_cluster_parameter_group" "this" {
  name   = "${var.name_prefix}-aurora-pg-params"
  family = "aurora-postgresql15"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  tags = {
    Name = "${var.name_prefix}-aurora-pg-params"
  }
}

resource "aws_rds_cluster" "this" {
  cluster_identifier      = "${var.name_prefix}-aurora-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = "15.4"
  availability_zones      = var.availability_zones
  database_name           = "appdb"
  master_username         = var.master_username
  master_password         = var.master_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [var.db_sg_id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.name

  storage_encrypted           = true
  deletion_protection         = false
  skip_final_snapshot         = false
  final_snapshot_identifier   = "${var.name_prefix}-aurora-final-snapshot"
  backup_retention_period     = 7
  preferred_backup_window     = "03:00-04:00"
  preferred_maintenance_window = "sun:05:00-sun:06:00"

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = {
    Name = "${var.name_prefix}-aurora-cluster"
  }
}

resource "aws_rds_cluster_instance" "writer" {
  identifier         = "${var.name_prefix}-aurora-writer"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version

  db_subnet_group_name    = aws_db_subnet_group.this.name
  publicly_accessible     = false
  auto_minor_version_upgrade = true

  performance_insights_enabled = true

  tags = {
    Name = "${var.name_prefix}-aurora-writer"
    role = "writer"
  }
}

resource "aws_rds_cluster_instance" "reader" {
  identifier         = "${var.name_prefix}-aurora-reader"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version

  db_subnet_group_name    = aws_db_subnet_group.this.name
  publicly_accessible     = false
  auto_minor_version_upgrade = true

  performance_insights_enabled = true

  tags = {
    Name = "${var.name_prefix}-aurora-reader"
    role = "reader"
  }
}
