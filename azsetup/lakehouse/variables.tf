variable "project_code" {
  type    = string
  default = "strifedtm"
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
  default = "dev"
}

variable "tags" {
  type = map(any)
  default = {
    projectCode = "strifedtm"
    application = "strifedtm"
    costCenter  = "strifedtm"
  }
}

variable "aad_groups" {
  description = "List of AAD groups that you want to add to Databricks account"
  type        = list(string)
  default     = ["data_engineer"]
}