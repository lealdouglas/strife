data "azurerm_client_config" "current" {
}

resource "azuread_user" "luke" {
  display_name        = "Luke Skywalker"
  password            = "SecretP@sswd99!"
  user_principal_name = "luke@${var.domain_azure}"
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

data "databricks_group" "admins" {
  display_name = "admins"
}

resource "databricks_user" "me" {
  user_name = var.user_principal_name
}

resource "databricks_group_member" "i-am-admin" {
  group_id  = data.databricks_group.admins.id
  member_id = databricks_user.me.id
}
