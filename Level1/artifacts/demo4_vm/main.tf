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

# Local variables
locals {
  common_tags = {
    Environment = terraform.workspace
    ManagedBy   = "Terraform"
    Project     = "AzureTraining"
    CreatedDate = timestamp()
  }
  
  vm_name = "${var.resource_group_name}-jenkins-01"
}

# Data sources for existing resources
data "azurerm_key_vault" "ops_secret_storage" {
  name                = "${substr(replace(var.resource_group_name, "-", ""), 0, 20)}kv01"
  resource_group_name = var.resource_group_name
}

data "azurerm_key_vault_secret" "jenkins_login" {
  name         = "jenkins-vm-admin-login"
  key_vault_id = data.azurerm_key_vault.ops_secret_storage.id
}

data "azurerm_key_vault_secret" "jenkins_password" {
  name         = "jenkins-vm-admin-password"
  key_vault_id = data.azurerm_key_vault.ops_secret_storage.id
}

data "azurerm_subnet" "ops_subnet" {
  name                 = "backend"
  virtual_network_name = "${var.resource_group_name}-vnet"
  resource_group_name  = var.resource_group_name
}

# Public IP for Load Balancer
resource "azurerm_public_ip" "jenkins" {
  name                = "${local.vm_name}-pip"
  location            = var.environment_region
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

# Load Balancer
resource "azurerm_lb" "jenkins" {
  name                = "${local.vm_name}-lb"
  location            = var.environment_region
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tags                = local.common_tags

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.jenkins.id
  }
}

# Load Balancer Backend Pool
resource "azurerm_lb_backend_address_pool" "jenkins" {
  loadbalancer_id = azurerm_lb.jenkins.id
  name            = "BackEndAddressPool"
}

# Load Balancer Health Probe
resource "azurerm_lb_probe" "jenkins" {
  loadbalancer_id = azurerm_lb.jenkins.id
  name            = "jenkins-health-probe"
  port            = 8080
  protocol        = "Tcp"
}

# Load Balancer Rule for Jenkins
resource "azurerm_lb_rule" "jenkins" {
  loadbalancer_id                = azurerm_lb.jenkins.id
  name                           = "Jenkins"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.jenkins.id]
  probe_id                       = azurerm_lb_probe.jenkins.id
}

# Network Interface
resource "azurerm_network_interface" "jenkins" {
  name                = "${local.vm_name}-nic"
  location            = var.environment_region
  resource_group_name = var.resource_group_name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.ops_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Associate Network Interface with Load Balancer Backend Pool
resource "azurerm_network_interface_backend_address_pool_association" "jenkins" {
  network_interface_id    = azurerm_network_interface.jenkins.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.jenkins.id
}

# Managed Disk for Jenkins data
resource "azurerm_managed_disk" "jenkins_data" {
  name                 = "${local.vm_name}-data-disk"
  location             = var.environment_region
  resource_group_name  = var.resource_group_name
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = 128
  tags                 = local.common_tags
}

# Linux Virtual Machine (modern resource type)
resource "azurerm_linux_virtual_machine" "jenkins" {
  name                = local.vm_name
  location            = var.environment_region
  resource_group_name = var.resource_group_name
  size                = "Standard_B2s" # Updated to newer, cost-effective size
  tags                = local.common_tags

  # For high availability, we'd use availability zones instead of availability sets
  zone = "1"

  admin_username                  = data.azurerm_key_vault_secret.jenkins_login.value
  admin_password                  = data.azurerm_key_vault_secret.jenkins_password.value
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.jenkins.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Cloud-init configuration for Jenkins installation
  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    jenkins_admin_user = data.azurerm_key_vault_secret.jenkins_login.value
  }))

  # Boot diagnostics with managed storage account
  boot_diagnostics {
    storage_account_uri = null # Uses managed storage account
  }
}

# Attach data disk to VM
resource "azurerm_virtual_machine_data_disk_attachment" "jenkins" {
  managed_disk_id    = azurerm_managed_disk.jenkins_data.id
  virtual_machine_id = azurerm_linux_virtual_machine.jenkins.id
  lun                = "10"
  caching            = "ReadWrite"
}

# Outputs
output "jenkins_public_ip" {
  description = "The public IP address of the Jenkins server"
  value       = azurerm_public_ip.jenkins.ip_address
}

output "jenkins_url" {
  description = "The URL to access Jenkins"
  value       = "http://${azurerm_public_ip.jenkins.ip_address}:8080"
}

output "vm_id" {
  description = "The ID of the Jenkins VM"
  value       = azurerm_linux_virtual_machine.jenkins.id
}

output "admin_username" {
  description = "The admin username for the VM"
  value       = data.azurerm_key_vault_secret.jenkins_login.value
  sensitive   = true
}