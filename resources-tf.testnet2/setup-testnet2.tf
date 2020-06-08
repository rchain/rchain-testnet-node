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
data ibm_compute_ssh_key "sre"    	{ label = "rchain-sre-ibm" }
data ibm_compute_ssh_key "gsj"    	{ label = "gsj-ibm-rsa" }
data ibm_compute_ssh_key "nutzipper"    { label = "nutzipper-gcp" }
  
data "ibm_security_group" "allow_in_rnode2"{ name = "allow_in_rnode2"}
data "ibm_security_group" "allow_ssh"      { name = "allow_ssh" }
data "ibm_security_group" "allow_http"     { name = "allow_http" }
data "ibm_security_group" "allow_https"    { name = "allow_https" }
data "ibm_security_group" "allow_outbound" { name = "allow_outbound" }
data "ibm_security_group" "allow_in_rnode2"   { name = "allow_in_rnode2" }

# Finally create some servers
locals { testnet_list =[{hostname = "node0", datacenter = "lon04"},
                        {hostname = "node1", datacenter = "fra04"},
                        {hostname = "node2", datacenter = "wdc04"},
                        {hostname = "node3", datacenter = "dal05"},
                        {hostname = "node4", datacenter = "tok04"},
                        {hostname = "observer", datacenter = "wdc04"} ] }

resource "ibm_compute_vm_instance" "testnet" {
  count                 = length(local.testnet_list)
  hostname              = local.testnet_list[count.index].hostname
  domain                = "testnet.rchain.coop"
  flavor_key_name       = "U1_4X8X25"
  datacenter            = local.testnet_list[count.index].datacenter
  os_reference_code     = "UBUNTU_LATEST"
  disks                 = ["250"]
  local_disk            = false
  ssh_key_ids              = [  data.ibm_compute_ssh_key.sre.id,
  				data.ibm_compute_ssh_key.gsj.key.id,
  				data.ibm_compute_ssh_key.nutzipper.id]
  dedicated_acct_host_only = false
  private_security_group_ids = [data.ibm_security_group.allow_ssh.id,
                                data.ibm_security_group.allow_outbound.id]
  public_security_group_ids=[   data.ibm_security_group.allow_in_rnode2.id,
                                data.ibm_security_group.allow_ssh.id,
                                data.ibm_security_group.allow_outbound.id]
  post_install_script_uri =  "https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/newinfra/setup-vm.sh"
} 
