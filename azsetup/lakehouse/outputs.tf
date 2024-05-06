

output "resource_group_name" {
  value = "[tf-dtmaster-dougsll] Resource Group criado com sucesso ${azurerm_resource_group.this.name}/"
}

output "storage_name" {
  value = "[tf-dtmaster-dougsll] Storage Account Gen2 criado com sucesso ${azurerm_storage_account.this.name}/"
}

output "databricks_host" {
  value = "[tf-dtmaster-dougsll] Databricks endpoint criado com sucesso: https://${azurerm_databricks_workspace.this.workspace_url}/"
}

output "databricks_id" {
  value = "[tf-dtmaster-dougsll] Databricks endpoint criado com sucesso: https://${azurerm_databricks_workspace.this.workspace_id}/"
}
