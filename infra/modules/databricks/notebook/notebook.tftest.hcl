mock_provider "databricks" {
  override_during = plan

  mock_resource "databricks_notebook" {
    defaults = {
      url = "https://adb-1234567890123456.7.azuredatabricks.net/#notebook/123"
    }
  }
}

variables {
  path           = "/Shared/learning"
  language       = "SQL"
  content_base64 = base64encode("-- Databricks notebook source\nSELECT 1;\n")
}

run "forward_sql_notebook" {
  command = plan

  assert {
    condition = alltrue([
      databricks_notebook.this.path == "/Shared/learning",
      databricks_notebook.this.language == "SQL",
      base64decode(databricks_notebook.this.content_base64) == "-- Databricks notebook source\nSELECT 1;\n",
      output.path == databricks_notebook.this.path,
      output.url == databricks_notebook.this.url,
    ])
    error_message = "Notebook path, language, and exact source must reach the resource, and outputs must forward the provider values."
  }
}

run "forward_python_notebook" {
  command = plan

  variables {
    path           = "/Users/learner@example.com/demo"
    language       = "PYTHON"
    content_base64 = base64encode("# Databricks notebook source\nprint('hello')\n")
  }

  assert {
    condition = alltrue([
      output.path == "/Users/learner@example.com/demo",
      databricks_notebook.this.language == "PYTHON",
      base64decode(databricks_notebook.this.content_base64) == "# Databricks notebook source\nprint('hello')\n",
    ])
    error_message = "The primitive module must also support a different source language and Workspace path."
  }
}

run "reject_relative_path" {
  command = plan
  variables {
    path = "Shared/learning"
  }
  expect_failures = [var.path]
}

run "reject_trailing_slash" {
  command = plan
  variables {
    path = "/Shared/learning/"
  }
  expect_failures = [var.path]
}

run "reject_parent_directory" {
  command = plan
  variables {
    path = "/Shared/../learning"
  }
  expect_failures = [var.path]
}

run "reject_empty_segment" {
  command = plan
  variables {
    path = "/Shared//learning"
  }
  expect_failures = [var.path]
}

run "reject_unsupported_language" {
  command = plan
  variables {
    language = "JAVASCRIPT"
  }
  expect_failures = [var.language]
}

run "reject_invalid_base64" {
  command = plan
  variables {
    content_base64 = "not base64!"
  }
  expect_failures = [var.content_base64]
}

run "reject_empty_source" {
  command = plan
  variables {
    content_base64 = base64encode("")
  }
  expect_failures = [var.content_base64]
}

run "reject_whitespace_source" {
  command = plan
  variables {
    content_base64 = base64encode(" \n\t")
  }
  expect_failures = [var.content_base64]
}
