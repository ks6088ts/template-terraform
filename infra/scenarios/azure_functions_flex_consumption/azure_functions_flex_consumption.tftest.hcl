mock_provider "azurerm" {
  override_during = plan

  mock_data "azurerm_client_config" {
    defaults = {
      object_id       = "00000000-0000-0000-0000-000000000001"
      subscription_id = "00000000-0000-0000-0000-000000000002"
    }
  }

  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/rg-test"
    }
  }

  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
      workspace_id = "00000000-0000-0000-0000-000000000003"
    }
  }

  mock_resource "azurerm_application_insights" {
    defaults = {
      id                = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/rg-test/providers/Microsoft.Insights/components/appi-test"
      app_id            = "00000000-0000-0000-0000-000000000004"
      connection_string = "InstrumentationKey=00000000-0000-0000-0000-000000000005"
    }
  }

  mock_resource "azurerm_storage_account" {
    defaults = {
      id                     = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/sttest1234"
      primary_blob_endpoint  = "https://sttest1234.blob.core.windows.net/"
      primary_queue_endpoint = "https://sttest1234.queue.core.windows.net/"
      primary_table_endpoint = "https://sttest1234.table.core.windows.net/"
    }
  }

  mock_resource "azurerm_function_app_flex_consumption" {
    defaults = {
      id               = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/rg-test/providers/Microsoft.Web/sites/func-test"
      default_hostname = "func-test.azurewebsites.net"
      identity = {
        principal_id = "00000000-0000-0000-0000-000000000006"
        tenant_id    = "00000000-0000-0000-0000-000000000007"
      }
    }
  }
}

mock_provider "azuread" {
  override_during = plan

  mock_data "azuread_client_config" {
    defaults = {
      object_id = "00000000-0000-0000-0000-000000000001"
      tenant_id = "00000000-0000-0000-0000-000000000007"
    }
  }

  mock_resource "azuread_application" {
    defaults = {
      id        = "/applications/00000000-0000-0000-0000-000000000008"
      client_id = "00000000-0000-0000-0000-000000000008"
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

  mock_resource "random_uuid" {
    defaults = {
      result = "00000000-0000-0000-0000-000000000009"
    }
  }
}

run "scenario_defaults_and_outputs" {
  command = plan

  assert {
    condition = alltrue([
      var.runtime_name == "python",
      var.runtime_version == "3.13",
      var.timer_schedule == "0 * * * * *",
      module.log_analytics.name == "law-azurefuncflex-test1234",
      module.application_insights.name == "appi-azurefuncflex-test1234",
      module.functions_flex_consumption.function_app_name == "func-azurefuncflex-test1234",
    ])
    error_message = "The default scenario must deploy monitored Python 3.13 Flex Consumption with a one-minute timer."
  }

  assert {
    condition = alltrue([
      azuread_application_pre_authorized.azure_cli.authorized_client_id == var.azure_cli_client_id,
      azuread_application_identifier_uri.function_app.identifier_uri == "api://${azuread_application.function_app.client_id}",
      output.function_app_authentication_client_id == azuread_application.function_app.client_id,
      output.function_app_authentication_tenant_id == data.azuread_client_config.current.tenant_id,
      output.function_app_url == "https://func-test.azurewebsites.net",
    ])
    error_message = "The existing Entra authentication and Function App URL contract must remain intact."
  }

  assert {
    condition = alltrue([
      output.subscription_id == "00000000-0000-0000-0000-000000000002",
      output.application_insights_id == module.application_insights.id,
      output.application_insights_app_id == module.application_insights.app_id,
      output.log_analytics_workspace_id == module.log_analytics.id,
      output.log_analytics_workspace_customer_id == module.log_analytics.workspace_id,
      output.storage_account_name == module.functions_flex_consumption.storage_account_name,
      output.deployment_container_name == "deploymentpackage",
      output.timer_schedule == var.timer_schedule,
    ])
    error_message = "Subscription, monitoring, and Storage probe outputs must reference the deployed resources."
  }
}

run "flex_module_wiring" {
  command = plan

  module {
    source = "../../modules/azure/functions_flex_consumption"
  }

  variables {
    name                                   = "test1234"
    resource_group_name                    = "rg-test"
    location                               = "japaneast"
    storage_account_name                   = "sttest1234"
    runtime_version                        = "3.13"
    application_insights_connection_string = "InstrumentationKey=00000000-0000-0000-0000-000000000005"
    app_settings = {
      TIMER_SCHEDULE                = "0 * * * * *"
      STORAGE_ACCOUNT_BLOB_ENDPOINT = "https://incorrect.blob.core.windows.net/"
      STORAGE_CONTAINER_NAME        = "incorrect"
    }
    authentication = {
      client_id            = "00000000-0000-0000-0000-000000000008"
      tenant_auth_endpoint = "https://login.microsoftonline.com/00000000-0000-0000-0000-000000000007/v2.0/"
      allowed_audiences    = ["api://00000000-0000-0000-0000-000000000008"]
      allowed_applications = ["04b07795-8ddb-461a-bbee-02f9e1bf7b46"]
      excluded_paths       = ["/api/hello-key"]
    }
  }

  assert {
    condition = alltrue([
      azurerm_service_plan.this.sku_name == "FC1",
      azurerm_function_app_flex_consumption.this.runtime_name == "python",
      azurerm_function_app_flex_consumption.this.runtime_version == "3.13",
      azurerm_function_app_flex_consumption.this.site_config[0].application_insights_connection_string == var.application_insights_connection_string,
      azurerm_function_app_flex_consumption.this.app_settings["TIMER_SCHEDULE"] == "0 * * * * *",
      azurerm_function_app_flex_consumption.this.app_settings["STORAGE_ACCOUNT_BLOB_ENDPOINT"] == azurerm_storage_account.this.primary_blob_endpoint,
      azurerm_function_app_flex_consumption.this.app_settings["STORAGE_CONTAINER_NAME"] == azurerm_storage_container.deployment.name,
      azurerm_function_app_flex_consumption.this.app_settings["AzureWebJobsStorage__credential"] == "managedidentity",
      !azurerm_storage_account.this.shared_access_key_enabled,
    ])
    error_message = "The Flex app must use monitored Python 3.13, a one-minute timer, and managed-identity Storage."
  }

  assert {
    condition = alltrue([
      azurerm_function_app_flex_consumption.this.auth_settings_v2[0].excluded_paths[0] == "/api/hello-key",
      azurerm_function_app_flex_consumption.this.auth_settings_v2[0].unauthenticated_action == "Return401",
      azurerm_role_assignment.storage_blob_data_owner.role_definition_name == "Storage Blob Data Owner",
      azurerm_role_assignment.storage_queue_data_contributor.role_definition_name == "Storage Queue Data Contributor",
      azurerm_role_assignment.storage_table_data_contributor.role_definition_name == "Storage Table Data Contributor",
    ])
    error_message = "The existing authentication exception and Storage identity permissions must remain intact."
  }
}
