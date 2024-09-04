// use locals for customizing vars
locals {

  suffix_concat             = "${var.variable1}${var.envv}"
  tags                      = merge(var.tags, { "env" = var.envv })
  resource_group            = "rsg${local.suffix_concat}"
  databricks_workspace_name = "adb${local.suffix_concat}"

}
