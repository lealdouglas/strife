data "azurerm_client_config" "current" {
}

resource "azuread_user" "fulano" {
  display_name        = "Fulano"
  password            = "SecretP@sswd99!"
  user_principal_name = "fulano@${var.domain_azure}"
}

data "azuread_user" "principal_name" {
  user_principal_name = var.user_principal_name
}

resource "azuread_group" "dt" {
  display_name     = "data_engineer"
  description      = "Group for Data Engineers"
  owners           = [data.azurerm_client_config.current.object_id]
  security_enabled = true

  members = [
    data.azuread_user.principal_name.object_id,
    azuread_user.fulano.object_id
    /* more users */
  ]

  depends_on = [azuread_user.fulano, data.azuread_user.principal_name]
}
