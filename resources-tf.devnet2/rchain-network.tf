variable "rchain_sre_git_crypt_key_file" {}

provider "google" {
  project = "developer-222401"
  zone = var.gcp_zone
}

provider "google-beta" {
  project = "developer-222401"
  zone = var.gcp_zone
}

resource "google_service_account" "svc_account_node" {
  account_id = "${var.network_id}-node"
}

resource "google_storage_bucket_iam_member" "member" {
  bucket = "heapdumps.bucket.rchain-dev.tk"
  role = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.svc_account_node.email}"
}

data "google_compute_network" "default_network" {
  name = "default"
}

resource "google_compute_firewall" "fw_public" {
  name = "${var.network_id}-node-public"
  network = data.google_compute_network.default_network.self_link
  priority = 530
  target_tags = ["${var.network_id}-node"]
  allow {
    protocol = "tcp"
    ports = [22, 40403, 18080]
  }
}

resource "google_compute_firewall" "fw_node_rpc" {
  name = "${var.network_id}-node-rpc"
  network = data.google_compute_network.default_network.self_link
  priority = 540
  target_tags = ["${var.network_id}-node"]
  allow {
    protocol = "tcp"
    ports = [40401]
  }
}

resource "google_compute_firewall" "fw_node_p2p" {
  name = "${var.network_id}-node-p2p"
  network = data.google_compute_network.default_network.self_link
  priority = 550
  target_tags = ["${var.network_id}-node"]
  allow {
    protocol = "tcp"
    ports = [40400, 40404]
  }
}

resource "google_compute_firewall" "fw_node_deny" {
  name = "${var.network_id}-node-deny"
  network = data.google_compute_network.default_network.self_link
  priority = 5010
  target_tags = ["${var.network_id}-node"]
  deny {
    protocol = "tcp"
  }
  deny {
    protocol = "udp"
  }
}

resource "google_compute_address" "node_ext_addr" {
  count = var.node_count
  name = "${var.network_id}-node${count.index}"
  address_type = "EXTERNAL"
}

resource "google_dns_record_set" "node_dns_record" {
  count = var.node_count
  name = "node${count.index}.${var.domain}."
  managed_zone = "rchain-dev"
  type = "A"
  ttl = 3600
  rrdatas = [google_compute_address.node_ext_addr[count.index].address]
}

resource "google_compute_instance" "node_host" {
  count = var.node_count
  name = "${var.network_id}-node${count.index}"
  hostname = "node${count.index}.${var.domain}"
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = var.os_image
      size = var.disk_size
      type = var.disk_type
    }
  }

  tags = [
    "${var.network_id}-node",
    "collectd-out",
    "elasticsearch-out",
    "logstash-tcp-out",
    "logspout-http",
  ]

  service_account {
    email = google_service_account.svc_account_node.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  network_interface {
    network = data.google_compute_network.default_network.self_link
    access_config {
      nat_ip = google_compute_address.node_ext_addr[count.index].address
      //public_ptr_domain_name = "node${count.index}${var.dns_suffix}."
    }
  }

  depends_on = [google_dns_record_set.node_dns_record]

  connection {
    type = "ssh"
    host = self.network_interface[0].access_config[0].nat_ip
    user = "root"
    private_key = file("~/.ssh/google_compute_engine")
  }

  provisioner "file" {
    source = var.rchain_sre_git_crypt_key_file
    destination = "/root/rchain-sre-git-crypt-key"
  }

  provisioner "remote-exec" {
    script = "../bootstrap.${var.network_id}"
  }
}

