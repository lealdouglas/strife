

output "resource_group_name" {
  value = "[tf-dtmaster-dougsll] Resource Group : ${azurerm_resource_group.this.name}/"
}

output "storage_name" {
  value = "[tf-dtmaster-dougsll] Storage Account : ${azurerm_storage_account.this.name}/"
}

output "event_hub" {
  value = "[tf-dtmaster-dougsll] Event hub : ${azurerm_eventhub_namespace.this.name}/"
}

output "databricks_name" {
  value = "[tf-dtmaster-dougsll] Databricks name : ${azurerm_databricks_workspace.this.name}/"
}

output "databricks_host" {
  value = "[tf-dtmaster-dougsll] Databricks endpoint : https://${azurerm_databricks_workspace.this.workspace_url}/"
}
