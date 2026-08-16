locals {
  tracing_resource_name = "tracing-${local.resource_suffix}"
}

module "log_analytics" {
  count  = var.enable_tracing ? 1 : 0
  source = "../../modules/azure/log_analytics"

  name                = local.tracing_resource_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
  retention_in_days   = 30
}

module "application_insights" {
  count  = var.enable_tracing ? 1 : 0
  source = "../../modules/azure/application_insights"

  name                         = local.tracing_resource_name
  resource_group_name          = module.resource_group.name
  location                     = module.resource_group.location
  tags                         = var.tags
  workspace_id                 = module.log_analytics[0].id
  application_type             = "web"
  sampling_percentage          = 100
  local_authentication_enabled = false
}
