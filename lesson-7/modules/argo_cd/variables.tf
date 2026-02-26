variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint for EKS cluster"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "CA certificate for EKS cluster"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "chart_version" {
  description = "Version of Argo CD Helm chart"
  type        = string
  default     = "7.7.12"
}

variable "django_app_repo_url" {
  description = "Git repository URL with Helm charts"
  type        = string
}

variable "django_app_path" {
  description = "Path to Django app Helm chart in repository"
  type        = string
  default     = "charts/django-app"
}

variable "django_app_namespace" {
  description = "Namespace for Django application"
  type        = string
  default     = "default"
}
