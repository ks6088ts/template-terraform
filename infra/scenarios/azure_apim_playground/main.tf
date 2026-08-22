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
  resource_suffix     = module.random_string.result
  resource_name       = "${trim(substr(var.name, 0, 36), "-")}-${local.resource_suffix}"
  api_management_name = "apim-${local.resource_name}"
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
# API Management
# =============================================================================

module "api_management" {
  source = "../../modules/azure/api_management"

  name                            = local.api_management_name
  resource_group_name             = module.resource_group.name
  location                        = module.resource_group.location
  publisher_name                  = var.publisher_name
  publisher_email                 = var.publisher_email
  sku_name                        = var.sku_name
  enable_system_assigned_identity = local.ai_enabled || local.observability_enabled
  tags                            = var.tags
}
