resource "azurerm_automation_account" "automation_account" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku_name = "Basic"
}

