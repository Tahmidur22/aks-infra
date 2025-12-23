resource "azurerm_public_ip" "ingress_ip" {
  name                = "ingress-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = module.aks.aks_node_resource_group
  allocation_method   = "Static"
  sku                 = "Standard"
}