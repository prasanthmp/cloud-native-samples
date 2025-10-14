resource oci_containerengine_cluster oke-mon-cluster {
  kubernetes_version = var.kubernetes.version
  name               = var.kubernetes.cluster_name
  type               = var.kubernetes.type
  vcn_id             = oci_core_vcn.vcn-oke-mon.id
  compartment_id     = var.compartment_ocid   

  cluster_pod_network_options {
    cni_type = "OCI_VCN_IP_NATIVE"
  }
  endpoint_config {
    is_public_ip_enabled = "true"
    nsg_ids = [
    ]
    subnet_id = oci_core_subnet.oke-mon-cluster-k8sApiEndpoint-subnet-regional.id
  }
  image_policy_config {
    is_policy_enabled = "false"
  }
  options {
    add_ons {
      is_kubernetes_dashboard_enabled = "false"
      is_tiller_enabled               = "false"
    }
    admission_controller_options {
      is_pod_security_policy_enabled = "false"
    }
    ip_families = [
      "IPv4",
    ]
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
    service_lb_subnet_ids = [
      oci_core_subnet.oke-mon-cluster-loadbalancer-subnet-regional.id,
    ]
  }
}

data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
}

resource oci_containerengine_node_pool oke_node_pool {
  cluster_id     = oci_containerengine_cluster.oke-mon-cluster.id
  compartment_id = var.compartment_ocid
  name = var.kubernetes.node_pool_name
  node_shape = var.kubernetes.node_pool_shape 

  node_shape_config {
    ocpus         = var.node_shape.ocpus
    memory_in_gbs = var.node_shape.memory
  }
    node_source_details {
    source_type = "image"
    image_id    = var.node_image_id  # Must be a valid image OCID
  }
  node_config_details {
    size = var.kubernetes.number_of_nodes # Number of worker nodes
      placement_configs {
        availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[0].name
        subnet_id           = oci_core_subnet.oke-mon-cluster-nodesubnet-regional.id
      }
    node_pool_pod_network_option_details {
      cni_type          = "OCI_VCN_IP_NATIVE"
      max_pods_per_node = "31"
      pod_nsg_ids = [
      ]
      pod_subnet_ids = [
        oci_core_subnet.oke-mon-cluster-nodesubnet-regional.id,
      ]
    }   
   }
   depends_on = [oci_containerengine_cluster.oke-mon-cluster]
}

data "oci_containerengine_cluster_kube_config" "kubeconfig" {
  cluster_id = "${oci_containerengine_cluster.oke-mon-cluster.id}"
  token_version = "2.0.0"
}

# provider "kubernetes" {
#   host                   = yamldecode(data.oci_containerengine_cluster_kube_config.kubeconfig.content).clusters[0].cluster.server
#   cluster_ca_certificate = base64decode(
#     yamldecode(data.oci_containerengine_cluster_kube_config.kubeconfig.content).clusters[0].cluster["certificate-authority-data"]
#   )
#   exec {
#     api_version = yamldecode(data.oci_containerengine_cluster_kube_config.kubeconfig.content).users[0].user.exec.apiVersion
#     command     = yamldecode(data.oci_containerengine_cluster_kube_config.kubeconfig.content).users[0].user.exec.command
#     args        = yamldecode(data.oci_containerengine_cluster_kube_config.kubeconfig.content).users[0].user.exec.args
#   }
# }

# Null resource: generate kubeconfig locally
resource "null_resource" "generate_kubeconfig" {
  provisioner "local-exec" {
    command = <<EOT
      oci ce cluster create-kubeconfig \
        --cluster-id ${oci_containerengine_cluster.oke-mon-cluster.id} \
        --file ${path.module}/kubeconfig \
        --region ${var.region} \
        --token-version 2.0.0 \
        --kube-endpoint PUBLIC_ENDPOINT
    EOT
  }
  depends_on = [oci_containerengine_node_pool.oke_node_pool]
}

resource "null_resource" "copy_kubeconfig" {
  provisioner "local-exec" {
    command = <<EOT
      mkdir -p $HOME/.kube
      cp ${path.module}/kubeconfig $HOME/.kube/config
      chmod 600 $HOME/.kube/config
      EOT
  }
  depends_on = [null_resource.generate_kubeconfig]
}

# Add a delay of 30s after copying kubeconfig
resource "time_sleep" "wait_for_kubeconfig" {
  depends_on = [null_resource.copy_kubeconfig]
  create_duration = "20s"
}


