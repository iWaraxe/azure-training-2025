resource "azurerm_sql_server" "azure_sql_server" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.admin_login
  administrator_login_password = var.admin_password

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_sql_firewall_rule" "rule" {
  for_each            = var.firewall_list
  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = azurerm_sql_server.azure_sql_server.name
  start_ip_address    = split(":", each.value)[0]
  end_ip_address      = split(":", each.value)[1]
}

