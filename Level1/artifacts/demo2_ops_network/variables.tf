# Global variables for TF template

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "environment_region" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "address_mask" {
  description = "First two octets of the IP address range (e.g., 10.1)"
  type        = string
}

# Microsoft Entra ID (formerly Azure AD) configuration for VPN
variable "entra_tenant_id" {
  description = "Microsoft Entra ID tenant ID for VPN authentication"
  type        = string
  default     = ""
}

variable "entra_audience" {
  description = "Microsoft Entra ID audience for VPN authentication"
  type        = string
  default     = "c632b3df-fb67-4d84-bdcf-b95ad541b5c8" # Default Azure VPN Client
}

variable "entra_issuer" {
  description = "Microsoft Entra ID issuer for VPN authentication"
  type        = string
  default     = ""
}

# Legacy variable names for backward compatibility (deprecated)
variable "aad_tenant" {
  description = "[DEPRECATED] Use entra_tenant_id instead. Azure AD tenant for VPN authentication"
  type        = string
  default     = ""
}

variable "aad_audience" {
  description = "[DEPRECATED] Use entra_audience instead. Azure AD audience for VPN authentication"
  type        = string
  default     = "c632b3df-fb67-4d84-bdcf-b95ad541b5c8"
}

variable "aad_issuer" {
  description = "[DEPRECATED] Use entra_issuer instead. Azure AD issuer for VPN authentication"
  type        = string
  default     = ""
}