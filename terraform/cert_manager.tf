resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
  depends_on = [module.aks]
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.12.2"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name

  create_namespace = true
  timeout          = 600
  wait             = true

  values = [
    <<-EOT
    installCRDs: true
    EOT
  ]
}
