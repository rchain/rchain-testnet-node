# Docs @ https://cloud.ibm.com/docs/terraform?topic=terraform-infrastructure-resources 
#
variable "ibmcloud_api_key" {}
variable "resource_group" {}
variable "region" {}
variable "rchain_owner_public_key" {}
variable "vm_server" {}


provider "ibm" {
        ibmcloud_api_key= var.ibmcloud_api_key
        generation      = 2
        region          = var.region
}

locals {
        vm_profile      = "bx2-4x16"
        zones           = 3
}

data "ibm_is_image"       "vm_image"    { name = "ibm-ubuntu-18-04-1-minimal-amd64-2" }
data "ibm_resource_group" "res_grp" 	{ name = var.resource_group }

resource "ibm_is_ssh_key" "rchain-owner" {
	name		= "rchain-owner-key"
	resource_group	= data.ibm_resource_group.res_grp.id
	public_key	= var.rchain_owner_public_key
}

# Create gen2 VPC in each region
resource "ibm_is_vpc" "vpc1" {
        name		= "${var.resource_group}-${var.region}-vpc"
        resource_group	= data.ibm_resource_group.res_grp.id
        tags		= [ "dev" ]
}

resource "ibm_is_instance" "vm1" {
	name	= var.vm_server
	vpc	= ibm_is_vpc.vpc1.id
	zone	= "${var.region}-${count.index % local.zones + 1}"
	profile	= local.vm_profile
	image	= data.ibm_is_image.vm_image.id
	volumes	= [ibm_is_volume.vol1[count.index].id]
	keys	= [ibm_is_ssh_key.rchain-owner.id]
        tags	= [ "dev" ]
	boot_volume  { name = "${var.resource_group}-${var.region}-${var.vm_server}-boot" }
	resource_group = data.ibm_resource_group.res_grp.id
	user_data = data.template_cloudinit_config.cloud-init-vm.rendered
	primary_network_interface {
		name	= "eth0"
		subnet	= ibm_is_subnet.subnet1[count.index % local.zones].id
		port_speed	= "1000"
		security_groups = [ ibm_is_security_group.allow-in-rnode.id ]
	}
}

resource "ibm_is_volume" "vol1" {
	name	= "${var.resource_group}-${var.region}-${var.vm_server}-data"
	profile	= "5iops-tier"
	zone	= "${var.region}-${count.index % local.zones + 1}"
        tags	= [ "dev" ]
	capacity= 1000
	resource_group = data.ibm_resource_group.res_grp.id
}

resource "ibm_is_floating_ip" "fip1" {
	name	= "${var.resource_group}-${var.region}-${var.vm_server}-fip"
	target	= ibm_is_instance.vm1[count.index].primary_network_interface.0.id
        tags	= [ "dev" ]
	resource_group = data.ibm_resource_group.res_grp.id
}

data "template_cloudinit_config" "cloud-init-vm" {
	base64_encode = false
	gzip          = false

	part {
		content = <<EOF
#cloud-config
package-update: true
package_upgrade: true
packages:
- docker.io
- docker-compose
- collectd
- certbot
- bc
- openjdk-11-jdk-headless

runcmd:
  - 'curl https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/node-files.mainnet-val/setup-mainnet-vm.sh | /bin/bash -s'

power_state:
 mode: reboot
 message: Rebooting server now.
 timeout: 30
 condition: True
 EOF
	}
}


#######################  Security Group ##############################################

resource "ibm_is_security_group" "allow-in-rnode" {
	name		= "${var.resource_group}-${var.region}-allow-in-rnode-sg"
	vpc		= ibm_is_vpc.vpc1.id
	resource_group	= data.ibm_resource_group.res_grp.id
}

resource "ibm_is_security_group_rule" "allow_out_all" {
	group	  = ibm_is_security_group.allow-in-rnode.id
	remote	  = "0.0.0.0/0"
	direction = "outbound"
}

resource "ibm_is_security_group_rule" "allow_in_icmp" {
	group	  = ibm_is_security_group.allow-in-rnode.id
	direction = "inbound"
	remote	  = "0.0.0.0/0"
	icmp {
		code = 0
		type = 8
	}
}

resource "ibm_is_security_group_rule" "allow_in_rnode_ports1" {
	group	  = ibm_is_security_group.allow-in-rnode.id
	direction = "inbound"
	remote	  = "0.0.0.0/0"
	tcp {
		port_min = 40400
		port_max = 40401
	}
}

resource "ibm_is_security_group_rule" "allow_in_rnode_propose" {
	group	  = ibm_is_security_group.allow-in-rnode.id
	direction = "inbound"
	remote	  = "34.76.132.208"
	tcp {
		port_min = 40402
		port_max = 40402
    }
}

resource "ibm_is_security_group_rule" "allow_in_rnode_ports2" {
	group	  = ibm_is_security_group.allow-in-rnode.id
	remote	  = "0.0.0.0/0"
	direction = "inbound"
	tcp {
		port_min = 40403
		port_max = 40411
	}
}

resource "ibm_is_security_group_rule" "allow_in_http" {
	group      = ibm_is_security_group.allow-in-rnode.id
	direction  = "inbound"
	remote     = "0.0.0.0/0"
	tcp {
		port_min = 80
		port_max = 80
	}
}

resource "ibm_is_security_group_rule" "allow_in_https" {
	group	  = ibm_is_security_group.allow-in-rnode.id
	direction = "inbound"
	remote	  = "0.0.0.0/0"
	tcp {
	        port_min = 443
		port_max = 443
	}
}

resource "ibm_is_security_group_rule" "allow_in_logview" {
	group	  = ibm_is_security_group.allow-in-rnode.id
	direction = "inbound"
	remote	  = "0.0.0.0/0"
	tcp {
		port_min = 18080
		port_max = 18080
	}
}
resource "ibm_is_security_group_rule" "allow_in_ssh" {
	group	  = ibm_is_security_group.allow-in-rnode.id
	direction = "inbound"
	remote	  = "0.0.0.0/0"
	tcp {
		port_min = 22
		port_max = 22
	}
}


#################################### Network ##############################################################
# Create subnet in each zone and set ACLs.  Unfortunately, subnet ACLs are stateless, therefore need to open 
# ports >1024 when making outbound connections
#################################### Network ##############################################################
resource "ibm_is_subnet" "subnet1" {
	count		= local.zones
	name		= "${var.resource_group}-${var.region}-${count.index + 1}-sn"
	vpc		= ibm_is_vpc.vpc1.id
	zone		= "${var.region}-${count.index + 1}"
	resource_group	= data.ibm_resource_group.res_grp.id
	network_acl	= ibm_is_network_acl.acl1.id
	total_ipv4_address_count = 8
}

resource "ibm_is_network_acl" "acl1" {
	name		= "${var.resource_group}-${var.region}-acl"
	vpc		= ibm_is_vpc.vpc1.id
	resource_group	= data.ibm_resource_group.res_grp.id
	rules {
		name        = "all-out"
		action      = "allow"
		source      = "0.0.0.0/0"
		destination = "0.0.0.0/0"
		direction   = "outbound"
	}
	rules {
		name        = "tcp-high-in"
		action      = "allow"
		source      = "0.0.0.0/0"
		destination = "0.0.0.0/0"
		direction   = "inbound"
		tcp {
			port_min = 1024
			port_max = 65535
		}
	}
	rules {
		name        = "udp-high-in"
		action      = "allow"
		source      = "0.0.0.0/0"
		destination = "0.0.0.0/0"
		direction   = "inbound"
		udp {
			port_min = 1024
			port_max = 65535
		}
	}
	rules {
		name        = "dns-in"
		action      = "allow"
		source      = "0.0.0.0/0"
		destination = "0.0.0.0/0"
		direction   = "inbound"
		udp {
			port_min = 53
			port_max = 53
		}
	}
	rules {
		name        = "ssh-in"
		action      = "allow"
		source      = "0.0.0.0/0"
		destination = "0.0.0.0/0"
		direction   = "inbound"
		tcp {
			port_min = 22
			port_max = 22
		}
	}
	rules {
		name        = "http-in"
		action      = "allow"
		source      = "0.0.0.0/0"
		destination = "0.0.0.0/0"
		direction   = "inbound"
		tcp {
			port_min = 80
			port_max = 80
		}
	}
	rules {
		name        = "https-in"
		action      = "allow"
		source      = "0.0.0.0/0"
		destination = "0.0.0.0/0"
		direction   = "inbound"
		tcp {
			port_min = 443
			port_max = 443
		}
	}
}

