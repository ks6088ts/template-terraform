resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  count = var.deploy_standard_agent ? 1 : 0

  scope                = module.blob_storage[0].account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.microsoft_foundry.project_principal_id
}

resource "azurerm_role_assignment" "search_index_data_contributor" {
  count = var.deploy_standard_agent ? 1 : 0

  scope                = module.azure_ai_search[0].id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = module.microsoft_foundry.project_principal_id
}

resource "azurerm_role_assignment" "search_service_contributor" {
  count = var.deploy_standard_agent ? 1 : 0

  scope                = module.azure_ai_search[0].id
  role_definition_name = "Search Service Contributor"
  principal_id         = module.microsoft_foundry.project_principal_id
}

resource "azurerm_role_assignment" "cosmos_db_operator" {
  count = var.deploy_standard_agent ? 1 : 0

  scope                = module.cosmosdb[0].account_id
  role_definition_name = "Cosmos DB Operator"
  principal_id         = module.microsoft_foundry.project_principal_id
}

resource "time_sleep" "wait_for_rbac" {
  count = var.deploy_standard_agent ? 1 : 0

  create_duration = "60s"

  depends_on = [
    azurerm_role_assignment.storage_blob_data_contributor,
    azurerm_role_assignment.search_index_data_contributor,
    azurerm_role_assignment.search_service_contributor,
    azurerm_role_assignment.cosmos_db_operator,
  ]
}

resource "azurerm_cosmosdb_sql_role_assignment" "cosmos_data_contributor" {
  count = var.deploy_standard_agent ? 1 : 0

  resource_group_name = module.resource_group.name
  account_name        = module.cosmosdb[0].account_name
  role_definition_id  = "${module.cosmosdb[0].account_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = module.microsoft_foundry.project_principal_id
  scope               = "${module.cosmosdb[0].account_id}/dbs/enterprise_memory"

  depends_on = [
    azapi_resource.project_capability_host,
  ]
}