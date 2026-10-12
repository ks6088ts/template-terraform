locals {
  medallion_layers = var.medallion_catalog_name == null ? {} : {
    bronze = {
      schema_name = "${var.medallion_schema_prefix}_bronze"
      table_name  = "orders_raw"
    }
    silver = {
      schema_name = "${var.medallion_schema_prefix}_silver"
      table_name  = "orders"
    }
    gold = {
      schema_name = "${var.medallion_schema_prefix}_gold"
      table_name  = "daily_sales"
    }
  }
  medallion_tables = {
    for layer, config in local.medallion_layers :
    layer => "${var.medallion_catalog_name}.${config.schema_name}.${config.table_name}"
  }
  medallion_notebook_content = var.medallion_catalog_name == null ? null : templatefile(
    "${path.module}/notebooks/medallion.sql.tftpl",
    {
      for layer, config in local.medallion_layers :
      "${layer}_table" => "`${var.medallion_catalog_name}`.`${config.schema_name}`.`${config.table_name}`"
    },
  )
}

module "medallion_schema" {
  source   = "../../modules/databricks/schema"
  for_each = local.medallion_layers

  catalog_name  = var.medallion_catalog_name
  name          = each.value.schema_name
  comment       = "Disposable ${each.key} layer for the databricks_playground medallion hands-on"
  force_destroy = true
}

module "medallion_notebook" {
  source = "../../modules/databricks/notebook"
  count  = var.medallion_catalog_name == null ? 0 : 1

  path           = "/Shared/${var.medallion_schema_prefix}"
  language       = "SQL"
  content_base64 = base64encode(local.medallion_notebook_content)

  depends_on = [module.medallion_schema]
}
