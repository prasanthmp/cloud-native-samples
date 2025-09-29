output "cluster_id" {
  description = "OKE Cluster ID"
  value       =oci_containerengine_cluster.oke-cluster.id
}

output "compartment_ocid" {
  description = "Compartment OCID where resources are created"
  value       = var.compartment_ocid
}


data "external" "webapp_url" {
  program = ["bash", "-c", <<EOT
set -e

MAX_WAIT=30
INTERVAL=3
ELAPSED=0

while true; do
  IP="LB_PENDING_IP"
  IP=$(kubectl get svc my-webapp-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
  
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
  depends_on = [oci_devops_deploy_stage.deploy-webapp-service-to-oke]
}



# Show name of the DevOps project
output "devops_project_name" {
  value = oci_devops_project.webapp-devops-project.name
  description = "The name of the DevOps project."
}

# Show private code repository name and uRL
output "private_code_repository_name" {
  value = oci_devops_repository.webapp-private-code-repo.name
  description = "The name of the private code repository."
}
output "private_code_repository_http_url" {
  value = oci_devops_repository.webapp-private-code-repo.http_url
  description = "The HTTP URL of the private code repository."
}


# Show app container image ID
output "app_container_image_id" {
  value       = local.image_id
  description = "The container image ID for the Flask app."
}


output "webapp_url" {
  value = data.external.webapp_url.result.external_ip
  description = "External URL of the web application"
}

# Display the path to the buildspec file
output "build_spec_file_path" {
  value       = local_file.buid_file_spec.filename
  sensitive   = false
  description = "The path to the generated build specification file for the Flask app."
}