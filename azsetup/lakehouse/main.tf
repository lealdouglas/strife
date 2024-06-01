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
  name                      = "sta${local.suffix_concat}raw"
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
  managed_resource_group_name = "rsg${local.suffix_concat}-workspace"
  tags                        = local.tags
}

variable "cluster_name" {
  description = "A name for the cluster."
  type        = string
  default     = "My Cluster"
}

variable "cluster_autotermination_minutes" {
  description = "How many minutes before automatically terminating due to inactivity."
  type        = number
  default     = 60
}

variable "cluster_num_workers" {
  description = "The number of workers."
  type        = number
  default     = 1
}

# Create the cluster with the "smallest" amount
# of resources allowed.
data "databricks_node_type" "smallest" {
  local_disk = true
}

# Use the latest Databricks Runtime
# Long Term Support (LTS) version.
data "databricks_spark_version" "latest_lts" {
  long_term_support = true
}

resource "databricks_cluster" "this" {
  cluster_name            = var.cluster_name
  node_type_id            = data.databricks_node_type.smallest.id
  spark_version           = data.databricks_spark_version.latest_lts.id
  autotermination_minutes = var.cluster_autotermination_minutes
  num_workers             = var.cluster_num_workers
}

output "cluster_url" {
 value = databricks_cluster.this.url
}
