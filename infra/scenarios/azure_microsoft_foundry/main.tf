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
  resource_suffix           = module.random_string.result
  resource_name             = "${trim(substr(var.name, 0, 78), "-")}-${local.resource_suffix}"
  microsoft_foundry_name    = "msfoundry${local.resource_suffix}"
  blob_storage_account_name = "stmsfoundry${local.resource_suffix}"
}

data "azurerm_client_config" "current" {}

# =============================================================================
# Resource Group
# =============================================================================

module "resource_group" {
  source = "../../modules/azure/resource_group"

  name     = local.resource_name
  location = var.location
  tags     = var.tags
}

locals {
  operator_principal_id                      = coalesce(var.operator_principal_id, data.azurerm_client_config.current.object_id)
  foundry_user_role_definition_id            = "/subscriptions/${split("/", module.resource_group.id)[2]}/providers/Microsoft.Authorization/roleDefinitions/53ca6127-db72-4b80-b1b0-d745d6d5456d"
  foundry_project_manager_role_definition_id = "/subscriptions/${split("/", module.resource_group.id)[2]}/providers/Microsoft.Authorization/roleDefinitions/eadc314b-1a2d-4efa-be10-5d325db5065e"
}

# =============================================================================
# Azure AI Search
# =============================================================================

module "azure_ai_search" {
  source = "../../modules/azure/ai_search"
  count  = var.deploy_standard_agent ? 1 : 0

  name                         = "aisearch${local.resource_suffix}"
  resource_group_name          = module.resource_group.name
  location                     = module.resource_group.location
  sku                          = var.azure_ai_search_sku
  local_authentication_enabled = false
  enable_identity              = true
  tags                         = var.tags
}

# =============================================================================
# Azure Blob Storage
# =============================================================================

module "blob_storage" {
  source = "../../modules/azure/storage"
  count  = var.deploy_standard_agent ? 1 : 0

  name                            = local.resource_name
  storage_account_name            = local.blob_storage_account_name
  resource_group_name             = module.resource_group.name
  location                        = module.resource_group.location
  tags                            = var.tags
  account_tier                    = "Standard"
  account_replication_type        = "ZRS"
  is_hns_enabled                  = false
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false
  enable_identity                 = false
  private_endpoint                = null
  enable_blob_soft_delete         = false
  create_queue                    = false
  create_container                = false
}

# =============================================================================
# Microsoft Foundry
# =============================================================================

module "microsoft_foundry" {
  source = "../../modules/azure/microsoft_foundry"

  name               = local.microsoft_foundry_name
  resource_group_id  = module.resource_group.id
  location           = var.location
  tags               = var.tags
  disable_local_auth = true
  model_deployments  = var.model_deployments

  # The destroy-only purge action must outlive the Foundry account.
  depends_on = [
    terraform_data.purge_microsoft_foundry_account,
  ]
}
