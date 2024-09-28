data "azurerm_client_config" "current" {
}

# #Criando um grupo de Data Engineers
# resource "azuread_group" "data_engineers" {
#   display_name     = "data_engineer"
#   description      = "Group for Data Engineers"
#   security_enabled = true
# }

# resource "azuread_user" "fulano" {
#   display_name        = "Fulano"
#   password            = "SecretP@sswd99!"
#   user_principal_name = "fulano@gabygouveahotmail.onmicrosoft.com"
# }

# resource "azuread_group_member" "user4_member" {
#   group_object_id  = azuread_group.data_engineers.id
#   member_object_id = azuread_user.fulano.object_id
# }

# resource "azuread_group_member" "user5_member" {
#   group_object_id  = azuread_group.data_engineers.id
#   member_object_id = "ea4d5a73-3bb2-4de6-ad62-6dcbf9234d6b"
# }


data "azuread_user" "example" {
  user_principal_name = "gaby-gouvea_hotmail.com#EXT#@gabygouveahotmail.onmicrosoft.com"
}

resource "azuread_group" "example" {
  display_name     = "MyGroup"
  owners           = [data.azurerm_client_config.current.object_id]
  security_enabled = true

  members = [
    data.azuread_user.example.object_id,
    /* more users */
  ]

  depends_on = [data.azuread_user.example]
}
