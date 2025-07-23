terraform {
  backend "azurerm" {
    resource_group_name   = "tfstate-rg"
    storage_account_name  = "tfstatek8sstore"
    container_name        = "tfstate"
    key                   = "infra.tfstate"
  }
}
