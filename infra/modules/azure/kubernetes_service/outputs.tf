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

output "oidc_issuer_url" {
  description = "OIDC issuer URL for Microsoft Entra Workload ID federation"
  value       = try(azurerm_kubernetes_cluster.this.oidc_issuer_url, null)
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "kube_config" {
  description = "Kubeconfig attributes for the AKS cluster"
  value = {
    host                   = try(azurerm_kubernetes_cluster.this.kube_config[0].host, null)
    client_certificate     = try(azurerm_kubernetes_cluster.this.kube_config[0].client_certificate, null)
    client_key             = try(azurerm_kubernetes_cluster.this.kube_config[0].client_key, null)
    cluster_ca_certificate = try(azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate, null)
  }
  sensitive = true
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet managed identity"
  value       = try(azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id, null)
}

output "identity_principal_id" {
  description = "Principal ID of the AKS cluster managed identity"
  value       = try(azurerm_kubernetes_cluster.this.identity[0].principal_id, null)
}

output "node_resource_group" {
  description = "Name of the resource group containing AKS nodes"
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "user_node_pool_id" {
  description = "ID of the optional user node pool"
  value       = try(azurerm_kubernetes_cluster_node_pool.user[0].id, null)
}

output "user_node_pool_name" {
  description = "Name of the optional user node pool"
  value       = try(azurerm_kubernetes_cluster_node_pool.user[0].name, null)
}
