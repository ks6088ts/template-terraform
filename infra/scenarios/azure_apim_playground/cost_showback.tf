locals {
  cost_showback_enabled = var.cost_showback != null
  business_units        = local.cost_showback_enabled ? var.cost_showback.business_units : {}

  entra_caller_validation_policy = local.cost_showback_enabled && try(var.cost_showback.entra_id, null) != null ? join("", [
    "<choose>",
    "<when condition=\"@(context.Request.Headers.ContainsKey(&quot;Authorization&quot;))\">",
    "<validate-azure-ad-token tenant-id=\"${var.cost_showback.entra_id.tenant_id}\" header-name=\"Authorization\" failed-validation-httpcode=\"401\" failed-validation-error-message=\"Unauthorized\">",
    "<audiences>",
    join("", [
      for audience in var.cost_showback.entra_id.audiences :
      "<audience>${audience}</audience>"
    ]),
    "</audiences>",
    "</validate-azure-ad-token>",
    "<set-variable name=\"callerJwtValidated\" value=\"@(true)\" />",
    "</when>",
    "</choose>",
  ]) : ""
  caller_attribution_policy = local.cost_showback_enabled ? join("", [
    local.entra_caller_validation_policy,
    "<include-fragment fragment-id=\"playground-caller-attribution\" />",
  ]) : ""
  stream_usage_policy = local.ai_enabled ? (
    "<include-fragment fragment-id=\"playground-ensure-stream-include-usage\" />"
  ) : ""
  caller_metric_policy = local.cost_showback_enabled ? join("", [
    "<emit-metric name=\"caller-requests\" value=\"1\" namespace=\"apim-costing\">",
    "<dimension name=\"CallerId\" value=\"@((string)context.Variables[&quot;callerId&quot;])\" />",
    "<dimension name=\"API\" value=\"@(context.Api.Name)\" />",
    "<dimension name=\"Operation\" value=\"@(context.Operation.Name)\" />",
    "</emit-metric>",
  ]) : ""
  caller_context_policy = local.cost_showback_enabled ? join("", [
    "<set-header name=\"x-business-unit\" exists-action=\"override\">",
    "<value>@((string)context.Variables[&quot;callerId&quot;])</value>",
    "</set-header>",
    "<set-header name=\"x-ms-client-request-id\" exists-action=\"skip\">",
    "<value>@(context.RequestId.ToString())</value>",
    "</set-header>",
  ]) : ""

  workbook_raw             = local.cost_showback_enabled && var.cost_showback.workbook_enabled ? file("${path.module}/workbooks/costing.workbook.json") : null
  workbook_with_app_id     = local.workbook_raw == null ? null : replace(local.workbook_raw, "__APP_INSIGHTS_NAME__", try(module.application_insights[0].app_id, ""))
  workbook_with_sku        = local.workbook_raw == null ? null : replace(local.workbook_with_app_id, "__APIM_SKU__", split("_", var.sku_name)[0])
  workbook_with_base_cost  = local.workbook_raw == null ? null : replace(local.workbook_with_sku, "__BASE_MONTHLY_COST__", tostring(var.cost_showback.base_monthly_cost))
  workbook_with_axis_limit = local.workbook_raw == null ? null : replace(local.workbook_with_base_cost, "987654321.123456", tostring(var.cost_showback.base_monthly_cost))
  workbook_with_request_rate = local.workbook_raw == null ? null : replace(
    local.workbook_with_axis_limit,
    "__PER_K_RATE__",
    tostring(var.cost_showback.per_1000_requests_cost),
  )
  workbook_with_prompt_rate = local.workbook_raw == null ? null : replace(
    local.workbook_with_request_rate,
    "__PROMPT_TOKEN_RATE__",
    tostring(var.cost_showback.prompt_per_1000_tokens_cost),
  )
  workbook_json = local.workbook_raw == null ? null : replace(
    local.workbook_with_prompt_rate,
    "__COMPLETION_TOKEN_RATE__",
    tostring(var.cost_showback.completion_per_1000_tokens_cost),
  )
}

resource "azurerm_api_management_policy_fragment" "caller_attribution" {
  count = local.cost_showback_enabled ? 1 : 0

  name              = "playground-caller-attribution"
  api_management_id = module.api_management.id
  description       = "Extracts a validated JWT appid or azp claim with APIM subscription fallback"
  format            = "rawxml"
  value             = file("${path.module}/policies/caller-attribution.xml")
}

resource "azurerm_api_management_policy_fragment" "stream_usage" {
  count = local.ai_enabled ? 1 : 0

  name              = "playground-ensure-stream-include-usage"
  api_management_id = module.api_management.id
  description       = "Ensures streaming chat completions include token usage without modifying Responses API requests"
  format            = "rawxml"
  value             = file("${path.module}/policies/ensure-stream-include-usage.xml")
}

resource "random_password" "business_unit_primary_key" {
  for_each = local.business_units

  length  = 32
  special = false
}

resource "random_password" "business_unit_secondary_key" {
  for_each = local.business_units

  length  = 32
  special = false
}

resource "azurerm_api_management_subscription" "business_unit" {
  for_each = local.business_units

  subscription_id     = each.key
  resource_group_name = module.resource_group.name
  api_management_name = module.api_management.name
  product_id          = azurerm_api_management_product.playground.id
  display_name        = each.value
  primary_key         = random_password.business_unit_primary_key[each.key].result
  secondary_key       = random_password.business_unit_secondary_key[each.key].result
  state               = "active"
}

resource "azapi_resource" "cost_workbook" {
  count = local.cost_showback_enabled && var.cost_showback.workbook_enabled ? 1 : 0

  type      = "Microsoft.Insights/workbooks@2023-06-01"
  name      = uuidv5("url", "${module.resource_group.id}/apim-cost-showback")
  parent_id = module.resource_group.id
  location  = module.resource_group.location

  body = {
    kind = "shared"
    properties = {
      displayName    = "APIM Cost Allocation and Showback"
      serializedData = local.workbook_json
      version        = "1.0"
      sourceId       = try(module.log_analytics[0].id, "")
      category       = "APIM"
    }
  }

  schema_validation_enabled = false
}

resource "azurerm_storage_account" "cost_export" {
  count = local.cost_showback_enabled && var.cost_showback.cost_export != null ? 1 : 0

  name                            = "stapim${local.resource_suffix}"
  resource_group_name             = module.resource_group.name
  location                        = module.resource_group.location
  account_tier                    = "Standard"
  account_replication_type        = var.cost_showback.cost_export.storage_replication_type
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  tags                            = var.tags
}

resource "azapi_resource" "cost_export_container" {
  count = local.cost_showback_enabled && var.cost_showback.cost_export != null ? 1 : 0

  type      = "Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01"
  name      = "cost-exports"
  parent_id = "${azurerm_storage_account.cost_export[0].id}/blobServices/default"

  body = {
    properties = {
      publicAccess = "None"
    }
  }
}

resource "azapi_resource" "cost_export" {
  count = local.cost_showback_enabled && var.cost_showback.cost_export != null ? 1 : 0

  type      = "Microsoft.CostManagement/exports@2023-11-01"
  name      = "apim-cost-export"
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"

  body = {
    properties = {
      definition = {
        type      = "ActualCost"
        timeframe = "MonthToDate"
        dataSet = {
          granularity = "Daily"
        }
      }
      deliveryInfo = {
        destination = {
          resourceId     = azurerm_storage_account.cost_export[0].id
          container      = azapi_resource.cost_export_container[0].name
          rootFolderPath = var.cost_showback.cost_export.root_folder_path
        }
      }
      format = "Csv"
      schedule = {
        status     = "Active"
        recurrence = var.cost_showback.cost_export.recurrence
        recurrencePeriod = {
          from = var.cost_showback.cost_export.start_date
          to   = "2099-12-31T00:00:00Z"
        }
      }
    }
  }

  schema_validation_enabled = false
}

resource "azurerm_monitor_action_group" "request_threshold" {
  count = local.cost_showback_enabled && var.cost_showback.request_alerts != null ? 1 : 0

  name                = "ag-apim-request-threshold"
  resource_group_name = module.resource_group.name
  short_name          = "apimreq"
  tags                = var.tags

  email_receiver {
    name                    = "apim-request-threshold"
    email_address           = var.cost_showback.request_alerts.email_address
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "request_threshold" {
  for_each = local.cost_showback_enabled && var.cost_showback.request_alerts != null ? local.business_units : {}

  name                 = "apim-request-threshold-${each.key}"
  resource_group_name  = module.resource_group.name
  location             = module.resource_group.location
  description          = "Fires when ${each.value} exceeds the configured APIM request threshold"
  enabled              = true
  severity             = 2
  scopes               = [module.log_analytics[0].id]
  evaluation_frequency = var.cost_showback.request_alerts.evaluation_frequency
  window_duration      = var.cost_showback.request_alerts.window_duration
  tags                 = var.tags

  criteria {
    query = <<-KQL
      ApiManagementGatewayLogs
      | where ApimSubscriptionId == "${each.key}"
      | summarize RequestCount = count()
      | where RequestCount > ${var.cost_showback.request_alerts.request_threshold}
    KQL

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.request_threshold[0].id]
  }
}
