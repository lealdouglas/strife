// use locals for customizing vars
locals {
  suffix_concat             = "d${var.domain}"
  catalog_name              = "c${var.catalog}"
  tags                      = merge({ "domain" = var.domain }, { "project" = var.project }, { "env" = var.envv })
  resource_group            = "rsg${local.suffix_concat}"
  databricks_workspace_name = "adb${local.suffix_concat}"
}
