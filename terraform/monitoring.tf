resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_secret" "grafana_admin" {
  metadata {
    name      = "grafana-admin-secret"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "admin-user"     = "admin"
    "admin-password" = azurerm_key_vault_secret.grafana_admin_password.value
  }

  type = "Opaque"
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  depends_on = [
    kubernetes_namespace.monitoring,
    kubernetes_secret.grafana_admin
  ]

  wait    = true
  atomic  = true
  timeout = 900

  values = [<<EOF
grafana:
  admin:
    existingSecret: grafana-admin-secret

prometheus:
  prometheusSpec:
    retention: 10d


kubeScheduler:
  enabled: false

kubeControllerManager:
  enabled: false

kubeEtcd:
  enabled: false

kubeProxy:
  enabled: false
EOF
  ]
}
