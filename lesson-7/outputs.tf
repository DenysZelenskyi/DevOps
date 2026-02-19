output "s3_bucket_name" {
  value       = module.s3_backend.s3_bucket_id
  description = "Name of the S3 bucket for Terraform state"
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID of the VPC"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "IDs of private subnets"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "IDs of public subnets"
}

output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "URL of the ECR repository"
}

output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "Name of the EKS cluster"
}

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "Endpoint of the EKS cluster"
}

output "eks_cluster_security_group_id" {
  value       = module.eks.cluster_security_group_id
  description = "Security group ID of the EKS cluster"
}

output "configure_kubectl" {
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
  description = "Command to configure kubectl"
}
