resource "azurerm_cosmosdb_account" "this" {
  name                          = "cosmos-${var.name}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  offer_type                    = "Standard"
  kind                          = "GlobalDocumentDB"
  tags                          = var.tags
  public_network_access_enabled = true

  capabilities {
    name = "EnableNoSQLVectorSearch"
  }

  capabilities {
    name = "EnableServerless"
  }

  consistency_policy {
    consistency_level = var.consistency_level
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_database" "this" {
  name                = "cosmos-${var.name}-sqldb"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
}

resource "azurerm_cosmosdb_sql_container" "this" {
  name                = "cosmos-${var.name}-sqlcontainer"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  database_name       = azurerm_cosmosdb_sql_database.this.name
  partition_key_paths = [var.partition_key_path]
}
