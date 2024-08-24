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

resource "azurerm_eventhub" "example" {
  name                = "acceptanceTestEventHub"
  namespace_name      = azurerm_eventhub_namespace.example.name
  resource_group_name = data.azurerm_resource_group.this.name
  partition_count     = 2
  message_retention   = 1
}
