resource "azurerm_monitor_activity_log_alert" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = "global"
  scopes              = var.scopes
  tags                = var.tags

  criteria {
    category       = "Administrative"
    resource_group = var.resource_group_filter
  }

  dynamic "action" {
    for_each = var.action_group_ids
    content {
      action_group_id = action.value
    }
  }
}
