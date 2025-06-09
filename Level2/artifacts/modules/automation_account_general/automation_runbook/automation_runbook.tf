resource "azurerm_automation_runbook" "automation_runbook" {
  name                      = var.name_runbook
  location                  = var.location
  resource_group_name       = var.resource_group_name
  automation_account_name   = var.automation_account_name
  log_verbose               = "true"
  log_progress              = "true"
  runbook_type              = var.runbook_type

  publish_content_link {
    uri = var.publish_content_link
  }

  content = var.content
}
