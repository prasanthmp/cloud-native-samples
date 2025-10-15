output "cluster_id" {
  description = "OKE Cluster ID"
  value       =oci_containerengine_cluster.oke-selfmanaged-cluster.id
}

output "compartment_ocid" {
  description = "Compartment OCID where resources are created"
  value       = var.compartment_ocid
}

output "oraclelinux_image_id" {
  value = var.node_image_id
  description = "The image ID of the Oracle Linux 8 image."
}

output "instances_info" {
  value = [
    for i in oci_core_instance.self-managed-instance : {
      name = i.display_name
      ip   = i.private_ip
    }
  ]
}
output "oke_private_api_endpoint" {
  value = replace(oci_containerengine_cluster.oke-selfmanaged-cluster.endpoints[0].private_endpoint, ":6443", "")
}