provider "databricks" {
  alias     = "fixture"
  auth_type = "pat"
  token     = "local-fixture-token"
}

variables {
  workspace_url          = "adb-1234567890123456.7.azuredatabricks.net"
  medallion_catalog_name = null
}

run "expose_dashboard_metadata" {
  command = plan

  providers = {
    databricks = databricks.fixture
  }

  assert {
    condition = alltrue([
      output.databricks_host == "https://adb-1234567890123456.7.azuredatabricks.net",
      output.dashboard_count == 3,
      output.dashboard_count == module.dashboards.dashboard_count,
      jsonencode(output.dashboards) == jsonencode(module.dashboards.dashboards),
      output.dashboards[0].dashboard_id == "sales-dashboard",
      output.dashboards[1].dashboard_id == "operations-dashboard",
      output.dashboards[2].dashboard_id == "undated-dashboard",
      output.medallion == null,
      length(module.medallion_schema) == 0,
      length(module.medallion_notebook) == 0,
    ])
    error_message = "The scenario must expose the module metadata and count without changing the workspace URL."
  }
}

run "forward_case_insensitive_filter" {
  command = plan

  providers = {
    databricks = databricks.fixture
  }

  variables {
    dashboard_name_contains = "oPeRaTiOnS"
  }

  assert {
    condition = output.dashboard_count == 1 && jsonencode(output.dashboards) == jsonencode([
      {
        dashboard_id = "operations-dashboard"
        display_name = "Operations Overview"
        create_time  = "2026-10-02T09:00:00Z"
      },
    ])
    error_message = "The scenario filter must reach the real provider and produce the exact matching metadata from the local API fixture."
  }
}

run "expose_empty_filtered_result" {
  command = plan

  providers = {
    databricks = databricks.fixture
  }

  variables {
    dashboard_name_contains = "not-found"
  }

  assert {
    condition     = jsonencode(output.dashboards) == "[]" && output.dashboard_count == 0
    error_message = "The scenario must propagate a genuine empty filtered result."
  }
}
