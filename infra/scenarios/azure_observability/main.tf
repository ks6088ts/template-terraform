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
  resource_name = "${var.name}-${module.random_string.result}"
  network_watcher_name = coalesce(
    var.network_watcher.name,
    var.network_watcher.create ? "nw-${local.resource_name}" : "NetworkWatcher_${var.location}",
  )
  network_watcher_resource_group = var.network_watcher.create ? module.resource_group.name : var.network_watcher.resource_group_name
  workbook_name                  = uuidv5("url", "${module.resource_group.id}/observability-workbook")
  workbook_data_json = var.features.workbook ? templatefile("${path.module}/templates/workbook.json.tftpl", {
    workspace_id = module.log_analytics[0].id
  }) : null
}

module "client_config" {
  source = "../../modules/azure/client_config"
}

module "resource_group" {
  source = "../../modules/azure/resource_group"

  name     = local.resource_name
  location = var.location
  tags     = var.tags
}

module "azure_monitor" {
  source = "../../modules/azure/monitor"
  count  = var.features.azure_monitor ? 1 : 0

  name                = local.resource_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
}

module "log_analytics" {
  source = "../../modules/azure/log_analytics"
  count  = var.features.log_analytics ? 1 : 0

  name                = local.resource_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_in_days
  daily_quota_gb      = var.log_analytics_daily_quota_gb
  tags                = var.tags
}

module "application_insights" {
  source = "../../modules/azure/application_insights"
  count  = var.features.application_insights ? 1 : 0

  name                = local.resource_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  workspace_id        = module.log_analytics[0].id
  sampling_percentage = var.application_insights_sampling_percentage
  tags                = var.tags
}

module "network_watcher" {
  source = "../../modules/azure/network_watcher"
  count  = var.features.network_watcher ? 1 : 0

  name                = local.network_watcher_name
  resource_group_name = local.network_watcher_resource_group
  location            = module.resource_group.location
  create              = var.network_watcher.create
  tags                = var.tags
}

module "activity_log" {
  source = "../../modules/azure/activity_log"
  count  = var.features.activity_log ? 1 : 0

  name                       = "activity-${local.resource_name}"
  subscription_id            = module.client_config.subscription_id
  log_analytics_workspace_id = module.log_analytics[0].id
  categories                 = var.activity_log_categories
}

module "action_group" {
  source = "../../modules/azure/monitor_action_group"
  count  = var.features.action_group ? 1 : 0

  name                = "ag-${local.resource_name}"
  resource_group_name = module.resource_group.name
  email_addresses     = var.action_group_email_addresses
  tags                = var.tags
}

module "alert_rule" {
  source = "../../modules/azure/monitor_activity_log_alert"
  count  = var.features.alert_rules ? 1 : 0

  name                  = "alert-${local.resource_name}"
  resource_group_name   = module.resource_group.name
  scopes                = [module.resource_group.id]
  resource_group_filter = module.resource_group.name
  action_group_ids      = [module.action_group[0].id]
  tags                  = var.tags
}

module "workbook" {
  source = "../../modules/azure/monitor_workbook"
  count  = var.features.workbook ? 1 : 0

  name                = local.workbook_name
  display_name        = "Observability ${local.resource_name}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  source_id           = module.log_analytics[0].id
  data_json           = local.workbook_data_json
  tags                = var.tags
}
