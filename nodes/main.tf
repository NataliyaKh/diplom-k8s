terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.99"
    }
  }
}


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
      memory      = 4
      preemptible = false
    }
    worker1 = {
      hostname    = "worker1"
      zone        = "ru-central1-b"
      subnet      = "subnet-b"
      cores       = 2
      memory      = 4
      preemptible = true
      core_fraction = 20
    }
    worker2 = {
      hostname    = "worker2"
      zone        = "ru-central1-d"
      subnet      = "subnet-d"
      cores       = 2
      memory      = 4
      preemptible = true
      core_fraction = 20
      platform_id = "standard-v3"
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
    subnet_id = local.subnets[each.value.subnet].id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}
