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
  resource_suffix       = module.random_string.result
  resource_name         = "${trim(substr(var.name, 0, 14), "-")}-${local.resource_suffix}"
  operator_principal_id = coalesce(var.operator_principal_id, module.client_config.object_id)
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

module "queue_storage" {
  source = "../../modules/azure/storage"
  count  = var.enable_queue_storage ? 1 : 0

  name                                = local.resource_name
  storage_account_name                = replace("st${local.resource_name}", "-", "")
  resource_group_name                 = module.resource_group.name
  location                            = module.resource_group.location
  tags                                = var.tags
  account_tier                        = "Standard"
  account_replication_type            = var.queue_storage_replication_type
  enable_hns                          = var.queue_storage_enable_hns
  shared_access_key_enabled           = false
  enable_identity                     = false
  create_queue                        = true
  queue_data_contributor_principal_id = local.operator_principal_id
}

module "service_bus" {
  source = "../../modules/azure/service_bus"
  count  = var.enable_service_bus ? 1 : 0

  name                  = "sb-${local.resource_name}"
  resource_group_name   = module.resource_group.name
  location              = module.resource_group.location
  tags                  = var.tags
  sku                   = var.service_bus_sku
  premium_capacity      = var.service_bus_premium_capacity
  queue_name            = "queue"
  topic_name            = "topic"
  subscription_name     = "subscription"
  operator_principal_id = local.operator_principal_id
}

module "event_grid" {
  source = "../../modules/azure/event_grid"
  count  = var.enable_event_grid ? 1 : 0

  name                  = "egt-${local.resource_name}"
  resource_group_name   = module.resource_group.name
  location              = module.resource_group.location
  tags                  = var.tags
  input_schema          = var.event_grid_input_schema
  operator_principal_id = local.operator_principal_id
}

module "event_hubs" {
  source = "../../modules/azure/event_hubs"
  count  = var.enable_event_hubs ? 1 : 0

  name                  = "evhns-${local.resource_name}"
  resource_group_name   = module.resource_group.name
  location              = module.resource_group.location
  tags                  = var.tags
  sku                   = var.event_hubs_sku
  capacity              = var.event_hubs_capacity
  eventhub_name         = "events"
  partition_count       = var.event_hubs_partition_count
  message_retention     = var.event_hubs_message_retention
  operator_principal_id = local.operator_principal_id
}
