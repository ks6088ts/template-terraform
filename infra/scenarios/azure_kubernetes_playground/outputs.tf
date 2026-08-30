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

output "aks_current_kubernetes_version" {
  description = "Current Kubernetes version running on the AKS cluster"
  value       = module.kubernetes_service.current_kubernetes_version
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL associated with the AKS cluster"
  value       = module.kubernetes_service.oidc_issuer_url
}

output "aks_node_resource_group" {
  description = "Name of the resource group containing AKS nodes"
  value       = module.kubernetes_service.node_resource_group
}

output "aks_node_resource_group_id" {
  description = "ID of the resource group containing AKS nodes"
  value       = module.kubernetes_service.node_resource_group_id
}

output "aks_user_node_pools" {
  description = "User node pool IDs, names, and node image versions"
  value       = module.kubernetes_service.user_node_pools
}

# =============================================================================
# Optional Container Insights Outputs
# =============================================================================

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID, or null when Container Insights is disabled"
  value       = try(module.log_analytics[0].id, null)
}

output "log_analytics_workspace_name" {
  description = "Log Analytics workspace name, or null when Container Insights is disabled"
  value       = try(module.log_analytics[0].name, null)
}
