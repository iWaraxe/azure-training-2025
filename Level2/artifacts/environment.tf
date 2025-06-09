########################
#     1. Provider      #
########################

# Terraform configuration
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Main Azure provider for resource deployment
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  
  # Modern authentication - use environment variables or Azure CLI
  # No hardcoded credentials in provider block
}

# Local variables for environment configuration
locals {
  environment = var.resource_group_name
  location    = var.location
  
  # Common tags for all resources
  common_tags = {
    Environment = local.environment
    ManagedBy   = "Terraform"
    Project     = "UmbracoCMS"
    CreatedDate = timestamp()
  }
}

# High workload applications configuration
locals {
  high_workload_applications = {
    umbraco-ui     = "${local.environment}-umbraco-ui"     # Umbraco CMS UI for project news
    umbraco-master = "${local.environment}-umbraco-master" # Umbraco CMS backend for content management
  }
}

# App Service Plan sizing
locals {
  # Modern App Service Plan SKUs
  high_workload_sku = "P1v3"  # Premium v3 - better performance than legacy Standard
  low_workload_sku  = "B2"    # Basic - cost-effective for development
}

# Database performance tiers (modernized to vCore model)
locals {
  # Modern SQL Database configuration using vCore model
  db_configuration = {
    dev = {
      sku_name                     = "S2"     # 50 DTU for development
      max_size_gb                  = 250
      auto_pause_delay_in_minutes  = 60      # Cost optimization
      min_capacity                 = 0.5
    }
    qa = {
      sku_name                     = "S3"     # 100 DTU for QA
      max_size_gb                  = 500
      auto_pause_delay_in_minutes  = null    # Always on for QA
      min_capacity                 = 1
    }
    production = {
      sku_name                     = "P1"     # Premium for production
      max_size_gb                  = 1024
      auto_pause_delay_in_minutes  = null    # Always on for production
      min_capacity                 = 2
    }
  }
  
  # Environment-specific database settings
  db_config = local.db_configuration[contains(keys(local.db_configuration), local.environment) ? local.environment : "dev"]
}

########################
#   2. Resources       #
########################

# Main Resource Group
module "main_resource_group" {
  source   = "./modules/resource_group"
  name     = local.environment
  location = local.location
  tags     = local.common_tags
}

# High workload App Service Plan and Apps
module "app_service_plan_high_workload_applications" {
  source                = "./modules/app_service"
  app_services          = local.high_workload_applications
  app_service_plan_name = "${local.environment}-high-workload-plan"
  location              = local.location
  resource_group_name   = module.main_resource_group.name
  sku_name              = local.high_workload_sku
  tags                  = local.common_tags
  
  # Modern App Service configuration
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"       = "1"
    "APPINSIGHTS_INSTRUMENTATIONKEY" = module.application_insights.instrumentation_key
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
  }
  
  depends_on = [module.main_resource_group]
}

# Application Insights for monitoring
module "application_insights" {
  source              = "./modules/application_insights"
  name                = "${local.environment}-appinsights"
  location            = local.location
  resource_group_name = module.main_resource_group.name
  tags                = local.common_tags
  
  depends_on = [module.main_resource_group]
}

# Azure SQL Server (modernized)
module "azure_sql_server" {
  source              = "./modules/azure_sql/sql_server"
  name                = "${lower(local.environment)}-sql-server"
  resource_group_name = module.main_resource_group.name
  location            = local.location
  admin_login         = var.azure_sql_server["admin_login"]
  admin_password      = var.azure_sql_server["admin_password"]
  tags                = local.common_tags
  
  # Modern security configuration
  azuread_administrator = {
    login_username = var.azure_sql_admin.login_username
    object_id      = var.azure_sql_admin.object_id
    tenant_id      = var.azure_sql_admin.tenant_id
  }
  
  # Network access rules
  firewall_rules = {
    "AllowAzureServices" = {
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    }
  }
  
  depends_on = [module.main_resource_group]
}

# Umbraco Main Database
module "UmbracoDB" {
  source              = "./modules/azure_sql/database"
  name                = "UmbracoDB"
  resource_group_name = module.main_resource_group.name
  location            = local.location
  server_name         = module.azure_sql_server.name
  sku_name            = local.db_config.sku_name
  max_size_gb         = local.db_config.max_size_gb
  tags                = local.common_tags
  
  # Modern features
  auto_pause_delay_in_minutes = local.db_config.auto_pause_delay_in_minutes
  min_capacity               = local.db_config.min_capacity
  
  depends_on = [module.azure_sql_server]
}

# Umbraco Users Database  
module "UmbracoUsers" {
  source              = "./modules/azure_sql/database"
  name                = "UmbracoUsers"
  resource_group_name = module.main_resource_group.name
  location            = local.location
  server_name         = module.azure_sql_server.name
  sku_name            = local.db_config.sku_name
  max_size_gb         = local.db_config.max_size_gb
  tags                = local.common_tags
  
  # Modern features
  auto_pause_delay_in_minutes = local.db_config.auto_pause_delay_in_minutes
  min_capacity               = local.db_config.min_capacity
  
  depends_on = [module.azure_sql_server]
}

# Traffic Manager for load balancing
module "main_website" {
  source              = "./modules/traffic_manager"
  name                = local.high_workload_applications["umbraco-ui"]
  resource_group_name = module.main_resource_group.name
  location            = "global" # Traffic Manager is global
  tags                = local.common_tags
  
  # Modern endpoint configuration
  primary_endpoint   = var.primary_endpoint_fqdn   # VM endpoint from Level 1
  secondary_endpoint = "${local.high_workload_applications["umbraco-ui"]}.azurewebsites.net"
  monitor_path       = "/umbraco"
  dns_ttl           = 30 # Faster failover
  
  depends_on = [module.app_service_plan_high_workload_applications]
}

# Key Vault for secrets management (modern approach)
module "key_vault" {
  source              = "./modules/key_vault"
  name                = "${substr(replace(local.environment, "-", ""), 0, 20)}kv"
  resource_group_name = module.main_resource_group.name
  location            = local.location
  tags                = local.common_tags
  
  # Store database connection strings
  secrets = {
    "UmbracoDB-ConnectionString"    = module.UmbracoDB.connection_string
    "UmbracoUsers-ConnectionString" = module.UmbracoUsers.connection_string
  }
  
  depends_on = [module.main_resource_group]
}

########################
#   3. Outputs         #
########################

# App Service outputs
output "app_service_urls" {
  description = "URLs of the deployed App Services"
  value = {
    umbraco_ui     = "https://${local.high_workload_applications["umbraco-ui"]}.azurewebsites.net"
    umbraco_master = "https://${local.high_workload_applications["umbraco-master"]}.azurewebsites.net"
  }
}

# Traffic Manager output
output "traffic_manager_url" {
  description = "Traffic Manager FQDN for load balancing"
  value       = module.main_website.fqdn
}

# Database outputs
output "sql_server_fqdn" {
  description = "SQL Server FQDN"
  value       = module.azure_sql_server.fqdn
  sensitive   = true
}

# Application Insights
output "application_insights_key" {
  description = "Application Insights instrumentation key"
  value       = module.application_insights.instrumentation_key
  sensitive   = true
}

# Key Vault
output "key_vault_uri" {
  description = "Key Vault URI"
  value       = module.key_vault.vault_uri
}