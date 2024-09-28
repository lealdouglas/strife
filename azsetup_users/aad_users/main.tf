data "azurerm_client_config" "current" {
}

#Criando um grupo de Data Engineers
resource "azuread_group" "data_engineers" {
  display_name     = "data_engineer"
  description      = "Group for Data Engineers"
  security_enabled = true
}

resource "azuread_user" "fulano" {
  display_name        = "Fulano"
  password            = "Fulano@2707!"
  user_principal_name = "fulano@gabygouveahotmail.onmicrosoft.com"
}

resource "azuread_group_member" "user4_member" {
  group_object_id  = azuread_group.data_engineers.id
  member_object_id = azuread_user.fulano.object_id
}

resource "azuread_group_member" "user5_member" {
  group_object_id  = azuread_group.data_engineers.id
  member_object_id = "ea4d5a73-3bb2-4de6-ad62-6dcbf9234d6b"
}

# resource "azuread_user" "teste" {
#   user_principal_name = ["gaby-gouvea_hotmail.com#EXT#@gabygouveahotmail.onmicrosoft.com"]
# }

# output "tessdte" {
#   value = azuread_user.teste.display_name
# }

# output "tesdte" {
#   value = azuread_user.teste.mail_nickname
# }

# # Criando um grupo de Data Engineers
# resource "azuread_group" "account_unity_admin" {
#   display_name     = "account_unity_admin"
#   description      = "Group for Admin Unity"
#   security_enabled = true
# }

# resource "azuread_application" "this" {
#   display_name = "spngroup${var.suffix_concat}"
#   owners       = [data.azurerm_client_config.current.object_id]
# }

# resource "azuread_service_principal" "this" {
#   client_id                    = azuread_application.this.client_id
#   app_role_assignment_required = false
#   owners                       = [data.azurerm_client_config.current.object_id]
#   account_enabled              = true
# }

# resource "time_rotating" "month" {
#   rotation_days = 30
# }

# resource "azuread_service_principal_password" "this" {
#   service_principal_id = azuread_service_principal.this.object_id
#   rotate_when_changed  = { rotation = time_rotating.month.id }
# }

