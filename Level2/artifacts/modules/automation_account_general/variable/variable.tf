resource "azurerm_automation_variable_string" "variable" {
  for_each                = var.variables
  name                    = each.key
  value                   = each.value
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
}

