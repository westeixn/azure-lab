variable "location" {
  description = "Região do Azure"
  type        = string
  default     = "East US"
}
variable "vnet_cidr" {
  description = "Bloco de IP da VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}
variable "subnet_cidr" {
  description = "Bloco de IP da Subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}
variable "username_vm" {
  description = "Nome do usuário para login na VM"
  type        = string
  default     = "adminuser"
}
variable "password_vm" {
  description = "Senha do usuário para login na VM"
  type        = string
  default     = "SenhaForteLab@2026"
}
variable "vm_size" {
  description = "Tamanho da VM"
  type        = string
  default     = "Standard_D2als_v7"
}
variable "allowed_ssh_ip" {
  description = "Meu IP publico atual (ex: 200.x.x.x/32)"
  type        = string
}
variable "ssh_public_key" {
  description = "Chave publica SSH para acesso a VM"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}