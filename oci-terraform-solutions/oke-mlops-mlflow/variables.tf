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

variable "create_datascience_job" {
  type        = bool
  description = "If true, creates an OCI Data Science Job for model training."
  default     = false
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
  default     = "bash training/run_training.sh"
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

variable "create_devops_pipeline" {
  type        = bool
  description = "If true, creates OCI DevOps project, build pipeline, build stage, and GitHub trigger."
  default     = false
}

variable "create_devops_github_connection" {
  type        = bool
  description = "If true, creates an OCI DevOps GitHub external connection using an OCI Vault secret OCID."
  default     = false
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
  description = "Existing OCI DevOps connection OCID for GitHub. Leave null when create_devops_github_connection=true."
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
  description = "OCI Vault secret OCID storing the GitHub personal access token (required when create_devops_github_connection=true)."
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

variable "devops_build_project_ocid" {
  type        = string
  description = "Data Science project OCID passed into build_spec env (PROJECT_OCID). If null, uses the resolved Data Science project ID."
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
  description = "OCIR repository name passed into build_spec env."
  default     = "mlflow-training-test"
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
