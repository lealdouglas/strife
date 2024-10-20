# Recomendamos fortemente o uso do bloco required_providers para definir a
# fonte e a versão do provedor Azure sendo usado
# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "=1.15.0"
    }
  }
}

# Obtém a configuração atual do cliente Azure
# Get the current Azure client configuration
data "azurerm_client_config" "current" {
}

# Módulo que cria o metastore UC e adiciona usuários, grupos e principais de serviço à conta Azure Databricks
# Module creating UC metastore and adding users, groups and service principals to Azure Databricks account
# module "azure_aad_users" {
#   source        = "./modules/azure-aad-users"
#   suffix_concat = local.suffix_concat
# }


# Obtém informações do workspace Databricks
# Get Databricks workspace information
data "azurerm_databricks_workspace" "this" {
  name                = local.databricks_name
  resource_group_name = local.resource_group
}

resource "databricks_secret_scope" "app" {
  name = "application-secret-scope"
}

# azure_client_id     = var.azure_client_id
# azure_client_secret = var.azure_client_secret
# azure_tenant_id     = var.azure_tenant_id

resource "databricks_secret" "azure_client_secret" {
  key          = "azure_client_secret"
  string_value = var.azure_client_secret
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
  cluster_name            = "testtt"
  spark_version           = "14.3.x-scala2.12" #data.databricks_spark_version.latest_lts.id
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



# Cria um namespace do Event Hub
# Create an Event Hub namespace
resource "azurerm_eventhub_namespace" "this" {
  name                = "novoeh"
  location            = var.location
  resource_group_name = local.resource_group
  sku                 = "Standard"
  capacity            = 1
  tags                = local.tags
}

resource "azurerm_role_assignment" "eventhub" {
  scope                = azurerm_eventhub_namespace.this.id
  role_definition_name = "Azure Event Hubs Data Sender"
  principal_id         = data.azurerm_client_config.current.client_id
}





