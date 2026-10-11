mock_provider "databricks" {
  override_during = plan
}

run "no_visible_dashboards" {
  command = plan

  assert {
    condition     = data.databricks_dashboards.this.dashboard_name_contains == null
    error_message = "The default lookup must not add a dashboard name filter."
  }

  assert {
    condition     = jsonencode(output.dashboards) == "[]" && output.dashboard_count == 0
    error_message = "A workspace with no visible dashboards must return an empty list and zero count."
  }
}

run "forward_name_filter" {
  command = plan

  variables {
    dashboard_name_contains = "sAlEs"
  }

  assert {
    condition     = data.databricks_dashboards.this.dashboard_name_contains == "sAlEs"
    error_message = "The filter must reach the data source unchanged."
  }
}

run "empty_filter" {
  command = plan

  variables {
    dashboard_name_contains = ""
  }

  assert {
    condition     = data.databricks_dashboards.this.dashboard_name_contains == "" && output.dashboard_count == 0
    error_message = "An empty filter must be forwarded without inventing a default name."
  }
}

run "no_matching_dashboards" {
  command = plan

  variables {
    dashboard_name_contains = "not-found"
  }

  assert {
    condition = alltrue([
      data.databricks_dashboards.this.dashboard_name_contains == "not-found",
      jsonencode(output.dashboards) == "[]",
      output.dashboard_count == 0,
    ])
    error_message = "An empty filtered result must remain a normal empty list and zero count."
  }
}
