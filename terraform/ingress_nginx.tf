resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.7.1"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name

  timeout = 1800
  wait    = true
  atomic  = false

  values = [
    <<-EOT
    controller:
      replicaCount: 1
      service:
        type: LoadBalancer
        externalTrafficPolicy: Cluster
        annotations:
          service.beta.kubernetes.io/azure-load-balancer-resource-group: "MC_aks-test-rg_aks-test-cluster_eastus"
          service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: /healthz
          service.beta.kubernetes.io/azure-load-balancer-health-probe-port: "10254"
      ingressClassResource:
        name: nginx
        enabled: true
        default: true
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 500m
          memory: 512Mi
      podDisruptionBudget:
        enabled: true
        minAvailable: 1
    EOT
  ]
  
  depends_on = [
    kubernetes_namespace.ingress_nginx,
    azurerm_public_ip.ingress_ip
  ]
}