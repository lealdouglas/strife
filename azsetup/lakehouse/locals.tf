// use locals for customizing vars
locals {

  suffix_main   = "${var.project_code}-${var.envv}"
  suffix_concat = "${var.project_code}${var.envv}"
  tags          = merge(var.tags, { "env" = var.envv })

}
