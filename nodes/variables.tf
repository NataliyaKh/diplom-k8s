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
