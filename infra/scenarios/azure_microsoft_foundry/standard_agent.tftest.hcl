mock_provider "azurerm" {
  override_during = plan

  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/azuremicrosoftfoundry-test1234"
    }
  }

  mock_resource "azurerm_search_service" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Search/searchServices/aisearchtest1234"
      endpoint = "https://aisearchtest1234.search.windows.net"
    }
  }

  mock_resource "azurerm_storage_account" {
    defaults = {
      id                    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Storage/storageAccounts/stmsfoundrytest1234"
      primary_blob_endpoint = "https://stmsfoundrytest1234.blob.core.windows.net/"
    }
  }

  mock_resource "azurerm_cosmosdb_account" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.DocumentDB/databaseAccounts/cosmosmsfoundrytest1234"
      endpoint = "https://cosmosmsfoundrytest1234.documents.azure.com:443/"
    }
  }
}

mock_provider "azapi" {
  override_during = plan

  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.CognitiveServices/accounts/test/projects/test"
      output = {
        identity = {
          principalId = "00000000-0000-0000-0000-000000000001"
        }
      }
    }
  }
}

mock_provider "random" {
  override_during = plan

  mock_resource "random_string" {
    defaults = {
      result = "test1234"
    }
  }
}

mock_provider "time" {
  override_during = plan
}

run "standard_agent_disabled_by_default" {
  command = plan

  variables {
    deploy_standard_agent = false
    model_deployments     = []
  }

  assert {
    condition = alltrue([
      length(module.azure_ai_search) == 0,
      length(module.blob_storage) == 0,
      length(azurerm_cosmosdb_account.agent_threads) == 0,
    ])
    error_message = "Standard Agent data services must not be deployed by default."
  }

  assert {
    condition = alltrue([
      length(azapi_resource.azure_ai_search_connection) == 0,
      length(azapi_resource.blob_storage_connection) == 0,
      length(azapi_resource.cosmosdb_connection) == 0,
      length(azapi_resource.account_capability_host) == 0,
      length(azapi_resource.project_capability_host) == 0,
    ])
    error_message = "Standard Agent connections and capability hosts must not be deployed by default."
  }

  assert {
    condition = alltrue([
      length(azurerm_role_assignment.storage_blob_data_contributor) == 0,
      length(azurerm_role_assignment.search_index_data_contributor) == 0,
      length(azurerm_role_assignment.search_service_contributor) == 0,
      length(azurerm_role_assignment.cosmos_db_operator) == 0,
      length(time_sleep.wait_for_rbac) == 0,
      length(azurerm_cosmosdb_sql_role_assignment.cosmos_data_contributor) == 0,
    ])
    error_message = "Standard Agent role assignments and propagation wait must not be deployed by default."
  }

  assert {
    condition = alltrue([
      output.azure_ai_search_id == null,
      output.blob_storage_account_id == null,
      output.cosmosdb_account_id == null,
      output.account_capability_host_id == null,
      output.project_capability_host_id == null,
    ])
    error_message = "Standard Agent outputs must be null when deployment is disabled."
  }

  assert {
    condition     = terraform_data.purge_microsoft_foundry_account.input.account_name == "msfoundrytest1234"
    error_message = "The Foundry purge hook must target the scenario account."
  }

  assert {
    condition     = terraform_data.purge_microsoft_foundry_account.input.resource_group_name == "rg-azuremicrosoftfoundry-test1234"
    error_message = "The Foundry purge hook must target the scenario resource group."
  }

  assert {
    condition     = terraform_data.purge_microsoft_foundry_account.input.location == "japaneast"
    error_message = "The Foundry purge hook must target the scenario location."
  }

  assert {
    condition     = terraform_data.purge_microsoft_foundry_account.input.subscription_id == "00000000-0000-0000-0000-000000000000"
    error_message = "The Foundry purge hook must target the resource group subscription."
  }
}

run "standard_agent_enabled" {
  command = plan

  variables {
    deploy_standard_agent = true
    azure_ai_search_sku   = "standard"
    model_deployments     = []
  }

  assert {
    condition = alltrue([
      length(module.azure_ai_search) == 1,
      length(module.blob_storage) == 1,
      length(azurerm_cosmosdb_account.agent_threads) == 1,
    ])
    error_message = "Standard Agent must deploy Search, Storage, and Cosmos DB together."
  }

  assert {
    condition = alltrue([
      module.azure_ai_search[0].name == "aisearchtest1234",
      module.blob_storage[0].account_name == "stmsfoundrytest1234",
      module.blob_storage[0].container_name == null,
      azurerm_cosmosdb_account.agent_threads[0].name == "cosmosmsfoundrytest1234",
    ])
    error_message = "Standard Agent data services must use the scenario suffix and must not create a Blob container."
  }

  assert {
    condition = alltrue([
      azurerm_cosmosdb_account.agent_threads[0].local_authentication_enabled == false,
      azurerm_cosmosdb_account.agent_threads[0].minimal_tls_version == "Tls12",
      azurerm_cosmosdb_account.agent_threads[0].consistency_policy[0].consistency_level == "Session",
    ])
    error_message = "Cosmos DB must use AAD-only authentication, TLS 1.2, and Session consistency."
  }

  assert {
    condition = alltrue([
      length(azapi_resource.azure_ai_search_connection) == 1,
      length(azapi_resource.blob_storage_connection) == 1,
      length(azapi_resource.cosmosdb_connection) == 1,
    ])
    error_message = "Standard Agent must create one connection for each data service."
  }

  assert {
    condition = alltrue([
      azapi_resource.azure_ai_search_connection[0].body.properties.authType == "AAD",
      azapi_resource.blob_storage_connection[0].body.properties.authType == "AAD",
      azapi_resource.cosmosdb_connection[0].body.properties.authType == "AAD",
    ])
    error_message = "All Standard Agent connections must use AAD authentication."
  }

  assert {
    condition = alltrue([
      azapi_resource.azure_ai_search_connection[0].body.properties.category == "CognitiveSearch",
      azapi_resource.blob_storage_connection[0].body.properties.category == "AzureStorageAccount",
      azapi_resource.cosmosdb_connection[0].body.properties.category == "CosmosDb",
    ])
    error_message = "Each Standard Agent connection must use the expected resource category."
  }

  assert {
    condition = alltrue([
      !contains(keys(azapi_resource.azure_ai_search_connection[0].body.properties), "credentials"),
      !contains(keys(azapi_resource.blob_storage_connection[0].body.properties), "credentials"),
      !contains(keys(azapi_resource.cosmosdb_connection[0].body.properties), "credentials"),
    ])
    error_message = "Standard Agent connection bodies must not contain credentials."
  }

  assert {
    condition = alltrue([
      azapi_resource.azure_ai_search_connection[0].body.properties.metadata.ResourceId == module.azure_ai_search[0].id,
      azapi_resource.blob_storage_connection[0].body.properties.metadata.ResourceId == module.blob_storage[0].account_id,
      azapi_resource.cosmosdb_connection[0].body.properties.metadata.ResourceId == azurerm_cosmosdb_account.agent_threads[0].id,
    ])
    error_message = "Standard Agent connection metadata must identify each backing resource."
  }

  assert {
    condition = alltrue([
      length(azurerm_role_assignment.storage_blob_data_contributor) == 1,
      length(azurerm_role_assignment.search_index_data_contributor) == 1,
      length(azurerm_role_assignment.search_service_contributor) == 1,
      length(azurerm_role_assignment.cosmos_db_operator) == 1,
    ])
    error_message = "Standard Agent must create the four required ARM role assignments."
  }

  assert {
    condition = alltrue([
      azurerm_role_assignment.storage_blob_data_contributor[0].role_definition_name == "Storage Blob Data Contributor",
      azurerm_role_assignment.search_index_data_contributor[0].role_definition_name == "Search Index Data Contributor",
      azurerm_role_assignment.search_service_contributor[0].role_definition_name == "Search Service Contributor",
      azurerm_role_assignment.cosmos_db_operator[0].role_definition_name == "Cosmos DB Operator",
    ])
    error_message = "Standard Agent must assign the required built-in ARM roles."
  }

  assert {
    condition = alltrue([
      azurerm_role_assignment.storage_blob_data_contributor[0].principal_id == module.microsoft_foundry.project_principal_id,
      azurerm_role_assignment.search_index_data_contributor[0].principal_id == module.microsoft_foundry.project_principal_id,
      azurerm_role_assignment.search_service_contributor[0].principal_id == module.microsoft_foundry.project_principal_id,
      azurerm_role_assignment.cosmos_db_operator[0].principal_id == module.microsoft_foundry.project_principal_id,
    ])
    error_message = "Standard Agent roles must be assigned to the Foundry project managed identity."
  }

  assert {
    condition     = time_sleep.wait_for_rbac[0].create_duration == "60s"
    error_message = "Standard Agent must wait 60 seconds for ARM role assignments to propagate."
  }

  assert {
    condition = alltrue([
      azapi_resource.account_capability_host[0].type == "Microsoft.CognitiveServices/accounts/capabilityHosts@2025-06-01",
      azapi_resource.project_capability_host[0].type == "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-06-01",
      azapi_resource.account_capability_host[0].body.properties.capabilityHostKind == "Agents",
    ])
    error_message = "Standard Agent capability hosts must use the stable API and Agents kind."
  }

  assert {
    condition = alltrue([
      azapi_resource.project_capability_host[0].body.properties.storageConnections == [module.blob_storage[0].account_name],
      azapi_resource.project_capability_host[0].body.properties.vectorStoreConnections == [module.azure_ai_search[0].name],
      azapi_resource.project_capability_host[0].body.properties.threadStorageConnections == [azurerm_cosmosdb_account.agent_threads[0].name],
      !contains(keys(azapi_resource.project_capability_host[0].body.properties), "capabilityHostKind"),
    ])
    error_message = "The project capability host must reference the three Standard Agent connections using the stable schema."
  }

  assert {
    condition = alltrue([
      azurerm_cosmosdb_sql_role_assignment.cosmos_data_contributor[0].role_definition_id == "${azurerm_cosmosdb_account.agent_threads[0].id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002",
      azurerm_cosmosdb_sql_role_assignment.cosmos_data_contributor[0].scope == "${azurerm_cosmosdb_account.agent_threads[0].id}/dbs/enterprise_memory",
      azurerm_cosmosdb_sql_role_assignment.cosmos_data_contributor[0].principal_id == module.microsoft_foundry.project_principal_id,
    ])
    error_message = "The Foundry project identity must receive Cosmos DB data-plane access to enterprise_memory."
  }

  assert {
    condition = alltrue([
      output.azure_ai_search_connection_id == azapi_resource.azure_ai_search_connection[0].id,
      output.blob_storage_connection_id == azapi_resource.blob_storage_connection[0].id,
      output.cosmosdb_connection_id == azapi_resource.cosmosdb_connection[0].id,
      output.account_capability_host_id == azapi_resource.account_capability_host[0].id,
      output.project_capability_host_id == azapi_resource.project_capability_host[0].id,
    ])
    error_message = "Standard Agent outputs must match the created connections and capability hosts."
  }
}

run "standard_agent_rejects_free_search_sku" {
  command = plan

  variables {
    deploy_standard_agent = true
    azure_ai_search_sku   = "free"
    model_deployments     = []
  }

  expect_failures = [
    var.azure_ai_search_sku,
  ]
}