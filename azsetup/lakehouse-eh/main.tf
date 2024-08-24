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

provider "azurerm" {
  features {}
  subscription_id = "8a66b4be-4d16-49bb-9c92-7610ca4ac552"
}


data "azurerm_client_config" "current" {
}


data "azurerm_resource_group" "this" {
  name = local.resource_group
}

resource "azurerm_eventhub_namespace" "example" {
  name                = "eth${local.suffix_concat}"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  sku                 = "Standard"
  capacity            = 1

  tags = {
    environment = local.tags.env
  }
}
