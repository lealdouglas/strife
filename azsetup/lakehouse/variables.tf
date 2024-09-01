variable "project_code" {
  type    = string
  default = "strife"
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

variable "tags" {
  type = map(any)
  default = {
    projectCode = "strife"
    application = "strife"
    costCenter  = "riscos"
  }
}

variable "aad_groups" {
  description = "List of AAD groups that you want to add to Databricks account"
  type        = list(string)
  default     = ["data_engineer"]
}
