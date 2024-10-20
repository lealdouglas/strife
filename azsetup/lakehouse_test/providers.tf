provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Provedor para workspace Databricks
# Provider for Databricks workspace
provider "databricks" {
  host = local.databricks_workspace_host
}

# Provedor para conta Databricks
# Provider for Databricks account
provider "databricks" {
  alias               = "azure_account"
  host                = "https://accounts.azuredatabricks.net"
  account_id          = var.account_id
  azure_client_id     = var.azure_client_id
  azure_client_secret = var.azure_client_secret
  azure_tenant_id     = var.azure_tenant_id
  auth_type           = "azure-client-secret"
}
