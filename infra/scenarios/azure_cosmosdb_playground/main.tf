module "random_string" {
  source      = "../../modules/common/random_string"
  length      = 8
  min_numeric = 0
  numeric     = true
  special     = false
  lower       = true
  upper       = false
}

locals {
  suffix                = module.random_string.result
  operator_principal_id = coalesce(var.operator_principal_id, data.azurerm_client_config.current.object_id)
  database_name         = "playground"
  container_name        = "documents"
}

data "azurerm_client_config" "current" {}

module "resource_group" {
  source   = "../../modules/azure/resource_group"
  name     = "${var.name}-${local.suffix}"
  location = var.location
  tags     = var.tags
}

module "cosmosdb" {
  source                       = "../../modules/azure/cosmosdb"
  name                         = local.suffix
  account_name                 = "cosmosplay${local.suffix}"
  resource_group_name          = module.resource_group.name
  location                     = module.resource_group.location
  tags                         = var.tags
  capabilities                 = ["EnableServerless", "EnableNoSQLVectorSearch"]
  consistency_level            = "Session"
  local_authentication_enabled = false
  create_sql_container         = false
  sql_database_name            = local.database_name
}

module "microsoft_foundry" {
  source             = "../../modules/azure/microsoft_foundry"
  name               = "foundryplay${local.suffix}"
  resource_group_id  = module.resource_group.id
  location           = module.resource_group.location
  tags               = var.tags
  disable_local_auth = true
  model_deployments = [
    merge(var.embedding_model, { format = "OpenAI" }),
    merge(var.chat_model, { format = "OpenAI" }),
  ]
}

resource "azapi_resource" "documents" {
  type      = "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2026-03-15"
  name      = local.container_name
  parent_id = module.cosmosdb.sql_database_id

  body = {
    properties = {
      resource = {
        id         = local.container_name
        defaultTtl = -1
        partitionKey = {
          paths   = ["/tenantId"]
          kind    = "Hash"
          version = 2
        }
        vectorEmbeddingPolicy = {
          vectorEmbeddings = [{
            path         = "/embedding"
            dataType     = "float32"
            dimensions   = var.vector_dimensions
            distanceFunction = "cosine"
          }]
        }
        fullTextPolicy = {
          defaultLanguage = "en-US"
          fullTextPaths = [{
            path     = "/content"
            language = "en-US"
          }]
        }
        indexingPolicy = {
          indexingMode = "consistent"
          includedPaths = [{
            path = "/*"
          }]
          excludedPaths = [{
            path = "/\"_etag\"/?"
          }]
          vectorIndexes = [{
            path = "/embedding"
            type = "flat"
          }]
          fullTextIndexes = [{
            path = "/content"
          }]
        }
      }
    }
  }
}

resource "azurerm_cosmosdb_sql_role_assignment" "operator" {
  resource_group_name = module.resource_group.name
  account_name        = module.cosmosdb.account_name
  principal_id        = local.operator_principal_id
  role_definition_id  = "${module.cosmosdb.account_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  scope               = "${module.cosmosdb.account_id}/dbs/${local.database_name}"
}

resource "azurerm_role_assignment" "operator_foundry" {
  scope                = module.microsoft_foundry.account_id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = local.operator_principal_id
}
