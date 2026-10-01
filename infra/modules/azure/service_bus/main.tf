resource "azurerm_servicebus_namespace" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  capacity                      = var.sku == "Premium" ? var.premium_capacity : 0
  public_network_access_enabled = true
  local_auth_enabled            = false
  minimum_tls_version           = "1.2"
  tags                          = var.tags
}

resource "azurerm_servicebus_queue" "this" {
  name         = var.queue_name
  namespace_id = azurerm_servicebus_namespace.this.id
}

resource "azurerm_servicebus_topic" "this" {
  name         = var.topic_name
  namespace_id = azurerm_servicebus_namespace.this.id
}

resource "azurerm_servicebus_subscription" "this" {
  name               = var.subscription_name
  topic_id           = azurerm_servicebus_topic.this.id
  max_delivery_count = 10
}

resource "azurerm_role_assignment" "data_sender" {
  count = var.operator_principal_id == null ? 0 : 1

  scope                = azurerm_servicebus_namespace.this.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = var.operator_principal_id
}

resource "azurerm_role_assignment" "data_receiver" {
  count = var.operator_principal_id == null ? 0 : 1

  scope                = azurerm_servicebus_namespace.this.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = var.operator_principal_id
}
