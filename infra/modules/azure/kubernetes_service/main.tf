resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix != null ? var.dns_prefix : "aks-${var.name}"
  kubernetes_version  = var.kubernetes_version
  tags                = var.tags

  default_node_pool {
    name                 = var.default_node_pool_name
    node_count           = var.node_count
    vm_size              = var.vm_size
    os_disk_size_gb      = var.os_disk_size_gb
    auto_scaling_enabled = var.auto_scaling_enabled
    min_count            = var.auto_scaling_enabled ? var.min_count : null
    max_count            = var.auto_scaling_enabled ? var.max_count : null
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = var.network_plugin
    network_policy = var.network_policy
  }
}

# Role assignment for ACR pull (optional)
resource "azurerm_role_assignment" "acr_pull" {
  count                            = var.enable_acr_pull ? 1 : 0
  scope                            = var.acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}
