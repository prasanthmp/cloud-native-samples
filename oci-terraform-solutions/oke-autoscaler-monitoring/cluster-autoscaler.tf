
# --- Install Cluster Autoscaler Add-On
resource "oci_containerengine_addon" "cluster_autoscaler" {
  cluster_id                      = oci_containerengine_cluster.oke-mon-cluster.id
  addon_name                      = "ClusterAutoscaler"
  remove_addon_resources_on_delete = true
  override_existing = true

  configurations {
    key   = "scaleDownEnabled"
    value = "true"
  }
  configurations {
    key   = "nodes"
    value = "${var.autoscaler.min_nodes}:${var.autoscaler.max_nodes}:${oci_containerengine_node_pool.oke_node_pool.id}"
  }
  configurations {
    key   = "scanInterval"
    value = "${var.autoscaler.scan_interval_seconds}s"
  }
  configurations {
    key   = "authType"
    value = "instance"
  }
  configurations {
    key   = "expander"
    value = "least-waste"
  }

  depends_on = [ null_resource.copy_kubeconfig ]
}

# --- Example output
output "cluster_autoscaler_status" {
  value = oci_containerengine_addon.cluster_autoscaler.state
}