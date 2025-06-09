variable "AADSecret" {
}

variable "depend_on_dbs" {
  type = list(string)
}

variable "server_url" {
}

variable "readonly_group" {
}

variable "db_owner_group" {
}

variable "db_owner_user" {
}

variable "readonly_user" {
}

variable "ad_admin_login" {
}

variable "ad_admin_password" {
}

variable "exclude_user_from_removal" {
  default = "null"
}

