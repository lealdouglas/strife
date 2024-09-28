output "grupo" {
  value = "[tf-dtmaster-dougsll] Grupo criado : ${azuread_group.dt.display_name}"
}

output "user" {
  value = "[tf-dtmaster-dougsll] Novo usuario criado : ${azuread_user.this.display_name}"
}

output "principal" {
  value = "[tf-dtmaster-dougsll] Usuario principal vinculado ao grupo criado : ${data.azuread_user.principal_name.display_name}"
}

