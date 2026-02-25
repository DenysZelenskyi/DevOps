variable "environment" {
  type    = string
  default = "lesson-5"
}

variable "eks_node_role_arn" {
  type        = string
  description = "ARN of the EKS node IAM role for ECR access"
  default     = ""
}