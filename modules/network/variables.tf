variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vnet_cidr" {
  type = list(string)
}

variable "subnet_cidr" {
  type = list(string)
}
variable "allowed_ssh_ip" {
  description = "IP publico autorizado para acesso SSH"
  type        = string
}