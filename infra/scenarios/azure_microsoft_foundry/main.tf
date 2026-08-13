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
  resource_suffix        = module.random_string.result
  resource_name          = "${trim(substr(var.name, 0, 78), "-")}-${local.resource_suffix}"
  microsoft_foundry_name = "msfoundry${local.resource_suffix}"
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
# Azure AI Search
# =============================================================================

module "azure_ai_search" {
  source = "../../modules/azure/ai_search"
  count  = var.deploy_azure_ai_search ? 1 : 0

  name                = "aisearch${local.resource_suffix}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.azure_ai_search_sku
  tags                = var.tags
}

# =============================================================================
# Microsoft Foundry
# =============================================================================

module "microsoft_foundry" {
  source = "../../modules/azure/microsoft_foundry"

  name              = local.microsoft_foundry_name
  resource_group_id = module.resource_group.id
  location          = var.location
  tags              = var.tags
  model_deployments = var.model_deployments

  # The destroy-only purge action must outlive the Foundry account.
  depends_on = [
    terraform_data.purge_microsoft_foundry_account,
  ]
}
