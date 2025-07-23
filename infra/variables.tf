variable "client_id" {
  type        = string
  description = "Azure Service Principal Client ID"
}

variable "client_secret" {
  type        = string
  description = "Azure Service Principal Client Secret"
  sensitive   = true
}

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "tenant_id" {
  type        = string
  description = "Azure Tenant ID"
}

variable "ssh_public_key" {
  type        = string
  description = "Clave pública SSH para nodos de AKS"
}

variable "location" {
  type        = string
  default     = "East US"
  description = "Ubicación de los recursos en Azure"
}

variable "project_name" {
  type        = string
  default     = "k8s-dotnet-aks"
  description = "Prefijo para nombres de recursos"
}
