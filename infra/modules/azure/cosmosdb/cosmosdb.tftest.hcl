mock_provider "azurerm" {
  override_during = plan
}

run "default_resources" {
  command = plan

  variables {
    name                = "test1234"
    resource_group_name = "rg-test"
    location            = "japaneast"
  }

  assert {
    condition = alltrue([
      azurerm_cosmosdb_account.this.name == "cosmos-test1234",
      azurerm_cosmosdb_account.this.public_network_access_enabled,
      azurerm_cosmosdb_account.this.local_authentication_enabled,
      azurerm_cosmosdb_account.this.minimal_tls_version == "Tls12",
      azurerm_cosmosdb_account.this.consistency_policy[0].consistency_level == "BoundedStaleness",
    ])
    error_message = "The Cosmos DB account defaults must remain backward compatible."
  }

  assert {
    condition = toset([
      for capability in azurerm_cosmosdb_account.this.capabilities : capability.name
      ]) == toset([
      "EnableNoSQLVectorSearch",
      "EnableServerless",
    ])
    error_message = "The default Cosmos DB capabilities must enable vector search and serverless mode."
  }

  assert {
    condition = alltrue([
      length(azurerm_cosmosdb_sql_database.this) == 1,
      azurerm_cosmosdb_sql_database.this[0].name == "cosmos-test1234-sqldb",
      length(azurerm_cosmosdb_sql_container.this) == 1,
      azurerm_cosmosdb_sql_container.this[0].name == "cosmos-test1234-sqlcontainer",
      toset(azurerm_cosmosdb_sql_container.this[0].partition_key_paths) == toset(["/partitionKey"]),
    ])
    error_message = "The module must create the legacy SQL database and container by default."
  }
}

run "account_only" {
  command = plan

  variables {
    name                         = "standard-agent"
    account_name                 = "cosmosmsfoundrytest1234"
    resource_group_name          = "rg-test"
    location                     = "japaneast"
    capabilities                 = []
    local_authentication_enabled = false
    consistency_level            = "Session"
    create_sql_database          = false
    create_sql_container         = false
  }

  assert {
    condition = alltrue([
      azurerm_cosmosdb_account.this.name == "cosmosmsfoundrytest1234",
      !azurerm_cosmosdb_account.this.local_authentication_enabled,
      azurerm_cosmosdb_account.this.minimal_tls_version == "Tls12",
      azurerm_cosmosdb_account.this.consistency_policy[0].consistency_level == "Session",
      length(azurerm_cosmosdb_account.this.capabilities) == 0,
    ])
    error_message = "Account-only mode must support an exact name, AAD-only authentication, and no capabilities."
  }

  assert {
    condition = alltrue([
      length(azurerm_cosmosdb_sql_database.this) == 0,
      length(azurerm_cosmosdb_sql_container.this) == 0,
      output.sql_database_name == null,
      output.sql_container_name == null,
    ])
    error_message = "Account-only mode must not create a SQL database or container."
  }
}

run "custom_resources" {
  command = plan

  variables {
    name                = "custom"
    account_name        = "cosmos-custom"
    resource_group_name = "rg-test"
    location            = "japaneast"
    capabilities        = ["EnableNoSQLVectorSearch"]
    consistency_level   = "Eventual"
    geo_locations = [
      {
        location          = "japaneast"
        failover_priority = 0
        zone_redundant    = true
      },
      {
        location          = "japanwest"
        failover_priority = 1
      },
    ]
    sql_database_name  = "appdb"
    sql_container_name = "items"
    partition_key_paths = [
      "/tenantId",
      "/userId",
    ]
  }

  assert {
    condition = alltrue([
      azurerm_cosmosdb_sql_database.this[0].name == "appdb",
      azurerm_cosmosdb_sql_container.this[0].name == "items",
      toset(azurerm_cosmosdb_sql_container.this[0].partition_key_paths) == toset(["/tenantId", "/userId"]),
      azurerm_cosmosdb_account.this.consistency_policy[0].consistency_level == "Eventual",
    ])
    error_message = "Custom database, container, partition keys, and consistency settings must be applied."
  }

  assert {
    condition = toset([
      for geo in azurerm_cosmosdb_account.this.geo_location : "${geo.location}:${geo.failover_priority}"
      ]) == toset([
      "japaneast:0",
      "japanwest:1",
    ])
    error_message = "Custom geo locations must be applied to the Cosmos DB account."
  }
}