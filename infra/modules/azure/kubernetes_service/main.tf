resource "azurerm_kubernetes_cluster" "this" {
  name                              = "aks-${var.name}"
  location                          = var.location
  resource_group_name               = var.resource_group_name
  dns_prefix                        = var.dns_prefix != null ? var.dns_prefix : "aks-${var.name}"
  kubernetes_version                = var.kubernetes_version
  automatic_upgrade_channel         = var.automatic_upgrade_channel
  node_os_upgrade_channel           = var.node_os_upgrade_channel
  oidc_issuer_enabled               = var.oidc_issuer_enabled
  workload_identity_enabled         = var.workload_identity_enabled
  role_based_access_control_enabled = true
  tags                              = var.tags

  default_node_pool {
    name                         = var.default_node_pool_name
    node_count                   = var.auto_scaling_enabled ? null : var.node_count
    vm_size                      = var.vm_size
    os_disk_size_gb              = var.os_disk_size_gb
    auto_scaling_enabled         = var.auto_scaling_enabled
    min_count                    = var.auto_scaling_enabled ? var.min_count : null
    max_count                    = var.auto_scaling_enabled ? var.max_count : null
    only_critical_addons_enabled = var.user_node_pool_enabled && var.only_critical_addons_enabled
    temporary_name_for_rotation  = var.default_node_pool_temporary_name
  }

  identity {
    type = "SystemAssigned"
  }

  dynamic "key_vault_secrets_provider" {
    for_each = var.key_vault_secrets_provider_enabled ? [1] : []

    content {
      secret_rotation_enabled = true
    }
  }

  node_provisioning_profile {
    mode = "Manual"
  }

  network_profile {
    network_plugin      = var.network_plugin
    network_plugin_mode = var.network_plugin == "azure" ? var.network_plugin_mode : null
    network_data_plane  = var.network_plugin == "azure" ? var.network_data_plane : null
    network_policy      = var.network_policy
    load_balancer_sku   = var.load_balancer_sku
    outbound_type       = var.outbound_type
  }

  lifecycle {
    precondition {
      condition     = !var.workload_identity_enabled || var.oidc_issuer_enabled
      error_message = "OIDC issuer must be enabled when workload identity is enabled."
    }

    precondition {
      condition     = !var.auto_scaling_enabled || var.min_count <= var.max_count
      error_message = "The system node pool min_count must be less than or equal to max_count."
    }

    precondition {
      condition     = var.network_plugin == "azure" || (var.network_plugin_mode == null && var.network_data_plane == null)
      error_message = "network_plugin_mode and network_data_plane can only be set when network_plugin is azure."
    }
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  count = var.user_node_pool_enabled ? 1 : 0

  name                  = var.user_node_pool_name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.user_node_pool_vm_size
  node_count            = var.user_node_pool_auto_scaling_enabled ? null : var.user_node_pool_node_count
  auto_scaling_enabled  = var.user_node_pool_auto_scaling_enabled
  min_count             = var.user_node_pool_auto_scaling_enabled ? var.user_node_pool_min_count : null
  max_count             = var.user_node_pool_auto_scaling_enabled ? var.user_node_pool_max_count : null
  os_disk_size_gb       = var.user_node_pool_os_disk_size_gb
  max_pods              = var.user_node_pool_max_pods
  mode                  = "User"
  os_sku                = var.user_node_pool_os_sku
  orchestrator_version  = var.kubernetes_version
  node_labels = {
    "workload.azure.com/pool" = "general"
  }
  temporary_name_for_rotation = var.user_node_pool_temporary_name
  tags                        = var.tags

  lifecycle {
    precondition {
      condition     = !var.user_node_pool_auto_scaling_enabled || var.user_node_pool_min_count <= var.user_node_pool_max_count
      error_message = "The user node pool min_count must be less than or equal to max_count."
    }
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
