variable "databricks_name" {
  description = "Azure databricks workspace name"
}

variable "resource_group" {
  description = "Azure resource group"
}

variable "aad_groups" {
  description = "List of AAD groups that you want to add to Databricks account"
  type        = list(string)
}

variable "account_id" {
  description = "Azure databricks account id"
}

variable "azure_client_id" {
  description = "Azure client id"
}

variable "azure_client_secret" {
  description = "Azure client secret id"
}

variable "azure_tenant_id" {
  description = "Azure Tenant id"
}

variable "prefix" {
  description = "Prefix to be used with resouce names"
}

variable "container_metastore" {
  description = "container_metastore"
}

variable "storage_account" {
  description = "storage_account"
}
