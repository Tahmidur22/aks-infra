resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  depends_on = [
    kubernetes_namespace.argocd
  ]

  wait    = true
  atomic  = true
  timeout = 600

  values = [<<EOF
server:
  service:
    type: ClusterIP
EOF
  ]
}

resource "helm_release" "argcocd_image_updater" {
  name       = "argocd-image-updater"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-image-updater"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  depends_on = [
    helm_release.argocd
  ]

  wait    = true
  atomic  = true
  timeout = 600

  values = [<<EOF
serviceAccount:
  create: true
EOF
  ]
}