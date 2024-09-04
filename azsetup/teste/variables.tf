variable "variable1" {
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
    projectCode = variable1
    application = variable1
    costCenter  = variable1
  }
}
