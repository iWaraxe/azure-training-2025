# Note on ARM Template Deployments: Due to the way the underlying Azure API is designed, Terraform can only 
# manage the deployment of the ARM Template - and not any resources which are created by it. This means that 
# when deleting the azurerm_template_deployment resource, Terraform will only remove the reference to the 
# deployment, whilst leaving any resources created by that ARM Template Deployment. One workaround for this 
# is to use a unique Resource Group for each ARM Template Deployment, which means deleting the 
# Resource Group would contain any resources created within it - however this isn't ideal
# https://hbuckle.github.io/terraform/2018/03/08/creating-azure-automation-webhooks-with-terraform.html

resource "azurerm_template_deployment" "webhook" {
  name                = var.webhook_name
  resource_group_name = var.resource_group_name
  deployment_mode     = "Incremental"
  parameters_body = jsonencode(local.parameters_body)
  template_body = <<DEPLOY
{
  "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
      "ps_parameters": {
          "type": "object",
          "metadata": {
              "description": "The map of comma separated items.."
          }
      }
  },
  "resources": [
    {
      "name": "${var.automation_account_name}/${var.webhook_name}",
      "type": "Microsoft.Automation/automationAccounts/webhooks",
      "apiVersion": "2015-10-31",
      "properties": {
        "isEnabled": true,
        "uri": "${local.webhook}",
        "expiryTime": "2027-01-01T00:00:00.000+00:00",
        "parameters": "[parameters('ps_parameters')]",
        "runbook": {
          "name": "${var.automation_runbook_receiver_runbook_name}"
        }
      }
    }
  ],
  "outputs": {
    "webhookResourceId": {
      "type": "string",
      "value": "[resourceId('Microsoft.Automation/automationAccounts/webhooks', '${var.automation_account_name}', '${var.webhook_name}')]"
    }
  }
}
DEPLOY
}

resource "random_string" "token1" {
  length  = 10
  upper   = true
  lower   = true
  number  = true
  special = false
}

resource "random_string" "token2" {
  length  = 31
  upper   = true
  lower   = true
  number  = true
  special = false
}

locals {
  webhook = "https://s13events.azure-automation.net/webhooks?token=%2b${random_string.token1.result}%2b${random_string.token2.result}%3d"

  parameters_body = {
    ps_parameters = {
      value = var.ps_param_map
    }
  }
}