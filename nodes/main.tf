provider "yandex" {
  service_account_key_file = var.sa_key_path
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2004-lts"
}

data "yandex_vpc_network" "main" {
  name = "diplom-vpc"
}

data "yandex_vpc_subnet" "subnet-a" { name = "subnet-a" }
data "yandex_vpc_subnet" "subnet-b" { name = "subnet-b" }
data "yandex_vpc_subnet" "subnet-d" { name = "subnet-d" }

locals {
  nodes = {
    master = {
      hostname    = "master"
      zone        = "ru-central1-a"
      subnet      = "subnet-a"
      cores       = 2
      memory      = 4096
      preemptible = false
    }
    worker1 = {
      hostname    = "worker1"
      zone        = "ru-central1-b"
      subnet      = "subnet-b"
      cores       = 2
      memory      = 4096
      preemptible = true
    }
    worker2 = {
      hostname    = "worker2"
      zone        = "ru-central1-d"
      subnet      = "subnet-d"
      cores       = 2
      memory      = 4096
      preemptible = true
    }
  }
}

resource "yandex_compute_instance" "vm" {
  for_each    = local.nodes
  name        = each.key
  hostname    = each.value.hostname
  platform_id = "standard-v1"
  zone        = each.value.zone

  resources {
    cores  = each.value.cores
    memory = each.value.memory
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
    subnet_id = data.yandex_vpc_subnet[each.value.subnet].id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}
