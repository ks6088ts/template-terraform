locals {
  project_internal_id_compact = replace(module.microsoft_foundry.project_internal_id == null ? "" : module.microsoft_foundry.project_internal_id, "-", "")
  project_workspace_id = length(local.project_internal_id_compact) == 32 ? join("-", [
    substr(local.project_internal_id_compact, 0, 8),
    substr(local.project_internal_id_compact, 8, 4),
    substr(local.project_internal_id_compact, 12, 4),
    substr(local.project_internal_id_compact, 16, 4),
    substr(local.project_internal_id_compact, 20, 12),
  ]) : local.project_internal_id_compact
  project_blob_data_contributor_condition = <<-EOT
    (
      @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringStartsWithIgnoreCase '${local.project_workspace_id}-'
      AND @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringLikeIgnoreCase '*-azureml-blobstore'
    )
  EOT
  project_blob_data_owner_condition       = <<-EOT
    (
      @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringStartsWithIgnoreCase '${local.project_workspace_id}-'
      AND
      (
        @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringLikeIgnoreCase '*-agents-blobstore'
        OR @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringLikeIgnoreCase '*-azureml-agent'
      )
    )
  EOT
}

resource "azurerm_role_assignment" "storage_account_contributor" {
  count = var.enable_standard_setup ? 1 : 0

  scope                            = module.blob_storage[0].account_id
  role_definition_name             = "Storage Account Contributor"
  principal_id                     = module.microsoft_foundry.project_principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  count = var.enable_standard_setup ? 1 : 0

  scope                            = module.blob_storage[0].account_id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = module.microsoft_foundry.project_principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
  condition_version                = "2.0"
  condition                        = local.project_blob_data_contributor_condition
}

resource "azurerm_role_assignment" "storage_blob_data_owner" {
  count = var.enable_standard_setup ? 1 : 0

  scope                            = module.blob_storage[0].account_id
  role_definition_name             = "Storage Blob Data Owner"
  principal_id                     = module.microsoft_foundry.project_principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
  condition_version                = "2.0"
  condition                        = local.project_blob_data_owner_condition
}

resource "azurerm_role_assignment" "search_index_data_contributor" {
  count = var.enable_standard_setup ? 1 : 0

  scope                            = module.azure_ai_search[0].id
  role_definition_name             = "Search Index Data Contributor"
  principal_id                     = module.microsoft_foundry.project_principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "search_service_contributor" {
  count = var.enable_standard_setup ? 1 : 0

  scope                            = module.azure_ai_search[0].id
  role_definition_name             = "Search Service Contributor"
  principal_id                     = module.microsoft_foundry.project_principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "search_storage_blob_data_reader" {
  count = var.enable_standard_setup ? 1 : 0

  scope                            = module.blob_storage[0].account_id
  role_definition_name             = "Storage Blob Data Reader"
  principal_id                     = module.azure_ai_search[0].identity_principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "search_cognitive_services_user" {
  count = var.enable_standard_setup ? 1 : 0

  scope                            = module.microsoft_foundry.account_id
  role_definition_name             = "Cognitive Services User"
  principal_id                     = module.azure_ai_search[0].identity_principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "project_foundry_user" {
  count = var.enable_standard_setup ? 1 : 0

  scope                            = module.microsoft_foundry.account_id
  role_definition_id               = local.foundry_user_role_definition_id
  principal_id                     = module.microsoft_foundry.project_principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "operator_storage_blob_data_contributor" {
  count = var.enable_standard_setup ? 1 : 0

  scope                = module.blob_storage[0].account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.operator_principal_id
}

resource "azurerm_role_assignment" "operator_search_index_data_contributor" {
  count = var.enable_standard_setup ? 1 : 0

  scope                = module.azure_ai_search[0].id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = local.operator_principal_id
}

resource "azurerm_role_assignment" "operator_search_service_contributor" {
  count = var.enable_standard_setup ? 1 : 0

  scope                = module.azure_ai_search[0].id
  role_definition_name = "Search Service Contributor"
  principal_id         = local.operator_principal_id
}

resource "azurerm_role_assignment" "operator_foundry_user" {
  count = var.enable_standard_setup ? 1 : 0

  scope              = module.microsoft_foundry.account_id
  role_definition_id = local.foundry_user_role_definition_id
  principal_id       = local.operator_principal_id
}

resource "azurerm_role_assignment" "operator_foundry_project_manager" {
  count = var.enable_standard_setup ? 1 : 0

  scope              = module.microsoft_foundry.account_id
  role_definition_id = local.foundry_project_manager_role_definition_id
  principal_id       = local.operator_principal_id
}

resource "azurerm_role_assignment" "operator_cosmos_db_reader" {
  count = var.enable_standard_setup && var.enable_operator_cosmosdb_read_access ? 1 : 0

  scope                = module.cosmosdb[0].account_id
  role_definition_name = "Reader"
  principal_id         = local.operator_principal_id
}

resource "azurerm_role_assignment" "cosmos_db_operator" {
  count = var.enable_standard_setup ? 1 : 0

  scope                            = module.cosmosdb[0].account_id
  role_definition_name             = "Cosmos DB Operator"
  principal_id                     = module.microsoft_foundry.project_principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "monitoring_metrics_publisher" {
  count = var.enable_tracing ? 1 : 0

  scope                            = module.application_insights[0].id
  role_definition_name             = "Monitoring Metrics Publisher"
  principal_id                     = module.microsoft_foundry.project_principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "operator_log_analytics_reader" {
  count = var.enable_tracing ? 1 : 0

  scope                = module.application_insights[0].id
  role_definition_name = "Log Analytics Reader"
  principal_id         = local.operator_principal_id
}

resource "azurerm_cosmosdb_sql_role_assignment" "cosmos_data_contributor" {
  count = var.enable_standard_setup ? 1 : 0

  resource_group_name = module.resource_group.name
  account_name        = module.cosmosdb[0].account_name
  role_definition_id  = "${module.cosmosdb[0].account_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = module.microsoft_foundry.project_principal_id
  scope               = "${module.cosmosdb[0].account_id}/dbs/enterprise_memory"

  depends_on = [
    azapi_resource.project_capability_host,
  ]
}

resource "azurerm_cosmosdb_sql_role_assignment" "operator_cosmos_data_reader" {
  count = var.enable_standard_setup && var.enable_operator_cosmosdb_read_access ? 1 : 0

  resource_group_name = module.resource_group.name
  account_name        = module.cosmosdb[0].account_name
  role_definition_id  = "${module.cosmosdb[0].account_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000001"
  principal_id        = local.operator_principal_id
  scope               = "${module.cosmosdb[0].account_id}/dbs/enterprise_memory"

  depends_on = [
    azapi_resource.project_capability_host,
  ]
}
