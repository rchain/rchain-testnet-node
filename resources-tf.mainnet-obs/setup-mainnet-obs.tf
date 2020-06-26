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
  
data "ibm_security_group" "allow_in_rnode2"{ name = "allow_in_rnode2"}
data "ibm_security_group" "allow_ssh"      { name = "allow_ssh" }
data "ibm_security_group" "allow_outbound" { name = "allow_outbound" }

# Finally create some servers
locals { vm_list = [    {hostname = "observer-ap-jp", datacenter = "tok05"},
                        {hostname = "observer-eu-de", datacenter = "fra05"},
                        {hostname = "observer-us-dc", datacenter = "wdc07"} ] }
   
resource "ibm_compute_vm_instance" "mainnet-obs" {
  count                 = length(local.vm_list)
  hostname              = local.vm_list[count.index].hostname
  domain                = "services.mainnet.rchain.coop"
  flavor_key_name       = "B1_4X16X25"
  datacenter            = local.vm_list[count.index].datacenter
  os_reference_code     = "UBUNTU_LATEST"
  disks                 = ["500"]
  local_disk                 = false
  dedicated_acct_host_only   = false
  ssh_key_ids                = [data.ibm_compute_ssh_key.sre.id]
  private_security_group_ids = [data.ibm_security_group.allow_ssh.id,
                                data.ibm_security_group.allow_outbound.id]
  public_security_group_ids  = [data.ibm_security_group.allow_in_rnode2.id,
                                data.ibm_security_group.allow_ssh.id,
                                data.ibm_security_group.allow_outbound.id]
  post_install_script_uri    = "https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/newinfra/setup-vm.sh"
}

locals { vm_list_exch =[{hostname = "observer-ap-exch", datacenter = "hkg02"},
                        {hostname = "observer-ap-exch2", datacenter = "tok04"} ] }
   
resource "ibm_compute_vm_instance" "mainnet-obs_exch" {
  count                 = length(local.vm_list_exch)
  hostname              = local.vm_list_exch[count.index].hostname
  domain                = "services.mainnet.rchain.coop"
  flavor_key_name       = "B1_8X32X25"
  datacenter            = local.vm_list_exch[count.index].datacenter
  os_reference_code     = "UBUNTU_LATEST"
  disks                 = ["500"]
  local_disk                 = false
  dedicated_acct_host_only   = false
  ssh_key_ids                = [data.ibm_compute_ssh_key.sre.id]
  private_security_group_ids = [data.ibm_security_group.allow_ssh.id,
                                data.ibm_security_group.allow_outbound.id]
  public_security_group_ids  = [data.ibm_security_group.allow_in_rnode2.id,
                                data.ibm_security_group.allow_ssh.id,
                                data.ibm_security_group.allow_outbound.id]
  post_install_script_uri    = "https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/newinfra/setup-vm.sh"
} 
