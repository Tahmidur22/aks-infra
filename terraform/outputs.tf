output "aks_cluster_name" {
  value = module.aks.cluster_name
}

output "aks_kube_config" {
  value     = module.aks.kube_config
  sensitive = true
}

output "acr_login_server" {
  value = module.acr.login_server
}

output "ingress_public_ip" {
  value = azurerm_public_ip.ingress_ip.ip_address
}

output "grafana_admin_password" {
  value     = azurerm_key_vault_secret.grafana_admin_password.value
  sensitive = true
}
