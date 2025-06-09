resource "azurerm_traffic_manager_profile" "traffic_manager" {
  name                = var.name
  resource_group_name = var.resource_group_name

  traffic_routing_method = "Priority"

  dns_config {
    relative_name = var.name
    ttl           = var.dns_ttl
  }

  monitor_config {
    protocol                     = "https"
    port                         = 443
    path                         = var.monitor_path
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
    expected_status_code_ranges  = var.expected_status_code_ranges
  }
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_traffic_manager_endpoint" "primary_endpoint" {
  name                = "primary_endpoint"
  resource_group_name = var.resource_group_name
  profile_name        = azurerm_traffic_manager_profile.traffic_manager.name
  target              = var.primary_endpoint
  type                = "externalEndpoints"
  priority            = 1
}

resource "azurerm_traffic_manager_endpoint" "secondary_endpoint" {
  name                = "secondary_endpoint"
  resource_group_name = var.resource_group_name
  profile_name        = azurerm_traffic_manager_profile.traffic_manager.name
  target              = var.secondary_endpoint
  type                = "externalEndpoints"
  priority            = 2
}