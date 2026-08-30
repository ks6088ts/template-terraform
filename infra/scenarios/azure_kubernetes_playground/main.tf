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
# Optional Container Insights workspace
# =============================================================================

module "log_analytics" {
  count  = var.container_insights_enabled ? 1 : 0
  source = "../../modules/azure/log_analytics"

  name                = local.resource_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_in_days
  tags                = var.tags
}

# =============================================================================
# Azure Kubernetes Service
# =============================================================================

module "kubernetes_service" {
  source = "../../modules/azure/kubernetes_service"

  name                = local.resource_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier

  oidc_issuer_enabled             = var.oidc_issuer_enabled
  workload_identity_enabled       = var.workload_identity_enabled
  local_account_disabled          = var.local_account_disabled
  entra_id                        = var.entra_id
  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges

  automatic_upgrade_channel       = var.automatic_upgrade_channel
  node_os_upgrade_channel         = var.node_os_upgrade_channel
  image_cleaner_enabled           = var.image_cleaner_enabled
  image_cleaner_interval_hours    = var.image_cleaner_interval_hours
  maintenance_window_auto_upgrade = var.maintenance_window_auto_upgrade
  maintenance_window_node_os      = var.maintenance_window_node_os

  system_node_pool = var.system_node_pool
  user_node_pools  = var.user_node_pools
  network_profile  = var.network_profile

  log_analytics_workspace_id = var.container_insights_enabled ? module.log_analytics[0].id : null
  container_registry_id      = module.container_registry.id
  tags                       = var.tags
}
