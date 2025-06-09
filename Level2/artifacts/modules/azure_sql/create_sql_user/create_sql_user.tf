data "azurerm_client_config" "current" {
}

resource "null_resource" "create_ad_sql_users_and_groups" {
  triggers = {
    trigger = timestamp()
    depend_on_dbs   = join(",", var.depend_on_dbs)
    depend_on_users = "${var.readonly_user},${var.db_owner_group},${var.db_owner_user},${var.readonly_user},${var.ad_admin_login},${var.ad_admin_password}"
    content         = filesha1("${path.module}/New-AzureSqlUsers.ps1")
  }

  provisioner "local-exec" {
    command = <<EOF
    powershell -file ${path.module}\New-AzureSqlUsers.ps1 -AADSecret "${var.AADSecret}" `
                                                          -AADClientID "${data.azurerm_client_config.current.client_id}" `
                                                          -TenantID "${data.azurerm_client_config.current.tenant_id}" `
                                                          -SubscriptionID "${data.azurerm_client_config.current.subscription_id}" `
                                                          -SqlServer "${var.server_url}" `
                                                          -SqlReadOnlyGroup "${var.readonly_group}" `
                                                          -SqlDbOwnerGroup "${var.db_owner_group}" `
                                                          -SqlDbOwnerUser "${var.db_owner_user}" `
                                                          -SqlReadOnlyUser "${var.readonly_user}" `
                                                          -SqlAdAdminLogin "${var.ad_admin_login}" `
                                                          -SqlAdminPassword "${var.ad_admin_password}" `
                                                          -ExcludeUserFromRemoval "${var.exclude_user_from_removal}"
EOF


    interpreter = ["PowerShell", "-Command"]
  }
}

