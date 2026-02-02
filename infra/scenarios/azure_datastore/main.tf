# =============================================================================
# Data sources
# =============================================================================

data "azurerm_client_config" "current" {}

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
# Cosmos DB
# =============================================================================

module "cosmosdb" {
  source = "../../modules/azure/cosmosdb"
  count  = var.deploy_cosmosdb ? 1 : 0

  name                = var.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
  consistency_level   = var.cosmosdb_consistency_level
  partition_key_path  = var.cosmosdb_partition_key_path
}

# =============================================================================
# Storage Account
# =============================================================================

module "storage" {
  source = "../../modules/azure/storage"
  count  = var.deploy_storage_account ? 1 : 0

  name                     = var.name
  resource_group_name      = module.resource_group.name
  location                 = module.resource_group.location
  tags                     = var.tags
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
}

# =============================================================================
# Key Vault
# =============================================================================

module "keyvault" {
  source = "../../modules/azure/keyvault"
  count  = var.deploy_keyvault ? 1 : 0

  name                = var.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
  sku_name            = var.keyvault_sku_name
}

# =============================================================================
# PostgreSQL Flexible Server
# =============================================================================

module "postgresql" {
  source = "../../modules/azure/postgresql"
  count  = var.deploy_postgresql ? 1 : 0

  name                   = var.name
  resource_group_name    = module.resource_group.name
  location               = module.resource_group.location
  tags                   = var.tags
  tenant_id              = data.azurerm_client_config.current.tenant_id
  administrator_login    = var.postgresql_administrator_login
  administrator_password = var.postgresql_administrator_password
  postgresql_version     = var.postgresql_version
  sku_name               = var.postgresql_sku_name
  zone                   = var.postgresql_zone
}

# =============================================================================
# Azure Monitor Workspace
# =============================================================================

module "monitor" {
  source = "../../modules/azure/monitor"
  count  = var.deploy_monitor_workspace ? 1 : 0

  name                = var.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
}
