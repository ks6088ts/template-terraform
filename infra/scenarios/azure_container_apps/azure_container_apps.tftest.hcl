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
