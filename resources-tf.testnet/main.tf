variable "resources_name" { default = "testnet1" }
variable "gcp_zone" { default = "us-central1-a" }
variable "node_count" { default = 10 }
variable "dns_suffix" { default = ".testnet.rchain-dev.tk" }
variable "rchain_sre_git_crypt_key_file" {}

provider "google" {
  project = "developer-222401"
  zone = var.gcp_zone
}

provider "google-beta" {
  project = "developer-222401"
  zone = var.gcp_zone
}

terraform {
  required_version = ">= 0.12"
  backend "gcs" {
    bucket = "rchain-terraform-state"
    prefix = "testnet"
  }
}
