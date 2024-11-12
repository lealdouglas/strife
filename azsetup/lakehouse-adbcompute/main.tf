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

resource "databricks_secret_scope" "app" {
  name = "strife-secret-scope"
}

resource "databricks_secret" "azure_client_secret" {
  key          = "azure_client_secret"
  string_value = var.azure_client_secret
  scope        = databricks_secret_scope.app.id
}

resource "databricks_secret" "azure_client_id" {
  key          = "azure_client_id"
  string_value = var.azure_client_id
  scope        = databricks_secret_scope.app.id
}

resource "databricks_secret" "azure_tenant_id" {
  key          = "azure_tenant_id"
  string_value = var.azure_tenant_id
  scope        = databricks_secret_scope.app.id
}

# Obtém o menor tipo de nó disponível
# Get the smallest available node type
data "databricks_node_type" "smallest" {
  local_disk = true
}

# Obtém a versão mais recente do Spark com suporte de longo prazo
# Get the latest long-term support Spark version
data "databricks_spark_version" "latest_lts" {
  long_term_support = true
}

# Cria um cluster Databricks
# Create a Databricks cluster
resource "databricks_cluster" "this" {
  cluster_name            = "cluster-single-dtm-${local.suffix_concat}"
  spark_version           = "15.4.x-scala2.12" #data.databricks_spark_version.latest_lts.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 10
  data_security_mode      = "SINGLE_USER"

  spark_conf = {
    # Single-node
    "spark.databricks.cluster.profile" : "singleNode"
    "spark.master" : "local[*]"
    "spark.databricks.sql.initial.catalog.namespace" : local.catalog_name
  }

  spark_env_vars = {
    "ARM_CLIENT_SECRET" = databricks_secret.azure_client_secret.config_reference
    "ARM_CLIENT_ID"     = databricks_secret.azure_client_id.config_reference
    "ARM_TENANT_ID"     = databricks_secret.azure_tenant_id.config_reference
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
  }
}

# Define permissões para o uso do cluster
# Define permissions for cluster usage
resource "databricks_permissions" "cluster_usage" {
  cluster_id = databricks_cluster.this.id

  access_control {
    group_name       = "data_engineer"
    permission_level = "CAN_MANAGE"
  }

  access_control {
    group_name       = "users"
    permission_level = "CAN_MANAGE"
  }
}

