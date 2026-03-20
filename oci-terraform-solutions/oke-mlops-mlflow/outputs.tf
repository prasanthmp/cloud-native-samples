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
  value       = oci_datascience_job.training[0].id
}

output "ocir_training_repository_id" {
  description = "OCIR training repository OCID"
  value       = var.create_ocir_training_repository ? oci_artifacts_container_repository.training[0].id : null
}

output "ocir_training_repository_name" {
  description = "OCIR training repository name used by the build pipeline"
  value       = local.devops_build_training_ocir_repository_value
}

output "ocir_serving_repository_id" {
  description = "OCIR serving repository OCID"
  value       = var.create_ocir_serving_repository ? oci_artifacts_container_repository.serving[0].id : null
}

output "ocir_serving_repository_name" {
  description = "OCIR serving repository name used by the build pipeline"
  value       = local.devops_build_serving_ocir_repository_value
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
  value       = oci_devops_build_pipeline.mlflow_training[0].id
}

output "devops_build_stage_id" {
  description = "OCI DevOps build stage OCID"
  value       = oci_devops_build_pipeline_stage.build_and_deploy[0].id
}

output "devops_build_trigger_deploy_stage_id" {
  description = "OCI DevOps build stage OCID that triggers serving deploy pipeline"
  value       = var.create_devops_deploy_pipeline ? oci_devops_build_pipeline_stage.trigger_serving_deploy[0].id : null
}

output "devops_deploy_pipeline_id" {
  description = "OCI DevOps deploy pipeline OCID for serving deployment"
  value       = var.create_devops_deploy_pipeline ? oci_devops_deploy_pipeline.serving[0].id : null
}

output "devops_deploy_stage_id" {
  description = "OCI DevOps deploy stage OCID for serving deployment"
  value       = var.create_devops_deploy_pipeline ? oci_devops_deploy_stage.deploy_serving_shell[0].id : null
}

output "devops_github_trigger_id" {
  description = "OCI DevOps GitHub trigger OCID"
  value       = oci_devops_trigger.github_push_build[0].id
}

output "policy_oke_cluster_id" {
  description = "IAM policy OCID for OKE workload permissions"
  value       = var.create_oke_workload_policy ? oci_identity_policy.oke_cluster[0].id : null
}

output "policy_devops_build_id" {
  description = "IAM policy OCID for OCI DevOps build pipeline permissions"
  value       = var.create_project_iam_policies ? oci_identity_policy.devops_build_pipeline[0].id : null
}

output "policy_devops_deploy_id" {
  description = "IAM policy OCID for OCI DevOps deploy pipeline permissions"
  value       = var.create_project_iam_policies && var.create_devops_deploy_pipeline ? oci_identity_policy.devops_deploy_pipeline[0].id : null
}

output "policy_datascience_runtime_id" {
  description = "IAM policy OCID for OCI Data Science notebook/job runtime permissions"
  value       = var.create_project_iam_policies ? oci_identity_policy.datascience_runtime[0].id : null
}

output "object_storage_namespace" {
  description = "Object Storage namespace used by dataset and model backup integration"
  value       = local.object_storage_namespace_value
}

output "dataset_bucket_name" {
  description = "Object Storage bucket name used for datasets"
  value       = var.object_storage_dataset_bucket_name
}

output "dataset_bucket_id" {
  description = "Object Storage dataset bucket OCID"
  value       = var.create_object_storage_buckets ? oci_objectstorage_bucket.datasets[0].id : null
}

output "model_backup_bucket_name" {
  description = "Object Storage bucket name used for model backups"
  value       = var.object_storage_model_backup_bucket_name
}

output "model_backup_bucket_id" {
  description = "Object Storage model backup bucket OCID"
  value       = var.create_object_storage_buckets ? oci_objectstorage_bucket.model_backups[0].id : null
}

output "mlflow_artifact_bucket_name" {
  description = "Object Storage bucket name configured for MLflow artifacts"
  value       = var.mlflow_artifact_bucket_name
}

output "mlflow_artifact_bucket_id" {
  description = "Object Storage MLflow artifact bucket OCID"
  value       = var.create_mlflow_artifact_bucket ? oci_objectstorage_bucket.mlflow_artifacts[0].id : null
}

output "mlflow_artifact_root" {
  description = "MLflow artifact root URI currently configured on the MLflow server"
  value       = local.mlflow_use_object_storage_artifacts_effective ? local.mlflow_artifact_root : "mlflow-artifacts:/"
  sensitive   = true
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

output "serving_url" {
  description = "Command that waits for serving Service external endpoint and prints full URL."
  value       = "bash -lc 'while true; do IP=$(kubectl -n ${var.serving_k8s_namespace} get svc ${var.serving_k8s_service_name} -o jsonpath=\"{.status.loadBalancer.ingress[0].ip}\" 2>/dev/null); HOST=$(kubectl -n ${var.serving_k8s_namespace} get svc ${var.serving_k8s_service_name} -o jsonpath=\"{.status.loadBalancer.ingress[0].hostname}\" 2>/dev/null); if [ -n \"$IP\" ]; then echo http://$IP; break; fi; if [ -n \"$HOST\" ]; then echo http://$HOST; break; fi; sleep 10; done'"
}
