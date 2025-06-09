output "service_plan_id" {
  description = "The ID of the App Service Plan"
  value       = azurerm_service_plan.app_service_plan.id
}

output "service_plan_name" {
  description = "The name of the App Service Plan"
  value       = azurerm_service_plan.app_service_plan.name
}

output "app_service_names" {
  description = "Map of app service names"
  value       = { for k, v in azurerm_windows_web_app.app_service : k => v.name }
}

output "app_service_ids" {
  description = "Map of app service IDs"
  value       = { for k, v in azurerm_windows_web_app.app_service : k => v.id }
}

output "app_service_urls" {
  description = "Map of app service default hostnames"
  value       = { for k, v in azurerm_windows_web_app.app_service : k => "https://${v.default_hostname}" }
}

output "app_service_identities" {
  description = "Map of app service managed identities"
  value       = { for k, v in azurerm_windows_web_app.app_service : k => v.identity[0].principal_id }
}

output "app_service_outbound_ip_addresses" {
  description = "Map of app service outbound IP addresses"
  value       = { for k, v in azurerm_windows_web_app.app_service : k => v.outbound_ip_addresses }
}

# Legacy outputs for backward compatibility
output "app_service_plan_id" {
  description = "[DEPRECATED] Use service_plan_id instead"
  value       = azurerm_service_plan.app_service_plan.id
}