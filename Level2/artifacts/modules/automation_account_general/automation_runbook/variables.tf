variable "resource_group_name" {
}

variable "location" {
}

variable "automation_account_name" {
}

variable "runbook_type" {
}

variable "publish_content_link" {
}

variable "name_runbook" {
}

variable "name_link_schedule" {
  default = ""
}

variable "name_schedule" {
  default = ""
}

variable "name_automation_ac" {
  default = ""
}

variable "content" {
}

variable "frequency" {
  default = ""
}

variable "interval" {
  default = ""
}

variable "timezone" {
  default = ""
}

variable "start_time" {
  default = ""
}

variable "week_days" {
  default = []
}
