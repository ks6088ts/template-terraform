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

  assert {
    condition     = !azurerm_container_app.this.ingress[0].allow_insecure_connections
    error_message = "Ingress must reject insecure HTTP connections."
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

run "http_health_probes_are_configured" {
  command = plan

  variables {
    name                       = "containerapps-test1234"
    resource_group_name        = "rg-test"
    location                   = "japaneast"
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
    container_image            = "registry.azurecr.io/tasks-mcp-server@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    target_port                = 8080
    health_probe_path          = "/health"
  }

  assert {
    condition = alltrue([
      azurerm_container_app.this.template[0].container[0].startup_probe[0].path == "/health",
      azurerm_container_app.this.template[0].container[0].startup_probe[0].port == 8080,
      azurerm_container_app.this.template[0].container[0].liveness_probe[0].path == "/health",
      azurerm_container_app.this.template[0].container[0].readiness_probe[0].path == "/health",
    ])
    error_message = "The configured health path must be used for all platform probes."
  }
}

run "replica_bounds_are_rejected" {
  command = plan

  variables {
    name                       = "containerapps-test1234"
    resource_group_name        = "rg-test"
    location                   = "japaneast"
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
    container_image            = "nginx:latest"
    min_replicas               = 2
    max_replicas               = 1
  }

  expect_failures = [azurerm_container_app.this]
}

run "unsupported_consumption_allocation_is_rejected" {
  command = plan

  variables {
    name                       = "containerapps-test1234"
    resource_group_name        = "rg-test"
    location                   = "japaneast"
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
    container_image            = "nginx:latest"
    cpu                        = 1
    memory                     = "1Gi"
  }

  expect_failures = [azurerm_container_app.this]
}

run "undefined_secret_reference_is_rejected" {
  command = plan

  variables {
    name                       = "containerapps-test1234"
    resource_group_name        = "rg-test"
    location                   = "japaneast"
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
    container_image            = "nginx:latest"
    env_vars = [{
      name        = "API_KEY"
      secret_name = "missing"
    }]
  }

  expect_failures = [azurerm_container_app.this]
}

run "registry_without_user_assigned_identity_is_rejected" {
  command = plan

  variables {
    name                       = "containerapps-test1234"
    resource_group_name        = "rg-test"
    location                   = "japaneast"
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
    container_image            = "registry.azurecr.io/tasks-mcp-server:latest"
    identity_type              = "SystemAssigned"
    identity_ids               = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-test"]
    registries = [{
      server   = "registry.azurecr.io"
      identity = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-test"
    }]
  }

  expect_failures = [azurerm_container_app.this]
}
