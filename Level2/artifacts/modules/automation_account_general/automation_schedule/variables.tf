variable "name" {
  type        = string
  description = " (Required) The name of a Runbook to link to a Schedule. It needs to be in the same Automation Account as the Schedule and Job Schedule. Changing this forces a new resource to be created."
}
variable "resource_group_name" {
  description = "(Required) The name of the resource group in which the Runbook is created."
}
variable "automation_account_name" {
  type        = string
  description = "(Required) The name of the automation account in which the Runbook is created. Changing this forces a new resource to be created."
}
variable "frequency" {
  type        = string
  description = "(Required) The frequency of the schedule. - can be either OneTime, Day, Hour, Week, or Month."
}
variable "interval" {
  type        = number
  description = "(Optional) The number of frequencys between runs. Only valid when frequency is Day, Hour, Week, or Month and defaults to 1."
  default     = null
}
variable "start_time"{
  type        = string
  description = "(Optional) Start time of the schedule. Must be at least five minutes in the future. Defaults to seven minutes in the future from the time the resource is created."
  default     = null
}
variable "expiry_time" {
  type        = string
  description = "(Optional) The end time of the schedule."
  default     = null
}
variable "timezone" {
  type        = string
  description = "(Optional) The timezone of the start time. Defaults to UTC. possible values see: https://msdn.microsoft.com/en-us/library/ms912391(v=winembedded.11).aspx"
}
variable "week_days" {
  type        = list
  description = "(Optional) List of days of the week that the job should execute on. Only valid when frequency is Week."
  default     = null
}
variable "month_days" {
  type        = list
  description = "(Optional) List of days of the month that the job should execute on. Must be between 1 and 31. -1 for last day of the month. Only valid when frequency is Month."
  default     = null
}
variable "monthly_occurrences" {
  type        = map(string)
  description = "tags"
  default = {}
}
variable "description" {
  type        = string
  description = "(Optional) A description for this Schedule."
  default     = "Schedule created by Terraform"
}
variable "runbook_name" {
  type        = string
  description = " (Required) The name of a Runbook to link to a Schedule. It needs to be in the same Automation Account as the Schedule and Job Schedule. Changing this forces a new resource to be created."
}
variable "parameters" {
  type        = map(any)
  description = "(Optional) A map of key/value pairs corresponding to the arguments that can be passed to the Runbook. Changing this forces a new resource to be created."
  default = {}
}