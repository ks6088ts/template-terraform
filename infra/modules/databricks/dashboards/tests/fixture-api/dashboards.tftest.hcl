provider "databricks" {
  alias     = "fixture"
  auth_type = "pat"
  token     = "local-fixture-token"
}

run "read_dashboard_metadata" {
  command = plan

  providers = {
    databricks = databricks.fixture
  }

  assert {
    condition = output.dashboard_count == 3 && jsonencode(output.dashboards) == jsonencode([
      {
        dashboard_id = "sales-dashboard"
        display_name = "Sales Overview"
        create_time  = "2026-10-01T09:00:00Z"
      },
      {
        dashboard_id = "operations-dashboard"
        display_name = "Operations Overview"
        create_time  = "2026-10-02T09:00:00Z"
      },
      {
        dashboard_id = "undated-dashboard"
        display_name = "Undated Dashboard"
        create_time  = data.databricks_dashboards.this.dashboards[2].create_time
      },
    ])
    error_message = "The module must expose exactly the returned metadata, preserving a missing timestamp and excluding dashboard contents."
  }
}

run "case_insensitive_name_filter" {
  command = plan

  providers = {
    databricks = databricks.fixture
  }

  variables {
    dashboard_name_contains = "sAlEs"
  }

  assert {
    condition = alltrue([
      data.databricks_dashboards.this.dashboard_name_contains == "sAlEs",
      output.dashboard_count == 1,
      output.dashboards[0].dashboard_id == "sales-dashboard",
      output.dashboards[0].display_name == "Sales Overview",
      output.dashboards[0].create_time == "2026-10-01T09:00:00Z",
    ])
    error_message = "The real provider must apply the case-insensitive filter to the local API fixture."
  }
}

run "empty_name_filter" {
  command = plan

  providers = {
    databricks = databricks.fixture
  }

  variables {
    dashboard_name_contains = ""
  }

  assert {
    condition     = output.dashboard_count == 3
    error_message = "An empty name filter must return all dashboards from the local API fixture."
  }
}

run "no_matching_name" {
  command = plan

  providers = {
    databricks = databricks.fixture
  }

  variables {
    dashboard_name_contains = "not-found"
  }

  assert {
    condition     = jsonencode(output.dashboards) == "[]" && output.dashboard_count == 0
    error_message = "A filter with no matches must return an empty list and zero count."
  }
}
