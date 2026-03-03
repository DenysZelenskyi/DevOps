# ─────────────────────────────────────────────
# Standard RDS Instance (use_aurora = false)
# ─────────────────────────────────────────────

resource "aws_db_instance" "this" {
  count = var.use_aurora ? 0 : 1

  identifier        = var.identifier
  engine            = var.engine
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  parameter_group_name   = aws_db_parameter_group.this[0].name

  multi_az            = var.multi_az
  skip_final_snapshot = var.skip_final_snapshot
  deletion_protection = var.deletion_protection

  tags = {
    Name        = var.identifier
    Environment = var.environment
  }
}
