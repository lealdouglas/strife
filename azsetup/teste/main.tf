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

# Create a resource group
resource "azurerm_resource_group" "this" {
  name     = "rsgtest${local.suffix_concat}"
  location = var.location
  tags     = local.tags
}

