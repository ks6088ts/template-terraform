mock_provider "azurerm" {
  override_during = plan

  mock_data "azurerm_client_config" {
    defaults = {
      object_id = "00000000-0000-0000-0000-000000000005"
    }
  }

  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
    }
  }

  mock_resource "azurerm_container_registry" {
    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerRegistry/registries/registrytest1234"
      login_server = "registrytest1234.azurecr.io"
    }
  }

  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-test"
      client_id    = "00000000-0000-0000-0000-000000000002"
      principal_id = "00000000-0000-0000-0000-000000000003"
      tenant_id    = "00000000-0000-0000-0000-000000000004"
    }
  }

  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
      workspace_id = "00000000-0000-0000-0000-000000000006"
    }
  }

  mock_resource "azurerm_application_insights" {
    defaults = {
      id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Insights/components/appi-test"
      app_id              = "00000000-0000-0000-0000-000000000008"
      connection_string   = "InstrumentationKey=00000000-0000-0000-0000-000000000007"
      instrumentation_key = "00000000-0000-0000-0000-000000000007"
    }
  }
}

mock_provider "azuread" {
  override_during = plan
}

mock_provider "azapi" {
  override_during = plan
}

mock_provider "random" {
  override_during = plan

  mock_resource "random_string" {
    defaults = {
      result = "test1234"
    }
  }
}

run "private_registry_is_wired_by_default" {
  command = plan

  assert {
    condition = alltrue([
      var.container_image == "nginx:latest",
      var.container_port == 80,
      var.health_probe_path == null,
      var.acr_sku == "Basic",
      module.container_registry.login_server == "registrytest1234.azurecr.io",
    ])
    error_message = "The bootstrap plan must create the Basic private registry while keeping the public nginx image."
  }

  assert {
    condition = alltrue([
      azurerm_role_assignment.container_app_acr_pull.scope == module.container_registry.id,
      azurerm_role_assignment.container_app_acr_pull.role_definition_name == "AcrPull",
      azurerm_role_assignment.container_app_acr_pull.principal_id == azurerm_user_assigned_identity.container_app_acr_pull.principal_id,
      azurerm_role_assignment.container_app_acr_pull.principal_type == "ServicePrincipal",
      azurerm_role_assignment.container_app_acr_pull.skip_service_principal_aad_check,
    ])
    error_message = "The Container App pull identity must receive AcrPull on the registry."
  }

  assert {
    condition = alltrue([
      azurerm_role_assignment.acr_push.scope == module.container_registry.id,
      azurerm_role_assignment.acr_push.role_definition_name == "AcrPush",
      azurerm_role_assignment.acr_push.principal_id == "00000000-0000-0000-0000-000000000005",
    ])
    error_message = "The Terraform client principal must receive AcrPush by default."
  }

  assert {
    condition = alltrue([
      output.acr_id == module.container_registry.id,
      output.acr_login_server == module.container_registry.login_server,
      output.acr_push_principal_id == "00000000-0000-0000-0000-000000000005",
      output.container_app_identity_id == azurerm_user_assigned_identity.container_app_acr_pull.id,
      output.container_app_identity_client_id == "00000000-0000-0000-0000-000000000002",
      output.container_app_identity_principal_id == "00000000-0000-0000-0000-000000000003",
      output.application_insights_app_id == "00000000-0000-0000-0000-000000000008",
    ])
    error_message = "Registry and pull identity outputs must expose the managed resources."
  }
}

run "acr_push_principal_can_be_overridden" {
  command = plan

  variables {
    acr_push_principal_id = "00000000-0000-0000-0000-000000000009"
  }

  assert {
    condition = alltrue([
      azurerm_role_assignment.acr_push.principal_id == "00000000-0000-0000-0000-000000000009",
      output.acr_push_principal_id == "00000000-0000-0000-0000-000000000009",
    ])
    error_message = "The configured AcrPush principal must override the Terraform client principal."
  }
}

run "acr_sku_rejects_unsupported_values" {
  command = plan

  variables {
    acr_sku = "Developer"
  }

  expect_failures = [var.acr_sku]
}

run "application_insights_can_be_disabled" {
  command = plan

  variables {
    enable_application_insights = false
  }

  assert {
    condition = alltrue([
      length(module.application_insights) == 0,
      output.application_insights_id == null,
      output.application_insights_app_id == null,
      output.application_insights_connection_string == null,
    ])
    error_message = "Disabling Application Insights must remove the resource and return null observability outputs."
  }
}

run "custom_image_enables_health_probes" {
  command = plan

  variables {
    container_image   = "registrytest1234.azurecr.io/tasks-mcp-server@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    container_port    = 8080
    health_probe_path = "/health"
    min_replicas      = 1
    max_replicas      = 1
  }

  assert {
    condition = alltrue([
      var.container_port == 8080,
      var.health_probe_path == "/health",
      var.min_replicas == 1,
      var.max_replicas == 1,
    ])
    error_message = "The custom MCP deployment settings must enable /health probes and one warm replica."
  }
}
