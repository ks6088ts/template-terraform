module "random_string" {
  source = "../../modules/common/random_string"
}

# =============================================================================
# Resource Group
# =============================================================================

module "resource_group" {
  source = "../../modules/azure/resource_group"

  name     = "${var.name}-${module.random_string.result}"
  location = var.location
  tags     = var.tags
}

# =============================================================================
# Microsoft Foundry
# =============================================================================

module "microsoft_foundry" {
  source = "../../modules/azure/microsoft_foundry"

  name              = "msfoundry${module.random_string.result}"
  resource_group_id = module.resource_group.id
  location          = var.location
  tags              = var.tags
  model_deployments = var.model_deployments
}
