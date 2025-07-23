# Random sufijo para evitar colisiones en nombres globales (ACR, etc.)
resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

# Resource Group principal
resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-rg"
  location = var.location
}

# Generar nombre válido para ACR (minúsculas, sin guiones, <= 50 chars)
# NOTA: El ACR es un nombre global único. Si Terraform falla por nombre duplicado,
# cambia var.project_name o agrega un sufijo manual.
locals {
  acr_name = substr("${replace(replace(lower(var.project_name), "-", ""), "_", "")}${random_string.suffix.result}", 0, 50)
}

resource "azurerm_container_registry" "acr" {
  name                = local.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# AKS
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.project_name}-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.project_name}-dns"

  default_node_pool {
    name                = "default"
    node_count          = 1
    vm_size             = "Standard_B2s"
    os_disk_size_gb     = 30
    temporary_name_for_rotation = "tempnode"
  }

  linux_profile {
    admin_username = "aksadmin"
    ssh_key {
      key_data = var.ssh_public_key
    }
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control_enabled = true

  network_profile {
    network_plugin = "azure"
  }
}

# Permitir que AKS haga pull de imágenes del ACR
resource "azurerm_role_assignment" "aks_acr" {
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}
