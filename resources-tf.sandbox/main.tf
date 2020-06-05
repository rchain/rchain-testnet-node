variable "ibmcloud_api_key" {}
variable "iaas_classic_username" {}
variable "iaas_classic_api_key" {}
  
provider "ibm" {
        ibmcloud_api_key = var.ibmcloud_api_key
        iaas_classic_username = var.iaas_classic_username
        iaas_classic_api_key  = var.iaas_classic_api_key
} 
  
data ibm_compute_ssh_key "ssh-key"    { label = "rchain-sre-ibm" }
data ibm_compute_ssh_key "gsj-ssh-key"    { label = "gsj-ibm-rsa" }
  
data "ibm_security_group" "allow_ssh"      { name = "allow_ssh" }
data "ibm_security_group" "allow_http"     { name = "allow_http" }
data "ibm_security_group" "allow_https"    { name = "allow_https" }
data "ibm_security_group" "allow_outbound" { name = "allow_outbound" }
data "ibm_security_group" "allow_in_rnode2"   { name = "allow_in_rnode2" }
