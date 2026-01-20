variable "location" {
  type    = string
  default = "eastus"
}

variable "env" {
  type    = string
  default = "dev"
}
variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "ssh_public_key_path" {
  type    = string
  default = "../../keys/vmss_rsa.pub"
}

