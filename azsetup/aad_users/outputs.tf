output "grupo" {
  value = "[tf-dtmaster-dougsll] Grupo criado : ${azuread_group.dt.display_name}"
}

output "user" {
  value = "[tf-dtmaster-dougsll] Novo usuario criado : ${azuread_user.this.display_name}"
}

output "user1" {
  value = "[tf-dtmaster-dougsll] Novo usuario criado : ${azuread_user.this1.display_name}"
}

output "user2" {
  value = "[tf-dtmaster-dougsll] Novo usuario criado : ${azuread_user.this2.display_name}"
}

output "user3" {
  value = "[tf-dtmaster-dougsll] Novo usuario criado : ${azuread_user.this3.display_name}"
}

# output "principal" {
#   value = "[tf-dtmaster-dougsll] Usuario principal vinculado ao grupo criado : ${data.azuread_user.principal_name.display_name}"
# }

