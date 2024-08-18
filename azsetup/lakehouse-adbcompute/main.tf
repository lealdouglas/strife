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

provider "azurerm" {
  features {}
}

data "azurerm_databricks_workspace" "this" {
  name                = local.databricks_workspace_name
  resource_group_name = local.resource_group
}

locals {
  databricks_workspace_host = data.azurerm_databricks_workspace.this.workspace_url
}

// Provider for databricks workspace
provider "databricks" {
  host = local.databricks_workspace_host
}

// Provider for databricks account
provider "databricks" {
  alias               = "azure_account"
  host                = "https://accounts.azuredatabricks.net"
  account_id          = var.account_id
  azure_client_id     = var.azure_client_id
  azure_client_secret = var.azure_client_secret
  azure_tenant_id     = var.azure_tenant_id
  auth_type           = "azure-client-secret"
}

# data "databricks_node_type" "smallest" {
#   local_disk = true
# }

# data "databricks_spark_version" "latest_lts" {
#   long_term_support = true
# }

# # 14.3.x-scala2.12
# resource "databricks_cluster" "this" {
#   cluster_name            = "dtmaster"
#   spark_version           = "14.3.x-scala2.12" #data.databricks_spark_version.latest_lts.id
#   node_type_id            = data.databricks_node_type.smallest.id
#   autotermination_minutes = 10
#   num_workers             = 1
#   data_security_mode      = "USER_ISOLATION"

#   spark_conf = {
#     # Single-node
#     # "spark.databricks.cluster.profile" : "singleNode"
#     # "spark.master" : "local[*]"
#     "spark.databricks.sql.initial.catalog.namespace" : "dev_catalog"
#   }
#   # custom_tags = {
#   #   "ResourceClass" = "SingleNode"
#   # }
#    azure_attributes {
#     availability       = "SPOT_WITH_FALLBACK_AZURE"
#     first_on_demand    = 1
#     spot_bid_max_price = -1
#   }
#   #   library {
#   #   pypi {
#   #     package = "fbprophet==0.6"
#   #     // repo can also be specified here
#   #   }
#   # }
# }

# resource "databricks_permissions" "cluster_usage" {
#   cluster_id = databricks_cluster.this.id

#   access_control {
#     group_name       = "data_engineer"
#     permission_level = "CAN_MANAGE"
#   }

#   access_control {
#     group_name       = "users"
#     permission_level = "CAN_MANAGE"
#   }
# }

# output "cluster_url" {
#  value = databricks_cluster.this.url
# }

# resource "databricks_sql_table" "thing" {
#   name               = "table_config_ingest"
#   catalog_name       = databricks_catalog.dev.name
#   schema_name        = databricks_schema.bronze.name
#   table_type         = "MANAGED"
#   data_source_format = "DELTA"
#   cluster_id         = databricks_cluster.this.id

#   column {
#     name = "SCHEMA"
#     type = "STRING"
#   }
#   column {
#     name = "TABLE"
#     type = "STRING"
#   }
#   column {
#     name = "DOMAIN"
#     type = "STRING"
#   }
#   column {
#     name = "REQUESTER"
#     type = "STRING"
#   }
#   comment = "this table is managed by terraform"
#   depends_on = [ databricks_cluster.this ]
# }
