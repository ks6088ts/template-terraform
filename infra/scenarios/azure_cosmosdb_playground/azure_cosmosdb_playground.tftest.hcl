mock_provider "azurerm" {
  override_during = plan

  mock_data "azurerm_client_config" {
    defaults = {
      object_id = "00000000-0000-0000-0000-000000000005"
    }
  }

  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-azurecosmosdbplayground-test1234"
    }
  }

  mock_resource "azurerm_cosmosdb_account" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-azurecosmosdbplayground-test1234/providers/Microsoft.DocumentDB/databaseAccounts/cosmos-azurecosmosdbplayground-test1234"
      endpoint = "https://cosmos-azurecosmosdbplayground-test1234.documents.azure.com:443/"
    }
  }

  mock_resource "azurerm_cosmosdb_sql_database" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-azurecosmosdbplayground-test1234/providers/Microsoft.DocumentDB/databaseAccounts/cosmos-azurecosmosdbplayground-test1234/sqlDatabases/playground"
    }
  }
}

mock_provider "azapi" {
  override_during = plan

  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-azurecosmosdbplayground-test1234/providers/Microsoft.CognitiveServices/accounts/azurecosmosdbplayground-test1234"
      output = {
        identity = {
          principalId = "00000000-0000-0000-0000-000000000006"
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

run "default_playground" {
  command = plan

  assert {
    condition = alltrue([
      module.resource_group.name == "rg-azurecosmosdbplayground-test1234",
      module.resource_group.location == "eastus2",
      module.cosmosdb.account_name == "cosmos-azurecosmosdbplayground-test1234",
      module.cosmosdb.sql_container_id == null,
      module.microsoft_foundry.account_name == "azurecosmosdbplayground-test1234",
      length(module.microsoft_foundry.deployment_ids) == 2,
      output.cosmos_database_name == module.cosmosdb.sql_database_name,
    ])
    error_message = "Default resources must be public, keyless, single-region serverless NoSQL and two keyless Foundry deployments."
  }

  assert {
    condition = alltrue([
      length(var.tags) == 4,
      var.tags["scenario"] == "azure_cosmosdb_playground",
      var.tags["owner"] == "ks6088ts",
      var.tags["SecurityControl"] == "Ignore",
      var.tags["CostControl"] == "Ignore",
    ])
    error_message = "Default resources must use the standard scenario, owner, security, and cost-control tags."
  }

  assert {
    condition = alltrue([
      azapi_resource.documents.parent_id == module.cosmosdb.sql_database_id,
      azapi_resource.documents.body.properties.resource.partitionKey.paths[0] == "/tenantId",
      azapi_resource.documents.body.properties.resource.defaultTtl == -1,
      azapi_resource.documents.body.properties.resource.vectorEmbeddingPolicy.vectorEmbeddings[0].dimensions == 256,
      azapi_resource.documents.body.properties.resource.indexingPolicy.vectorIndexes[0].type == "flat",
      azapi_resource.documents.body.properties.resource.fullTextPolicy.defaultLanguage == "en-US",
      azapi_resource.documents.body.properties.resource.indexingPolicy.fullTextIndexes[0].path == "/content",
    ])
    error_message = "The container must declare partition, TTL, vector, and full-text policies at creation."
  }

  assert {
    condition = alltrue([
      azurerm_cosmosdb_sql_role_assignment.operator.principal_id == "00000000-0000-0000-0000-000000000005",
      endswith(azurerm_cosmosdb_sql_role_assignment.operator.role_definition_id, "/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"),
      azurerm_cosmosdb_sql_role_assignment.operator.scope == "${module.cosmosdb.account_id}/dbs/playground",
      azurerm_role_assignment.operator_foundry.role_definition_name == "Cognitive Services OpenAI User",
      output.cosmos_endpoint == module.cosmosdb.account_endpoint,
      output.foundry_endpoint == module.microsoft_foundry.openai_endpoint,
      output.embedding_deployment_name == "text-embedding-3-small",
      output.chat_deployment_name == "gpt-5.4-mini",
    ])
    error_message = "Operator roles and nonsecret lab outputs must be wired to their resources."
  }
}

run "custom_operator_and_dimensions" {
  command = plan

  variables {
    name                  = "customplayground"
    operator_principal_id = "00000000-0000-0000-0000-000000000007"
    vector_dimensions     = 128
  }

  assert {
    condition = alltrue([
      module.resource_group.name == "rg-customplayground-test1234",
      module.cosmosdb.account_name == "cosmos-customplayground-test1234",
      module.microsoft_foundry.account_name == "customplayground-test1234",
      azurerm_cosmosdb_sql_role_assignment.operator.principal_id == var.operator_principal_id,
      azurerm_role_assignment.operator_foundry.principal_id == var.operator_principal_id,
      azapi_resource.documents.body.properties.resource.vectorEmbeddingPolicy.vectorEmbeddings[0].dimensions == 128,
      output.vector_dimensions == 128,
    ])
    error_message = "Custom name, operator, and vector dimensions must propagate to resources and outputs."
  }
}

run "reject_oversized_flat_index" {
  command = plan

  variables {
    vector_dimensions = 506
  }

  expect_failures = [var.vector_dimensions]
}

run "reject_invalid_capacity" {
  command = plan

  variables {
    embedding_model = {
      name     = "text-embedding-3-small"
      model    = "text-embedding-3-small"
      version  = "1"
      sku_name = "GlobalStandard"
      capacity = 0
    }
  }

  expect_failures = [var.embedding_model]
}

run "reject_duplicate_deployments" {
  command = plan

  variables {
    chat_model = {
      name     = "text-embedding-3-small"
      model    = "gpt-5.4-mini"
      version  = "2026-03-17"
      sku_name = "GlobalStandard"
      capacity = 100
    }
  }

  expect_failures = [var.chat_model]
}
