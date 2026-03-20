variable "tenancy_ocid" {
  type        = string
  description = "OCI tenancy OCID"
}

variable "user_ocid" {
  type        = string
  description = "OCI user OCID"
}

variable "fingerprint" {
  type        = string
  description = "API key fingerprint"
}

variable "private_key_path" {
  type        = string
  description = "Path to OCI API private key PEM file"
}

variable "region" {
  type        = string
  description = "OCI region, for example us-ashburn-1"
}

variable "compartment_id" {
  type        = string
  description = "Compartment OCID where OKE and network resources are created"
}

variable "cluster_name" {
  type        = string
  description = "OKE cluster name"
  default     = "mlflow-oke"
}

variable "kubernetes_version" {
  type        = string
  description = "Optional explicit OKE Kubernetes version. If null, Terraform picks the latest available in the target region."
  default     = null
  nullable    = true
}

variable "node_image_ocid" {
  type        = string
  description = "OCI image OCID for worker nodes (required)."
}

variable "node_shape" {
  type        = string
  description = "Compute shape for OKE worker nodes"
  default     = "VM.Standard.E4.Flex"
}

variable "node_ocpus" {
  type        = number
  description = "OCPUs per worker node"
  default     = 1
}

variable "node_memory_gb" {
  type        = number
  description = "Memory (GB) per worker node"
  default     = 16
}

variable "node_pool_size" {
  type        = number
  description = "Number of worker nodes in the node pool"
  default     = 1
}

variable "create_datascience_notebook" {
  type        = bool
  description = "If true, creates an OCI Data Science project and notebook session for MLflow testing."
  default     = true
}

variable "existing_datascience_project_id" {
  type        = string
  description = "Existing OCI Data Science project OCID to use when create_datascience_notebook is false."
  default     = null
  nullable    = true
}

variable "datascience_project_name" {
  type        = string
  description = "OCI Data Science project display name"
  default     = "mlflow-test-project"
}

variable "datascience_notebook_name" {
  type        = string
  description = "OCI Data Science notebook session display name"
  default     = "mlflow-test-notebook"
}

variable "datascience_notebook_shape" {
  type        = string
  description = "Shape for OCI Data Science notebook session"
  default     = "VM.Standard.E3.Flex"
}

variable "datascience_notebook_block_storage_size_gb" {
  type        = number
  description = "Notebook block storage size in GB"
  default     = 50
}

variable "datascience_job_name" {
  type        = string
  description = "OCI Data Science job display name"
  default     = "mlflow-training-job"
}

variable "datascience_job_delete_related_job_runs" {
  type        = bool
  description = "If true, allows deleting related job runs when Terraform replaces/deletes the Data Science job."
  default     = true
}

variable "datascience_job_container_image" {
  type        = string
  description = "Container image for OCI Data Science Job (OCIR image recommended)"
  default     = "iad.ocir.io/replace-me/mlflow-training:latest"
}

variable "datascience_job_shape_name" {
  type        = string
  description = "Shape name for OCI Data Science Job infrastructure"
  default     = "VM.Standard.E4.Flex"
}

variable "datascience_job_ocpus" {
  type        = number
  description = "OCPUs for OCI Data Science Job shape config"
  default     = 1
}

variable "datascience_job_memory_gb" {
  type        = number
  description = "Memory in GB for OCI Data Science Job shape config"
  default     = 16
}

variable "datascience_job_block_storage_size_gb" {
  type        = number
  description = "Block storage size in GB for OCI Data Science Job"
  default     = 100
}

variable "datascience_job_command_line_arguments" {
  type        = string
  description = "Command line arguments for OCI Data Science Job"
  default     = "bash /app/training/run_training.sh"
}

variable "datascience_job_environment_variables" {
  type        = map(string)
  description = "Environment variables for OCI Data Science Job"
  default = {
    MLFLOW_TRACKING_URI          = "http://129.80.216.101"
    MLFLOW_EXPERIMENT_NAME       = "basic-iris-training-pipeline"
    MLFLOW_REGISTERED_MODEL_NAME = "iris-logreg-model"
  }
}

variable "datascience_job_log_group_id" {
  type        = string
  description = "OCI Logging log group OCID used for Data Science job run logs."
  default     = null
  nullable    = true
}

variable "create_object_storage_buckets" {
  type        = bool
  description = "If true, creates Object Storage buckets for dataset storage and model backups."
  default     = true
}

variable "object_storage_bucket_compartment_id" {
  type        = string
  description = "Compartment OCID where Object Storage buckets are created. If null, uses var.compartment_id."
  default     = null
  nullable    = true
}

variable "object_storage_namespace" {
  type        = string
  description = "Optional Object Storage namespace override for Data Science job env vars. If null, Terraform discovers the tenancy namespace."
  default     = null
  nullable    = true
}

variable "object_storage_dataset_bucket_name" {
  type        = string
  description = "Object Storage bucket name for training datasets."
  default     = "mlops-datasets"
}

variable "object_storage_dataset_object_name" {
  type        = string
  description = "Object name (path) of the training dataset inside the dataset bucket."
  default     = "datasets/iris.csv"
}

variable "object_storage_model_backup_bucket_name" {
  type        = string
  description = "Object Storage bucket name for model backup files."
  default     = "mlops-model-backups"
}

variable "object_storage_model_backup_prefix" {
  type        = string
  description = "Object prefix used for model backups."
  default     = "models"
}

variable "devops_project_name" {
  type        = string
  description = "OCI DevOps project name"
  default     = "mlflow-training-devops"
}

variable "devops_build_pipeline_name" {
  type        = string
  description = "OCI DevOps build pipeline display name"
  default     = "mlflow-training-build-pipeline"
}

variable "devops_build_stage_name" {
  type        = string
  description = "OCI DevOps build stage display name"
  default     = "build-and-deploy-training"
}

variable "create_devops_deploy_pipeline" {
  type        = bool
  description = "If true, creates OCI DevOps deploy pipeline for serving deployment and wires it after the build stage."
  default     = true
}

variable "devops_deploy_pipeline_name" {
  type        = string
  description = "OCI DevOps deploy pipeline display name for serving deployment."
  default     = "mlflow-serving-deploy-pipeline"
}

variable "devops_deploy_command_artifact_name" {
  type        = string
  description = "Display name for the command spec deploy artifact used by serving deploy stage."
  default     = "deploy-serving-command-spec"
}

variable "devops_deploy_stage_name" {
  type        = string
  description = "OCI DevOps deploy stage display name for serving deployment."
  default     = "deploy-serving-to-oke"
}

variable "devops_trigger_deploy_stage_name" {
  type        = string
  description = "OCI DevOps build stage name that triggers the deploy pipeline."
  default     = "trigger-serving-deploy"
}

variable "devops_deploy_stage_timeout_in_seconds" {
  type        = number
  description = "Timeout in seconds for the serving deploy stage."
  default     = 3600
}

variable "devops_deploy_stage_shape_name" {
  type        = string
  description = "Compute shape for OCI DevOps deploy shell stage container instance."
  default     = "CI.Standard.E4.Flex"
}

variable "devops_deploy_stage_shape_ocpus" {
  type        = number
  description = "OCPUs for OCI DevOps deploy shell stage container instance."
  default     = 1
}

variable "devops_deploy_stage_shape_memory_in_gbs" {
  type        = number
  description = "Memory in GBs for OCI DevOps deploy shell stage container instance."
  default     = 2
}

variable "devops_deploy_stage_subnet_id" {
  type        = string
  description = "Subnet OCID for OCI DevOps deploy shell stage container instance. If null, uses the Terraform-created Data Science subnet."
  default     = null
  nullable    = true
}

variable "devops_build_stage_image" {
  type        = string
  description = "OCI DevOps build stage image"
  default     = "OL7_X86_64_STANDARD_10"
}

variable "devops_build_spec_file_path" {
  type        = string
  description = "Path to OCI DevOps build spec file in the source repository"
  default     = "devops/build_spec.yaml"
}

variable "devops_notification_topic_id" {
  type        = string
  description = "Optional existing ONS topic OCID for OCI DevOps project notifications."
  default     = null
  nullable    = true
}

variable "devops_notification_topic_name" {
  type        = string
  description = "Name of ONS notification topic created for OCI DevOps when devops_notification_topic_id is not provided."
  default     = "mlflow-training-devops-topic"
}

variable "devops_github_connection_id" {
  type        = string
  description = "Existing OCI DevOps connection OCID for GitHub. If null, Terraform creates and manages one using devops_github_access_token_secret_id."
  default     = null
  nullable    = true
}

variable "devops_github_connection_name" {
  type        = string
  description = "Display name for the Terraform-managed OCI DevOps GitHub connection."
  default     = "mlflow-training-github-connection"
}

variable "devops_github_access_token_secret_id" {
  type        = string
  description = "OCI Vault secret OCID storing the GitHub personal access token (required only when devops_github_connection_id is null)."
  default     = null
  nullable    = true
}

variable "devops_repository_url" {
  type        = string
  description = "Git repository URL for OCI DevOps build source"
  default     = null
  nullable    = true
}

variable "devops_repository_branch" {
  type        = string
  description = "Git branch for OCI DevOps trigger/build source"
  default     = "main"
}

variable "devops_trigger_file_paths" {
  type        = list(string)
  description = "Optional list of repository paths to monitor for GitHub push trigger. When empty, all paths trigger builds."
  default     = []
}

variable "devops_project_root" {
  type        = string
  description = "Repository path that contains this project (used when rendering devops/build_spec.yaml)."
  default     = "oci-terraform-solutions/oke-mlops-mlflow"
}

variable "devops_build_compartment_ocid" {
  type        = string
  description = "Compartment OCID passed into build_spec env (COMPARTMENT_OCID). If null, uses var.compartment_id."
  default     = null
  nullable    = true
}

variable "devops_build_ocir_region_code" {
  type        = string
  description = "OCIR region code passed into build_spec env (for example: iad)."
  default     = "iad"
}

variable "devops_build_ocir_namespace" {
  type        = string
  description = "OCIR namespace passed into build_spec env."
  default     = null
  nullable    = true
}

variable "devops_build_ocir_repository" {
  type        = string
  description = "Training OCIR repository name passed into build_spec env."
  default     = "mlflow-training-test"
}

variable "devops_build_serving_ocir_repository" {
  type        = string
  description = "Serving OCIR repository name passed into build_spec env."
  default     = "mlflow-serving"
}

variable "devops_build_image_tag" {
  type        = string
  description = "Container image tag passed into build_spec env."
  default     = "latest"
}

variable "devops_build_ocir_username" {
  type        = string
  description = "OCIR username (<namespace>/<username>) passed into build_spec env."
  default     = null
  nullable    = true
}

variable "devops_build_ocir_auth_token" {
  type        = string
  description = "OCIR auth token passed into build_spec env. Prefer using OCI DevOps secret variables in production."
  default     = null
  nullable    = true
  sensitive   = true
}

variable "devops_build_ocir_auth_token_secret_ocid" {
  type        = string
  description = "OCI Vault secret OCID containing OCIR auth token. Build script can fetch and decode this secret at runtime when OCIR_AUTH_TOKEN is empty."
  default     = null
  nullable    = true
}

variable "serving_k8s_namespace" {
  type        = string
  description = "Kubernetes namespace for serving deployment."
  default     = "mlflow"
}

variable "serving_k8s_deployment_name" {
  type        = string
  description = "Kubernetes deployment name for serving API."
  default     = "mlflow-serving"
}

variable "serving_k8s_service_name" {
  type        = string
  description = "Kubernetes service name for serving API."
  default     = "mlflow-serving"
}

variable "serving_mlflow_tracking_uri" {
  type        = string
  description = "MLflow tracking URI passed to serving deployment."
  default     = null
  nullable    = true
}

variable "serving_mlflow_model_name" {
  type        = string
  description = "Registered MLflow model name loaded by serving API."
  default     = "iris-logreg-model"
}

variable "serving_mlflow_model_stage" {
  type        = string
  description = "MLflow model stage loaded by serving API."
  default     = "Production"
}

variable "serving_image_pull_secret_name" {
  type        = string
  description = "Kubernetes secret name used by serving pods to pull private images from OCIR."
  default     = "ocir-pull-secret"
}

variable "create_ocir_training_repository" {
  type        = bool
  description = "If true, creates the OCIR repository used for training image pushes."
  default     = true
}

variable "ocir_training_repository_name" {
  type        = string
  description = "OCIR repository name to create for training images."
  default     = "mlflow-training-test"
}

variable "ocir_training_repository_compartment_id" {
  type        = string
  description = "Compartment OCID where the OCIR training repository is created. If null, uses var.compartment_id."
  default     = null
  nullable    = true
}

variable "create_ocir_serving_repository" {
  type        = bool
  description = "If true, creates the OCIR repository used for serving image pushes."
  default     = true
}

variable "ocir_serving_repository_name" {
  type        = string
  description = "OCIR repository name to create for serving images."
  default     = "mlflow-serving"
}

variable "ocir_serving_repository_compartment_id" {
  type        = string
  description = "Compartment OCID where the OCIR serving repository is created. If null, uses var.compartment_id."
  default     = null
  nullable    = true
}

variable "datascience_subnet_id" {
  type        = string
  description = "Optional subnet OCID for Data Science notebook session. If null, uses the Terraform-created private Data Science subnet."
  default     = null
  nullable    = true
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to SSH public key to inject into worker nodes"
}

variable "mlflow_image" {
  type        = string
  description = "MLflow container image"
  default     = "ghcr.io/mlflow/mlflow:v2.12.2"
}

variable "mlflow_use_object_storage_artifacts" {
  type        = bool
  description = "If true and S3 credentials are provided, MLflow stores artifacts in OCI Object Storage (S3-compatible endpoint)."
  default     = true
}

variable "create_mlflow_artifact_bucket" {
  type        = bool
  description = "If true, creates a dedicated Object Storage bucket for MLflow artifacts."
  default     = true
}

variable "mlflow_artifact_bucket_name" {
  type        = string
  description = "Object Storage bucket name used by MLflow artifact store."
  default     = "mlops-mlflow-artifacts"
}

variable "mlflow_artifact_bucket_compartment_id" {
  type        = string
  description = "Compartment OCID where the MLflow artifact bucket is created. If null, uses var.compartment_id."
  default     = null
  nullable    = true
}

variable "mlflow_artifact_object_prefix" {
  type        = string
  description = "Object prefix for MLflow artifacts inside the bucket."
  default     = "artifacts"
}

variable "mlflow_s3_access_key_id" {
  type        = string
  description = "OCI Customer Secret Key access key used by MLflow/boto3 via AWS_ACCESS_KEY_ID for OCI Object Storage S3-compatible access."
  default     = null
  nullable    = true
}

variable "mlflow_s3_access_key_id_secret_ocid" {
  type        = string
  description = "OCI Vault secret OCID that stores the MLflow S3 access key ID. If set, Terraform reads and decodes the secret value."
  default     = null
  nullable    = true
}

variable "mlflow_s3_secret_access_key" {
  type        = string
  description = "OCI Customer Secret Key secret used by MLflow/boto3 via AWS_SECRET_ACCESS_KEY for OCI Object Storage S3-compatible access."
  default     = null
  nullable    = true
  sensitive   = true
}

variable "mlflow_s3_secret_access_key_secret_ocid" {
  type        = string
  description = "OCI Vault secret OCID that stores the MLflow S3 secret access key. If set, Terraform reads and decodes the secret value."
  default     = null
  nullable    = true
}

variable "mlflow_namespace" {
  type        = string
  description = "Kubernetes namespace where MLflow is deployed"
  default     = "mlflow"
}

variable "vcn_cidr" {
  type        = string
  description = "VCN CIDR"
  default     = "10.0.0.0/16"
}

variable "api_subnet_cidr" {
  type        = string
  description = "Subnet CIDR for OKE API endpoint"
  default     = "10.0.0.0/24"
}

variable "nodes_subnet_cidr" {
  type        = string
  description = "Subnet CIDR for OKE worker nodes"
  default     = "10.0.1.0/24"
}

variable "lb_subnet_cidr" {
  type        = string
  description = "Subnet CIDR for Kubernetes LoadBalancer services"
  default     = "10.0.2.0/24"
}

variable "datascience_subnet_cidr" {
  type        = string
  description = "Subnet CIDR for OCI Data Science notebook sessions"
  default     = "10.0.3.0/24"
}

variable "create_oke_workload_policy" {
  type        = bool
  description = "If true, creates an IAM policy for OKE Service LoadBalancer operations"
  default     = true
}

variable "create_project_iam_policies" {
  type        = bool
  description = "If true, creates IAM policies for OKE, OCI DevOps build, and OCI DevOps deploy principals."
  default     = true
}
