resource "azurerm_monitor_action_group" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  short_name          = var.short_name
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = var.email_addresses
    content {
      name                    = "email-${substr(sha256(email_receiver.value), 0, 24)}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }
}
