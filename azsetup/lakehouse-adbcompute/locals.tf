// use locals for customizing vars
locals {
  suffix_concat       = "d${var.domain}"
  catalog_name        = "c${var.catalog}"
  resource_group      = "rsgd${var.domain}"
  event_hub           = "ethd${var.domain}"
  databricks_name     = "adbd${var.domain}"
  storage_account     = "stad${var.domain}"
  container_raw       = "ctrd${var.domain}raw"
  container_metastore = "ctrd${var.domain}mtst"
  tags                = merge({ "domain" = var.domain }, { "project" = var.project }, { "env" = var.envv })
}
