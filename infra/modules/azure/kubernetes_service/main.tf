locals {
  node_resource_group_name = var.node_resource_group_name != null ? var.node_resource_group_name : "rg-aks-${var.name}-nodes"
}

resource "azurerm_kubernetes_cluster" "this" {
  name                              = "aks-${var.name}"
  location                          = var.location
  resource_group_name               = var.resource_group_name
  node_resource_group               = local.node_resource_group_name
  dns_prefix                        = var.dns_prefix != null ? var.dns_prefix : "aks-${var.name}"
  kubernetes_version                = var.kubernetes_version
  sku_tier                          = var.sku_tier
  role_based_access_control_enabled = var.role_based_access_control_enabled
  local_account_disabled            = var.local_account_disabled
  oidc_issuer_enabled               = var.oidc_issuer_enabled
  workload_identity_enabled         = var.workload_identity_enabled
  automatic_upgrade_channel         = var.automatic_upgrade_channel
  node_os_upgrade_channel           = var.node_os_upgrade_channel
  image_cleaner_enabled             = var.image_cleaner_enabled
  image_cleaner_interval_hours      = var.image_cleaner_enabled ? var.image_cleaner_interval_hours : null
  tags                              = var.tags

  default_node_pool {
    name                         = var.system_node_pool.name
    node_count                   = var.system_node_pool.node_count
    vm_size                      = var.system_node_pool.vm_size
    type                         = "VirtualMachineScaleSets"
    os_sku                       = var.system_node_pool.os_sku
    os_disk_size_gb              = var.system_node_pool.os_disk_size_gb
    os_disk_type                 = var.system_node_pool.os_disk_type
    only_critical_addons_enabled = var.system_node_pool.only_critical_addons_enabled
    temporary_name_for_rotation  = var.system_node_pool.temporary_name_for_rotation
    zones                        = length(var.system_node_pool.zones) > 0 ? var.system_node_pool.zones : null
    tags                         = var.tags

    upgrade_settings {
      max_surge = var.system_node_pool.max_surge
    }
  }

  identity {
    type = "SystemAssigned"
  }

  node_provisioning_profile {
    mode = "Manual"
  }

  network_profile {
    network_plugin      = var.network_profile.network_plugin
    network_plugin_mode = var.network_profile.network_plugin_mode
    network_data_plane  = var.network_profile.network_data_plane
    network_policy      = var.network_profile.network_policy
    pod_cidr            = var.network_profile.pod_cidr
    service_cidr        = var.network_profile.service_cidr
    dns_service_ip      = var.network_profile.dns_service_ip
    load_balancer_sku   = var.network_profile.load_balancer_sku
    outbound_type       = var.network_profile.outbound_type
    ip_versions         = var.network_profile.ip_versions
  }

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.entra_id == null ? [] : [var.entra_id]

    content {
      tenant_id              = azure_active_directory_role_based_access_control.value.tenant_id
      admin_group_object_ids = azure_active_directory_role_based_access_control.value.admin_group_object_ids
      azure_rbac_enabled     = azure_active_directory_role_based_access_control.value.azure_rbac_enabled
    }
  }

  dynamic "api_server_access_profile" {
    for_each = length(var.api_server_authorized_ip_ranges) > 0 ? [var.api_server_authorized_ip_ranges] : []

    content {
      authorized_ip_ranges = api_server_access_profile.value
    }
  }

  dynamic "maintenance_window_auto_upgrade" {
    for_each = var.maintenance_window_auto_upgrade == null ? [] : [var.maintenance_window_auto_upgrade]

    content {
      frequency   = "Weekly"
      interval    = maintenance_window_auto_upgrade.value.interval
      duration    = maintenance_window_auto_upgrade.value.duration
      day_of_week = maintenance_window_auto_upgrade.value.day_of_week
      start_time  = maintenance_window_auto_upgrade.value.start_time
      utc_offset  = maintenance_window_auto_upgrade.value.utc_offset
      start_date  = maintenance_window_auto_upgrade.value.start_date
    }
  }

  dynamic "maintenance_window_node_os" {
    for_each = var.maintenance_window_node_os == null ? [] : [var.maintenance_window_node_os]

    content {
      frequency   = "Weekly"
      interval    = maintenance_window_node_os.value.interval
      duration    = maintenance_window_node_os.value.duration
      day_of_week = maintenance_window_node_os.value.day_of_week
      start_time  = maintenance_window_node_os.value.start_time
      utc_offset  = maintenance_window_node_os.value.utc_offset
      start_date  = maintenance_window_node_os.value.start_date
    }
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id == null ? [] : [var.log_analytics_workspace_id]

    content {
      log_analytics_workspace_id      = oms_agent.value
      msi_auth_for_monitoring_enabled = true
    }
  }

  lifecycle {
    precondition {
      condition     = length(local.node_resource_group_name) <= 80
      error_message = "The AKS node resource group name must not exceed 80 characters."
    }

    precondition {
      condition     = lower(local.node_resource_group_name) != lower(var.resource_group_name)
      error_message = "The AKS node resource group must differ from the cluster resource group."
    }

    precondition {
      condition     = !var.workload_identity_enabled || var.oidc_issuer_enabled
      error_message = "Workload Identity requires oidc_issuer_enabled to be true."
    }

    precondition {
      condition     = !var.local_account_disabled || (var.role_based_access_control_enabled && try(length(var.entra_id.admin_group_object_ids) > 0, false))
      error_message = "Disabling local accounts requires Kubernetes RBAC and managed Microsoft Entra integration with at least one admin group object ID."
    }

    precondition {
      condition     = !var.system_node_pool.only_critical_addons_enabled || length(var.user_node_pools) > 0
      error_message = "At least one user node pool is required when the system pool is reserved for critical add-ons."
    }

    precondition {
      condition     = var.automatic_upgrade_channel != "node-image" || var.node_os_upgrade_channel == "NodeImage"
      error_message = "The node-image automatic upgrade channel requires node_os_upgrade_channel to be NodeImage."
    }
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each = var.user_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = each.value.vm_size
  mode                  = "User"
  os_type               = "Linux"
  os_sku                = each.value.os_sku
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_disk_type          = each.value.os_disk_type
  priority              = "Regular"
  auto_scaling_enabled  = true
  node_count            = each.value.node_count
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  scale_down_mode       = "Delete"
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints
  zones                 = length(each.value.zones) > 0 ? each.value.zones : null
  temporary_name_for_rotation = coalesce(
    each.value.temporary_name_for_rotation,
    "${substr(each.key, 0, 8)}tmp",
  )
  tags = var.tags

  upgrade_settings {
    max_surge = each.value.max_surge
  }

  lifecycle {
    ignore_changes = [node_count]
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  count                            = var.acr_pull_role_assignment_enabled ? 1 : 0
  scope                            = var.container_registry_id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true

  lifecycle {
    precondition {
      condition     = var.container_registry_id != null
      error_message = "container_registry_id must be set when acr_pull_role_assignment_enabled is true."
    }
  }
}
