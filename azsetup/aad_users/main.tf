data "azurerm_client_config" "current" {
}

resource "azuread_user" "this" {
  display_name        = "Luke Skywalker"
  password            = "SecretP@sswd99!"
  user_principal_name = "luke@${var.domain_azure}"
}

data "azuread_user" "principal_name" {
  user_principal_name = var.user_principal_name
}

resource "azuread_group" "dt" {
  display_name     = "test" #data_engineer
  description      = "Group for Data Engineers"
  owners           = [data.azurerm_client_config.current.object_id]
  security_enabled = true

  members = [
    data.azuread_user.principal_name.object_id,
    azuread_user.this.object_id
    /* more users */
  ]

  depends_on = [azuread_user.this, data.azuread_user.principal_name]
}
