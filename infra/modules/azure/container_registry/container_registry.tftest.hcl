mock_provider "azurerm" {
  override_during = plan
}

run "secure_legacy_rbac_defaults" {
  command = plan

  variables {
    name                = "registry-test1234"
    resource_group_name = "rg-test"
    location            = "japaneast"
  }

  assert {
    condition = alltrue([
      azurerm_container_registry.this.sku == "Basic",
      !azurerm_container_registry.this.admin_enabled,
      !azurerm_container_registry.this.anonymous_pull_enabled,
      azurerm_container_registry.this.public_network_access_enabled,
      azurerm_container_registry.this.azuread_authentication_as_arm_policy_enabled,
      azurerm_container_registry.this.role_assignment_mode == "LegacyRegistryPermissions",
    ])
    error_message = "The registry must use secure defaults compatible with AcrPull and AcrPush."
  }
}

run "abac_mode_can_be_selected" {
  command = plan

  variables {
    name                 = "registry-test1234"
    resource_group_name  = "rg-test"
    location             = "japaneast"
    role_assignment_mode = "AbacRepositoryPermissions"
  }

  assert {
    condition     = azurerm_container_registry.this.role_assignment_mode == "AbacRepositoryPermissions"
    error_message = "The configured role assignment mode must be forwarded to ACR."
  }
}
