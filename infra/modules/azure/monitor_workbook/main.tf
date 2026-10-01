resource "azurerm_application_insights_workbook" "this" {
  name                = var.name
  display_name        = var.display_name
  resource_group_name = var.resource_group_name
  location            = var.location
  source_id           = lower(var.source_id)
  data_json           = var.data_json
  tags                = var.tags
}
