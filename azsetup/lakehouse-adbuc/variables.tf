
variable "account_id" {
  description = "Azure databricks account id"
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "aad_groups" {
  description = "List of AAD groups that you want to add to Databricks account"
  type        = list(string)
  default     = ["data_engineer"]
}


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


variable "envv" {
  type    = string
  default = "dtm"
}

variable "azure_client_id" {
  description = "Azure client id"
  default     = "000000"
}

variable "azure_client_secret" {
  description = "Azure client secret id"
  default     = "000000"
}

variable "azure_tenant_id" {
  description = "Azure Tenant id"
  default     = "000000"
}

# variable "user_principal_name" {
#   type    = string
#   default = "gaby-gouvea_hotmail.com#EXT#@gabygouveahotmail.onmicrosoft.com"

# }

