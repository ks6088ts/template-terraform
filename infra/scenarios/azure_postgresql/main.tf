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
# PostgreSQL Flexible Server
# =============================================================================

data "azurerm_client_config" "current" {}

# Auto-generate a strong administrator password unless one is provided
resource "random_password" "admin" {
  length           = 24
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!#%*-_=+"
}

locals {
  administrator_password = var.administrator_password != null ? var.administrator_password : random_password.admin.result
}

module "postgresql" {
  source = "../../modules/azure/postgresql"

  name                   = var.name
  resource_group_name    = module.resource_group.name
  location               = module.resource_group.location
  tags                   = var.tags
  tenant_id              = data.azurerm_client_config.current.tenant_id
  administrator_login    = var.administrator_login
  administrator_password = local.administrator_password
  postgresql_version     = var.postgresql_version
  sku_name               = var.sku_name
}

# Database
resource "azurerm_postgresql_flexible_server_database" "this" {
  name      = var.database_name
  server_id = module.postgresql.server_id
}
