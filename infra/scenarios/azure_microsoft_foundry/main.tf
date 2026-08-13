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
  resource_name   = "${trim(substr(var.name, 0, 78), "-")}-${local.resource_suffix}"
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
# Microsoft Foundry
# =============================================================================

module "microsoft_foundry" {
  source = "../../modules/azure/microsoft_foundry"

  name              = "msfoundry${local.resource_suffix}"
  resource_group_id = module.resource_group.id
  location          = var.location
  tags              = var.tags
  model_deployments = var.model_deployments
}
