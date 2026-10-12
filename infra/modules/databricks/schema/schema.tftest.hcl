mock_provider "databricks" {
  override_during = plan

  mock_resource "databricks_schema" {
    defaults = {
      id = "workspace.bronze"
    }
  }
}

variables {
  catalog_name = "workspace"
  name         = "bronze"
}

run "protect_schema_by_default" {
  command = plan

  assert {
    condition = alltrue([
      databricks_schema.this.catalog_name == "workspace",
      databricks_schema.this.name == "bronze",
      databricks_schema.this.comment == null,
      databricks_schema.this.force_destroy == false,
      output.id == databricks_schema.this.id,
      output.name == "bronze",
      output.catalog_name == "workspace",
    ])
    error_message = "The module must create one schema in the existing catalog, protect its contents by default, and forward its outputs."
  }
}

run "forward_custom_configuration" {
  command = plan

  variables {
    catalog_name  = "learning-catalog"
    name          = "learning_silver"
    comment       = "Disposable learning data"
    force_destroy = true
  }

  assert {
    condition = alltrue([
      databricks_schema.this.catalog_name == "learning-catalog",
      output.catalog_name == "learning-catalog",
      output.name == "learning_silver",
      databricks_schema.this.comment == "Disposable learning data",
      databricks_schema.this.force_destroy,
    ])
    error_message = "Catalog, name, comment, and explicit force_destroy must reach the resource unchanged."
  }
}

run "accept_maximum_name_lengths" {
  command = plan

  variables {
    catalog_name = join("", [for i in range(255) : "a"])
    name         = join("", [for i in range(255) : "b"])
  }

  assert {
    condition     = length(output.catalog_name) == 255 && length(output.name) == 255
    error_message = "Names at the supported length boundary must be accepted."
  }
}

run "reject_empty_catalog" {
  command = plan
  variables {
    catalog_name = ""
  }
  expect_failures = [var.catalog_name]
}

run "reject_qualified_catalog" {
  command = plan
  variables {
    catalog_name = "catalog.schema"
  }
  expect_failures = [var.catalog_name]
}

run "reject_overlong_catalog" {
  command = plan
  variables {
    catalog_name = join("", [for i in range(256) : "a"])
  }
  expect_failures = [var.catalog_name]
}

run "reject_empty_schema" {
  command = plan
  variables {
    name = ""
  }
  expect_failures = [var.name]
}

run "reject_schema_path" {
  command = plan
  variables {
    name = "bronze/orders"
  }
  expect_failures = [var.name]
}

run "reject_overlong_schema" {
  command = plan
  variables {
    name = join("", [for i in range(256) : "a"])
  }
  expect_failures = [var.name]
}
