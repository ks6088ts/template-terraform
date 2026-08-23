module "random_string" {
  source = "../../modules/common/random_string"

  length      = 8
  min_numeric = 0
  numeric     = true
  special     = false
  lower       = true
  upper       = false
}

locals {
  resource_suffix = module.random_string.result
  resource_name   = "${trim(substr(var.name, 0, 40), "-")}-${local.resource_suffix}"
}

# =============================================================================
# Resource Group
# =============================================================================

module "resource_group" {
  source = "../../modules/azure/resource_group"

  name     = local.resource_name
  location = var.location
  tags     = var.tags
}

# =============================================================================
# Azure Container Registry
# =============================================================================

module "container_registry" {
  source = "../../modules/azure/container_registry"

  name                = local.resource_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.acr_sku
  admin_enabled       = var.acr_admin_enabled
  tags                = var.tags
}

# =============================================================================
# Azure Kubernetes Service
# =============================================================================

module "kubernetes_service" {
  source = "../../modules/azure/kubernetes_service"

  name                                = local.resource_name
  resource_group_name                 = module.resource_group.name
  location                            = module.resource_group.location
  kubernetes_version                  = var.kubernetes_version
  automatic_upgrade_channel           = var.automatic_upgrade_channel
  node_os_upgrade_channel             = var.node_os_upgrade_channel
  oidc_issuer_enabled                 = var.oidc_issuer_enabled
  workload_identity_enabled           = var.workload_identity_enabled
  key_vault_secrets_provider_enabled  = var.key_vault_secrets_provider_enabled
  vm_size                             = var.vm_size
  node_count                          = var.node_count
  os_disk_size_gb                     = var.os_disk_size_gb
  auto_scaling_enabled                = var.auto_scaling_enabled
  min_count                           = var.min_count
  max_count                           = var.max_count
  network_plugin                      = var.network_plugin
  network_plugin_mode                 = var.network_plugin_mode
  network_data_plane                  = var.network_data_plane
  network_policy                      = var.network_policy
  user_node_pool_enabled              = var.user_node_pool_enabled
  user_node_pool_vm_size              = var.user_node_pool_vm_size
  user_node_pool_auto_scaling_enabled = var.user_node_pool_auto_scaling_enabled
  user_node_pool_min_count            = var.user_node_pool_min_count
  user_node_pool_max_count            = var.user_node_pool_max_count
  user_node_pool_os_disk_size_gb      = var.user_node_pool_os_disk_size_gb
  enable_acr_pull                     = true
  acr_id                              = module.container_registry.id
  tags                                = var.tags
}
