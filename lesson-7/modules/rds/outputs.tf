output "db_endpoint" {
  description = "Endpoint to connect to the database"
  value = var.use_aurora ? aws_rds_cluster.this[0].endpoint : aws_db_instance.this[0].address
}

output "db_reader_endpoint" {
  description = "Reader endpoint (Aurora only, otherwise same as db_endpoint)"
  value = var.use_aurora ? aws_rds_cluster.this[0].reader_endpoint : aws_db_instance.this[0].address
}

output "db_port" {
  description = "Port of the database"
  value = local.db_port
}

output "db_name" {
  description = "Name of the initial database"
  value = var.db_name
}

output "cluster_id" {
  description = "Aurora cluster ID (empty for standard RDS)"
  value = var.use_aurora ? aws_rds_cluster.this[0].cluster_identifier : null
}

output "instance_id" {
  description = "RDS instance ID (empty for Aurora)"
  value = var.use_aurora ? null : aws_db_instance.this[0].identifier
}

output "security_group_id" {
  description = "ID of the RDS security group"
  value = aws_security_group.this.id
}

output "subnet_group_name" {
  description = "Name of the DB subnet group"
  value = aws_db_subnet_group.this.name
}
