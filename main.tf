terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token = "y0_AgAAAABpdBaYAATuwQAAAADhS5g0LgLru5B6SJKpZaf_JKE1uEyxqRw"
  cloud_id = "b1gmtujeraulvnf2bj1i"
  folder_id = "b1ghauke2h8p27vt648a"
  zone = "ru-central1-b"
}

resource "yandex_compute_instance" "vm" {

  count = 2
  name = "vm${count.index}"

  resources {
    core_fraction = 20
    cores = 2
    memory = 2
  }


  boot_disk {
    initialize_params {
        image_id = "fd80eup4e4h7mmodr9d4"
        size = 5
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat = true
  }

  placement_policy {
    placement_group_id = "${yandex_compute_placement_group.group1.id}"
  }

  metadata = {
    user-data = file("./metadate.yaml")
  }
}

resource "yandex_compute_placement_group" "group1" {
  name="test-pg1"
}

resource "yandex_vpc_network" "network-1"{
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1"{
  name           = "subnet1"
  zone           = "ru-central1-b"
  v4_cidr_blocks = ["192.168.10.0/24"]
  network_id     = "${yandex_vpc_network.network-1.id}"
}


resource "yandex_lb_network_load_balancer" "lb-1" {
  name = "lb-1"
  listener {
    name = "my-lb1"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }
  attached_target_group {
    target_group_id = yandex_lb_target_group.test-1.id
    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}


resource "yandex_lb_target_group" "test-1" {
  name      = "test-1"
  target {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    address   = yandex_compute_instance.vm[0].network_interface.0.ip_address
  }
  target {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    address   = yandex_compute_instance.vm[1].network_interface.0.ip_address
  }
}