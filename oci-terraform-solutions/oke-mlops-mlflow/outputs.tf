output "cluster_id" {
  description = "OKE cluster OCID"
  value       = oci_containerengine_cluster.oke.id
}

output "node_pool_id" {
  description = "OKE node pool OCID"
  value       = oci_containerengine_node_pool.default.id
}

output "datascience_subnet_id" {
  description = "Subnet OCID used by Data Science notebook sessions"
  value       = local.datascience_subnet_id
}

output "nat_gateway_id" {
  description = "NAT Gateway OCID for private subnet internet egress"
  value       = oci_core_nat_gateway.oke.id
}

output "datascience_project_id" {
  description = "OCI Data Science project OCID for MLflow testing"
  value       = local.datascience_project_id
}

output "datascience_notebook_session_id" {
  description = "OCI Data Science notebook session OCID for MLflow testing"
  value       = var.create_datascience_notebook ? oci_datascience_notebook_session.mlflow_test[0].id : null
}

output "datascience_notebook_session_url" {
  description = "OCI Data Science notebook session URL"
  value       = var.create_datascience_notebook ? try(oci_datascience_notebook_session.mlflow_test[0].notebook_session_url, null) : null
}

output "datascience_job_id" {
  description = "OCI Data Science training job OCID"
  value       = var.create_datascience_job ? oci_datascience_job.training[0].id : null
}

output "devops_project_id" {
  description = "OCI DevOps project OCID"
  value       = local.devops_project_enabled ? oci_devops_project.mlflow_training[0].id : null
}

output "devops_notification_topic_id" {
  description = "ONS topic OCID used by OCI DevOps project notifications"
  value       = local.devops_project_enabled ? local.devops_notification_topic_id : null
}

output "devops_github_connection_id" {
  description = "Effective OCI DevOps GitHub connection OCID used by the pipeline/trigger"
  value       = local.effective_devops_github_connection_id
}

output "devops_build_pipeline_id" {
  description = "OCI DevOps build pipeline OCID"
  value       = var.create_devops_pipeline ? oci_devops_build_pipeline.mlflow_training[0].id : null
}

output "devops_build_stage_id" {
  description = "OCI DevOps build stage OCID"
  value       = var.create_devops_pipeline ? oci_devops_build_pipeline_stage.build_and_deploy[0].id : null
}

output "devops_github_trigger_id" {
  description = "OCI DevOps GitHub trigger OCID"
  value       = var.create_devops_pipeline ? oci_devops_trigger.github_push_build[0].id : null
}

output "node_image_ocid" {
  description = "Node image OCID used by the node pool"
  value       = var.node_image_ocid
}

output "node_image_name" {
  description = "Node image display name used by the node pool"
  value       = data.oci_core_image.selected_node_image.display_name
}

output "oke_kubernetes_version" {
  description = "Kubernetes version used by OKE (latest available unless overridden)"
  value       = local.selected_kubernetes_version
}

output "kubeconfig_path" {
  description = "Path to generated kubeconfig used by Terraform Kubernetes provider"
  value       = local_sensitive_file.kubeconfig.filename
}

output "mlflow_url" {
  description = "Public URL for MLflow"
  value       = local.mlflow_host != "" ? "http://${local.mlflow_host}" : "LoadBalancer is still provisioning. Re-run: terraform output mlflow_url"
}
