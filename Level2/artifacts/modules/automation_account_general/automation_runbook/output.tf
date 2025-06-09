output "id" {
  value = azurerm_automation_runbook.automation_runbook.id
}

output "name" {
  value = element(
    split("/", azurerm_automation_runbook.automation_runbook.id),
    10,
  )
}

