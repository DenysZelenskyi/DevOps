# Create namespace for Argo CD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

# Install Argo CD via Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    file("${path.module}/values.yaml")
  ]

  depends_on = [
    kubernetes_namespace.argocd
  ]
}

# Install Argo CD Application and Repository via custom Helm chart
resource "helm_release" "argocd_apps" {
  name      = "argocd-apps"
  chart     = "${path.module}/charts"
  namespace = kubernetes_namespace.argocd.metadata[0].name

  set {
    name  = "repoUrl"
    value = var.django_app_repo_url
  }

  set {
    name  = "appPath"
    value = var.django_app_path
  }

  set {
    name  = "appNamespace"
    value = var.django_app_namespace
  }

  set {
    name  = "argocdNamespace"
    value = var.namespace
  }

  depends_on = [
    helm_release.argocd
  ]
}
