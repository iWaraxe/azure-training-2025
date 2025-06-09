variable "name" {
  description = "Name of the resource group"
  type        = string
  
  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters."
  }
}

variable "location" {
  description = "Azure region for the resource group"
  type        = string
  
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

variable "tags" {
  description = "Tags to be applied to the resource group"
  type        = map(string)
  default     = {}
}