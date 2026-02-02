resource "azurerm_postgresql_flexible_server" "this" {
  name                          = "psqlfs-${var.name}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.postgresql_version
  administrator_login           = var.administrator_login
  administrator_password        = var.administrator_password
  zone                          = var.zone
  sku_name                      = var.sku_name
  tags                          = var.tags
  public_network_access_enabled = true

  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = true
    tenant_id                     = var.tenant_id
  }
}

# Firewall rule to allow all Azure services and external access
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_all" {
  name             = "AllowAll"
  server_id        = azurerm_postgresql_flexible_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}
