# Bloco terraform para definir os provedores necessários
# Terraform block to define required providers
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.3.0"
    }
  }
}

# Provedor Azure
# Azure provider
provider "azurerm" {
  features {}
}
