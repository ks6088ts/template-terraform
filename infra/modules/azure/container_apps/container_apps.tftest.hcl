mock_provider "azurerm" {
  override_during = plan
}

mock_provider "azapi" {
  override_during = plan
}

run "registry_is_optional" {
  command = plan

  variables {
    name                       = "containerapps-test1234"
    resource_group_name        = "rg-test"
    location                   = "japaneast"
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
    container_image            = "nginx:latest"
  }

  assert {
    condition     = length(azurerm_container_app.this.registry) == 0
    error_message = "The module must remain compatible with public images when registries is empty."
  }
}

run "user_assigned_identity_authenticates_registry" {
  command = plan

  variables {
    name                       = "containerapps-test1234"
    resource_group_name        = "rg-test"
    location                   = "japaneast"
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
    container_image            = "registry.azurecr.io/tasks-mcp-server@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    identity_type              = "UserAssigned"
    identity_ids               = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-test"]
    registries = [{
      server   = "registry.azurecr.io"
      identity = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-test"
    }]
  }

  assert {
    condition = alltrue([
      azurerm_container_app.this.identity[0].type == "UserAssigned",
      contains(azurerm_container_app.this.identity[0].identity_ids, var.registries[0].identity),
      azurerm_container_app.this.registry[0].server == "registry.azurecr.io",
      azurerm_container_app.this.registry[0].identity == var.registries[0].identity,
    ])
    error_message = "The registry and Container App must use the same user assigned identity resource ID."
  }
}
