# Should be called via IBM Cloud Console Schematics
# Docs @ https://cloud.ibm.com/docs/terraform?topic=terraform-infrastructure-resources

variable "ibmcloud_api_key" {}
variable "iaas_classic_username" {}
variable "iaas_classic_api_key" {}

provider "ibm" {
        ibmcloud_api_key = var.ibmcloud_api_key
        iaas_classic_username = var.iaas_classic_username
        iaas_classic_api_key  = var.iaas_classic_api_key
}

resource "ibm_security_group" "allow_in_rnode2" {
    name = "allow_in_rnode2"
    description = "allow inbound traffic for rnode"
}

resource "ibm_security_group_rule" "allow_in_rnode_ports" {
    direction = "ingress"
    ether_type = "IPv4"
    port_range_min = 40400
    port_range_max = 40401
    protocol = "tcp"
    security_group_id = ibm_security_group.allow_in_rnode2.id
}

# 40402 - User specifically has to open internal gRPC port for proposing

resource "ibm_security_group_rule" "allow_in_rnode_http" {
    direction = "ingress"
    ether_type = "IPv4"
    port_range_min = 40403
    port_range_max = 40403
    protocol = "tcp"
    security_group_id = ibm_security_group.allow_in_rnode2.id
}

resource "ibm_security_group_rule" "allow_in_rnode_discovery" {
    direction = "ingress"
    ether_type = "IPv4"
    port_range_min = 40404
    port_range_max = 40404
    protocol = "tcp"
    security_group_id = ibm_security_group.allow_in_rnode2.id
}

# 40405 - User specifically has to open admin gRPC api port 

# Secure gRPC api port
resource "ibm_security_group_rule" "allow_in_grpcs_api_proxy" {
    direction = "ingress"
    ether_type = "IPv4"
    port_range_min = 40411
    port_range_max = 40411
    protocol = "tcp"
    security_group_id = ibm_security_group.allow_in_rnode2.id
}

resource "ibm_security_group_rule" "allow_in_http" {
    direction = "ingress"
    ether_type = "IPv4"
    port_range_min = 80
    port_range_max = 80
    protocol = "tcp"
    security_group_id = ibm_security_group.allow_in_rnode2.id
}

resource "ibm_security_group_rule" "allow_in_https" {
    direction = "ingress"
    ether_type = "IPv4"
    port_range_min = 443
    port_range_max = 443
    protocol = "tcp"
    security_group_id = ibm_security_group.allow_in_rnode2.id
}

resource "ibm_security_group_rule" "allow_in_logstash" {
    direction = "ingress"
    ether_type = "IPv4"
    port_range_min = 8181
    port_range_max = 8181
    protocol = "tcp"
    security_group_id = ibm_security_group.allow_in_rnode2.id
}

resource "ibm_security_group_rule" "allow_in_logview" {
    direction = "ingress"
    ether_type = "IPv4"
    port_range_min = 18080
    port_range_max = 18080
    protocol = "tcp"
    security_group_id = ibm_security_group.allow_in_rnode2.id
}

