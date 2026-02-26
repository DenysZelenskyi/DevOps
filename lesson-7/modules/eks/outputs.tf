output "cluster_id" {
  value       = aws_eks_cluster.main.id
  description = "EKS cluster ID"
}

output "cluster_name" {
  value       = aws_eks_cluster.main.name
  description = "EKS cluster name"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "Endpoint for EKS control plane"
}

output "cluster_security_group_id" {
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  description = "Security group ID attached to the EKS cluster"
}

output "cluster_certificate_authority_data" {
  value       = aws_eks_cluster.main.certificate_authority[0].data
  description = "Base64 encoded certificate data required to communicate with the cluster"
  sensitive   = true
}

output "cluster_version" {
  value       = aws_eks_cluster.main.version
  description = "The Kubernetes server version for the cluster"
}

output "oidc_issuer_url" {
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
  description = "OIDC issuer URL for the EKS cluster"
}

output "node_role_arn" {
  value       = aws_iam_role.eks_nodes.arn
  description = "ARN of the EKS node IAM role"
}

output "node_group_id" {
  value       = aws_eks_node_group.main.id
  description = "EKS node group ID"
}

output "node_group_status" {
  value       = aws_eks_node_group.main.status
  description = "Status of the EKS node group"
}
