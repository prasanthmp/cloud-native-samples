output "cluster_id" {
  description = "OKE Cluster ID"
  value       =oci_containerengine_cluster.oke-mon-cluster.id
}

output "compartment_ocid" {
  description = "Compartment OCID where resources are created"
  value       = var.compartment_ocid
}