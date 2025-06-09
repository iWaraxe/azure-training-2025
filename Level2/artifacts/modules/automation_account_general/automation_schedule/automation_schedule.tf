# https://github.com/scalair/terraform-azure-automation-schedule
resource "azurerm_automation_schedule" "schedule" {
  name                    = var.name
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  frequency               = var.frequency
  interval                = var.interval
  start_time              = var.start_time
  expiry_time             = var.expiry_time
  timezone                = var.timezone
  # (Optional) Only valid when frequency is Week:
  week_days               = var.week_days
  # (Optional) Must be between 1 and 31. -1 for last day of the month. Only valid when frequency is Month
  month_days              = var.month_days
  # (Optional) List of occurrences of days within a month. Only valid when frequency is Month
  dynamic monthly_occurrence {
    for_each = var.monthly_occurrences
    content {
      day                 = monthly_occurrence.value.day
      occurrence          = monthly_occurrence.value.occurrence
    }
  }
  description             = var.description
}

resource "azurerm_automation_job_schedule" "job_schedule" {
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  schedule_name           = azurerm_automation_schedule.schedule.name
  runbook_name            = var.runbook_name
  parameters              = var.parameters
}