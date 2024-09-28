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

# Cria um grupo de recursos
# Create a resource group
resource "azurerm_resource_group" "this" {
  name     = local.resource_group
  location = var.location
  tags     = local.tags
}

# Cria uma conta de armazenamento gen2 no grupo de recursos
# Create a storage account gen2 in the resource group
resource "azurerm_storage_account" "this" {
  name                      = local.storage_account
  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  account_kind              = "StorageV2"
  access_tier               = "Hot"
  is_hns_enabled            = true
  shared_access_key_enabled = true
  min_tls_version           = "TLS1_2"
  tags                      = local.tags
}

# Cria um workspace Databricks
# Create a Databricks workspace
resource "azurerm_databricks_workspace" "this" {
  location                    = azurerm_resource_group.this.location
  resource_group_name         = azurerm_resource_group.this.name
  name                        = local.databricks_name
  sku                         = "premium"
  managed_resource_group_name = "rsgadbmanaged"
  tags                        = local.tags
}

# Cria uma identidade gerenciada do Azure para ser usada pelo metastore do Unity Catalog
# Create an Azure managed identity to be used by Unity Catalog metastore
resource "azurerm_databricks_access_connector" "unity" {
  name                = "${local.databricks_name}-mi"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  identity {
    type = "SystemAssigned"
  }
}

# Cria um contêiner na conta de armazenamento para ser usado pelo metastore do Unity Catalog como armazenamento raiz
# Create a container in the storage account to be used by Unity Catalog metastore as root storage
resource "azurerm_storage_container" "unity_catalog" {
  name                  = local.container_metastore
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

# Cria um contêiner na conta de armazenamento para ser usado pelo metastore do Unity Catalog como armazenamento raiz
# Create a container in the storage account to be used by Unity Catalog metastore as root storage
resource "azurerm_storage_container" "raw" {
  name                  = local.container_raw
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

# Atribui a função de Contribuidor de Dados do Blob de Armazenamento à identidade gerenciada para permitir que o Unity Catalog acesse o armazenamento
# Assign the Storage Blob Data Contributor role to managed identity to allow Unity Catalog to access the storage
resource "azurerm_role_assignment" "mi_data_contributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.unity.identity[0].principal_id
}

# Cria um namespace do Event Hub
# Create an Event Hub namespace
resource "azurerm_eventhub_namespace" "this" {
  name                = local.event_hub
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
  capacity            = 1
  tags                = local.tags
}
