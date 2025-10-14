output "grafana_admin_username" {
  description = "Grafana admin username"
  value       = var.grafana_user
}

output "cluster_id" {
  description = "OKE Cluster ID"
  value       =oci_containerengine_cluster.oke-mon-cluster.id
}

output "compartment_ocid" {
  description = "Compartment OCID where resources are created"
  value       = var.compartment_ocid
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.grafana_pass
  sensitive   = true
}

data "external" "prometheus_ip" {
  program = ["bash", "-c", <<EOT
set -e

MAX_WAIT=30
INTERVAL=5
ELAPSED=0

while true; do
  IP="LB_PENDING_IP"
  IP=$(kubectl get svc -n monitoring prometheus-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
  
  if [ -n "$IP" ]; then
    # Only this JSON goes to stdout
    echo "{\"external_ip\": \"$IP\"}"
    exit 0
  fi

  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
    echo "{\"external_ip\": \"$IP\"}"
    exit 0
  fi

  # Send debug messages to stderr, not stdout
  echo "Waiting for Prometheus LoadBalancer IP..." >&2
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done
EOT
  ]
  depends_on = [null_resource.install_prometheus]
}

output "prometheus_url" {
  value = "http://${data.external.prometheus_ip.result.external_ip}"
}

data "external" "grafana_ip" {
  program = ["bash", "-c", <<EOT
set -e

MAX_WAIT=30
INTERVAL=5
ELAPSED=0

while true; do

  IP="LB_PENDING_IP"
  IP=$(kubectl get svc -n monitoring grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
  
  if [ -n "$IP" ]; then
    # Only this JSON goes to stdout
    echo "{\"external_ip\": \"$IP\"}"
    exit 0
  fi

  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
    echo "{\"external_ip\": \"$IP\"}"
    exit 0
  fi

  # Send debug messages to stderr, not stdout
  echo "Waiting for Grafana LoadBalancer IP..." >&2
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done
EOT
  ]
  depends_on = [null_resource.install_grafana]
}

output "grafana_url" {
  value = "http://${data.external.grafana_ip.result.external_ip}"
}


data "external" "jupyterhub_ip" {
  program = ["bash", "-c", <<EOT
set -e

MAX_WAIT=30
INTERVAL=5
ELAPSED=0

while true; do

  IP="LB_PENDING_IP"
  IP=$(kubectl get svc -n jhub proxy-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
  
  if [ -n "$IP" ]; then
    # Only this JSON goes to stdout
    echo "{\"external_ip\": \"$IP\"}"
    exit 0
  fi

  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
    echo "{\"external_ip\": \"$IP\"}"
    exit 0
  fi

  # Send debug messages to stderr, not stdout
  echo "Waiting for JupyterHub LoadBalancer IP..." >&2
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done
EOT
  ]
  depends_on = [helm_release.jupyterhub]
}

output "jupyterhub_url" {
  value = "http://${data.external.jupyterhub_ip.result.external_ip}"
}

