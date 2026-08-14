locals {
  account_name       = coalesce(var.account_name, "cosmos-${var.name}")
  sql_database_name  = coalesce(var.sql_database_name, "cosmos-${var.name}-sqldb")
  sql_container_name = coalesce(var.sql_container_name, "cosmos-${var.name}-sqlcontainer")
  partition_key_paths = coalesce(
    var.partition_key_paths,
    [var.partition_key_path],
  )
  geo_locations = length(var.geo_locations) > 0 ? var.geo_locations : [
    {
      location          = var.location
      failover_priority = 0
      zone_redundant    = false
    }
  ]
}

resource "azurerm_cosmosdb_account" "this" {
  name                          = local.account_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  offer_type                    = "Standard"
  kind                          = "GlobalDocumentDB"
  tags                          = var.tags
  public_network_access_enabled = var.public_network_access_enabled
  local_authentication_enabled  = var.local_authentication_enabled
  minimal_tls_version           = var.minimal_tls_version

  dynamic "capabilities" {
    for_each = var.capabilities
    content {
      name = capabilities.value
    }
  }

  consistency_policy {
    consistency_level       = var.consistency_level
    max_interval_in_seconds = var.consistency_max_interval_in_seconds
    max_staleness_prefix    = var.consistency_max_staleness_prefix
  }

  dynamic "geo_location" {
    for_each = local.geo_locations
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.failover_priority
      zone_redundant    = geo_location.value.zone_redundant
    }
  }
}

resource "azurerm_cosmosdb_sql_database" "this" {
  count = var.create_sql_database ? 1 : 0

  name                = local.sql_database_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
}

resource "azurerm_cosmosdb_sql_container" "this" {
  count = var.create_sql_container ? 1 : 0

  name                = local.sql_container_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  database_name       = one(azurerm_cosmosdb_sql_database.this[*].name)
  partition_key_paths = local.partition_key_paths

  lifecycle {
    precondition {
      condition     = var.create_sql_database
      error_message = "create_sql_database must be true when create_sql_container is true."
    }
  }
}

moved {
  from = azurerm_cosmosdb_sql_database.this
  to   = azurerm_cosmosdb_sql_database.this[0]
}

moved {
  from = azurerm_cosmosdb_sql_container.this
  to   = azurerm_cosmosdb_sql_container.this[0]
}
