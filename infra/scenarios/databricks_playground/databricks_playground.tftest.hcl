mock_provider "databricks" {
  override_during = plan
}

variables {
  workspace_url          = "adb-1234567890123456.7.azuredatabricks.net"
  medallion_catalog_name = null
}

run "read_workspace_dashboards" {
  command = plan

  assert {
    condition = alltrue([
      output.databricks_host == "https://adb-1234567890123456.7.azuredatabricks.net",
      output.databricks_host == local.databricks_host,
      output.dashboard_count == module.dashboards.dashboard_count,
      output.dashboard_count == 0,
      jsonencode(output.dashboards) == jsonencode(module.dashboards.dashboards),
      output.medallion == null,
      length(module.medallion_schema) == 0,
      length(module.medallion_notebook) == 0,
    ])
    error_message = "The scenario must construct the exact HTTPS host, expose the dashboard outputs, and create no medallion resources by default."
  }

  assert {
    condition     = jsonencode(output.dashboards) == "[]"
    error_message = "An empty dashboard result must remain an empty list."
  }
}

run "read_another_workspace_with_filter" {
  command = plan

  variables {
    workspace_url           = "adb-9876543210987654.8.azuredatabricks.net"
    dashboard_name_contains = "oPeRaTiOnS"
  }

  assert {
    condition = alltrue([
      output.databricks_host == "https://adb-9876543210987654.8.azuredatabricks.net",
      output.dashboard_count == 0,
      jsonencode(output.dashboards) == "[]",
    ])
    error_message = "A different workspace must produce the exact HTTPS host, and outputs must reflect the returned filtered metadata."
  }
}

run "reject_empty_workspace_url" {
  command = plan

  variables {
    workspace_url = ""
  }

  expect_failures = [var.workspace_url]
}

run "reject_https_url" {
  command = plan

  variables {
    workspace_url = "https://adb-1234567890123456.7.azuredatabricks.net/"
  }

  expect_failures = [var.workspace_url]
}

run "reject_http_url" {
  command = plan

  variables {
    workspace_url = "http://adb-1234567890123456.7.azuredatabricks.net"
  }

  expect_failures = [var.workspace_url]
}

run "reject_workspace_path" {
  command = plan

  variables {
    workspace_url = "adb-1234567890123456.7.azuredatabricks.net/dashboards"
  }

  expect_failures = [var.workspace_url]
}

run "reject_workspace_port" {
  command = plan

  variables {
    workspace_url = "adb-1234567890123456.7.azuredatabricks.net:443"
  }

  expect_failures = [var.workspace_url]
}

run "reject_workspace_whitespace" {
  command = plan

  variables {
    workspace_url = " adb-1234567890123456.7.azuredatabricks.net "
  }

  expect_failures = [var.workspace_url]
}

run "reject_workspace_credentials" {
  command = plan

  variables {
    workspace_url = "user@adb-1234567890123456.7.azuredatabricks.net"
  }

  expect_failures = [var.workspace_url]
}

run "reject_invalid_dns_label" {
  command = plan

  variables {
    workspace_url = "-adb-1234567890123456.7.azuredatabricks.net"
  }

  expect_failures = [var.workspace_url]
}

run "reject_overlong_dns_label" {
  command = plan

  variables {
    workspace_url = "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijkl.azuredatabricks.net"
  }

  expect_failures = [var.workspace_url]
}
