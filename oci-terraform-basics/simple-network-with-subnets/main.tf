terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key_path = var.private_key_path
  fingerprint      = var.fingerprint
  region           = var.region
}

# VCN Setup
resource "oci_core_vcn" "vcn" {
  compartment_id = var.compartment_id
  cidr_block     = "10.0.0.0/16"
  display_name   = "nginx-container-vcn"
}

# Public Subnet Setup (For the Container and Internet Access)
resource "oci_core_subnet" "public_subnet" {
  vcn_id = oci_core_vcn.vcn.id
  compartment_id     = var.compartment_id
  cidr_block         = "10.0.0.0/24"
  display_name       = "public-subnet"
  availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[1].name
  route_table_id     = oci_core_route_table.public_rt.id
}

# Private Subnet Setup (For the Container, now omitted)
# Not needed if we move the container to the public subnet.

# Internet Gateway (For Internet Access)
resource "oci_core_internet_gateway" "igw" {
  vcn_id = oci_core_vcn.vcn.id
  compartment_id     = var.compartment_id
  display_name       = "nginx-container-igw"
}

# Route Table for Public Subnet (To route traffic through the Internet Gateway)
resource "oci_core_route_table" "public_rt" {
  compartment_id     = var.compartment_id
  vcn_id = oci_core_vcn.vcn.id
  display_name       = "public-subnet-route-table"

  route_rules {
    description       = "Traffic to the internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
    route_type        = "STATIC"
  }
#   route_rules {
#     description       = "Traffic to OCI services"
#     destination       = var.all_oci_services_gw
#     destination_type  = "SERVICE_CIDR_BLOCK"
#     network_entity_id = oci_core_service_gateway.oke-selfmanaged-cluster-sgw.id
#     route_type        = "STATIC"
#   }
}


# Security List (Allow inbound HTTP and SSH)
resource "oci_core_default_security_list" "default_security_list" {

  manage_default_resource_id = oci_core_vcn.vcn.default_security_list_id
  compartment_id     = var.compartment_id
  display_name       = "default-security-list"

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  egress_security_rules {
    protocol = "all"
    destination = "0.0.0.0/0"
  }
}

# Security List (Allow inbound HTTP and SSH)
resource "oci_core_security_list" "security_list" {
  compartment_id     = var.compartment_id
  vcn_id = oci_core_vcn.vcn.id
  display_name       = "nginx-container-security-list"

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  egress_security_rules {
    protocol = "all"
    destination = "0.0.0.0/0"
  }
}

data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
}

# Create the NGINX Container Instance in the Public Subnet
resource "oci_container_instances_container_instance" "nginx_container" {
  compartment_id = var.compartment_id
  display_name   = "nginx-container-instance"
  availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[1].name
  shape = "CI.Standard.E4.Flex"

 shape_config{
    ocpus = 1
    memory_in_gbs = 2
 }
 containers {
    image_url = "nginx:latest"
  }
  vnics {
    subnet_id = oci_core_subnet.public_subnet.id
    is_public_ip_assigned = "true"
  }

}

output "container_instance_id" {
  value = oci_container_instances_container_instance.nginx_container.id
}

