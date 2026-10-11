mock_provider "azurerm" {
  override_during = plan

  mock_resource "azurerm_databricks_workspace" {
    defaults = {
      id                          = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-test/providers/Microsoft.Databricks/workspaces/dbw-test"
      workspace_id                = "1234567890123456"
      workspace_url               = "adb-1234567890123456.7.azuredatabricks.net"
      managed_resource_group_id   = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-test-managed"
      managed_resource_group_name = "rg-test-managed"
    }
  }
}

variables {
  name                = "dbw-test"
  resource_group_name = "rg-test"
  location            = "japaneast"
}

run "default_workspace" {
  command = plan

  assert {
    condition = alltrue([
      azurerm_databricks_workspace.this.name == "dbw-test",
      azurerm_databricks_workspace.this.resource_group_name == "rg-test",
      azurerm_databricks_workspace.this.location == "japaneast",
      azurerm_databricks_workspace.this.sku == "premium",
      azurerm_databricks_workspace.this.public_network_access_enabled,
      azurerm_databricks_workspace.this.custom_parameters[0].no_public_ip,
      length(azurerm_databricks_workspace.this.tags) == 0,
      var.managed_resource_group_name == null,
    ])
    error_message = "The default workspace must use Premium, public workspace access, no public node IPs, and Azure-generated managed resource group naming."
  }

  assert {
    condition = alltrue([
      output.id == azurerm_databricks_workspace.this.id,
      output.name == "dbw-test",
      output.location == "japaneast",
      output.sku == "premium",
      length(output.tags) == 0,
      output.workspace_id == "1234567890123456",
      output.workspace_url == "adb-1234567890123456.7.azuredatabricks.net",
      output.databricks_host == "https://adb-1234567890123456.7.azuredatabricks.net/",
      output.managed_resource_group_id == azurerm_databricks_workspace.this.managed_resource_group_id,
      output.managed_resource_group_name == "rg-test-managed",
    ])
    error_message = "Workspace outputs must distinguish Azure and Databricks IDs and expose the exact hostname, HTTPS host, and managed resource group."
  }
}

run "custom_workspace" {
  command = plan

  variables {
    name                        = "dbw-custom"
    resource_group_name         = "rg-custom"
    location                    = "westeurope"
    sku                         = "standard"
    managed_resource_group_name = "rg-custom-managed"
    tags = {
      environment = "test"
    }
  }

  assert {
    condition = alltrue([
      azurerm_databricks_workspace.this.name == "dbw-custom",
      azurerm_databricks_workspace.this.resource_group_name == "rg-custom",
      output.location == "westeurope",
      output.sku == "standard",
      output.managed_resource_group_name == "rg-custom-managed",
      output.tags == tomap({ environment = "test" }),
      azurerm_databricks_workspace.this.public_network_access_enabled,
      azurerm_databricks_workspace.this.custom_parameters[0].no_public_ip,
    ])
    error_message = "Workspace inputs must reach the resource without changing the minimal networking configuration."
  }
}

run "trial_workspace" {
  command = plan

  variables {
    sku = "trial"
  }

  assert {
    condition     = output.sku == "trial"
    error_message = "The trial SKU must be supported when explicitly selected."
  }
}

run "workspace_name_boundaries" {
  command = plan

  variables {
    name = "abcdefghijklmnopqrstuvwxyz012345abcdefghijklmnopqrstuvwxyz012345"
  }

  assert {
    condition     = length(output.name) == 64
    error_message = "A 64-character workspace name must be accepted without truncation."
  }
}

run "minimum_workspace_name" {
  command = plan

  variables {
    name = "dbw"
  }

  assert {
    condition     = output.name == "dbw"
    error_message = "A three-character workspace name must be accepted."
  }
}

run "invalid_sku" {
  command = plan

  variables {
    sku = "basic"
  }

  expect_failures = [var.sku]
}

run "invalid_workspace_name" {
  command = plan

  variables {
    name = "invalid workspace"
  }

  expect_failures = [var.name]
}

run "overlong_workspace_name" {
  command = plan

  variables {
    name = "abcdefghijklmnopqrstuvwxyz012345abcdefghijklmnopqrstuvwxyz0123456"
  }

  expect_failures = [var.name]
}

run "short_workspace_name" {
  command = plan

  variables {
    name = "db"
  }

  expect_failures = [var.name]
}

run "empty_resource_group_name" {
  command = plan

  variables {
    resource_group_name = " "
  }

  expect_failures = [var.resource_group_name]
}

run "empty_location" {
  command = plan

  variables {
    location = " "
  }

  expect_failures = [var.location]
}

run "empty_managed_resource_group_name" {
  command = plan

  variables {
    managed_resource_group_name = ""
  }

  expect_failures = [var.managed_resource_group_name]
}
