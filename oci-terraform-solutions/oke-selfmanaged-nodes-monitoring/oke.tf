resource oci_containerengine_cluster oke-selfmanaged-cluster {
  kubernetes_version = var.kubernetes.version
  name               = var.kubernetes.cluster_name
  type   = var.kubernetes.type
  vcn_id = oci_core_vcn.vcn-oke-managed.id  
  compartment_id = var.compartment_ocid  

  cluster_pod_network_options {
    cni_type = "OCI_VCN_IP_NATIVE"
  }
  endpoint_config {
    is_public_ip_enabled = "true"
    nsg_ids = [
    ]
    subnet_id = oci_core_subnet.oke-selfmanaged-cluster-k8sApiEndpoint-subnet-regional.id
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
      oci_core_subnet.oke-selfmanaged-cluster-loadbalancer-subnet-regional.id,
    ]
  }
}

data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
}

data "oci_containerengine_cluster_kube_config" "kubeconfig" {
  cluster_id = "${oci_containerengine_cluster.oke-selfmanaged-cluster.id}"
  token_version = "2.0.0"
}

# Null resource: generate kubeconfig locally
resource "null_resource" "generate_kubeconfig" {
  provisioner "local-exec" {
    command = <<EOT
      oci ce cluster create-kubeconfig \
        --cluster-id ${oci_containerengine_cluster.oke-selfmanaged-cluster.id} \
        --file ${path.module}/kubeconfig \
        --region ${var.region} \
        --token-version 2.0.0 \
        --kube-endpoint PUBLIC_ENDPOINT
    EOT
  }
  depends_on = [oci_containerengine_cluster.oke-selfmanaged-cluster]
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


