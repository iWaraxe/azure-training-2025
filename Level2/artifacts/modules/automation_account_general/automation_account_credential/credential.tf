resource "azurerm_automation_credential" "credential" {
  name                    = var.name
  resource_group_name     = element(split("/", var.automation_account_id), 4)
  automation_account_name = element(split("/", var.automation_account_id), 8)
  username                = var.username
  password                = var.password
  description             = "This is an example credential"
}