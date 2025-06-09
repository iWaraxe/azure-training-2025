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
  # Authentication methods:
  # 1. Azure CLI - az login (simplest for development)
  # 2. Service Principal - for CI/CD pipelines
  # 3. Managed Identity - for running from Azure resources
}

# Local variables to minimize hardcoding
locals {
  resource_group_name = "az-training-rg"
  location            = "eastus"
  
  # Common tags to apply to all resources
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
  name     = "${local.resource_group_name}-${terraform.workspace}"
  location = local.location
  tags     = local.common_tags
}

# Output the resource group details for reference
output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.for_application.name
}

output "resource_group_id" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.for_application.id
}

# Deployment steps:
# 1. terraform init          - Initialize Terraform and download providers
# 2. terraform workspace new dev  - Create development workspace (optional)
# 3. terraform plan          - Preview changes
# 4. terraform apply         - Deploy the resources
# 5. terraform destroy       - Clean up resources when done
