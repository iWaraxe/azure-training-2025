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
}

# Variables
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

# Optional Entra ID (formerly Azure AD) configuration for VPN
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

# Local variables
locals {
  common_tags = {
    Environment = terraform.workspace
    ManagedBy   = "Terraform"
    Project     = "AzureTraining"
    CreatedDate = timestamp()
  }
  
  # Network Security Group rules for ops environment
  inbound_nsg_rules = [
    {
      name                       = "AllowHTTP"
      priority                   = 100
      protocol                   = "Tcp"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowHTTPS"
      priority                   = 200
      protocol                   = "Tcp"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowSecurityScanning"
      priority                   = 300
      protocol                   = "Tcp"
      destination_port_range     = "1000"
      source_address_prefix      = "10.0.0.0/8" # Restrict to private networks
      destination_address_prefix = "*"
    }
  ]
}

# Resource Group
resource "azurerm_resource_group" "resource_group_for_ops" {
  name     = var.resource_group_name
  location = var.environment_region
  tags     = local.common_tags
}

# Virtual Network for OPS workload
resource "azurerm_virtual_network" "vnet_for_ops_workload" {
  name                = "${var.resource_group_name}-vnet"
  location            = azurerm_resource_group.resource_group_for_ops.location
  resource_group_name = azurerm_resource_group.resource_group_for_ops.name
  address_space       = ["${var.address_mask}.0.0/16"]
  dns_servers         = ["168.63.129.16"] # Azure DNS
  tags                = local.common_tags
}

# Backend subnet for workloads
resource "azurerm_subnet" "subnet_for_ops_workload" {
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.resource_group_for_ops.name
  virtual_network_name = azurerm_virtual_network.vnet_for_ops_workload.name
  address_prefixes     = ["${var.address_mask}.1.0/24"]
}

# Gateway subnet (required for VPN Gateway)
resource "azurerm_subnet" "subnet_for_gateway" {
  name                 = "GatewaySubnet" # Name must be exactly "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.resource_group_for_ops.name
  virtual_network_name = azurerm_virtual_network.vnet_for_ops_workload.name
  address_prefixes     = ["${var.address_mask}.3.0/24"]
}

# Public IP for VPN Gateway
resource "azurerm_public_ip" "ip_for_gateway" {
  name                = "${var.resource_group_name}-vpn-pip"
  location            = azurerm_resource_group.resource_group_for_ops.location
  resource_group_name = azurerm_resource_group.resource_group_for_ops.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

# VPN Gateway
resource "azurerm_virtual_network_gateway" "development_vpn" {
  name                = "${var.resource_group_name}-vpn-gw"
  location            = azurerm_resource_group.resource_group_for_ops.location
  resource_group_name = azurerm_resource_group.resource_group_for_ops.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  active_active       = false
  enable_bgp          = false
  sku                 = "VpnGw1" # Updated to modern SKU
  generation          = "Generation1"
  tags                = local.common_tags

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.ip_for_gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.subnet_for_gateway.id
  }

  # Point-to-Site VPN configuration with modern authentication
  dynamic "vpn_client_configuration" {
    for_each = var.entra_tenant_id != "" ? [1] : []
    content {
      address_space        = ["172.2.0.0/24"]
      vpn_client_protocols = ["OpenVPN"]
      vpn_auth_types       = ["AAD"]
      
      # Microsoft Entra ID (formerly Azure AD) authentication
      aad_tenant   = "https://login.microsoftonline.com/${var.entra_tenant_id}/"
      aad_audience = var.entra_audience
      aad_issuer   = "https://sts.windows.net/${var.entra_tenant_id}/"
    }
  }
}

# Network Security Group for OPS network
resource "azurerm_network_security_group" "nsg_for_ops_network" {
  name                = "${var.resource_group_name}-nsg"
  location            = azurerm_resource_group.resource_group_for_ops.location
  resource_group_name = azurerm_resource_group.resource_group_for_ops.name
  tags                = local.common_tags
}

# Inbound NSG rules using for_each (modern pattern)
resource "azurerm_network_security_rule" "inbound_nsg_rules_for_ops_network" {
  for_each = { for rule in local.inbound_nsg_rules : rule.name => rule }

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = each.value.protocol
  source_port_range          = "*"
  destination_port_range     = each.value.destination_port_range
  source_address_prefix      = each.value.source_address_prefix
  destination_address_prefix = each.value.destination_address_prefix
  resource_group_name        = azurerm_resource_group.resource_group_for_ops.name
  network_security_group_name = azurerm_network_security_group.nsg_for_ops_network.name
}

# Associate NSG with backend subnet
resource "azurerm_subnet_network_security_group_association" "ops_subnet_nsg" {
  subnet_id                 = azurerm_subnet.subnet_for_ops_workload.id
  network_security_group_id = azurerm_network_security_group.nsg_for_ops_network.id
}

# Data sources for existing VNets (for peering)
# Note: These reference hardcoded names from the training environment
data "azurerm_virtual_network" "dev" {
  name                = "azis2dev-vnet"  # Updated to match new naming convention
  resource_group_name = "azis2dev"
}

data "azurerm_virtual_network" "qa" {
  name                = "azis2qa-vnet"   # Updated to match new naming convention
  resource_group_name = "azis2qa"
}

# VNet Peering: OPS to DEV
resource "azurerm_virtual_network_peering" "from_ops_to_dev" {
  name                      = "ops-to-dev"
  resource_group_name       = azurerm_resource_group.resource_group_for_ops.name
  virtual_network_name      = azurerm_virtual_network.vnet_for_ops_workload.name
  remote_virtual_network_id = data.azurerm_virtual_network.dev.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# VNet Peering: DEV to OPS
resource "azurerm_virtual_network_peering" "from_dev_to_ops" {
  name                      = "dev-to-ops"
  resource_group_name       = "azis2dev"
  virtual_network_name      = data.azurerm_virtual_network.dev.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_for_ops_workload.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# VNet Peering: OPS to QA
resource "azurerm_virtual_network_peering" "from_ops_to_qa" {
  name                      = "ops-to-qa"
  resource_group_name       = azurerm_resource_group.resource_group_for_ops.name
  virtual_network_name      = azurerm_virtual_network.vnet_for_ops_workload.name
  remote_virtual_network_id = data.azurerm_virtual_network.qa.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# VNet Peering: QA to OPS
resource "azurerm_virtual_network_peering" "from_qa_to_ops" {
  name                      = "qa-to-ops"
  resource_group_name       = "azis2qa"
  virtual_network_name      = data.azurerm_virtual_network.qa.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_for_ops_workload.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Outputs
output "vnet_id" {
  description = "The ID of the OPS virtual network"
  value       = azurerm_virtual_network.vnet_for_ops_workload.id
}

output "vpn_gateway_id" {
  description = "The ID of the VPN Gateway"
  value       = azurerm_virtual_network_gateway.development_vpn.id
}

output "vpn_gateway_public_ip" {
  description = "The public IP address of the VPN Gateway"
  value       = azurerm_public_ip.ip_for_gateway.ip_address
}

output "backend_subnet_id" {
  description = "The ID of the backend subnet"
  value       = azurerm_subnet.subnet_for_ops_workload.id
}