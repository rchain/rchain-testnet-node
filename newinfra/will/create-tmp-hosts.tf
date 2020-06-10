# Must have called newinfra/setup-rnode-network.tf via IBM Cloud Console Schematics before this script
# Docs @ https://cloud.ibm.com/docs/terraform?topic=terraform-infrastructure-resources

variable "ibmcloud_api_key" {}
variable "iaas_classic_username" {}
variable "iaas_classic_api_key" {}
  
provider "ibm" {
        ibmcloud_api_key      = var.ibmcloud_api_key
        iaas_classic_username = var.iaas_classic_username
        iaas_classic_api_key  = var.iaas_classic_api_key
} 
  
# Admin keys for root access
data "ibm_compute_ssh_key" "sre"    	{ label = "rchain-sre-ibm" }
data "ibm_compute_ssh_key" "user"    	{ label = "will-gcp" }
  
data "ibm_security_group" "allow_in_rnode2"{ name = "allow_in_rnode2"}
data "ibm_security_group" "allow_ssh"      { name = "allow_ssh" }
data "ibm_security_group" "allow_outbound" { name = "allow_outbound" }

# Finally create some servers
resource "ibm_compute_vm_instance" "tmp-hosts" {
  hostname              = "will-tmp"
  domain                = "dev.rchain.coop"
  flavor_key_name       = "U1_4X8X25"
  datacenter            = "fra05"
  os_reference_code     = "UBUNTU_LATEST"
  disks                 = ["500"]
  local_disk                 = false
  dedicated_acct_host_only   = false
  ssh_key_ids                = [data.ibm_compute_ssh_key.sre.id, data.ibm_compute_ssh_key.user.id]
  private_security_group_ids = [data.ibm_security_group.allow_ssh.id,
                                data.ibm_security_group.allow_outbound.id]
  public_security_group_ids  = [data.ibm_security_group.allow_in_rnode2.id,
                                data.ibm_security_group.allow_ssh.id,
                                data.ibm_security_group.allow_outbound.id]
  post_install_script_uri    = "https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/newinfra/setup-vm.sh"
} 
