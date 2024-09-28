data "azurerm_client_config" "current" {
}

resource "azuread_user" "fulano" {
  display_name        = "Fulano"
  password            = "SecretP@sswd99!"
  user_principal_name = "fulano@gabygouveahotmail.onmicrosoft.com"
}

data "azuread_user" "you" {
  user_principal_name = "gaby-gouvea_hotmail.com#EXT#@gabygouveahotmail.onmicrosoft.com"
}

resource "azuread_group" "dt" {
  display_name     = "data_engineer"
  description      = "Group for Data Engineers"
  owners           = [data.azurerm_client_config.current.object_id]
  security_enabled = true

  members = [
    data.azuread_user.you.object_id,
    /* more users */
  ]

  depends_on = [azuread_user.fulano, data.azuread_user.you]
}
