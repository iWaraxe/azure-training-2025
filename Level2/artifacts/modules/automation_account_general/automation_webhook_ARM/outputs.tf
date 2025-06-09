output "service_uri" {
  value = local.webhook
}

output "webhookResourceId" {
  value = azurerm_template_deployment.webhook.outputs["webhookResourceId"]
#   depends_on = [
#     azurerm_template_deployment.webhook,
#   ]
}