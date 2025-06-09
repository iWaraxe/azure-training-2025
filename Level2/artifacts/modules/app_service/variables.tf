variable "app_services" {
  description = "Map of app service names"
  type        = map(string)
  
  validation {
    condition     = length(var.app_services) > 0
    error_message = "At least one app service must be defined."
  }
}

variable "app_service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
  
  validation {
    condition     = length(var.app_service_plan_name) > 0
    error_message = "App Service Plan name cannot be empty."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "sku_name" {
  description = "The SKU name for the App Service Plan (e.g., P1v3, B2, S1)"
  type        = string
  default     = "P1v3"
  
  validation {
    condition = can(regex("^(F1|D1|B[1-3]|S[1-3]|P[1-3]v[2-3]|I[1-6]v[2]|WS[1-3]|PC[2-6]|EP[1-3]|Y1)$", var.sku_name))
    error_message = "SKU name must be a valid App Service Plan SKU."
  }
}

variable "location" {
  description = "Azure region for the App Service"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {}
}

variable "app_settings" {
  description = "Application settings for the App Services"
  type        = map(string)
  default     = {}
}

variable "connection_strings" {
  description = "Connection strings for the App Services"
  type = list(object({
    name  = string
    type  = string
    value = string
  }))
  default = []
}

variable "enable_backup" {
  description = "Enable backup for App Services"
  type        = bool
  default     = false
}

variable "backup_storage_account_url" {
  description = "Storage account URL for backups (required if enable_backup is true)"
  type        = string
  default     = ""
}

# Legacy variables for backward compatibility (deprecated)
variable "sku_tier" {
  description = "[DEPRECATED] Use sku_name instead. SKU tier for the App Service Plan"
  type        = string
  default     = ""
}

variable "sku_size" {
  description = "[DEPRECATED] Use sku_name instead. SKU size for the App Service Plan" 
  type        = string
  default     = ""
}