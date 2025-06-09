variable "name" {
  
}
variable "resource_group_name" {
  
}
variable "primary_endpoint" {

}
variable "secondary_endpoint" {
  
}

variable "monitor_path" {
  
}

variable "dns_ttl" {
  
}

variable "expected_status_code_ranges" {
    default = [ "200-200" ]
    type = list(string)
}