mock_provider "azurerm" {
  override_during = plan

  mock_resource "azurerm_application_insights_workbook" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Insights/workbooks/00000000-0000-0000-0000-000000000001"
    }
  }
}

variables {
  name                = "00000000-0000-0000-0000-000000000001"
  display_name        = "Observability"
  resource_group_name = "rg-test"
  location            = "japaneast"
  source_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
  data_json           = "{\"version\":\"Notebook/1.0\",\"items\":[]}"
}

run "configured_workbook" {
  command = plan

  variables {
    tags = { environment = "test" }
  }

  assert {
    condition = alltrue([
      azurerm_application_insights_workbook.this.name == var.name,
      azurerm_application_insights_workbook.this.display_name == "Observability",
      azurerm_application_insights_workbook.this.resource_group_name == "rg-test",
      azurerm_application_insights_workbook.this.location == "japaneast",
      azurerm_application_insights_workbook.this.source_id == lower(var.source_id),
      jsondecode(azurerm_application_insights_workbook.this.data_json).version == "Notebook/1.0",
      length(jsondecode(azurerm_application_insights_workbook.this.data_json).items) == 0,
      azurerm_application_insights_workbook.this.tags.environment == "test",
      output.name == var.name,
      output.id == azurerm_application_insights_workbook.this.id,
    ])
    error_message = "The Workbook must preserve its content and metadata while normalizing the source ID to lowercase."
  }
}

run "reject_invalid_uuid" {
  command = plan

  variables {
    name = "workbook-name"
  }

  expect_failures = [var.name]
}

run "reject_invalid_json" {
  command = plan

  variables {
    data_json = "not-json"
  }

  expect_failures = [var.data_json]
}
