output "grafana_url" {
  description = "Grafana URL (use port-forward)"
  value       = "Use: kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n ${var.namespace}"
}

output "prometheus_url" {
  description = "Prometheus URL (use port-forward)"
  value       = "Use: kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n ${var.namespace}"
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.grafana_admin_password
  sensitive   = true
}

output "monitoring_namespace" {
  description = "Namespace where monitoring stack is deployed"
  value       = var.namespace
}
