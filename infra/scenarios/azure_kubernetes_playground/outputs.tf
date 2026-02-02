# =============================================================================
# Resource Group Outputs
# =============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.resource_group.id
}

# =============================================================================
# ACR Outputs
# =============================================================================

output "acr_id" {
  description = "ID of the Azure Container Registry"
  value       = module.container_registry.id
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = module.container_registry.name
}

output "acr_login_server" {
  description = "Login server URL of the Azure Container Registry"
  value       = module.container_registry.login_server
}

# =============================================================================
# AKS Outputs
# =============================================================================

output "aks_id" {
  description = "ID of the AKS cluster"
  value       = module.kubernetes_service.id
}

output "aks_name" {
  description = "Name of the AKS cluster"
  value       = module.kubernetes_service.name
}

output "aks_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = module.kubernetes_service.fqdn
}

output "aks_kube_config_raw" {
  description = "Raw kubeconfig for connecting to the AKS cluster"
  value       = module.kubernetes_service.kube_config_raw
  sensitive   = true
}

output "aks_node_resource_group" {
  description = "Name of the resource group containing AKS nodes"
  value       = module.kubernetes_service.node_resource_group
}
