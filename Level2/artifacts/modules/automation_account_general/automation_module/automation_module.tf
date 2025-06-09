resource "azurerm_automation_module" "az_accounts" {
  count                   = contains(var.name, "Az.Accounts") == true ? 1:0
  name                    = "Az.Accounts"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name

  module_link {
    uri = "https://psg-prod-eastus.azureedge.net/packages/az.accounts.2.3.0.nupkg"
  }
}
resource "azurerm_automation_module" "az_resources" {
  depends_on              = [azurerm_automation_module.az_accounts]
  count                   = contains(var.name, "Az.Resources") == true ? 1:0
  name                    = "Az.Resources"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name

  module_link {
    uri = "https://psg-prod-eastus.azureedge.net/packages/az.resources.4.1.0.nupkg"
  }
}
resource "azurerm_automation_module" "az_storage" {
  depends_on              = [azurerm_automation_module.az_accounts]
  count                   = contains(var.name, "Az.Storage") == true ? 1:0
  name                    = "Az.Storage"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name

  module_link {
    uri = "https://psg-prod-eastus.azureedge.net/packages/az.storage.3.7.0.nupkg"
  }
}
resource "azurerm_automation_module" "az_profile" {
  depends_on              = [azurerm_automation_module.az_accounts]
  count                   = contains(var.name, "Az.Profile") == true ? 1:0
  name                    = "Az.Profile"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name

  module_link {
    uri = "https://devopsgallerystorage.blob.core.windows.net/packages/az.profile.0.7.0.nupkg"
  }
}
resource "azurerm_automation_module" "az_table" {
  depends_on              = [azurerm_automation_module.az_resources]
  count                   = contains(var.name, "AzTable") == true ? 1:0
  name                    = "AzTable"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name

  module_link {
    uri = "https://psg-prod-eastus.azureedge.net/packages/aztable.2.1.0.nupkg"
  }
}

# Az.Websites
resource "azurerm_automation_module" "az_websites" {
  depends_on              = [azurerm_automation_module.az_resources]
  count                   = contains(var.name, "Az.Websites") == true ? 1:0
  name                    = "Az.Websites"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name

  module_link {
    uri = "https://psg-prod-eastus.azureedge.net/packages/az.websites.2.6.0.nupkg"
  }
}
resource "azurerm_automation_module" "az_trafficManager" {
  depends_on              = [azurerm_automation_module.az_resources]
  count                   = contains(var.name, "Az.TrafficManager") == true ? 1:0
  name                    = "Az.TrafficManager"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name

  module_link {
    uri = "https://psg-prod-eastus.azureedge.net/packages/az.trafficmanager.1.0.4.nupkg"
  }
}
#Az.Automation
resource "azurerm_automation_module" "az_automation" {
  depends_on              = [azurerm_automation_module.az_resources]
  count                   = contains(var.name, "Az.Automation") == true ? 1:0
  name                    = "Az.Automation"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name

  module_link {
    uri = "https://psg-prod-eastus.azureedge.net/packages/az.automation.1.7.0.nupkg"
  }
}
# Az.SQL (for Backup-AzureSQLDatabases.ps1)
resource "azurerm_automation_module" "az_sql" {
  depends_on              = [azurerm_automation_module.az_resources]
  count                   = contains(var.name, "Az.Sql") == true ? 1:0
  name                    = "Az.Sql"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name

  module_link {
    uri = "https://psg-prod-eastus.azureedge.net/packages/az.sql.3.1.0.nupkg"
  }
}
# NuGet (for Backup-AzureSQLDatabases.ps1)
resource "azurerm_automation_module" "nuget" {
  depends_on              = [azurerm_automation_module.az_resources]
  count                   = contains(var.name, "Nuget") == true ? 1:0
  name                    = "Nuget"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name

  module_link {
    uri = "https://psg-prod-eastus.azureedge.net/packages/nuget.1.3.3.nupkg"
  }
}
# PoshRSJob (for Backup-AzureSQLDatabases.ps1)
resource "azurerm_automation_module" "poshrsjob" {
  depends_on              = [azurerm_automation_module.az_resources]
  count                   = contains(var.name, "PoshRSJob") == true ? 1:0
  name                    = "PoshRSJob"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name

  module_link {
    uri = "https://psg-prod-eastus.azureedge.net/packages/poshrsjob.1.7.4.4.nupkg"
  }
}

# SqlServer (for Backup-AzureSQLDatabases.ps1)
resource "azurerm_automation_module" "sqlserver" {
  depends_on              = [azurerm_automation_module.az_resources]
  count                   = contains(var.name, "SqlServer") == true ? 1:0
  name                    = "SqlServer"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name

  module_link {
    uri = "https://psg-prod-eastus.azureedge.net/packages/sqlserver.21.1.18245.nupkg"
  }
}

# Pester
resource "azurerm_automation_module" "Pester" {
  depends_on              = [azurerm_automation_module.az_resources]
  count                   = contains(var.name, "Pester") == true ? 1:0
  name                    = "Pester"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name

  module_link {
    uri = "https://psg-prod-eastus.azureedge.net/packages/pester.5.2.2.nupkg"
  }
}

# Pester
resource "azurerm_automation_module" "az_keyvault" {
  depends_on              = [azurerm_automation_module.az_resources]
  count                   = contains(var.name, "Az.KeyVault") == true ? 1:0
  name                    = "Az.KeyVault"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name

  module_link {
    uri = "https://psg-prod-eastus.azureedge.net/packages/az.keyvault.3.4.4.nupkg"
  }
}
