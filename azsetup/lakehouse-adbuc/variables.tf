
variable "account_id" {
  description = "Azure databricks account id"
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "aad_groups" {
  description = "List of AAD groups that you want to add to Databricks account"
  type        = list(string)
  default     = ["data_engineer"]
}


variable "project_code" {
  type    = string
  default = "strifedtm"
}

variable "tags" {
  type = map(any)
  default = {
    projectCode = "strifedtm"
    application = "strifedtm"
    costCenter  = "strifedtm"
  }
}

variable "envv" {
  type    = string
  default = "dev"
}

