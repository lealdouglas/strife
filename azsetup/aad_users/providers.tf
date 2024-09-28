# Bloco terraform para definir os provedores necessários
# Terraform block to define required providers
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # version = "=21.90.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

// Provider for databricks workspace
provider "databricks" {
  alias     = "workspace"
  host      = azurerm_databricks_workspace.this.workspace_url
  auth_type = "azure-cli"
}

// Provider for databricks account
provider "databricks" {
  alias      = "azure_account"
  host       = "https://accounts.azuredatabricks.net"
  account_id = azurerm_databricks_workspace.this.workspace_id
  auth_type  = "azure-cli"
}
