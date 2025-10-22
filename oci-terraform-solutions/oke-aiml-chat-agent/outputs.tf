output "cluster_id" {
  description = "OKE Cluster ID"
  value       =oci_containerengine_cluster.oke-mon-cluster.id
}

output "compartment_ocid" {
  description = "Compartment OCID where resources are created"
  value       = var.compartment_ocid
}


data "external" "ai_agent_url" {
  program = ["bash", "-c", <<EOT
set -e

MAX_WAIT=30
INTERVAL=3
ELAPSED=0

while true; do
  IP="LB_PENDING_IP"
  IP=$(kubectl get svc ai-agent-service -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "")
  
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
  depends_on = [kubectl_manifest.ai-agent-service]
}

output "ai_agent_app_url" {
  value = "${data.external.ai_agent_url.result.external_ip}:8002/chat"
  description = "External URL of the AI Agent application"
}


data "external" "ai_agent_frontend_url" {
  program = ["bash", "-c", <<EOT
set -e

MAX_WAIT=30
INTERVAL=3
ELAPSED=0

while true; do
  IP="LB_PENDING_IP"
  IP=$(kubectl get svc ai-agent-frontend-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
  
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
  depends_on = [kubectl_manifest.ai-agent-service]
}

output "ai_agent_frontend_app_url" {
  value = "${data.external.ai_agent_frontend_url.result.external_ip}:8080"
  description = "External URL of the AI Agent frontend application"
}
