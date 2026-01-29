data "azurerm_client_config" "current" {}

resource "random_password" "grafana_admin_password" {
  length  = 16
  special = true
}

resource "azurerm_resource_group" "rg" {
  name     = "aks-test-rg"
  location = "East US"
}

module "network" {
  source              = "git::https://github.com/Tahmidur22/terraform-modules.git//modules/networking"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
  aks_subnet_cidr     = "10.0.1.0/24"
  vnet_name           = "aks-test-vnet"
}

module "acr" {
  source              = "git::https://github.com/Tahmidur22/terraform-modules.git//modules/acr"
  acr_name            = "akstestacraitjbd"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  acr_sku             = "Standard"
  admin_enabled       = true
  aks_subnet_id       = module.network.aks_subnet_id
}

module "aks" {
  source              = "git::https://github.com/Tahmidur22/terraform-modules.git//modules/aks"
  cluster_name        = "aks-test-cluster"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  dns_prefix          = "akstestdns"
  kubernetes_version  = "1.33.5"
  vnet_subnet_id      = module.network.aks_subnet_id
  system_node_count   = 3
  system_vm_size      = "Standard_D2s_v3"
}


resource "azurerm_role_assignment" "acr_pull" {
  scope                = module.acr.acr_id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity
  depends_on           = [module.aks, module.acr]

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_user_assigned_identity" "grafana" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "grafana-identity"
}


module "key_vault" {
  source              = "git::https://github.com/Tahmidur22/terraform-modules.git//modules/key_vault"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  kv_name             = "akstestkeyvault"
}

resource "azurerm_role_assignment" "terraform_kv" {
  scope                = module.key_vault.key_vault_id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "grafana_kv" {
  scope                = module.key_vault.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.grafana.principal_id
}

resource "azurerm_key_vault_secret" "grafana_admin_password" {
  name         = "grafana-admin-password"
  value        = random_password.grafana_admin_password.result
  key_vault_id = module.key_vault.key_vault_id

  depends_on = [
    azurerm_role_assignment.terraform_kv,
    azurerm_role_assignment.grafana_kv
  ]
}

