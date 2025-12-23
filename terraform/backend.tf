//backend config

terraform {
  backend "azurerm" {
    resource_group_name  = "sttfldatatfstate-rg"
    storage_account_name = "sttfldatatfstate"
    container_name       = "sttfldatatfstate-container"
    key                  = "tfl-data/dev.tfstate"
  }
}