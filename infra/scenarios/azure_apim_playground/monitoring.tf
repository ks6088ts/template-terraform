locals {
  observability_enabled = var.observability != null
  llm_logging_enabled   = try(var.observability.llm_logging, null) != null
  token_metrics_enabled = var.llm_token_metrics != null

  llm_token_metric_policy = var.llm_token_metrics == null ? "" : format(
    "<llm-emit-token-metric namespace=\"%s\">%s</llm-emit-token-metric>",
    var.llm_token_metrics.namespace,
    join("", [
      for dimension in var.llm_token_metrics.dimensions :
      "<dimension name=\"${dimension}\" />"
    ]),
  )
}

module "log_analytics" {
  count  = local.observability_enabled ? 1 : 0
  source = "../../modules/azure/log_analytics"

  name                = local.resource_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  retention_in_days   = var.observability.retention_in_days
  tags                = var.tags
}

module "application_insights" {
  count  = local.observability_enabled ? 1 : 0
  source = "../../modules/azure/application_insights"

  name                         = local.resource_name
  resource_group_name          = module.resource_group.name
  location                     = module.resource_group.location
  workspace_id                 = module.log_analytics[0].id
  sampling_percentage          = var.observability.sampling_percentage
  local_authentication_enabled = false
  tags                         = var.tags
}

resource "azapi_update_resource" "application_insights_custom_metrics" {
  count = local.token_metrics_enabled && local.observability_enabled ? 1 : 0

  type        = "Microsoft.Insights/components@2020-02-02"
  resource_id = module.application_insights[0].id

  body = {
    properties = {
      CustomMetricsOptedInType = "WithDimensions"
    }
  }
}

resource "azurerm_role_assignment" "apim_monitoring_metrics_publisher" {
  count = local.observability_enabled ? 1 : 0

  scope                            = module.application_insights[0].id
  role_definition_name             = "Monitoring Metrics Publisher"
  principal_id                     = module.api_management.identity_principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_api_management_logger" "application_insights" {
  count = local.observability_enabled ? 1 : 0

  name                = "playground-application-insights"
  api_management_name = module.api_management.name
  resource_group_name = module.resource_group.name
  resource_id         = module.application_insights[0].id
  description         = "Application Insights logger authenticated with the API Management managed identity"

  application_insights {
    connection_string  = module.application_insights[0].connection_string
    identity_client_id = "systemAssigned"
  }

  depends_on = [azurerm_role_assignment.apim_monitoring_metrics_publisher]
}

resource "azapi_resource" "application_insights_diagnostic" {
  count = local.observability_enabled ? 1 : 0

  type      = "Microsoft.ApiManagement/service/diagnostics@2024-06-01-preview"
  name      = "applicationinsights"
  parent_id = module.api_management.id

  body = {
    properties = {
      alwaysLog               = "allErrors"
      httpCorrelationProtocol = "W3C"
      logClientIp             = var.observability.log_client_ip
      loggerId                = azurerm_api_management_logger.application_insights[0].id
      metrics                 = local.token_metrics_enabled
      sampling = {
        percentage   = var.observability.sampling_percentage
        samplingType = "fixed"
      }
      verbosity = var.observability.verbosity
      frontend = {
        request  = { body = { bytes = 0 } }
        response = { body = { bytes = 0 } }
      }
      backend = {
        request  = { body = { bytes = 0 } }
        response = { body = { bytes = 0 } }
      }
    }
  }

  schema_validation_enabled = false

  depends_on = [azapi_update_resource.application_insights_custom_metrics]
}

resource "azurerm_monitor_diagnostic_setting" "api_management" {
  count = local.observability_enabled ? 1 : 0

  name                           = "apim-observability"
  target_resource_id             = module.api_management.id
  log_analytics_workspace_id     = module.log_analytics[0].id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azapi_resource" "ai_llm_diagnostic" {
  count = local.llm_logging_enabled && local.ai_enabled ? 1 : 0

  type      = "Microsoft.ApiManagement/service/apis/diagnostics@2024-06-01-preview"
  name      = "azuremonitor"
  parent_id = azurerm_api_management_api.ai[0].id

  body = {
    properties = {
      alwaysLog               = "allErrors"
      httpCorrelationProtocol = "W3C"
      logClientIp             = var.observability.log_client_ip
      loggerId                = "${module.api_management.id}/loggers/azuremonitor"
      sampling = {
        percentage   = var.observability.sampling_percentage
        samplingType = "fixed"
      }
      verbosity = var.observability.verbosity
      largeLanguageModel = merge(
        { logs = "enabled" },
        var.observability.llm_logging.log_prompts ? {
          requests = {
            maxSizeInBytes = var.observability.llm_logging.max_message_size_in_bytes
            messages       = "all"
          }
        } : {},
        var.observability.llm_logging.log_completions ? {
          responses = {
            maxSizeInBytes = var.observability.llm_logging.max_message_size_in_bytes
            messages       = "all"
          }
        } : {},
      )
    }
  }

  schema_validation_enabled = false

  depends_on = [azurerm_monitor_diagnostic_setting.api_management]
}
