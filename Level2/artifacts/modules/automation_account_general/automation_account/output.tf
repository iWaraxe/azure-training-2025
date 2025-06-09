output "id" {
  value = azurerm_automation_account.automation_account.id
}

output "name" {
  value = azurerm_automation_account.automation_account.name
}
# output "name" {
#   value = element(
#     split("/", azurerm_automation_account.automation_account.id),
#     8,
#   )
# }

