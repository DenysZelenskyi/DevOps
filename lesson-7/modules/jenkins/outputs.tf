output "jenkins_url" {
  description = "Jenkins URL (use port-forward)"
  value       = "Use: kubectl port-forward -n jenkins svc/jenkins 8080:8080"
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = var.jenkins_admin_password
  sensitive   = true
}

output "service_account_role_arn" {
  description = "IAM role ARN for Jenkins service account"
  value       = aws_iam_role.jenkins.arn
}

data "kubernetes_service" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = var.namespace
  }

  depends_on = [helm_release.jenkins]
}
