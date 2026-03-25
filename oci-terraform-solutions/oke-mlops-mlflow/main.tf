terraform {
  required_version = ">= 1.6.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.27.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.1"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_objectstorage_namespace" "this" {
  compartment_id = var.tenancy_ocid
}

data "oci_secrets_secretbundle" "mlflow_s3_access_key_id" {
  count     = var.mlflow_s3_access_key_id_secret_ocid != null ? 1 : 0
  secret_id = var.mlflow_s3_access_key_id_secret_ocid
}

data "oci_secrets_secretbundle" "mlflow_s3_secret_access_key" {
  count     = var.mlflow_s3_secret_access_key_secret_ocid != null ? 1 : 0
  secret_id = var.mlflow_s3_secret_access_key_secret_ocid
}

data "oci_containerengine_cluster_option" "oke" {
  cluster_option_id = "all"
}

locals {
  latest_kubernetes_version   = element(sort(data.oci_containerengine_cluster_option.oke.kubernetes_versions), length(data.oci_containerengine_cluster_option.oke.kubernetes_versions) - 1)
  selected_kubernetes_version = var.kubernetes_version != null ? var.kubernetes_version : local.latest_kubernetes_version
}

data "oci_core_image" "selected_node_image" {
  image_id = var.node_image_ocid
}

resource "oci_core_vcn" "oke" {
  compartment_id = var.compartment_id
  display_name   = "${var.cluster_name}-vcn"
  cidr_blocks    = [var.vcn_cidr]
  dns_label      = "okevcn"
}

resource "oci_core_internet_gateway" "oke" {
  compartment_id = var.compartment_id
  display_name   = "${var.cluster_name}-igw"
  vcn_id         = oci_core_vcn.oke.id
  enabled        = true
}

resource "oci_core_nat_gateway" "oke" {
  compartment_id = var.compartment_id
  display_name   = "${var.cluster_name}-nat"
  vcn_id         = oci_core_vcn.oke.id
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.cluster_name}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.oke.id
  }
}

resource "oci_core_route_table" "private" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.cluster_name}-private-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.oke.id
  }
}

resource "oci_core_security_list" "oke" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.cluster_name}-sl"

  lifecycle {
    # OKE and cloud-controller integrations may add/remove operational rules.
    # Ignore drift to avoid Terraform removing required runtime rules.
    ignore_changes = [
      ingress_security_rules,
      egress_security_rules
    ]
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    source   = var.vcn_cidr
    protocol = "all"
  }

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "6"

    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "6"

    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "6"

    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "6"

    tcp_options {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_security_list" "datascience" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.cluster_name}-datascience-sl"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    source   = var.vcn_cidr
    protocol = "all"
  }
}

resource "oci_core_subnet" "api" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.oke.id
  display_name               = "${var.cluster_name}-api-subnet"
  cidr_block                 = var.api_subnet_cidr
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.oke.id]
  dns_label                  = "apisub"
  prohibit_public_ip_on_vnic = false
}

resource "oci_core_subnet" "nodes" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.oke.id
  display_name               = "${var.cluster_name}-nodes-subnet"
  cidr_block                 = var.nodes_subnet_cidr
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.oke.id]
  dns_label                  = "nodesub"
  prohibit_public_ip_on_vnic = false
}

resource "oci_core_subnet" "lb" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.oke.id
  display_name               = "${var.cluster_name}-lb-subnet"
  cidr_block                 = var.lb_subnet_cidr
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.oke.id]
  dns_label                  = "lbsub"
  prohibit_public_ip_on_vnic = false
}

resource "oci_core_subnet" "datascience" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.oke.id
  display_name               = "${var.cluster_name}-datascience-subnet"
  cidr_block                 = var.datascience_subnet_cidr
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.datascience.id]
  dns_label                  = "dssub"
  prohibit_public_ip_on_vnic = true
}

resource "oci_containerengine_cluster" "oke" {
  compartment_id     = var.compartment_id
  kubernetes_version = local.selected_kubernetes_version
  name               = var.cluster_name
  vcn_id             = oci_core_vcn.oke.id

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.api.id
  }

  options {
    service_lb_subnet_ids = [oci_core_subnet.lb.id]

    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }
  }
}

resource "oci_containerengine_node_pool" "default" {
  cluster_id         = oci_containerengine_cluster.oke.id
  compartment_id     = var.compartment_id
  kubernetes_version = local.selected_kubernetes_version
  name               = "${var.cluster_name}-nodepool"
  node_shape         = var.node_shape

  node_shape_config {
    memory_in_gbs = var.node_memory_gb
    ocpus         = var.node_ocpus
  }

  node_config_details {
    size = var.node_pool_size

    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = oci_core_subnet.nodes.id
    }
  }

  node_source_details {
    image_id    = var.node_image_ocid
    source_type = "IMAGE"
  }

  ssh_public_key = file(var.ssh_public_key_path)
}

locals {
  create_datascience_project_enabled            = true
  datascience_subnet_id                         = var.datascience_subnet_id != null ? var.datascience_subnet_id : oci_core_subnet.datascience.id
  datascience_project_id                        = oci_datascience_project.mlflow_test[0].id
  ocir_training_repository_compartment_id_value = var.ocir_training_repository_compartment_id != null ? var.ocir_training_repository_compartment_id : var.compartment_id
  ocir_serving_repository_compartment_id_value  = var.ocir_serving_repository_compartment_id != null ? var.ocir_serving_repository_compartment_id : var.compartment_id
  create_root_object_storage_bucket             = var.create_object_storage_buckets || var.create_mlflow_artifact_bucket
  object_storage_bucket_compartment_id_value    = var.object_storage_bucket_compartment_id != null ? var.object_storage_bucket_compartment_id : var.compartment_id
  mlflow_artifact_bucket_compartment_id_value   = var.mlflow_artifact_bucket_compartment_id != null ? var.mlflow_artifact_bucket_compartment_id : var.compartment_id
  object_storage_namespace_value                = var.object_storage_namespace != null ? var.object_storage_namespace : data.oci_objectstorage_namespace.this.namespace
  mlflow_s3_access_key_id_from_secret           = var.mlflow_s3_access_key_id_secret_ocid != null ? base64decode(data.oci_secrets_secretbundle.mlflow_s3_access_key_id[0].secret_bundle_content[0].content) : null
  mlflow_s3_secret_access_key_from_secret       = var.mlflow_s3_secret_access_key_secret_ocid != null ? base64decode(data.oci_secrets_secretbundle.mlflow_s3_secret_access_key[0].secret_bundle_content[0].content) : null
  mlflow_s3_access_key_id_value                 = var.mlflow_s3_access_key_id != null ? var.mlflow_s3_access_key_id : local.mlflow_s3_access_key_id_from_secret
  mlflow_s3_secret_access_key_value             = var.mlflow_s3_secret_access_key != null ? var.mlflow_s3_secret_access_key : local.mlflow_s3_secret_access_key_from_secret
  mlflow_tracking_uri_runtime                   = local.mlflow_host != "" ? "http://${local.mlflow_host}" : null
  datascience_mlflow_runtime_env                = local.mlflow_tracking_uri_runtime != null ? { MLFLOW_TRACKING_URI = local.mlflow_tracking_uri_runtime } : {}
  datascience_mlflow_artifact_env = local.mlflow_use_object_storage_artifacts_effective ? {
    AWS_ACCESS_KEY_ID                = local.mlflow_s3_access_key_id_value
    AWS_SECRET_ACCESS_KEY            = local.mlflow_s3_secret_access_key_value
    AWS_DEFAULT_REGION               = var.region
    AWS_REQUEST_CHECKSUM_CALCULATION = "when_required"
    AWS_RESPONSE_CHECKSUM_VALIDATION = "when_required"
    MLFLOW_S3_ENDPOINT_URL           = local.mlflow_s3_endpoint
  } : {}
  datascience_object_storage_env = {
    OBJECT_STORAGE_NAMESPACE   = local.object_storage_namespace_value
    DATASET_BUCKET_NAME        = var.object_storage_root_bucket_name
    DATASET_OBJECT_NAME        = var.object_storage_dataset_object_name
    MODEL_BACKUP_BUCKET_NAME   = var.object_storage_root_bucket_name
    MODEL_BACKUP_OBJECT_PREFIX = var.object_storage_model_backup_prefix
  }
  datascience_job_environment_variables_merged = merge(
    var.datascience_job_environment_variables,
    local.datascience_object_storage_env,
    local.datascience_mlflow_artifact_env,
    local.datascience_mlflow_runtime_env
  )
}

resource "oci_logging_log_group" "datascience_training" {
  count          = var.create_datascience_job_log_group && var.datascience_job_log_group_id == null ? 1 : 0
  compartment_id = var.compartment_id
  display_name   = var.datascience_job_log_group_name
}

locals {
  managed_datascience_job_log_group_id   = var.create_datascience_job_log_group && var.datascience_job_log_group_id == null ? oci_logging_log_group.datascience_training[0].id : null
  effective_datascience_job_log_group_id = var.datascience_job_log_group_id != null ? var.datascience_job_log_group_id : local.managed_datascience_job_log_group_id
}

resource "oci_artifacts_container_repository" "training" {
  count          = var.create_ocir_training_repository ? 1 : 0
  compartment_id = local.ocir_training_repository_compartment_id_value
  display_name   = var.ocir_training_repository_name
  is_public      = false
}

resource "oci_artifacts_container_repository" "serving" {
  count          = var.create_ocir_serving_repository ? 1 : 0
  compartment_id = local.ocir_serving_repository_compartment_id_value
  display_name   = var.ocir_serving_repository_name
  is_public      = false
}

resource "oci_objectstorage_bucket" "root" {
  count          = local.create_root_object_storage_bucket ? 1 : 0
  compartment_id = local.object_storage_bucket_compartment_id_value
  namespace      = local.object_storage_namespace_value
  name           = var.object_storage_root_bucket_name
  access_type    = "NoPublicAccess"
  storage_tier   = "Standard"
}

resource "oci_datascience_project" "mlflow_test" {
  count          = local.create_datascience_project_enabled ? 1 : 0
  compartment_id = var.compartment_id
  display_name   = var.datascience_project_name
  description    = "Project for testing MLflow on OKE from OCI Data Science notebook."
}

resource "oci_datascience_notebook_session" "mlflow_test" {
  count          = var.create_datascience_notebook ? 1 : 0
  compartment_id = var.compartment_id
  project_id     = local.datascience_project_id
  display_name   = var.datascience_notebook_name

  notebook_session_configuration_details {
    shape                     = var.datascience_notebook_shape
    block_storage_size_in_gbs = var.datascience_notebook_block_storage_size_gb
    subnet_id                 = local.datascience_subnet_id
  }
}

resource "oci_datascience_job" "training" {
  count                   = 1
  compartment_id          = var.compartment_id
  project_id              = local.datascience_project_id
  display_name            = var.datascience_job_name
  delete_related_job_runs = var.datascience_job_delete_related_job_runs

  job_configuration_details {
    job_type               = "DEFAULT"
    command_line_arguments = var.datascience_job_command_line_arguments
    environment_variables  = local.datascience_job_environment_variables_merged
  }

  job_environment_configuration_details {
    job_environment_type = "OCIR_CONTAINER"
    image                = var.datascience_job_container_image
  }

  job_infrastructure_configuration_details {
    job_infrastructure_type   = "STANDALONE"
    shape_name                = var.datascience_job_shape_name
    subnet_id                 = local.datascience_subnet_id
    block_storage_size_in_gbs = var.datascience_job_block_storage_size_gb

    job_shape_config_details {
      ocpus         = var.datascience_job_ocpus
      memory_in_gbs = var.datascience_job_memory_gb
    }
  }

  job_log_configuration_details {
    enable_logging           = true
    enable_auto_log_creation = true
    log_group_id             = local.effective_datascience_job_log_group_id
  }
}
