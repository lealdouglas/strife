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

data "azurerm_client_config" "current" {
}

// Module creating UC metastore and adding users, groups and service principals to azure databricks account
module "azure_aad_users" {
  source        = "./modules/azure-aad-users"
  suffix_concat = local.suffix_concat
}

# Create a resource group
resource "azurerm_resource_group" "this" {
  name     = "rsg${local.suffix_concat}"
  location = var.location
  tags     = local.tags
}


# Create a storage account gen2 in resource group
resource "azurerm_storage_account" "this" {
  name                      = "sta2${local.suffix_concat}"
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

resource "azurerm_databricks_workspace" "this" {
  location                    = azurerm_resource_group.this.location
  resource_group_name         = azurerm_resource_group.this.name
  name                        = "adb${local.suffix_concat}"
  sku                         = "premium"
  managed_resource_group_name = "rsgadbmanaged"
  tags                        = local.tags
}

// Create azure managed identity to be used by unity catalog metastore
resource "azurerm_databricks_access_connector" "unity" {
  name                = "adb${local.suffix_concat}-mi"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  identity {
    type = "SystemAssigned"
  }
}

# // Create a storage account to be used by unity catalog metastore as root storage
# resource "azurerm_storage_account" "unity_catalog" {
#   name                     = "sta2${local.suffix_concat}uc"
#   resource_group_name      = azurerm_resource_group.this.name
#   location                 = azurerm_resource_group.this.location
#   tags                     = azurerm_resource_group.this.tags
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
#   is_hns_enabled           = true
# }

// Create a container in storage account to be used by unity catalog metastore as root storage
resource "azurerm_storage_container" "unity_catalog" {
  name                  = "ctr${local.suffix_concat}mtst"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

// Create a container in storage account to be used by unity catalog metastore as root storage
resource "azurerm_storage_container" "raw" {
  name                  = "ctr${local.suffix_concat}raw"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

// Assign the Storage Blob Data Contributor role to managed identity to allow unity catalog to access the storage
resource "azurerm_role_assignment" "mi_data_contributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.unity.identity[0].principal_id
}

resource "azurerm_eventhub_namespace" "example" {
  name                = "eth${local.suffix_concat}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
  capacity            = 1
  tags                = local.tags
}
