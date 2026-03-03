variable "identifier" {
  type        = string
  description = "Unique identifier for the RDS instance or Aurora cluster"
}

variable "use_aurora" {
  type        = bool
  description = "If true, creates an Aurora Cluster. If false, creates a standard RDS instance."
  default     = false
}

variable "engine" {
  type        = string
  description = "Database engine (e.g. postgres, mysql, aurora-postgresql, aurora-mysql)"
  default     = "postgres"
}

variable "engine_version" {
  type        = string
  description = "Database engine version"
  default     = "15.4"
}

variable "instance_class" {
  type        = string
  description = "Instance class for the DB instance or Aurora cluster instance"
  default     = "db.t3.medium"
}

variable "multi_az" {
  type        = bool
  description = "Enable Multi-AZ deployment (only applies to standard RDS, not Aurora)"
  default     = false
}

variable "allocated_storage" {
  type        = number
  description = "Allocated storage in GB (only for standard RDS)"
  default     = 20
}

variable "db_name" {
  type        = string
  description = "Name of the initial database"
  default     = "appdb"
}

variable "db_username" {
  type        = string
  description = "Master username for the database"
  default     = "dbadmin"
}

variable "db_password" {
  type        = string
  description = "Master password for the database"
  sensitive   = true
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the RDS will be deployed"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the DB subnet group (at least 2)"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to connect to the database"
  default     = ["10.0.0.0/16"]
}

variable "environment" {
  type        = string
  description = "Environment tag"
  default     = "lesson-7"
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot when destroying the database"
  default     = true
}

variable "deletion_protection" {
  type        = bool
  description = "Enable deletion protection"
  default     = false
}
