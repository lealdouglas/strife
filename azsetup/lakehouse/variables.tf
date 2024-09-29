variable "domain" {
  type    = string
  default = "domain"
}

variable "catalog" {
  type    = string
  default = "catalog"
}

variable "project" {
  type    = string
  default = "project"
}

variable "location" {
  type    = string
  default = "Brazil South"
}

variable "location_code" {
  type    = string
  default = "br"
}

variable "envv" {
  type    = string
  default = "dtm"
}

variable "aad_groups" {
  description = "List of AAD groups that you want to add to Databricks account"
  type        = list(string)
  default     = ["data_engineer"]
}


variable "domain_azure" {
  type    = string
  default = "gabygouveahotmail.onmicrosoft.com"
}

# variable "user_principal_name" {
#   type    = string
#   default = "gaby-gouvea_hotmail.com#EXT#@gabygouveahotmail.onmicrosoft.com"

# }

