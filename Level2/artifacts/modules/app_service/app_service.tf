# Modern App Service Plan (replaces deprecated azurerm_app_service_plan)
resource "azurerm_service_plan" "app_service_plan" {
  name                = var.app_service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Windows" # Umbraco typically runs on Windows
  sku_name            = var.sku_name
  tags                = var.tags
}

# Modern Windows Web Apps (replaces deprecated azurerm_app_service)
resource "azurerm_windows_web_app" "app_service" {
  for_each            = var.app_services
  name                = each.value
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.app_service_plan.id
  tags                = var.tags

  site_config {
    # Modern .NET configuration for Umbraco
    always_on                         = true
    use_32_bit_worker                 = false
    managed_pipeline_mode            = "Integrated"
    default_documents                = ["default.htm", "default.html", "default.aspx", "index.htm", "index.html"]
    http2_enabled                    = true
    minimum_tls_version              = "1.2"
    scm_minimum_tls_version          = "1.2"
    ftps_state                       = "FtpsOnly"
    remote_debugging_enabled         = false
    
    # Application stack for .NET
    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v6.0" # Modern .NET for Umbraco 10+
    }
  }

  # App settings including Application Insights integration
  app_settings = merge(var.app_settings, {
    "WEBSITE_NODE_DEFAULT_VERSION" = "18.17.1"
    "WEBSITE_RUN_FROM_PACKAGE"     = "1"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "false"
    "ENABLE_ORYX_BUILD"            = "false"
  })

  # Connection strings for databases
  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  # HTTPS only for security
  https_only = true

  # Identity for accessing Azure resources
  identity {
    type = "SystemAssigned"
  }

  # Backup configuration (optional)
  dynamic "backup" {
    for_each = var.enable_backup ? [1] : []
    content {
      name     = "${each.value}-backup"
      enabled  = true
      schedule {
        frequency_interval       = 1
        frequency_unit          = "Day"
        keep_at_least_one_backup = true
        retention_period_days   = 7
      }
      storage_account_url = var.backup_storage_account_url
    }
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to app_settings that might be managed externally
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}