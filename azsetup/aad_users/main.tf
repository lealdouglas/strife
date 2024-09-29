data "azurerm_client_config" "current" {
}

resource "azuread_user" "this" {
  display_name        = "Luke Skywalker"
  password            = "SecretP@sswd99!"
  user_principal_name = "luke@${var.domain_azure}"
}

resource "azuread_user" "this" {
  display_name        = "Leia Skywalker"
  password            = "SecretP@sswd98!"
  user_principal_name = "leia@${var.domain_azure}"
}

resource "azuread_user" "this" {
  display_name        = "Obi Wan"
  password            = "SecretP@sswd97!"
  user_principal_name = "obi@${var.domain_azure}"
}

resource "azuread_user" "this" {
  display_name        = "Jar Jar binks"
  password            = "SecretP@sswd96!"
  user_principal_name = "jarjar@${var.domain_azure}"
}

# data "azuread_user" "principal_name" {
#   user_principal_name = var.user_principal_name
# }

resource "azuread_group" "dt" {
  display_name     = "data_engineer"
  description      = "Group for Data Engineers"
  owners           = [data.azurerm_client_config.current.object_id]
  security_enabled = true

  members = [
    azuread_user.this.object_id
    # data.azuread_user.principal_name.object_id,
    /* more users */
  ]

  depends_on = [azuread_user.this]
}
