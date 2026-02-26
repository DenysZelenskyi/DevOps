output "argocd_url" {
  description = "Argo CD server URL (use port-forward)"
  value       = "Use: kubectl port-forward -n argocd svc/argocd-server 8080:80"
}

output "argocd_admin_password" {
  description = "Argo CD initial admin password (stored in secret)"
  value       = "Use: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
  sensitive   = false
}

output "argocd_namespace" {
  description = "Argo CD namespace"
  value       = var.namespace
}

data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = var.namespace
  }

  depends_on = [helm_release.argocd]
}
