resource "ibm_compute_vm_instance" "tmpvm" {
  count                    = local.node_count
  hostname                 = "tmp${count.index}"
  domain                   = local.domain_name
  flavor_key_name          = "U1_1X2X25"
  datacenter               = local.datacenter
  os_reference_code        = "UBUNTU_LATEST"
  disks                    = ["10"]
  local_disk               = false
  ssh_key_ids              = [  data.ibm_compute_ssh_key.ssh-key.id, data.ibm_compute_ssh_key.gsj-ssh-key.id]
  dedicated_acct_host_only =    false
#placement_group_id       =   ibm_compute_placement_group.tmpgrp.id
  private_security_group_ids = [data.ibm_security_group.allow_ssh.id,
                                data.ibm_security_group.allow_outbound.id]
  public_security_group_ids  = [data.ibm_security_group.allow_in_rnode2.id,
                                data.ibm_security_group.allow_ssh.id,
                                data.ibm_security_group.allow_outbound.id]
  post_install_script_uri =  "https://raw.githubusercontent.com/gsj5/rchain-testnet-node/gsj5_branch/bootstrap.sandbox.ibm"
}
