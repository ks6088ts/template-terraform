resource "azurerm_eventgrid_topic" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  input_schema                  = var.input_schema
  public_network_access_enabled = true
  local_auth_enabled            = false
  tags                          = var.tags
}

resource "azurerm_role_assignment" "event_grid_data_sender" {
  count = var.operator_principal_id == null ? 0 : 1

  scope                = azurerm_eventgrid_topic.this.id
  role_definition_name = "EventGrid Data Sender"
  principal_id         = var.operator_principal_id
}
