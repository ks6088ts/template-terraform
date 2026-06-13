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
# Application Insights
# =============================================================================

module "application_insights" {
  count  = var.enable_application_insights ? 1 : 0
  source = "../../modules/azure/application_insights"

  name                = var.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
  workspace_id        = module.log_analytics.id
  application_type    = var.application_insights_type
  sampling_percentage = var.application_insights_sampling_percentage
}

# =============================================================================
# Container Apps
# =============================================================================

locals {
  # Application Insights connection string is sensitive, so it is stored as a
  # Container App secret and referenced from an environment variable.
  application_insights_secret_name = "applicationinsights-connection-string"

  application_insights_secrets = var.enable_application_insights ? [{
    name  = local.application_insights_secret_name
    value = module.application_insights[0].connection_string
  }] : []

  application_insights_env_vars = var.enable_application_insights ? [{
    name        = "APPLICATIONINSIGHTS_CONNECTION_STRING"
    secret_name = local.application_insights_secret_name
  }] : []
}

module "container_apps" {
  source = "../../modules/azure/container_apps"

  name                       = var.name
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  tags                       = var.tags
  log_analytics_workspace_id = module.log_analytics.id
  container_image            = var.container_image
  container_command          = var.container_command
  cpu                        = var.cpu
  memory                     = var.memory
  min_replicas               = var.min_replicas
  max_replicas               = var.max_replicas
  target_port                = var.container_port
  env_vars                   = concat(local.application_insights_env_vars, var.env_vars)
  secrets                    = concat(local.application_insights_secrets, var.secrets)
}
