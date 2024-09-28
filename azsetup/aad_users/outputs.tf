output "grupo" {
  value = "[tf-dtmaster-dougsll] Grupo criado : ${azuread_group.dt.display_name}"
}

output "user" {
  value = "[tf-dtmaster-dougsll] Usuario criado : ${azuread_user.fulano.display_name}"
}

output "principal" {
  value = "[tf-dtmaster-dougsll] Usuario principal vinculado ao grupo criado : ${data.azuread_user.principal_name.display_name}"
}