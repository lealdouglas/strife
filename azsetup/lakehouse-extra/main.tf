# Bloco terraform para definir os provedores necessários
# Terraform block to define required providers
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # version = "=21.90.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "=1.15.0"
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
  alias = "workspace"
  host  = local.databricks_workspace_host
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

# Cria o catálogo de desenvolvimento
# Create dev environment catalog
data "databricks_catalog" "dev" {
  name = local.catalog_name
}

data "databricks_schema" "bronze" {
  name = "bronze"
}

# Cria uma localização externa para ser usada como armazenamento raiz pelo catálogo de desenvolvimento
# Create an external location to be used as root storage by dev catalog
data "databricks_external_location" "dev_location" {
  name = "dtmaster-catalog-external-location"
}

resource "databricks_volume" "this" {
  provider         = databricks.workspace
  name             = "checkpoint_locations_table"
  catalog_name     = data.databricks_catalog.dev.name
  schema_name      = data.databricks_schema.bronze.name
  volume_type      = "EXTERNAL"
  storage_location = data.databricks_external_location.dev_location.url
  comment          = "this volume is managed by terraform"
}

# Concede permissões no catálogo de desenvolvimento
# Grants on dev catalog
resource "databricks_grants" "volume" {
  catalog = databricks_volume.this.id
  grant {
    principal  = "data_engineer"
    privileges = ["WRITE_VOLUME", "READ_VOLUME"]
  }
  depends_on = [databricks_volume.this]
}


# Obtém o principal de serviço do Databricks
# Get Databricks service principal
data "databricks_service_principal" "sp" {
  application_id = var.azure_client_id
}

data "databricks_group" "data_engineer" {
  display_name = "data_engineer"
}

# data "databricks_user" "me" {
#   user_name  = var.user_principal_name
#   depends_on = [databricks_mws_permission_assignment.workspace_user_groups]
# }

resource "databricks_group_member" "i-am-admin" {
  group_id  = data.databricks_group.data_engineer.id
  member_id = data.databricks_service_principal.sp.application_id
}
