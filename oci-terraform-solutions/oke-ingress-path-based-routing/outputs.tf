

data "external" "webapp_url" {
  program = ["bash", "-c", <<EOT
set -e

MAX_WAIT=30
INTERVAL=3
ELAPSED=0

while true; do
  IP="LB_PENDING_IP"
  IP=$(kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")  
  
  if [ -n "$IP" ]; then
    # Only this JSON goes to stdout
    echo "{\"external_ip\": \"http://$IP\"}"
    exit 0
  fi

  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
    echo "{\"external_ip\": \"http://$IP\"}"
    exit 0
  fi

  # Send debug messages to stderr, not stdout
  echo "Waiting for LoadBalancer IP..." >&2
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done
EOT
  ]
  depends_on = [kubectl_manifest.ingress]
}

output "cluster_id" {
  description = "OKE Cluster ID"
  value       =oci_containerengine_cluster.oke-cluster.id
}

output "compartment_ocid" {
  description = "Compartment OCID where resources are created"
  value       = var.compartment_ocid
}

output "python_webapp_url" {
  value = "${data.external.webapp_url.result.external_ip}/python"
  description = "External URL of the python web application"
}

output "node_webapp_url" {
  value = "${data.external.webapp_url.result.external_ip}/node"
  description = "External URL of the node web application"
}