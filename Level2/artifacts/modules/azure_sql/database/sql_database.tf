resource "azurerm_sql_database" "database" {
  count                            = var.enable == "true" ? 1:0
  name                             = var.name
  resource_group_name              = var.resource_group_name
  location                         = var.location
  server_name                      = var.server_name
  edition                          = var.edition
  requested_service_objective_name = var.requested_service_objective_name

  tags = {
    environment  = "${var.resource_group_name}-${var.location}"
    sql_database = var.server_name
  }

  threat_detection_policy {
    state = "Disabled"
  }
  lifecycle {
    ignore_changes = [
      resource_group_name,              # can be removed once CRGS and CRGP will be re-created with lower case
      edition,
      tags
    ]
  }
}

