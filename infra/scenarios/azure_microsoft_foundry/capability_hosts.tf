locals {
  capability_host_retry = {
    error_message_regex = [
      "(?i)(AuthorizationFailed|Forbidden|does not have authorization)",
      "(?i)(PrincipalNotFound|RoleAssignment[^\\n]*(not found|does not exist))",
      "(?i)(AnotherOperationInProgress|OperationPreempted|resource[^\\n]*not ready)",
    ]
    interval_seconds     = 10
    max_interval_seconds = 60
  }
}

resource "azapi_resource" "account_capability_host" {
  count = var.enable_standard_setup ? 1 : 0

  type                      = "Microsoft.CognitiveServices/accounts/capabilityHosts@2026-07-01"
  name                      = "${local.microsoft_foundry_name}-capHost"
  parent_id                 = module.microsoft_foundry.account_id
  schema_validation_enabled = false

  body = {
    properties = {
      capabilityHostKind = "Agents"
    }
  }

  replace_triggers_refs = [
    "body.properties",
  ]
  retry = local.capability_host_retry

  timeouts {
    create = "30m"
  }
}

resource "azapi_resource" "project_capability_host" {
  count = var.enable_standard_setup ? 1 : 0

  type                      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2026-07-01"
  name                      = "${module.microsoft_foundry.project_name}-capHost"
  parent_id                 = module.microsoft_foundry.project_id
  schema_validation_enabled = false

  body = {
    properties = {
      storageConnections       = [module.blob_storage[0].account_name]
      vectorStoreConnections   = [module.azure_ai_search[0].name]
      threadStorageConnections = [module.cosmosdb[0].account_name]
    }
  }

  replace_triggers_refs = [
    "body.properties",
  ]
  retry = local.capability_host_retry

  timeouts {
    create = "30m"
  }

  lifecycle {
    precondition {
      condition     = length(local.project_internal_id_compact) == 32
      error_message = "The Foundry project response must expose a 32-character internal ID for project-scoped Storage authorization."
    }
  }

  depends_on = [
    azapi_resource.account_capability_host,
    azapi_resource.azure_ai_search_connection,
    azapi_resource.blob_storage_connection,
    azapi_resource.cosmosdb_connection,
    azurerm_role_assignment.cosmos_db_operator,
    azurerm_role_assignment.project_foundry_user,
    azurerm_role_assignment.search_index_data_contributor,
    azurerm_role_assignment.search_service_contributor,
    azurerm_role_assignment.storage_account_contributor,
    azurerm_role_assignment.storage_blob_data_contributor,
    azurerm_role_assignment.storage_blob_data_owner,
  ]
}
