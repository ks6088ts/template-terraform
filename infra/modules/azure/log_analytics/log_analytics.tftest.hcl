mock_provider "azurerm" {
  override_during = plan
}

variables {
  name                = "observe"
  resource_group_name = "rg-test"
  location            = "japaneast"
}

run "unlimited_quota_preserves_defaults" {
  command = plan

  assert {
    condition = alltrue([
      azurerm_log_analytics_workspace.this.daily_quota_gb == -1,
      azurerm_log_analytics_workspace.this.sku == "PerGB2018",
      azurerm_log_analytics_workspace.this.retention_in_days == 30,
      output.name == "law-observe",
    ])
    error_message = "Existing callers must retain unlimited daily ingestion and the existing workspace defaults."
  }
}

run "custom_daily_quota" {
  command = plan

  variables {
    daily_quota_gb = 0.5
  }

  assert {
    condition     = azurerm_log_analytics_workspace.this.daily_quota_gb == 0.5
    error_message = "The configured daily ingestion quota must be forwarded to the workspace."
  }
}

run "reject_invalid_negative_quota" {
  command = plan

  variables {
    daily_quota_gb = -2
  }

  expect_failures = [var.daily_quota_gb]
}
