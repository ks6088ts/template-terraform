# =============================================================================
# Random String
# =============================================================================

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
  resource_name   = "${trim(substr(var.name, 0, 46), "-")}-${local.resource_suffix}"
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
# Azure Functions Flex Consumption
# =============================================================================

module "functions_flex_consumption" {
  source = "../../modules/azure/functions_flex_consumption"

  name                 = local.resource_name
  resource_group_name  = module.resource_group.name
  location             = module.resource_group.location
  tags                 = var.tags
  storage_account_name = "st${local.resource_suffix}"

  # Runtime configuration
  runtime_name    = var.runtime_name
  runtime_version = var.runtime_version

  # Scaling configuration
  maximum_instance_count = var.maximum_instance_count
  instance_memory_in_mb  = var.instance_memory_in_mb
  zone_redundant         = var.zone_redundant

  # Additional app settings
  app_settings = var.app_settings
}
