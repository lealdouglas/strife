// use locals for customizing vars
locals {

  suffix_concat             = "d${var.domain}"
  tags                      = merge({ "domain" = var.domain }, { "project" = var.project }, { "env" = var.envv })
  resource_group            = "rsg${local.suffix_concat}"
  databricks_workspace_name = "adb${local.suffix_concat}"

}
