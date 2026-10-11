mock_provider "azurerm" {
  override_during = plan

  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-azuredatabricks-test1234"
    }
  }

  mock_resource "azurerm_databricks_workspace" {
    defaults = {
      id                        = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-azuredatabricks-test1234/providers/Microsoft.Databricks/workspaces/dbw-azuredatabricks-test1234"
      workspace_id              = "1234567890123456"
      workspace_url             = "adb-1234567890123456.7.azuredatabricks.net"
      managed_resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-azuredatabricks-test1234-managed"
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

run "default_workspace" {
  command = plan

  assert {
    condition = alltrue([
      module.resource_group.name == "rg-azuredatabricks-test1234",
      module.resource_group.location == "japaneast",
      module.databricks_workspace.name == "dbw-azuredatabricks-test1234",
      module.databricks_workspace.location == module.resource_group.location,
      module.databricks_workspace.sku == "premium",
      module.databricks_workspace.tags == var.tags,
      module.databricks_workspace.managed_resource_group_name == "rg-azuredatabricks-test1234-managed",
    ])
    error_message = "The default scenario must compose a Premium Japan East workspace and consistently named resource groups."
  }

  assert {
    condition = alltrue([
      output.resource_group_id == module.resource_group.id,
      output.resource_group_name == module.resource_group.name,
      output.workspace_resource_id == module.databricks_workspace.id,
      output.workspace_name == module.databricks_workspace.name,
      output.workspace_id == "1234567890123456",
      output.workspace_url == "adb-1234567890123456.7.azuredatabricks.net",
      output.databricks_host == "https://adb-1234567890123456.7.azuredatabricks.net/",
      output.managed_resource_group_id == module.databricks_workspace.managed_resource_group_id,
      output.managed_resource_group_name == module.databricks_workspace.managed_resource_group_name,
    ])
    error_message = "Scenario outputs must propagate resource identifiers and the exact workspace connection URLs."
  }
}

run "custom_workspace" {
  command = plan

  variables {
    name     = "analytics"
    location = "westeurope"
    sku      = "standard"
    tags = {
      environment = "test"
    }
  }

  assert {
    condition = alltrue([
      output.resource_group_name == "rg-analytics-test1234",
      output.workspace_name == "dbw-analytics-test1234",
      module.resource_group.location == "westeurope",
      module.databricks_workspace.location == "westeurope",
      module.databricks_workspace.sku == "standard",
      module.databricks_workspace.tags == tomap({ environment = "test" }),
      output.managed_resource_group_name == "rg-analytics-test1234-managed",
    ])
    error_message = "Custom naming, region, SKU, and tags must reach the workspace module."
  }
}

run "maximum_base_name" {
  command = plan

  variables {
    name = "abcdefghijklmnopqrstuvwxyz012345"
  }

  assert {
    condition = alltrue([
      output.workspace_name == "dbw-abcdefghijklmnopqrstuvwxyz012345-test1234",
      length(output.workspace_name) <= 64,
      output.managed_resource_group_name == "rg-abcdefghijklmnopqrstuvwxyz012345-test1234-managed",
    ])
    error_message = "A 32-character base name must remain intact and produce a valid workspace name."
  }
}

run "trial_workspace" {
  command = plan

  variables {
    sku = "trial"
  }

  assert {
    condition     = module.databricks_workspace.sku == "trial"
    error_message = "The scenario must support an explicitly selected trial SKU."
  }
}

run "minimum_base_name" {
  command = plan

  variables {
    name = "adb"
  }

  assert {
    condition     = output.workspace_name == "dbw-adb-test1234"
    error_message = "A three-character base name must be accepted without modification."
  }
}

run "invalid_sku" {
  command = plan

  variables {
    sku = "basic"
  }

  expect_failures = [var.sku]
}

run "invalid_base_name" {
  command = plan

  variables {
    name = "-analytics"
  }

  expect_failures = [var.name]
}

run "overlong_base_name" {
  command = plan

  variables {
    name = "abcdefghijklmnopqrstuvwxyz0123456"
  }

  expect_failures = [var.name]
}

run "short_base_name" {
  command = plan

  variables {
    name = "ad"
  }

  expect_failures = [var.name]
}

run "empty_location" {
  command = plan

  variables {
    location = ""
  }

  expect_failures = [var.location]
}
