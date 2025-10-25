terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.156.0"
    }
  }
}

provider "yandex" {
  service_account_key_file = var.sa_key_path
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
}

data "terraform_remote_state" "infrastructure" {
  backend = "s3"
  config = {
    bucket                      = var.tfstate_bucket
    key                         = var.tfstate_key
    region                      = var.tfstate_region
    endpoints                   = { s3 = "https://storage.yandexcloud.net" }
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    use_path_style              = true
  }
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

data "yandex_vpc_network" "main" {
  name = var.vpc_name
}

data "yandex_vpc_subnet" "subnet-a" { name = "subnet-a" }
data "yandex_vpc_subnet" "subnet-b" { name = "subnet-b" }
data "yandex_vpc_subnet" "subnet-d" { name = "subnet-d" }

data "yandex_vpc_security_group" "my_sg" {
  name = var.security_group_name
}

locals {
  nodes = {
    master = {
      hostname    = "master"
      zone        = "ru-central1-a"
      subnet      = "subnet-a"
      cores       = 2
      memory      = 4
      preemptible = false
    }
    worker1 = {
      hostname      = "worker1"
      zone          = "ru-central1-b"
      subnet        = "subnet-b"
      cores         = 2
      memory        = 4
      preemptible   = true
      core_fraction = 20
    }
    worker2 = {
      hostname      = "worker2"
      zone          = "ru-central1-d"
      subnet        = "subnet-d"
      cores         = 2
      memory        = 4
      preemptible   = true
      core_fraction = 20
      platform_id   = "standard-v3"
    }
  }

  subnets = {
    subnet-a = data.yandex_vpc_subnet.subnet-a
    subnet-b = data.yandex_vpc_subnet.subnet-b
    subnet-d = data.yandex_vpc_subnet.subnet-d
  }
}

resource "yandex_compute_instance" "vm" {
  for_each    = local.nodes
  name        = each.key
  hostname    = each.value.hostname
  platform_id = lookup(each.value, "platform_id", "standard-v1")
  zone        = each.value.zone

  resources {
    cores         = each.value.cores
    memory        = each.value.memory
    core_fraction = lookup(each.value, "core_fraction", 100)
  }

  scheduling_policy {
    preemptible = each.value.preemptible
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 30
    }
  }

  network_interface {
    subnet_id          = local.subnets[each.value.subnet].id
    nat                = true
    security_group_ids = [data.yandex_vpc_security_group.my_sg.id]
  }

  metadata = {
    ssh-keys           = "ubuntu:${file(var.ssh_public_key_path)}"
    enable-oslogin     = "false"
    serial-port-enable = "1"

    user-data = <<EOF
users:
  - default
  - name: ubuntu
    ssh-authorized-keys:
      - ${file(var.ssh_public_key_path)}
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash
EOF
  }
}
