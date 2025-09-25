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

# NAT Gateway
resource oci_core_nat_gateway oke-vnode-cluster-ngw {
  block_traffic  = "false"
  compartment_id = var.compartment_ocid
  display_name = "oke-vnode-cluster-ngw"
  vcn_id = oci_core_vcn.vcn-oke-vnode.id
}

# Internet Gateway
resource oci_core_internet_gateway oke-vnode-cluster-igw {
  compartment_id = var.compartment_ocid
  display_name = "oke-vnode-cluster-igw"
  enabled      = "true"
  vcn_id = oci_core_vcn.vcn-oke-vnode.id
}

data "oci_core_services" "all" {}

# Service Gateway
resource oci_core_service_gateway oke-vnode-cluster-sgw {
  compartment_id = var.compartment_ocid
  display_name = "oke-vnode-cluster-sgw"
  services {
     service_id = data.oci_core_services.all.services[0].id
  }
  vcn_id = oci_core_vcn.vcn-oke-vnode.id
}

# VCN
resource oci_core_vcn vcn-oke-vnode {
  cidr_blocks = [
    var.cloud_network.vcn_cidr_block,
  ]

  compartment_id = var.compartment_ocid
  display_name = "vcn-oke-vnode"
  dns_label    = "okemoncluster"
}

# Node subnet
resource oci_core_subnet oke-vnode-cluster-nodesubnet-regional {
  cidr_block     = var.cloud_network.node_subnet_cidr
  compartment_id = var.compartment_ocid
  display_name    = "oke-vnode-cluster-nodesubnet-regional"
  dns_label       = "monsubabe82f780"
  prohibit_internet_ingress  = "true"
  prohibit_public_ip_on_vnic = "true"
  route_table_id             = oci_core_route_table.oke-vnode-cluster-private-routetable.id

  security_list_ids = [
    oci_core_security_list.oke-vnode-cluster-sl-nodeseclist.id,
  ]
  vcn_id = oci_core_vcn.vcn-oke-vnode.id
}

# K8S Endpoint subnet - PUBLIC
resource oci_core_subnet oke-vnode-cluster-k8sApiEndpoint-subnet-regional {
  cidr_block     = var.cloud_network.k8sApiEndpoint_cidr
  compartment_id = var.compartment_ocid
  display_name    = "oke-vnode-cluster-k8sApiEndpoint-subnet-regional"
  dns_label       = "sub25e3ca65b"
  prohibit_internet_ingress  = "false"
  prohibit_public_ip_on_vnic = "false"
  route_table_id             = oci_core_vcn.vcn-oke-vnode.default_route_table_id

  security_list_ids = [
    oci_core_security_list.oke-vnode-cluster-sl-k8sApiEndpoint.id,
  ]
  vcn_id = oci_core_vcn.vcn-oke-vnode.id
}

# Load Balancer subnet - PUBLIC
resource oci_core_subnet oke-vnode-cluster-loadbalancer-subnet-regional {
  cidr_block     = var.cloud_network.loadBalancer_cidr
  compartment_id = var.compartment_ocid
  display_name    = "oke-vnode-cluster-loadbalancer-subnet-regional"
  dns_label       = "lbsub95ab0274d"
  prohibit_internet_ingress  = "false"
  prohibit_public_ip_on_vnic = "false"
  route_table_id             = oci_core_vcn.vcn-oke-vnode.default_route_table_id

  security_list_ids = [
    oci_core_vcn.vcn-oke-vnode.default_security_list_id,
  ]
  vcn_id = oci_core_vcn.vcn-oke-vnode.id
}

# Private Route table
resource oci_core_route_table oke-vnode-cluster-private-routetable {
  compartment_id = var.compartment_ocid
  display_name = "oke-vnode-cluster-private-routetable"

  route_rules {
    description       = "Traffic to the internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.oke-vnode-cluster-ngw.id
    route_type        = "STATIC"
  }
  route_rules {
    description       = "Traffic to OCI services"
    destination       = var.all_oci_services_gw
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.oke-vnode-cluster-sgw.id
    route_type        = "STATIC"
  }
  vcn_id = oci_core_vcn.vcn-oke-vnode.id
}

# Public Route table
resource oci_core_default_route_table oke-vnode-cluster-public-routetable {
  compartment_id = var.compartment_ocid
  display_name = "oke-vnode-cluster-public-routetable"
  manage_default_resource_id = oci_core_vcn.vcn-oke-vnode.default_route_table_id

  route_rules {
    description       = "Traffic to/from internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.oke-vnode-cluster-igw.id
    route_type        = "STATIC"
  }
}

# API Endpoint SL - PUBLIC
resource oci_core_security_list oke-vnode-cluster-sl-k8sApiEndpoint {
  compartment_id = var.compartment_ocid
  display_name = "oke-vnode-cluster-sl-k8sApiEndpoint"
  
  egress_security_rules {
    description      = "Allow Kubernetes Control Plane to communicate with OKE"
    destination      = var.all_oci_services_gw
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol  = "6"
    stateless = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  egress_security_rules {
    description      = "All traffic to worker nodes"
    destination      = "10.0.10.0/24"
    destination_type = "CIDR_BLOCK"
    protocol  = "6"
    stateless = "false"
  }
  egress_security_rules {
    description      = "Path discovery"
    destination      = "10.0.10.0/24"
    destination_type = "CIDR_BLOCK"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol  = "1"
    stateless = "false"
  }
  ingress_security_rules {
    description = "External access to Kubernetes API endpoint"
    protocol    = "6"
    source      =  var.my_ipaddress #Access only from dev machine
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "6443"
      min = "6443"
    }
  }
  ingress_security_rules {
    description = "Kubernetes worker to Kubernetes API endpoint communication"
    protocol    = "6"
    source      = "10.0.10.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "6443"
      min = "6443"
    }
  }
  ingress_security_rules {
    description = "Kubernetes worker to control plane communication"
    protocol    = "6"
    source      = "10.0.10.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "12250"
      min = "12250"
    }
  }
  ingress_security_rules {
    description = "Path discovery"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol    = "1"
    source      = "10.0.10.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  vcn_id = oci_core_vcn.vcn-oke-vnode.id
}

# Node Security List
resource oci_core_security_list oke-vnode-cluster-sl-nodeseclist {
  compartment_id = var.compartment_ocid
  display_name = "oke-vnode-cluster-sl-nodeseclist"
  
  egress_security_rules {
    description      = "Allow pods on one worker node to communicate with pods on other worker nodes"
    destination      = "10.0.10.0/24"
    destination_type = "CIDR_BLOCK"
    protocol  = "all"
    stateless = "false"
  }
  egress_security_rules {
    description      = "Access to Kubernetes API Endpoint"
    destination      = "10.0.0.0/28"
    destination_type = "CIDR_BLOCK"
    protocol  = "6"
    stateless = "false"
    tcp_options {
      max = "6443"
      min = "6443"
    }
  }
  egress_security_rules {
    description      = "Kubernetes worker to control plane communication"
    destination      = "10.0.0.0/28"
    destination_type = "CIDR_BLOCK"
    protocol  = "6"
    stateless = "false"
    tcp_options {
      max = "12250"
      min = "12250"
    }
  }
  egress_security_rules {
    description      = "Path discovery"
    destination      = "10.0.0.0/28"
    destination_type = "CIDR_BLOCK"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol  = "1"
    stateless = "false"
  }
  egress_security_rules {
    description      = "Allow nodes to communicate with OKE to ensure correct start-up and continued functioning"
    destination      = var.all_oci_services_gw
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol  = "6"
    stateless = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  egress_security_rules {
    description      = "ICMP Access from Kubernetes Control Plane"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol  = "1"
    stateless = "false"
  }
  egress_security_rules {
    description      = "Worker Nodes access to Internet"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol  = "all"
    stateless = "false"
  }
  ingress_security_rules {
    description = "Allow pods on one worker node to communicate with pods on other worker nodes"
    protocol    = "all"
    source      = "10.0.10.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    description = "Path discovery"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol    = "1"
    source      = "10.0.0.0/28"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    description = "TCP access from Kubernetes Control Plane"
    protocol    = "6"
    source      = "10.0.0.0/28"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    description = "Inbound SSH traffic to worker nodes"
    protocol    = "6"
    source      = var.my_ipaddress  #Access only from dev machine
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  ingress_security_rules {
    description = "Allow TCP traffic from Load Balancers to node ports"
    protocol    = "6"
    source      = "10.0.20.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "32767"
      min = "30000"
    }
  }
  ingress_security_rules {
    description = "Allow TCP traffic from Load Balancers to pod's healthcheck port"
    protocol    = "6"
    source      = "10.0.20.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "10256"
      min = "10256"
    }
  }
  vcn_id = oci_core_vcn.vcn-oke-vnode.id
}

# Load balancer SL - PUBLIC
resource oci_core_default_security_list oke-vnode-cluster-sl-loadbalancer {
  compartment_id = var.compartment_ocid
  display_name = "oke-vnode-cluster-sl-loadbalancer"
  egress_security_rules {
    description      = "Allow TCP traffic from Load Balancers to node ports"
    destination      = "10.0.10.0/24"
    destination_type = "CIDR_BLOCK"
    protocol  = "6"
    stateless = "false"
    tcp_options {
      max = "32767"
      min = "30000"
    }
  }
  egress_security_rules {
    description      = "Allow TCP traffic from Load Balancers to pod's healthcheck port"
    destination      = "10.0.10.0/24"
    destination_type = "CIDR_BLOCK"
    protocol  = "6"
    stateless = "false"
    tcp_options {
      max = "10256"
      min = "10256"
    }
  }
  ingress_security_rules {
    description = "Allow HTTP traffic from my_ipaddress to LB port 80"
    protocol    = "6"
    source      = var.my_ipaddress #Access only from dev machine
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "80"
      min = "80"
    }
  }
  ingress_security_rules {
    description = "Allow HTTPS traffic from my_ipaddress to LB port 443"
    protocol    = "6"
    source      = var.my_ipaddress #Access only from dev machine
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  ingress_security_rules {
    description = "Allow HTTP traffic from my_ipaddress to LB port 8080"
    protocol    = "6"
    source      = var.my_ipaddress #Access only from dev machine
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "8080"
      min = "8080"
    }
  }
  manage_default_resource_id = oci_core_vcn.vcn-oke-vnode.default_security_list_id
}



