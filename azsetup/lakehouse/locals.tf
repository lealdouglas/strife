// use locals for customizing vars
locals {

  suffix_main   = "${var.project_code}-${var.envv}"
  suffix_concat = "${var.project_code}${var.envv}"
  tags          = merge(var.tags, { "env" = var.envv })

}

# databricks_account_id = "databricks account_id: 952363069268242"
# databricks_host = "https://adb-952363069268242.2.azuredatabricks.net/"
# databricks_resource_id = "databricks databricks_resource_id: /subscriptions/e2e4ef16-cf9a-4c3b-8b45-7138b689a405/resourceGroups/rsgdtmaster-douglaslealdev-workspace"
# tenant_id = "azure tenant_id: cc618b0e-4a39-4cbf-b22c-4a531bc6faac"

# databricks_host           = azurerm_databricks_workspace.this.workspace_url
# databricks_account_id     = azurerm_databricks_workspace.this.workspace_id
# databricks_resource_id    = azurerm_databricks_workspace.this.managed_resource_group_id
# databricks_workspace_name = azurerm_databricks_workspace.this.name

# resource_regex            = "(?i)subscriptions/(.+)/resourceGroups/(.+)"
# subscription_id           = regex(local.resource_regex, local.databricks_resource_id)[0]
# resource_group            = regex(local.resource_regex, local.databricks_resource_id)[1]
# tenant_id                 = data.azurerm_client_config.current.tenant_id
