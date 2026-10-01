mock_provider "azurerm" {
  override_during = plan

  mock_data "azurerm_client_config" {
    defaults = {
      client_id       = "00000000-0000-0000-0000-000000000001"
      object_id       = "00000000-0000-0000-0000-000000000002"
      subscription_id = "00000000-0000-0000-0000-000000000003"
      tenant_id       = "00000000-0000-0000-0000-000000000004"
    }
  }

  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-observability-test1234"
    }
  }

  mock_resource "azurerm_monitor_workspace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-observability-test1234/providers/Microsoft.Monitor/accounts/amw-observability-test1234"
    }
  }

  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-observability-test1234/providers/Microsoft.OperationalInsights/workspaces/law-observability-test1234"
      workspace_id = "00000000-0000-0000-0000-000000000005"
    }
  }

  mock_resource "azurerm_application_insights" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-observability-test1234/providers/Microsoft.Insights/components/appi-observability-test1234"
    }
  }

  mock_data "azurerm_network_watcher" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/NetworkWatcherRG/providers/Microsoft.Network/networkWatchers/NetworkWatcher_japaneast"
    }
  }

  mock_resource "azurerm_network_watcher" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-observability-test1234/providers/Microsoft.Network/networkWatchers/nw-observability-test1234"
    }
  }

  mock_resource "azurerm_monitor_diagnostic_setting" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003|activity-observability-test1234"
    }
  }

  mock_resource "azurerm_monitor_action_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-observability-test1234/providers/Microsoft.Insights/actionGroups/ag-observability-test1234"
    }
  }

  mock_resource "azurerm_monitor_activity_log_alert" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-observability-test1234/providers/Microsoft.Insights/activityLogAlerts/alert-observability-test1234"
    }
  }

  mock_resource "azurerm_application_insights_workbook" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-observability-test1234/providers/Microsoft.Insights/workbooks/00000000-0000-0000-0000-000000000006"
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

run "resource_group_only_by_default" {
  command = plan

  assert {
    condition = alltrue([
      output.resource_group_name == "rg-observability-test1234",
      output.resource_group_id == "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-observability-test1234",
      module.resource_group.location == "japaneast",
      length(var.tags) == 0,
      alltrue([for enabled in var.features : !enabled]),
      length(module.azure_monitor) == 0,
      length(module.log_analytics) == 0,
      length(module.application_insights) == 0,
      length(module.network_watcher) == 0,
      length(module.activity_log) == 0,
      length(module.action_group) == 0,
      length(module.alert_rule) == 0,
      length(module.workbook) == 0,
    ])
    error_message = "The default deployment must contain only the resource group and shared naming/identity helpers."
  }

  assert {
    condition = alltrue([
      output.azure_monitor_id == null,
      output.azure_monitor_name == null,
      output.log_analytics_id == null,
      output.log_analytics_name == null,
      output.log_analytics_workspace_id == null,
      output.application_insights_id == null,
      output.application_insights_name == null,
      output.network_watcher_id == null,
      output.network_watcher_name == null,
      output.network_watcher_created == null,
      output.activity_log_id == null,
      output.activity_log_name == null,
      output.action_group_id == null,
      output.action_group_name == null,
      output.alert_rule_id == null,
      output.alert_rule_name == null,
      output.workbook_id == null,
      output.workbook_name == null,
      local.workbook_data_json == null,
    ])
    error_message = "Every disabled feature must return null, including Network Watcher ownership."
  }
}

run "azure_monitor_independent" {
  command = plan

  variables {
    features = { azure_monitor = true }
  }

  assert {
    condition = alltrue([
      length(module.azure_monitor) == 1,
      output.azure_monitor_name == "amw-observability-test1234",
      output.azure_monitor_id == module.azure_monitor[0].id,
      length(module.log_analytics) == 0,
      length(module.application_insights) == 0,
      length(module.network_watcher) == 0,
      length(module.activity_log) == 0,
      length(module.action_group) == 0,
      length(module.alert_rule) == 0,
      length(module.workbook) == 0,
    ])
    error_message = "Azure Monitor workspace must not implicitly enable other services or collection."
  }
}

run "log_analytics_independent" {
  command = plan

  variables {
    features = { log_analytics = true }
  }

  assert {
    condition = alltrue([
      length(module.log_analytics) == 1,
      output.log_analytics_name == "law-observability-test1234",
      output.log_analytics_id == module.log_analytics[0].id,
      output.log_analytics_workspace_id == "00000000-0000-0000-0000-000000000005",
      output.log_analytics_workspace_id != output.log_analytics_id,
      length(module.azure_monitor) == 0,
      length(module.application_insights) == 0,
      length(module.network_watcher) == 0,
      length(module.activity_log) == 0,
      length(module.action_group) == 0,
      length(module.alert_rule) == 0,
      length(module.workbook) == 0,
    ])
    error_message = "Log Analytics must expose its ARM ID and workspace GUID without enabling dependents."
  }
}

run "application_insights_with_workspace" {
  command = plan

  variables {
    features = {
      log_analytics        = true
      application_insights = true
    }
  }

  assert {
    condition = alltrue([
      length(module.log_analytics) == 1,
      length(module.application_insights) == 1,
      output.application_insights_id == module.application_insights[0].id,
      output.application_insights_name == "appi-observability-test1234",
      length(module.azure_monitor) == 0,
      length(module.network_watcher) == 0,
      length(module.activity_log) == 0,
      length(module.action_group) == 0,
      length(module.alert_rule) == 0,
      length(module.workbook) == 0,
    ])
    error_message = "Application Insights must compose only with the explicitly enabled workspace."
  }
}

run "network_watcher_existing_by_default" {
  command = plan

  variables {
    features = { network_watcher = true }
  }

  assert {
    condition = alltrue([
      length(module.network_watcher) == 1,
      output.network_watcher_name == "NetworkWatcher_japaneast",
      output.network_watcher_id == "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/NetworkWatcherRG/providers/Microsoft.Network/networkWatchers/NetworkWatcher_japaneast",
      output.network_watcher_created == false,
      local.network_watcher_resource_group == "NetworkWatcherRG",
      length(module.azure_monitor) == 0,
      length(module.log_analytics) == 0,
      length(module.application_insights) == 0,
      length(module.activity_log) == 0,
      length(module.action_group) == 0,
      length(module.alert_rule) == 0,
      length(module.workbook) == 0,
    ])
    error_message = "Network Watcher must default to a non-owned regional lookup without creating other features."
  }
}

run "activity_log_with_workspace" {
  command = plan

  variables {
    features = {
      log_analytics = true
      activity_log  = true
    }
  }

  assert {
    condition = alltrue([
      length(module.log_analytics) == 1,
      length(module.activity_log) == 1,
      output.activity_log_id == module.activity_log[0].id,
      output.activity_log_name == "activity-observability-test1234",
      length(module.azure_monitor) == 0,
      length(module.application_insights) == 0,
      length(module.network_watcher) == 0,
      length(module.action_group) == 0,
      length(module.alert_rule) == 0,
      length(module.workbook) == 0,
    ])
    error_message = "Activity Log export must only require the explicitly enabled Log Analytics workspace."
  }
}

run "action_group_independent" {
  command = plan

  variables {
    features = { action_group = true }
  }

  assert {
    condition = alltrue([
      length(module.action_group) == 1,
      output.action_group_id == module.action_group[0].id,
      output.action_group_name == "ag-observability-test1234",
      length(var.action_group_email_addresses) == 0,
      length(module.azure_monitor) == 0,
      length(module.log_analytics) == 0,
      length(module.application_insights) == 0,
      length(module.network_watcher) == 0,
      length(module.activity_log) == 0,
      length(module.alert_rule) == 0,
      length(module.workbook) == 0,
    ])
    error_message = "An Action Group must be usable alone with no notification recipients by default."
  }
}

run "alert_rule_with_action_group" {
  command = plan

  variables {
    features = {
      action_group = true
      alert_rules  = true
    }
  }

  assert {
    condition = alltrue([
      length(module.action_group) == 1,
      length(module.alert_rule) == 1,
      output.alert_rule_id == module.alert_rule[0].id,
      output.alert_rule_name == "alert-observability-test1234",
      length(module.azure_monitor) == 0,
      length(module.log_analytics) == 0,
      length(module.application_insights) == 0,
      length(module.network_watcher) == 0,
      length(module.activity_log) == 0,
      length(module.workbook) == 0,
    ])
    error_message = "Native Activity Log alerts must not require exported logs or a workspace."
  }
}

run "workbook_with_workspace_without_export" {
  command = plan

  variables {
    features = {
      log_analytics = true
      workbook      = true
    }
  }

  assert {
    condition = alltrue([
      length(module.log_analytics) == 1,
      length(module.workbook) == 1,
      output.workbook_id == module.workbook[0].id,
      output.workbook_name == uuidv5("url", "${output.resource_group_id}/observability-workbook"),
      length(module.azure_monitor) == 0,
      length(module.application_insights) == 0,
      length(module.network_watcher) == 0,
      length(module.activity_log) == 0,
      length(module.action_group) == 0,
      length(module.alert_rule) == 0,
    ])
    error_message = "A Workbook requires a workspace but must not implicitly enable ingestion or alerts."
  }

  assert {
    condition = alltrue([
      jsondecode(local.workbook_data_json).version == "Notebook/1.0",
      jsondecode(local.workbook_data_json).fallbackResourceIds[0] == output.log_analytics_id,
      length(jsondecode(local.workbook_data_json).items) == 4,
      alltrue([
        for item in jsondecode(local.workbook_data_json).items : alltrue([
          item.content.crossComponentResources[0] == output.log_analytics_id,
          strcontains(item.content.query, "AzureActivity"),
          strcontains(item.content.query, "where TimeGenerated > ago(24h)"),
        ]) if item.type == 3
      ]),
      strcontains(jsondecode(local.workbook_data_json).items[3].content.query, "top 100 by TimeGenerated desc"),
    ])
    error_message = "Workbook JSON must target the workspace and bound all AzureActivity queries to 24 hours with at most 100 recent events."
  }
}

run "all_features_enabled_economical_defaults" {
  command = plan

  variables {
    features = {
      azure_monitor        = true
      log_analytics        = true
      application_insights = true
      network_watcher      = true
      activity_log         = true
      alert_rules          = true
      action_group         = true
      workbook             = true
    }
  }

  assert {
    condition = alltrue([
      length(module.azure_monitor) == 1,
      length(module.log_analytics) == 1,
      length(module.application_insights) == 1,
      length(module.network_watcher) == 1,
      length(module.activity_log) == 1,
      length(module.action_group) == 1,
      length(module.alert_rule) == 1,
      length(module.workbook) == 1,
      output.azure_monitor_id != null,
      output.log_analytics_id != null,
      output.application_insights_id != null,
      output.network_watcher_id != null,
      output.activity_log_id != null,
      output.action_group_id != null,
      output.alert_rule_id != null,
      output.workbook_id != null,
    ])
    error_message = "All eight flags must create exactly one module instance and expose each resource ID."
  }

  assert {
    condition = alltrue([
      var.log_analytics_sku == "PerGB2018",
      var.log_analytics_retention_in_days == 30,
      var.log_analytics_daily_quota_gb == 0.5,
      var.application_insights_sampling_percentage == 25,
      var.activity_log_categories == toset(["Administrative", "Security", "ServiceHealth", "Alert", "Recommendation", "Policy", "Autoscale", "ResourceHealth"]),
      length(var.action_group_email_addresses) == 0,
      output.network_watcher_created == false,
    ])
    error_message = "All-enabled must retain economical ingestion/retention/sampling defaults and reuse Network Watcher."
  }
}

run "custom_settings" {
  command = plan

  variables {
    name     = "custom"
    location = "westus2"
    tags     = { environment = "test" }
    features = {
      log_analytics        = true
      application_insights = true
      activity_log         = true
      action_group         = true
      alert_rules          = true
      workbook             = true
    }
    log_analytics_sku                        = "PerGB2018"
    log_analytics_retention_in_days          = 60
    log_analytics_daily_quota_gb             = 1
    application_insights_sampling_percentage = 10
    activity_log_categories                  = ["Administrative", "Security"]
    action_group_email_addresses             = ["operator@example.com", "backup@example.com"]
  }

  assert {
    condition = alltrue([
      output.resource_group_name == "rg-custom-test1234",
      module.resource_group.location == "westus2",
      output.log_analytics_name == "law-custom-test1234",
      output.application_insights_name == "appi-custom-test1234",
      output.activity_log_name == "activity-custom-test1234",
      output.action_group_name == "ag-custom-test1234",
      output.alert_rule_name == "alert-custom-test1234",
      var.tags == tomap({ environment = "test" }),
      var.log_analytics_retention_in_days == 60,
      var.log_analytics_daily_quota_gb == 1,
      var.application_insights_sampling_percentage == 10,
      var.activity_log_categories == toset(["Administrative", "Security"]),
      var.action_group_email_addresses == toset(["operator@example.com", "backup@example.com"]),
    ])
    error_message = "Custom names, location, tags, ingestion controls, categories, and recipients must remain configurable."
  }
}

run "network_watcher_create" {
  command = plan

  variables {
    features        = { network_watcher = true }
    network_watcher = { create = true }
  }

  assert {
    condition = alltrue([
      output.network_watcher_created,
      output.network_watcher_name == "nw-observability-test1234",
      local.network_watcher_resource_group == output.resource_group_name,
      output.network_watcher_id == "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-observability-test1234/providers/Microsoft.Network/networkWatchers/nw-observability-test1234",
    ])
    error_message = "Explicit create mode must own a newly named Network Watcher in the scenario resource group."
  }
}

run "network_watcher_existing_custom" {
  command = plan

  variables {
    features = { network_watcher = true }
    network_watcher = {
      name                = "shared-watcher"
      resource_group_name = "shared-network"
    }
  }

  assert {
    condition = alltrue([
      !output.network_watcher_created,
      output.network_watcher_name == "shared-watcher",
      local.network_watcher_resource_group == "shared-network",
    ])
    error_message = "Lookup mode must respect explicit existing Network Watcher and resource group names."
  }
}

run "network_watcher_create_custom" {
  command = plan

  variables {
    features = { network_watcher = true }
    network_watcher = {
      create              = true
      name                = "dedicated-watcher"
      resource_group_name = "ignored-existing-group"
    }
  }

  assert {
    condition = alltrue([
      output.network_watcher_created,
      output.network_watcher_name == "dedicated-watcher",
      local.network_watcher_resource_group == output.resource_group_name,
    ])
    error_message = "Create mode must use the custom name but always the scenario-owned resource group."
  }
}

run "unlimited_quota_explicit" {
  command = plan

  variables {
    features                     = { log_analytics = true }
    log_analytics_daily_quota_gb = -1
  }

  assert {
    condition     = length(module.log_analytics) == 1 && var.log_analytics_daily_quota_gb == -1
    error_message = "Unlimited ingestion must be an explicit supported opt-in."
  }
}

run "application_insights_requires_log_analytics" {
  command = plan

  variables {
    features = { application_insights = true }
  }

  expect_failures = [var.features]
}

run "activity_log_requires_log_analytics" {
  command = plan

  variables {
    features = { activity_log = true }
  }

  expect_failures = [var.features]
}

run "workbook_requires_log_analytics" {
  command = plan

  variables {
    features = { workbook = true }
  }

  expect_failures = [var.features]
}

run "alert_rules_require_action_group" {
  command = plan

  variables {
    features = { alert_rules = true }
  }

  expect_failures = [var.features]
}

run "reject_invalid_daily_quota" {
  command = plan

  variables {
    log_analytics_daily_quota_gb = 0
  }

  expect_failures = [var.log_analytics_daily_quota_gb]
}

run "reject_invalid_sampling" {
  command = plan

  variables {
    application_insights_sampling_percentage = 101
  }

  expect_failures = [var.application_insights_sampling_percentage]
}

run "reject_unknown_activity_category" {
  command = plan

  variables {
    activity_log_categories = ["Unknown"]
  }

  expect_failures = [var.activity_log_categories]
}

run "reject_empty_activity_categories" {
  command = plan

  variables {
    activity_log_categories = []
  }

  expect_failures = [var.activity_log_categories]
}
