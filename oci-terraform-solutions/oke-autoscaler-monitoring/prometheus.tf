# -----------------------------
# Null resource: Install Prometheus
# -----------------------------
resource "null_resource" "install_prometheus" {
  provisioner "local-exec" {
    command = <<EOT
      export KUBECONFIG=$HOME/.kube/config
      kubectl create namespace monitoring || true

      helm repo add prometheus-community ${var.helm.prometheus_repo}
      helm repo update

      helm upgrade --install prometheus prometheus-community/prometheus -n monitoring \
        --set server.service.type=LoadBalancer \
        --set server.persistentVolume.enabled=false \
        --set alertmanager.persistentVolume.enabled=false \
        --set pushgateway.persistentVolume.enabled=false
          EOT
  }
  depends_on = [ time_sleep.wait_for_kubeconfig ]
}
