output "id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.id
}

output "name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.name
}

output "fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "current_kubernetes_version" {
  description = "Current Kubernetes version running on the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.current_kubernetes_version
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL associated with the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet managed identity"
  value       = try(azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id, null)
}

output "identity_principal_id" {
  description = "Principal ID of the AKS cluster managed identity"
  value       = azurerm_kubernetes_cluster.this.identity[0].principal_id
}

output "node_resource_group" {
  description = "Name of the resource group containing AKS nodes"
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "node_resource_group_id" {
  description = "ID of the resource group containing AKS nodes"
  value       = azurerm_kubernetes_cluster.this.node_resource_group_id
}

output "user_node_pools" {
  description = "User node pool IDs, names, and current node image versions"
  value = {
    for name, pool in azurerm_kubernetes_cluster_node_pool.user : name => {
      id                 = pool.id
      name               = pool.name
      node_image_version = pool.node_image_version
    }
  }
}

output "oms_agent_identity" {
  description = "Managed identity used by Container Insights, or null when the add-on is disabled"
  value = try({
    client_id                 = azurerm_kubernetes_cluster.this.oms_agent[0].oms_agent_identity[0].client_id
    object_id                 = azurerm_kubernetes_cluster.this.oms_agent[0].oms_agent_identity[0].object_id
    user_assigned_identity_id = azurerm_kubernetes_cluster.this.oms_agent[0].oms_agent_identity[0].user_assigned_identity_id
  }, null)
}
