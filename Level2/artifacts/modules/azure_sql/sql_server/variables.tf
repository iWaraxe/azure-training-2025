variable "name" {
}

variable "location" {
}

variable "resource_group_name" {
}

variable "admin_login" {
}

variable "admin_password" {
}

variable "firewall_list" {
    type = map(string)
    description = "SQL server firewall list"
}
