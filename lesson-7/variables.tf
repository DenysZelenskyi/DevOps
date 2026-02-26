variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "student_name" {
  type    = string
  default = "denys"
}

variable "environment" {
  type    = string
  default = "lesson-7"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of CIDR blocks for public subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  type        = list(string)
  description = "List of CIDR blocks for private subnets"
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Enable NAT Gateway for private subnets"
  default     = true
}

variable "dynamodb_table_name" {
  type    = string
  default = "terraform-locks"
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
  default     = "lesson-7-eks-cluster"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version"
  default     = "1.31"
}

variable "jenkins_admin_password" {
  type        = string
  description = "Admin password for Jenkins"
  sensitive   = true
  default     = "admin123"
}

variable "django_app_repo_url" {
  type        = string
  description = "Git repository URL with Django Helm charts"
  default     = "https://github.com/DenysZelenskyi/devops-lesson-8-9.git"
}

variable "github_token" {
  type        = string
  description = "GitHub Personal Access Token for Jenkins pipeline"
  sensitive   = true
  default     = ""
}

variable "django_app_path" {
  type        = string
  description = "Path to Django app Helm chart in repository"
  default     = "charts/django-app"
}
