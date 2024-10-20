// use locals for customizing vars
locals {

  suffix_concat       = "d${var.domain}"
  resource_group      = "rsgd${var.domain}"
  event_hub           = "ethd${var.domain}"
  databricks_name     = "adbd${var.domain}"
  catalog_name        = "c${var.catalog}"
  storage_account     = "stad${var.domain}"
  container_raw       = "ctrd${var.domain}raw"
  container_log       = "ctrd${var.domain}log"
  container_metastore = "ctrd${var.domain}mtst"
  container_catalog   = "ctrd${var.domain}catlog"
  tags                = merge({ "domain" = var.domain }, { "project" = var.project }, { "env" = var.envv })

  databricks_workspace_host = data.azurerm_databricks_workspace.this.workspace_url

}
