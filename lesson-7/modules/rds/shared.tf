# ─────────────────────────────────────────────
# Shared resources: always created regardless of use_aurora
# ─────────────────────────────────────────────

# DB Subnet Group
resource "aws_db_subnet_group" "this" {
  name        = "${var.identifier}-subnet-group"
  subnet_ids  = var.subnet_ids
  description = "DB subnet group for ${var.identifier}"

  tags = {
    Name        = "${var.identifier}-subnet-group"
    Environment = var.environment
  }
}

# Security Group
resource "aws_security_group" "this" {
  name        = "${var.identifier}-sg"
  description = "Security group for RDS ${var.identifier}"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow DB traffic from VPC"
    from_port   = local.db_port
    to_port     = local.db_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.identifier}-sg"
    Environment = var.environment
  }
}

# Parameter Group — aurora uses cluster parameter group, standard RDS uses db parameter group
resource "aws_db_parameter_group" "this" {
  count = var.use_aurora ? 0 : 1

  name        = "${var.identifier}-pg"
  family      = local.rds_parameter_family
  description = "Parameter group for ${var.identifier}"

  parameter {
    name  = "max_connections"
    value = "200"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "log_statement"
    value = "all"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "work_mem"
    value = "4096"
    apply_method = "pending-reboot"
  }

  tags = {
    Name        = "${var.identifier}-pg"
    Environment = var.environment
  }
}

resource "aws_rds_cluster_parameter_group" "this" {
  count = var.use_aurora ? 1 : 0

  name        = "${var.identifier}-cluster-pg"
  family      = local.aurora_parameter_family
  description = "Cluster parameter group for ${var.identifier}"

  parameter {
    name  = "max_connections"
    value = "200"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "log_statement"
    value = "all"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "work_mem"
    value = "4096"
    apply_method = "pending-reboot"
  }

  tags = {
    Name        = "${var.identifier}-cluster-pg"
    Environment = var.environment
  }
}

# ─────────────────────────────────────────────
# Locals: derive port and parameter family from engine
# ─────────────────────────────────────────────
locals {
  db_port = contains(["mysql", "aurora-mysql"], var.engine) ? 3306 : 5432

  # Parameter family for standard RDS (e.g. postgres15, mysql8.0)
  rds_parameter_family = var.engine == "postgres" ? "postgres${split(".", var.engine_version)[0]}" : "${var.engine}${split(".", var.engine_version)[0]}.${split(".", var.engine_version)[1]}"

  # Parameter family for Aurora clusters (e.g. aurora-postgresql15, aurora-mysql8.0)
  aurora_parameter_family = var.engine == "aurora-postgresql" ? "aurora-postgresql${split(".", var.engine_version)[0]}" : "aurora-mysql${split(".", var.engine_version)[0]}.${split(".", var.engine_version)[1]}"
}
