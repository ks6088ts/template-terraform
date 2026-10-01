resource "azurerm_eventhub_namespace" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  capacity                      = var.capacity
  public_network_access_enabled = true
  local_authentication_enabled  = false
  minimum_tls_version           = "1.2"
  tags                          = var.tags
}

resource "azurerm_eventhub" "this" {
  name              = var.eventhub_name
  namespace_id      = azurerm_eventhub_namespace.this.id
  partition_count   = var.partition_count
  message_retention = var.message_retention

  lifecycle {
    precondition {
      condition     = var.sku != "Basic" || var.message_retention == 1
      error_message = "Basic Event Hubs namespaces require message_retention to be 1 day."
    }
  }
}

resource "azurerm_role_assignment" "data_sender" {
  count = var.operator_principal_id == null ? 0 : 1

  scope                = azurerm_eventhub_namespace.this.id
  role_definition_name = "Azure Event Hubs Data Sender"
  principal_id         = var.operator_principal_id
}

resource "azurerm_role_assignment" "data_receiver" {
  count = var.operator_principal_id == null ? 0 : 1

  scope                = azurerm_eventhub_namespace.this.id
  role_definition_name = "Azure Event Hubs Data Receiver"
  principal_id         = var.operator_principal_id
}
