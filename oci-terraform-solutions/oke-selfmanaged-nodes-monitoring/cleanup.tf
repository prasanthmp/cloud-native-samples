
resource "null_resource" "cleanup_monitoring_ns" {
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      set -euo pipefail
      echo "Deleting all resources in monitoring namespace..."
      helm uninstall prometheus -n monitoring || true
      sleep 20
      helm uninstall grafana -n monitoring || true
      # Wait for a few seconds to ensure resources are deleted
      sleep 50
      # Delete all resources in the monitoring namespace
      # kubectl delete all --all -n monitoring || true
      echo "✅ Cleanup done in monitoring namespace."
    EOT
  }
}

