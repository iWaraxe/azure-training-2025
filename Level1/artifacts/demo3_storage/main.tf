# Terraform strongly recommends using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Configure the Microsoft Azure Provider
# This tells Terraform where resources need to be created
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Variables for configuration
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
  
  ops_credentials = {
    jenkins-vm-admin-login    = "jenkins-admin-${random_string.jenkins-vm-admin-login.result}"
    jenkins-vm-admin-password = random_password.jenkins-vm-admin-password.result
  }
}
# Generate random suffix for admin username
resource "random_string" "jenkins-vm-admin-login" {
  length  = 4
  upper   = false
  numeric = false
  lower   = true
  special = false
}

# Generate secure password for VM admin
# Azure requirement: 12-72 characters, must have 3 of: uppercase, lowercase, number, special
resource "random_password" "jenkins-vm-admin-password" {
  length           = 16
  special          = true
  override_special = "_%@"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Create Key Vault for storing secrets
resource "azurerm_key_vault" "ops_secret_storage" {
  name                        = "${substr(replace(var.resource_group_name, "-", ""), 0, 20)}kv01"
  location                    = var.environment_region
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  enabled_for_deployment      = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
  tags                        = local.common_tags

  # Network ACLs - restrict access
  network_acls {
    default_action = "Allow" # For training purposes - should be "Deny" in production
    bypass         = "AzureServices"
  }

  # Access policy for Terraform user/service principal
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Update", "Create", "Delete", "Recover", "Backup", "Restore"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
    ]

    certificate_permissions = [
      "Get", "List", "Update", "Create", "Delete", "Recover", "Backup", "Restore"
    ]
  }
}

# Store VM credentials in Key Vault
resource "azurerm_key_vault_secret" "secrets" {
  for_each     = local.ops_credentials
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.ops_secret_storage.id
  
  depends_on = [azurerm_key_vault.ops_secret_storage]
}

# Storage Account for ops feed/artifacts
resource "azurerm_storage_account" "ops_feed" {
  name                     = "${substr(replace(lower(var.resource_group_name), "-", ""), 0, 20)}st01"
  location                 = var.environment_region
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  tags                     = local.common_tags
  
  # Security settings
  min_tls_version                 = "TLS1_2"
  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = false
  
  # Enable blob encryption
  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
  }
}

# Storage Container for ops artifacts
resource "azurerm_storage_container" "ops_feed" {
  name                  = "opsfeed"
  storage_account_name  = azurerm_storage_account.ops_feed.name
  container_access_type = "private"
}

# Upload Jenkins installation package
resource "azurerm_storage_blob" "jenkins_installation" {
  name                   = "jenkins_install.zip"
  storage_account_name   = azurerm_storage_account.ops_feed.name
  storage_container_name = azurerm_storage_container.ops_feed.name
  type                   = "Block"
  source                 = "${path.module}/ops_feed/jenkins_install.zip" # ${path.module} = current directory
}

# Outputs
output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.ops_secret_storage.id
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.ops_secret_storage.vault_uri
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.ops_feed.name
}

output "storage_primary_access_key" {
  description = "The primary access key for the storage account"
  value       = azurerm_storage_account.ops_feed.primary_access_key
  sensitive   = true
}