variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint for EKS cluster"
  type        = string
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL for IRSA"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "CA certificate for EKS cluster"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for Jenkins"
  type        = string
  default     = "jenkins"
}

variable "jenkins_admin_password" {
  description = "Admin password for Jenkins"
  type        = string
  sensitive   = true
  default     = "admin123"
}

variable "ecr_repository_url" {
  description = "ECR repository URL for pushing images"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "chart_version" {
  description = "Version of Jenkins Helm chart"
  type        = string
  default     = "5.8.142"
}

variable "github_token" {
  description = "GitHub Personal Access Token for pushing to Helm charts repo"
  type        = string
  sensitive   = true
  default     = ""
}

variable "helm_charts_repo_url" {
  description = "GitHub repository URL for Helm charts"
  type        = string
  default     = "https://github.com/DenysZelenskyi/devops-lesson-8-9.git"
}
