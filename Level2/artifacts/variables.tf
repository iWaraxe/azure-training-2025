# Main environment configuration
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  
  validation {
    condition     = length(var.resource_group_name) > 0 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
  
  validation {
    condition = contains([
      "eastus", "eastus2", "westus", "westus2", "westus3", 
      "centralus", "southcentralus", "northcentralus",
      "westeurope", "northeurope", "uksouth", "ukwest",
      "francecentral", "germanywestcentral", "switzerlandnorth",
      "norwayeast", "swedencentral"
    ], var.location)
    error_message = "Location must be a valid Azure region."
  }
}

# Legacy provider configuration (deprecated - use environment variables instead)
variable "provider_default" {
  description = "[DEPRECATED] Provider configuration - use environment variables or Azure CLI instead"
  type        = map(string)
  default = {
    subscription_id = ""
    client_id       = ""
    client_secret   = ""
    tenant_id       = ""
  }
  sensitive = true
}

# Azure SQL Server configuration
variable "azure_sql_server" {
  description = "Azure SQL Server admin credentials"
  type        = map(string)
  sensitive   = true
  
  validation {
    condition     = length(var.azure_sql_server.admin_login) >= 1
    error_message = "SQL Server admin login is required."
  }
  
  validation {
    condition     = length(var.azure_sql_server.admin_password) >= 8
    error_message = "SQL Server admin password must be at least 8 characters."
  }
}

# Modern Azure AD/Entra ID admin configuration for SQL Server
variable "azure_sql_admin" {
  description = "Azure AD administrator for SQL Server"
  type = object({
    login_username = string
    object_id      = string
    tenant_id      = string
  })
  default = {
    login_username = ""
    object_id      = ""
    tenant_id      = ""
  }
}

# Primary endpoint for Traffic Manager (typically from Level 1 VM deployment)
variable "primary_endpoint_fqdn" {
  description = "Primary endpoint FQDN for Traffic Manager (e.g., from Level 1 VM)"
  type        = string
  default     = "www.terraform.io" # Placeholder - should be updated with actual VM endpoint
}

# Environment-specific configurations
variable "environment_config" {
  description = "Environment-specific configuration overrides"
  type = object({
    app_service_sku = optional(string, "P1v3")
    sql_sku_name    = optional(string, "S2")
    enable_backup   = optional(bool, true)
    enable_monitoring = optional(bool, true)
  })
  default = {}
}

# Security configuration
variable "security_config" {
  description = "Security-related configuration"
  type = object({
    enable_private_endpoints = optional(bool, false)
    enable_waf              = optional(bool, false)
    allowed_ip_ranges       = optional(list(string), [])
  })
  default = {}
}

# Monitoring and logging configuration  
variable "monitoring_config" {
  description = "Monitoring and logging configuration"
  type = object({
    log_retention_days     = optional(number, 30)
    enable_diagnostics     = optional(bool, true)
    alert_email_addresses  = optional(list(string), [])
  })
  default = {}
}