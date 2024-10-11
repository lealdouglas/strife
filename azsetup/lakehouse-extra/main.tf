# Bloco terraform para definir os provedores necessários
# Terraform block to define required providers
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # version = "=21.90.0"
    }
    databricks = {
      source = "databricks/databricks"
    }
  }
}

# Provedor Azure
# Azure provider
provider "azurerm" {
  features {}
}

# Obtém a configuração atual do cliente Azure
# Get the current Azure client configuration
data "azurerm_client_config" "current" {
}


# Obtém informações do workspace Databricks
# Get Databricks workspace information
data "azurerm_databricks_workspace" "this" {
  name                = local.databricks_name
  resource_group_name = local.resource_group
}

# Variáveis locais
# Local variables
locals {
  databricks_workspace_host = data.azurerm_databricks_workspace.this.workspace_url
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


# data "databricks_service_principal" "sp" {
#   display_name = var.azure_client_id
# }


# data "databricks_group" "data_engineer" {
#   display_name = "data_engineer"
# }

# resource "databricks_group_member" "i-am-admin" {
#   provider  = databricks.azure_account
#   group_id  = data.databricks_group.data_engineer.id
#   member_id = data.databricks_service_principal.sp.id
# }

resource "databricks_volume" "this" {
  name             = "volume_checkpoint_locations"
  catalog_name     = local.catalog_name
  schema_name      = "bronze"
  volume_type      = "EXTERNAL"
  storage_location = format("abfss://%s@%s.dfs.core.windows.net/volume_checkpoint_locations/", local.container_catalog, local.storage_account)
  comment          = "this volume is managed by terraform"
}

# Concede permissões no catálogo de desenvolvimento
# Grants on dev catalogdatabricks_volume
resource "databricks_grants" "volume" {
  catalog = databricks_volume.this.id
  grant {
    principal  = "data_engineer"
    privileges = ["WRITE_VOLUME", "READ_VOLUME"]
  }
  depends_on = [databricks_volume.this]
}
