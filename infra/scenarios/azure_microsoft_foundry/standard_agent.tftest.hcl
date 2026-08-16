mock_provider "azurerm" {
  override_during = plan

  mock_data "azurerm_client_config" {
    defaults = {
      object_id = "00000000-0000-0000-0000-000000000005"
    }
  }

  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/azuremicrosoftfoundry-test1234"
    }
  }

  mock_resource "azurerm_search_service" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Search/searchServices/aisearchtest1234"
      endpoint = "https://aisearchtest1234.search.windows.net"
      identity = {
        principal_id = "00000000-0000-0000-0000-000000000002"
        tenant_id    = "00000000-0000-0000-0000-000000000003"
      }
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

  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.OperationalInsights/workspaces/law-tracing-test1234"
      workspace_id = "00000000-0000-0000-0000-000000000006"
    }
  }

  mock_resource "azurerm_application_insights" {
    defaults = {
      id                           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Insights/components/appi-tracing-test1234"
      app_id                       = "00000000-0000-0000-0000-000000000007"
      connection_string            = "InstrumentationKey=00000000-0000-0000-0000-000000000008"
      instrumentation_key          = "00000000-0000-0000-0000-000000000008"
      local_authentication_enabled = false
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
    enable_tracing        = false
    model_deployments     = []
  }

  assert {
    condition = alltrue([
      length(module.azure_ai_search) == 0,
      length(module.blob_storage) == 0,
      length(module.cosmosdb) == 0,
    ])
    error_message = "Standard Agent data services must not be deployed by default."
  }

  assert {
    condition = alltrue([
      length(module.log_analytics) == 0,
      length(module.application_insights) == 0,
      length(azapi_resource.application_insights_connection) == 0,
      length(azurerm_role_assignment.monitoring_metrics_publisher) == 0,
      length(azurerm_role_assignment.operator_log_analytics_reader) == 0,
    ])
    error_message = "Foundry tracing resources must not be deployed by default."
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
      length(azurerm_role_assignment.search_index_data_reader) == 0,
      length(azurerm_role_assignment.search_storage_blob_data_reader) == 0,
      length(azurerm_role_assignment.search_cognitive_services_user) == 0,
      length(azurerm_role_assignment.project_foundry_user) == 0,
      length(azurerm_role_assignment.operator_storage_blob_data_contributor) == 0,
      length(azurerm_role_assignment.operator_search_index_data_contributor) == 0,
      length(azurerm_role_assignment.operator_search_index_data_reader) == 0,
      length(azurerm_role_assignment.operator_search_service_contributor) == 0,
      length(azurerm_role_assignment.operator_foundry_project_manager) == 0,
      length(azurerm_role_assignment.operator_cosmos_db_reader) == 0,
      length(azurerm_role_assignment.cosmos_db_operator) == 0,
      length(time_sleep.wait_for_rbac) == 0,
      length(azurerm_cosmosdb_sql_role_assignment.cosmos_data_contributor) == 0,
      length(azurerm_cosmosdb_sql_role_assignment.operator_cosmos_data_reader) == 0,
    ])
    error_message = "Standard Agent role assignments and propagation wait must not be deployed by default."
  }

  assert {
    condition = alltrue([
      output.azure_ai_search_id == null,
      output.azure_ai_search_identity_principal_id == null,
      output.blob_storage_account_id == null,
      output.cosmosdb_account_id == null,
      output.account_capability_host_id == null,
      output.project_capability_host_id == null,
    ])
    error_message = "Standard Agent outputs must be null when deployment is disabled."
  }

  assert {
    condition = alltrue([
      output.log_analytics_workspace_id == null,
      output.application_insights_id == null,
      output.application_insights_connection_id == null,
    ])
    error_message = "Foundry tracing outputs must be null when tracing is disabled."
  }

  assert {
    condition     = output.operator_principal_id == "00000000-0000-0000-0000-000000000005"
    error_message = "The operator principal must default to the Terraform client principal."
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

run "tracing_enabled_independently" {
  command = plan

  variables {
    deploy_standard_agent = false
    enable_tracing        = true
    model_deployments     = []
    operator_principal_id = "00000000-0000-0000-0000-000000000004"
  }

  assert {
    condition = alltrue([
      length(module.log_analytics) == 1,
      length(module.application_insights) == 1,
      length(module.azure_ai_search) == 0,
      length(module.blob_storage) == 0,
      length(module.cosmosdb) == 0,
    ])
    error_message = "Tracing must deploy independently from Standard Agent data services."
  }

  assert {
    condition = alltrue([
      module.log_analytics[0].name == "law-tracing-test1234",
      module.application_insights[0].name == "appi-tracing-test1234",
    ])
    error_message = "Tracing resources must use deterministic names."
  }

  assert {
    condition = alltrue([
      length(azapi_resource.application_insights_connection) == 1,
      azapi_resource.application_insights_connection[0].type == "Microsoft.CognitiveServices/accounts/projects/connections@2025-09-01",
      azapi_resource.application_insights_connection[0].name == module.application_insights[0].name,
      azapi_resource.application_insights_connection[0].parent_id == module.microsoft_foundry.project_id,
    ])
    error_message = "Tracing must create one Application Insights connection on the Foundry project."
  }

  assert {
    condition = alltrue([
      nonsensitive(azapi_resource.application_insights_connection[0].body.properties.category) == "AppInsights",
      nonsensitive(azapi_resource.application_insights_connection[0].body.properties.target) == module.application_insights[0].id,
      nonsensitive(azapi_resource.application_insights_connection[0].body.properties.authType) == "ProjectManagedIdentity",
      !nonsensitive(azapi_resource.application_insights_connection[0].body.properties.isSharedToAll),
      !contains(nonsensitive(keys(azapi_resource.application_insights_connection[0].body.properties)), "credentials"),
    ])
    error_message = "The Application Insights connection must use project managed identity without credentials."
  }

  assert {
    condition = alltrue([
      nonsensitive(azapi_resource.application_insights_connection[0].body.properties.metadata.ApiType) == "Azure",
      nonsensitive(azapi_resource.application_insights_connection[0].body.properties.metadata.ResourceId) == module.application_insights[0].id,
      nonsensitive(azapi_resource.application_insights_connection[0].body.properties.metadata.ApplicationInsightsConnectionString) == nonsensitive(module.application_insights[0].connection_string),
    ])
    error_message = "The Application Insights connection metadata must identify and route to the tracing resource."
  }

  assert {
    condition = alltrue([
      length(azurerm_role_assignment.monitoring_metrics_publisher) == 1,
      azurerm_role_assignment.monitoring_metrics_publisher[0].scope == module.application_insights[0].id,
      azurerm_role_assignment.monitoring_metrics_publisher[0].role_definition_name == "Monitoring Metrics Publisher",
      azurerm_role_assignment.monitoring_metrics_publisher[0].principal_id == module.microsoft_foundry.project_principal_id,
      azurerm_role_assignment.monitoring_metrics_publisher[0].skip_service_principal_aad_check,
    ])
    error_message = "The Foundry project identity must be authorized to ingest tracing telemetry."
  }

  assert {
    condition = alltrue([
      length(azurerm_role_assignment.operator_log_analytics_reader) == 1,
      azurerm_role_assignment.operator_log_analytics_reader[0].scope == module.application_insights[0].id,
      azurerm_role_assignment.operator_log_analytics_reader[0].role_definition_name == "Log Analytics Reader",
      azurerm_role_assignment.operator_log_analytics_reader[0].principal_id == "00000000-0000-0000-0000-000000000004",
    ])
    error_message = "The scenario operator must be authorized to query tracing telemetry."
  }

  assert {
    condition = alltrue([
      output.log_analytics_workspace_id == module.log_analytics[0].id,
      output.log_analytics_workspace_name == module.log_analytics[0].name,
      output.application_insights_id == module.application_insights[0].id,
      output.application_insights_name == module.application_insights[0].name,
      output.application_insights_app_id == module.application_insights[0].app_id,
      output.application_insights_connection_id == azapi_resource.application_insights_connection[0].id,
    ])
    error_message = "Foundry tracing outputs must match the deployed resources."
  }
}

run "standard_agent_enabled" {
  command = plan

  variables {
    deploy_standard_agent = true
    azure_ai_search_sku   = "standard"
    model_deployments     = []
    operator_principal_id = "00000000-0000-0000-0000-000000000004"
  }

  assert {
    condition = alltrue([
      length(module.azure_ai_search) == 1,
      length(module.blob_storage) == 1,
      length(module.cosmosdb) == 1,
    ])
    error_message = "Standard Agent must deploy Search, Storage, and Cosmos DB together."
  }

  assert {
    condition = alltrue([
      module.azure_ai_search[0].name == "aisearchtest1234",
      module.azure_ai_search[0].identity_principal_id == "00000000-0000-0000-0000-000000000002",
      module.blob_storage[0].account_name == "stmsfoundrytest1234",
      module.blob_storage[0].container_name == null,
      module.cosmosdb[0].account_name == "cosmosmsfoundrytest1234",
      module.cosmosdb[0].sql_database_name == null,
      module.cosmosdb[0].sql_container_name == null,
    ])
    error_message = "Standard Agent data services must use the scenario suffix and must not create a Blob container."
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
      azapi_resource.cosmosdb_connection[0].body.properties.metadata.ResourceId == module.cosmosdb[0].account_id,
    ])
    error_message = "Standard Agent connection metadata must identify each backing resource."
  }

  assert {
    condition = alltrue([
      length(azurerm_role_assignment.storage_blob_data_contributor) == 1,
      length(azurerm_role_assignment.search_index_data_contributor) == 1,
      length(azurerm_role_assignment.search_service_contributor) == 1,
      length(azurerm_role_assignment.search_index_data_reader) == 1,
      length(azurerm_role_assignment.search_storage_blob_data_reader) == 1,
      length(azurerm_role_assignment.search_cognitive_services_user) == 1,
      length(azurerm_role_assignment.project_foundry_user) == 1,
      length(azurerm_role_assignment.operator_storage_blob_data_contributor) == 1,
      length(azurerm_role_assignment.operator_search_index_data_contributor) == 1,
      length(azurerm_role_assignment.operator_search_index_data_reader) == 1,
      length(azurerm_role_assignment.operator_search_service_contributor) == 1,
      length(azurerm_role_assignment.operator_foundry_project_manager) == 1,
      length(azurerm_role_assignment.cosmos_db_operator) == 1,
    ])
    error_message = "Standard Agent must create all required ARM role assignments."
  }

  assert {
    condition = alltrue([
      length(azurerm_role_assignment.operator_cosmos_db_reader) == 0,
      length(azurerm_cosmosdb_sql_role_assignment.operator_cosmos_data_reader) == 0,
    ])
    error_message = "Operator Cosmos DB read access must remain disabled unless explicitly enabled."
  }

  assert {
    condition = alltrue([
      azurerm_role_assignment.storage_blob_data_contributor[0].role_definition_name == "Storage Blob Data Contributor",
      azurerm_role_assignment.search_index_data_contributor[0].role_definition_name == "Search Index Data Contributor",
      azurerm_role_assignment.search_service_contributor[0].role_definition_name == "Search Service Contributor",
      azurerm_role_assignment.search_index_data_reader[0].role_definition_name == "Search Index Data Reader",
      azurerm_role_assignment.search_storage_blob_data_reader[0].role_definition_name == "Storage Blob Data Reader",
      azurerm_role_assignment.search_cognitive_services_user[0].role_definition_name == "Cognitive Services User",
      endswith(azurerm_role_assignment.project_foundry_user[0].role_definition_id, "/53ca6127-db72-4b80-b1b0-d745d6d5456d"),
      azurerm_role_assignment.operator_storage_blob_data_contributor[0].role_definition_name == "Storage Blob Data Contributor",
      azurerm_role_assignment.operator_search_index_data_contributor[0].role_definition_name == "Search Index Data Contributor",
      azurerm_role_assignment.operator_search_index_data_reader[0].role_definition_name == "Search Index Data Reader",
      azurerm_role_assignment.operator_search_service_contributor[0].role_definition_name == "Search Service Contributor",
      endswith(azurerm_role_assignment.operator_foundry_project_manager[0].role_definition_id, "/eadc314b-1a2d-4efa-be10-5d325db5065e"),
      azurerm_role_assignment.cosmos_db_operator[0].role_definition_name == "Cosmos DB Operator",
    ])
    error_message = "Standard Agent must assign the required built-in ARM roles."
  }

  assert {
    condition = alltrue([
      azurerm_role_assignment.storage_blob_data_contributor[0].principal_id == module.microsoft_foundry.project_principal_id,
      azurerm_role_assignment.search_index_data_contributor[0].principal_id == module.microsoft_foundry.project_principal_id,
      azurerm_role_assignment.search_service_contributor[0].principal_id == module.microsoft_foundry.project_principal_id,
      azurerm_role_assignment.search_index_data_reader[0].principal_id == module.microsoft_foundry.project_principal_id,
      azurerm_role_assignment.project_foundry_user[0].principal_id == module.microsoft_foundry.project_principal_id,
      azurerm_role_assignment.search_storage_blob_data_reader[0].principal_id == module.azure_ai_search[0].identity_principal_id,
      azurerm_role_assignment.search_cognitive_services_user[0].principal_id == module.azure_ai_search[0].identity_principal_id,
      azurerm_role_assignment.operator_storage_blob_data_contributor[0].principal_id == "00000000-0000-0000-0000-000000000004",
      azurerm_role_assignment.operator_search_index_data_contributor[0].principal_id == "00000000-0000-0000-0000-000000000004",
      azurerm_role_assignment.operator_search_index_data_reader[0].principal_id == "00000000-0000-0000-0000-000000000004",
      azurerm_role_assignment.operator_search_service_contributor[0].principal_id == "00000000-0000-0000-0000-000000000004",
      azurerm_role_assignment.operator_foundry_project_manager[0].principal_id == "00000000-0000-0000-0000-000000000004",
      azurerm_role_assignment.cosmos_db_operator[0].principal_id == module.microsoft_foundry.project_principal_id,
    ])
    error_message = "Standard Agent roles must be assigned to the intended managed identities and operator."
  }

  assert {
    condition = alltrue([
      azurerm_role_assignment.search_storage_blob_data_reader[0].scope == module.blob_storage[0].account_id,
      azurerm_role_assignment.search_cognitive_services_user[0].scope == module.microsoft_foundry.account_id,
      azurerm_role_assignment.project_foundry_user[0].scope == module.microsoft_foundry.account_id,
      azurerm_role_assignment.operator_foundry_project_manager[0].scope == module.microsoft_foundry.account_id,
    ])
    error_message = "Foundry IQ role assignments must use the intended resource scopes."
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
      azapi_resource.project_capability_host[0].body.properties.threadStorageConnections == [module.cosmosdb[0].account_name],
      !contains(keys(azapi_resource.project_capability_host[0].body.properties), "capabilityHostKind"),
    ])
    error_message = "The project capability host must reference the three Standard Agent connections using the stable schema."
  }

  assert {
    condition = alltrue([
      azurerm_cosmosdb_sql_role_assignment.cosmos_data_contributor[0].role_definition_id == "${module.cosmosdb[0].account_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002",
      azurerm_cosmosdb_sql_role_assignment.cosmos_data_contributor[0].scope == "${module.cosmosdb[0].account_id}/dbs/enterprise_memory",
      azurerm_cosmosdb_sql_role_assignment.cosmos_data_contributor[0].principal_id == module.microsoft_foundry.project_principal_id,
    ])
    error_message = "The Foundry project identity must receive Cosmos DB data-plane access to enterprise_memory."
  }

  assert {
    condition = alltrue([
      output.azure_ai_search_connection_id == azapi_resource.azure_ai_search_connection[0].id,
      output.azure_ai_search_identity_principal_id == module.azure_ai_search[0].identity_principal_id,
      output.blob_storage_connection_id == azapi_resource.blob_storage_connection[0].id,
      output.cosmosdb_connection_id == azapi_resource.cosmosdb_connection[0].id,
      output.account_capability_host_id == azapi_resource.account_capability_host[0].id,
      output.project_capability_host_id == azapi_resource.project_capability_host[0].id,
    ])
    error_message = "Standard Agent outputs must match the created connections and capability hosts."
  }

  assert {
    condition = alltrue([
      output.microsoft_foundry_project_id == module.microsoft_foundry.project_id,
      output.microsoft_foundry_project_endpoint == "https://msfoundrytest1234.services.ai.azure.com/api/projects/msfoundrytest1234project",
      output.microsoft_foundry_openai_endpoint == "https://msfoundrytest1234.openai.azure.com/",
      output.microsoft_foundry_deployment_ids == {},
      output.operator_principal_id == "00000000-0000-0000-0000-000000000004",
    ])
    error_message = "Foundry IQ setup outputs must expose the project, model, and operator values used by scripts."
  }
}

run "operator_cosmosdb_read_access_enabled" {
  command = plan

  variables {
    deploy_standard_agent                = true
    enable_operator_cosmosdb_read_access = true
    model_deployments                    = []
    operator_principal_id                = "00000000-0000-0000-0000-000000000004"
  }

  assert {
    condition = alltrue([
      length(azurerm_role_assignment.operator_cosmos_db_reader) == 1,
      azurerm_role_assignment.operator_cosmos_db_reader[0].role_definition_name == "Reader",
      azurerm_role_assignment.operator_cosmos_db_reader[0].scope == module.cosmosdb[0].account_id,
      azurerm_role_assignment.operator_cosmos_db_reader[0].principal_id == "00000000-0000-0000-0000-000000000004",
    ])
    error_message = "Operator must receive control-plane Reader access at the Cosmos DB account scope when enabled."
  }

  assert {
    condition = alltrue([
      length(azurerm_cosmosdb_sql_role_assignment.operator_cosmos_data_reader) == 1,
      azurerm_cosmosdb_sql_role_assignment.operator_cosmos_data_reader[0].role_definition_id == "${module.cosmosdb[0].account_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000001",
      azurerm_cosmosdb_sql_role_assignment.operator_cosmos_data_reader[0].scope == "${module.cosmosdb[0].account_id}/dbs/enterprise_memory",
      azurerm_cosmosdb_sql_role_assignment.operator_cosmos_data_reader[0].principal_id == "00000000-0000-0000-0000-000000000004",
    ])
    error_message = "Operator must receive read-only Cosmos DB data access scoped to enterprise_memory when enabled."
  }
}

run "operator_cosmosdb_read_access_requires_standard_agent" {
  command = plan

  variables {
    deploy_standard_agent                = false
    enable_operator_cosmosdb_read_access = true
    model_deployments                    = []
  }

  expect_failures = [
    var.enable_operator_cosmosdb_read_access,
  ]
}

run "standard_agent_rejects_free_search_sku" {
  command = plan

  variables {
    deploy_standard_agent = true
    azure_ai_search_sku   = "free"
    model_deployments     = []
    operator_principal_id = "00000000-0000-0000-0000-000000000004"
  }

  expect_failures = [
    var.azure_ai_search_sku,
  ]
}
