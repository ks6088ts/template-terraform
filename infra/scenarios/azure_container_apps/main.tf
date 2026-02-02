# =============================================================================
# Resource Group
# =============================================================================

module "resource_group" {
  source = "../../modules/azure/resource_group"

  name     = var.name
  location = var.location
  tags     = var.tags
}

# =============================================================================
# Log Analytics Workspace
# =============================================================================

module "log_analytics" {
  source = "../../modules/azure/log_analytics"

  name                = var.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
}

# =============================================================================
# Container Apps
# =============================================================================

module "container_apps" {
  source = "../../modules/azure/container_apps"

  name                       = var.name
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  tags                       = var.tags
  log_analytics_workspace_id = module.log_analytics.id
  container_image            = var.container_image
  cpu                        = var.cpu
  memory                     = var.memory
  min_replicas               = var.min_replicas
  max_replicas               = var.max_replicas
  target_port                = var.container_port
}
