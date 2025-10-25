variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "sa_key_path" {
  type = string
}

variable "ssh_public_key_path" {
  type    = string
  default = "/root/.ssh/id_ed25519.pub"
}

variable "tfstate_bucket" {
  type = string
}

variable "tfstate_key" {
  type = string
}

variable "tfstate_region" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "security_group_name" {
  type = string
}
