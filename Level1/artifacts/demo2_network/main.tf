# Terraform strongly recommends using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Configure the Microsoft Azure Provider
# This tells Terraform where resources need to be created
provider "azurerm" {
  features {}
  # Authentication is handled via Azure CLI or environment variables
}

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
  description = "First two octets of the IP address range (e.g., 10.0)"
  type        = string
}

# Local variables for common configurations
locals {
  common_tags = {
    Environment = terraform.workspace
    ManagedBy   = "Terraform"
    Project     = "AzureTraining"
    CreatedDate = timestamp()
  }
}
# Create or update resource group
# Syntax explanation:
# Resource type  |  Azure provider resource name  |  Friendly name for output and resource reference  |  Resource properties
#       ⇣                       ⇣                                         ⇣                                    ⇣
#    resource      "azurerm_resource_group"                    "for_application"                           {}

resource "azurerm_resource_group" "for_application" {
  name     = var.resource_group_name
  location = var.environment_region
  tags     = local.common_tags
}

# Network Security Group for application subnets
resource "azurerm_network_security_group" "for_application_network" {
  name                = "${var.resource_group_name}-nsg"
  location            = azurerm_resource_group.for_application.location
  resource_group_name = azurerm_resource_group.for_application.name
  tags                = local.common_tags
}

# HTTP inbound rule
resource "azurerm_network_security_rule" "in_http_nsg_rules_for_application_network" {
  name                        = "AllowHTTP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "80"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name        = azurerm_resource_group.for_application.name
  network_security_group_name = azurerm_network_security_group.for_application_network.name
}

# HTTPS inbound rule
resource "azurerm_network_security_rule" "in_https_nsg_rules_for_application_network" {
  name                        = "AllowHTTPS"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "443"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name        = azurerm_resource_group.for_application.name
  network_security_group_name = azurerm_network_security_group.for_application_network.name
}

# Virtual Network
resource "azurerm_virtual_network" "for_application" {
  name                = "${var.resource_group_name}-vnet"
  location            = azurerm_resource_group.for_application.location
  resource_group_name = azurerm_resource_group.for_application.name
  address_space       = ["${var.address_mask}.0.0/16"]
  dns_servers         = ["168.63.129.16"] # Azure DNS
  tags                = local.common_tags
}

# Backend Subnet (separate resource - modern pattern)
resource "azurerm_subnet" "backend" {
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.for_application.name
  virtual_network_name = azurerm_virtual_network.for_application.name
  address_prefixes     = ["${var.address_mask}.1.0/24"]
}

# Frontend Subnet
resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.for_application.name
  virtual_network_name = azurerm_virtual_network.for_application.name
  address_prefixes     = ["${var.address_mask}.2.0/24"]
}

# Associate NSG with Backend subnet
resource "azurerm_subnet_network_security_group_association" "backend" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.for_application_network.id
}

# Associate NSG with Frontend subnet
resource "azurerm_subnet_network_security_group_association" "frontend" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.for_application_network.id
}

# Outputs for reference
output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.for_application.id
}

output "backend_subnet_id" {
  description = "The ID of the backend subnet"
  value       = azurerm_subnet.backend.id
}

output "frontend_subnet_id" {
  description = "The ID of the frontend subnet"
  value       = azurerm_subnet.frontend.id
}

