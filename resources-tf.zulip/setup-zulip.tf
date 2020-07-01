# Must have called newinfra/setup-rnode-network.tf via IBM Cloud Console Schematics before this script
# Docs @ https://cloud.ibm.com/docs/terraform?topic=terraform-infrastructure-resources

variable "ibmcloud_api_key" {}
variable "iaas_classic_username" {}
variable "iaas_classic_api_key" {}
  
provider "ibm" {
        ibmcloud_api_key = var.ibmcloud_api_key
        iaas_classic_username = var.iaas_classic_username
        iaas_classic_api_key  = var.iaas_classic_api_key
} 
  
# Admin keys for root access
data "ibm_compute_ssh_key" "sre"    	   { label = "rchain-sre-ibm" }
 
data "ibm_security_group" "allow_ssh"      { name = "allow_ssh" }
data "ibm_security_group" "allow_https"      { name = "allow_https" }
data "ibm_security_group" "allow_outbound" { name = "allow_outbound" }

locals { 
   datacenter   = "dal13" 
   domain_name  = "rchain.coop"
}

# Finally create some servers
resource "ibm_compute_vm_instance" "zulip" {
  hostname                 = "zulip
  domain                   = local.domain_name
  flavor_key_name          = "U1_2X4X100"
  datacenter               = local.datacenter
  os_reference_code        = "UBUNTU_LATEST"
  local_disk               = false
  dedicated_acct_host_only = false
  ssh_key_ids                = [data.ibm_compute_ssh_key.sre.id]
  private_security_group_ids = [data.ibm_security_group.allow_ssh.id,
                                data.ibm_security_group.allow_outbound.id]
  public_security_group_ids  = [data.ibm_security_group.allow_https.id,
                                data.ibm_security_group.allow_ssh.id,
                                data.ibm_security_group.allow_outbound.id]
}
