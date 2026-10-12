mock_provider "databricks" {
  override_during = plan

  mock_resource "databricks_notebook" {
    defaults = {
      url = "https://adb-1234567890123456.7.azuredatabricks.net/#notebook/123"
    }
  }
}

variables {
  workspace_url          = "adb-1234567890123456.7.azuredatabricks.net"
  medallion_catalog_name = "workspace"
}

run "provision_minimal_medallion" {
  command = plan

  assert {
    condition = alltrue([
      length(module.medallion_schema) == 3,
      length(module.medallion_notebook) == 1,
      output.medallion.catalog_name == "workspace",
      output.medallion.notebook_path == "/Shared/medallion_playground",
      output.medallion.notebook_url == module.medallion_notebook[0].url,
      output.medallion.notebook_url == "https://adb-1234567890123456.7.azuredatabricks.net/#notebook/123",
      output.dashboard_count == 0,
      jsonencode(output.dashboards) == "[]",
    ])
    error_message = "Opt-in must add exactly three schema modules and one Notebook while preserving dashboard lookup and forwarding the Notebook outputs."
  }

  assert {
    condition = jsonencode(output.medallion.schemas) == jsonencode({
      bronze = "medallion_playground_bronze"
      silver = "medallion_playground_silver"
      gold   = "medallion_playground_gold"
      }) && jsonencode(output.medallion.tables) == jsonencode({
      bronze = "workspace.medallion_playground_bronze.orders_raw"
      silver = "workspace.medallion_playground_silver.orders"
      gold   = "workspace.medallion_playground_gold.daily_sales"
    })
    error_message = "All three dedicated schemas and table names must use the selected existing catalog and default prefix."
  }

  assert {
    condition = alltrue([
      for layer in ["bronze", "silver", "gold"] :
      module.medallion_schema[layer].catalog_name == "workspace" &&
      module.medallion_schema[layer].name == "medallion_playground_${layer}"
    ])
    error_message = "Every schema module must receive the same existing catalog and its layer-specific name."
  }

  assert {
    condition = alltrue([
      startswith(local.medallion_notebook_content, "-- Databricks notebook source\n"),
      length(regexall("CREATE OR REPLACE TABLE ", local.medallion_notebook_content)) == 3,
      strcontains(local.medallion_notebook_content, "CREATE OR REPLACE TABLE `workspace`.`medallion_playground_bronze`.`orders_raw` USING DELTA"),
      strcontains(local.medallion_notebook_content, "CREATE OR REPLACE TABLE `workspace`.`medallion_playground_silver`.`orders` USING DELTA"),
      strcontains(local.medallion_notebook_content, "CREATE OR REPLACE TABLE `workspace`.`medallion_playground_gold`.`daily_sales` USING DELTA"),
      strcontains(local.medallion_notebook_content, "try_cast(order_date_raw AS DATE)"),
      strcontains(local.medallion_notebook_content, "PARTITION BY order_id ORDER BY ingestion_seq DESC"),
      strcontains(local.medallion_notebook_content, "GROUP BY order_date, region"),
      strcontains(local.medallion_notebook_content, "assert_true(count(*) = 10"),
      strcontains(local.medallion_notebook_content, "assert_true(count(*) = 4"),
      strcontains(local.medallion_notebook_content, "assert_true(count(*) = 3"),
      strcontains(local.medallion_notebook_content, "EXCEPT ALL"),
      strcontains(local.medallion_notebook_content, "Gold sales must total 390.00"),
      !strcontains(local.medallion_notebook_content, "$${"),
    ])
    error_message = "The deployed source must render all qualified names and contain repeatable Delta writes, cleaning, deterministic deduplication, aggregation, and exact result checks."
  }
}

run "custom_catalog_and_prefix" {
  command = plan

  variables {
    medallion_catalog_name  = "learning-catalog"
    medallion_schema_prefix = "learner_01"
  }

  assert {
    condition = alltrue([
      output.medallion.catalog_name == "learning-catalog",
      output.medallion.notebook_path == "/Shared/learner_01",
      output.medallion.tables.bronze == "learning-catalog.learner_01_bronze.orders_raw",
      output.medallion.tables.silver == "learning-catalog.learner_01_silver.orders",
      output.medallion.tables.gold == "learning-catalog.learner_01_gold.daily_sales",
      !strcontains(local.medallion_notebook_content, "medallion_playground"),
      !strcontains(local.medallion_notebook_content, "`workspace`"),
    ])
    error_message = "Changing catalog and prefix must update every table name and the Notebook path, with no default names left in the SQL."
  }

  assert {
    condition = alltrue([
      for layer, config in local.medallion_layers :
      output.medallion.schemas[layer] == "learner_01_${layer}" &&
      module.medallion_schema[layer].catalog_name == "learning-catalog" &&
      length(regexall("`learning-catalog`\\.`learner_01_${layer}`\\.`${config.table_name}`", local.medallion_notebook_content)) >= 3
    ])
    error_message = "The custom catalog, including its hyphen, must be quoted consistently in every layer's SQL."
  }
}

run "accept_name_length_boundaries" {
  command = plan

  variables {
    medallion_catalog_name  = join("", [for i in range(255) : "a"])
    medallion_schema_prefix = join("", [for i in range(248) : "b"])
  }

  assert {
    condition = alltrue([
      length(output.medallion.catalog_name) == 255,
      length(output.medallion.schemas.bronze) == 255,
      length(output.medallion.schemas.silver) == 255,
      length(output.medallion.schemas.gold) == 253,
    ])
    error_message = "The longest accepted prefix must leave space for every layer suffix."
  }
}

run "accept_short_prefix" {
  command = plan
  variables {
    medallion_schema_prefix = "a"
  }
  assert {
    condition     = output.medallion.schemas.bronze == "a_bronze" && output.medallion.notebook_path == "/Shared/a"
    error_message = "A single-letter prefix must be accepted."
  }
}

run "disable_medallion_explicitly" {
  command = plan
  variables {
    medallion_catalog_name = null
  }
  assert {
    condition = alltrue([
      output.medallion == null,
      length(module.medallion_schema) == 0,
      length(module.medallion_notebook) == 0,
      local.medallion_notebook_content == null,
      jsonencode(local.medallion_tables) == "{}",
      output.dashboard_count == 0,
    ])
    error_message = "An explicit null catalog must retain read-only behavior without rendering or provisioning the hands-on."
  }
}

run "reject_empty_catalog" {
  command = plan
  variables {
    medallion_catalog_name = ""
  }
  expect_failures = [var.medallion_catalog_name]
}

run "reject_catalog_sql_injection" {
  command = plan
  variables {
    medallion_catalog_name = "workspace`; DROP CATALOG workspace; --"
  }
  expect_failures = [var.medallion_catalog_name]
}

run "reject_overlong_catalog" {
  command = plan
  variables {
    medallion_catalog_name = join("", [for i in range(256) : "a"])
  }
  expect_failures = [var.medallion_catalog_name]
}

run "reject_hive_metastore" {
  command = plan
  variables {
    medallion_catalog_name = "hive_metastore"
  }
  expect_failures = [var.medallion_catalog_name]
}

run "reject_system_catalog" {
  command = plan
  variables {
    medallion_catalog_name = "system"
  }
  expect_failures = [var.medallion_catalog_name]
}

run "reject_empty_prefix" {
  command = plan
  variables {
    medallion_schema_prefix = ""
  }
  expect_failures = [var.medallion_schema_prefix]
}

run "reject_prefix_path" {
  command = plan
  variables {
    medallion_schema_prefix = "../shared"
  }
  expect_failures = [var.medallion_schema_prefix]
}

run "reject_overlong_prefix" {
  command = plan
  variables {
    medallion_schema_prefix = join("", [for i in range(249) : "a"])
  }
  expect_failures = [var.medallion_schema_prefix]
}
