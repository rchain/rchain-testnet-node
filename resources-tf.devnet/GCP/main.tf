variable "resources_name" { default = "devnet" }
variable "gcp_zone" { default = "us-east1-b" }
variable "node_count" { default = 5 }
variable "dns_suffix" { default = ".devnet.rchain-dev.tk" }
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
    prefix = "devnet"
  }
}
