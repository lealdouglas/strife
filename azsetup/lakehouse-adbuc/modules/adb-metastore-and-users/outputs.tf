output "databricks_groups" {
  value = {
    for group in databricks_group.this : group.external_id => group.id
  }
}

output "databricks_users" {
  value = {
    for user in databricks_user.this : user.external_id => user.id
  }
}

output "databricks_sps" {
  value = {
    for sp in databricks_service_principal.sp : sp.external_id => sp.id
  }
}

output "azurerm_storage_account_unity_catalog" {
  value = data.azurerm_storage_account.unity_catalog
}

output "azurerm_databricks_access_connector_id" {
  value = data.azurerm_databricks_access_connector.unity.id
}

output "metastore_id" {
  value = databricks_metastore.this.id
}

output "databricks_workspace_id" {
  value = local.databricks_workspace_id
}
