
# Get kubelet CA cert from kubeconfig
data "external" "kube_ca_cert" {
  program = [
    "/bin/bash", "-c",
    "cat ~/.kube/config | grep -oE 'LS0t.*' | tr -d '\\n' | jq -R -c '{value: .}'"
  ]
  depends_on = [ null_resource.copy_kubeconfig ]
}

locals {
  instance_ssh_authorized_keys = file("${path.module}/instance-ssh/ssh-public-key.pub")
    self_managed_instance_userdata = templatefile("${path.module}/cloud-init.sh.tpl",{
    apiserver_endpoint_private = replace(oci_containerengine_cluster.oke-selfmanaged-cluster.endpoints[0].private_endpoint, ":6443", "")
    kubelet_ca_cert            = data.external.kube_ca_cert.result["value"]
})    
depends_on = [data.external.kube_ca_cert]
}

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

resource "oci_core_instance" "self-managed-instance" {
    count = length(var.instance_names)
    display_name = "${var.instance_names[count.index]}-${var.kubernetes.cluster_name}"

    availability_config {
        recovery_action = "RESTORE_INSTANCE"
    }
    availability_domain = data.oci_identity_availability_domain.ad.name
    compartment_id = var.compartment_ocid
    create_vnic_details {
        assign_public_ip = "false"
        display_name = "${var.instance_names[count.index]}-${var.kubernetes.cluster_name}"
        hostname_label = "${var.instance_names[count.index]}-${var.kubernetes.cluster_name}"
        skip_source_dest_check = "false"
        subnet_id              = oci_core_subnet.oke-selfmanaged-cluster-nodesubnet-regional.id
    }
 
    metadata = {
        "ssh_authorized_keys" = local.instance_ssh_authorized_keys
        "user_data"           = base64encode(local.self_managed_instance_userdata)
        "oke-native-pod-networking" = "true"
        "pod-subnets" = oci_core_subnet.oke-selfmanaged-cluster-nodesubnet-regional.id
        "oke-max-pods" = "31"
    }
 
    shape = var.node_settings.shape
    shape_config {
        memory_in_gbs             = var.node_settings.memory
        ocpus                     = var.node_settings.ocpus
    }
    source_details {
        boot_volume_vpus_per_gb = "10"
        source_id   = var.node_image_id  # Must be a valid image OCID
        source_type = "image"
        boot_volume_size_in_gbs = "50"
    }

    state = "RUNNING"
    agent_config {
        plugins_config {
            desired_state = "ENABLED"
            name          = "Bastion"
        }
    }
    depends_on = [data.oci_containerengine_cluster_kube_config.kubeconfig]
}



