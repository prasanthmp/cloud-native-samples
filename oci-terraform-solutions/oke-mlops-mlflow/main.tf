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

resource "oci_identity_policy" "oke_cluster" {
  count          = var.create_oke_workload_policy ? 1 : 0
  compartment_id = var.tenancy_ocid
  name           = "${var.cluster_name}-oke-workload-policy"
  description    = "Allows OKE cluster workloads to manage OCI resources needed by Kubernetes services."

  statements = [
    "Allow any-user to manage load-balancers in compartment id ${var.compartment_id} where all {request.principal.type = 'cluster', request.principal.compartment.id = '${var.compartment_id}'}",
    "Allow any-user to use subnets in compartment id ${var.compartment_id} where all {request.principal.type = 'cluster', request.principal.compartment.id = '${var.compartment_id}'}",
    "Allow any-user to manage vnics in compartment id ${var.compartment_id} where all {request.principal.type = 'cluster', request.principal.compartment.id = '${var.compartment_id}'}"
  ]
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
  datascience_subnet_id  = var.datascience_subnet_id != null ? var.datascience_subnet_id : oci_core_subnet.datascience.id
  datascience_project_id = var.create_datascience_notebook ? oci_datascience_project.mlflow_test[0].id : var.existing_datascience_project_id
  devops_build_job_ocid_value = var.devops_build_job_ocid != null ? var.devops_build_job_ocid : (
    var.create_datascience_job ? oci_datascience_job.training[0].id : ""
  )
  devops_build_compartment_ocid_value = var.devops_build_compartment_ocid != null ? var.devops_build_compartment_ocid : var.compartment_id
}

resource "oci_datascience_project" "mlflow_test" {
  count          = var.create_datascience_notebook ? 1 : 0
  compartment_id = var.compartment_id
  display_name   = var.datascience_project_name
  description    = "Project for testing MLflow on OKE from OCI Data Science notebook."
}

resource "oci_datascience_notebook_session" "mlflow_test" {
  count          = var.create_datascience_notebook ? 1 : 0
  compartment_id = var.compartment_id
  project_id     = oci_datascience_project.mlflow_test[0].id
  display_name   = var.datascience_notebook_name

  notebook_session_configuration_details {
    shape                     = var.datascience_notebook_shape
    block_storage_size_in_gbs = var.datascience_notebook_block_storage_size_gb
    subnet_id                 = local.datascience_subnet_id
  }
}

resource "oci_datascience_job" "training" {
  count          = var.create_datascience_job ? 1 : 0
  compartment_id = var.compartment_id
  project_id     = local.datascience_project_id
  display_name   = var.datascience_job_name

  job_configuration_details {
    job_type               = "DEFAULT"
    command_line_arguments = var.datascience_job_command_line_arguments
    environment_variables  = var.datascience_job_environment_variables
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
}

resource "local_file" "devops_build_spec" {
  filename = "${path.module}/devops/build_spec.yaml"
  content = templatefile("${path.module}/devops/build_spec.yaml.tftpl", {
    project_root                = var.devops_project_root
    job_ocid                    = local.devops_build_job_ocid_value
    compartment_ocid            = local.devops_build_compartment_ocid_value
    ocir_region_code            = var.devops_build_ocir_region_code
    ocir_namespace              = coalesce(var.devops_build_ocir_namespace, "")
    ocir_repository             = var.devops_build_ocir_repository
    image_tag                   = var.devops_build_image_tag
    ocir_username               = var.devops_build_ocir_username != null ? var.devops_build_ocir_username : ""
    ocir_auth_token             = var.devops_build_ocir_auth_token != null ? var.devops_build_ocir_auth_token : ""
    ocir_auth_token_secret_ocid = var.devops_build_ocir_auth_token_secret_ocid != null ? var.devops_build_ocir_auth_token_secret_ocid : ""
  })
}

locals {
  devops_project_enabled       = var.create_devops_pipeline || var.create_devops_github_connection
  devops_notification_topic_id = local.devops_project_enabled ? (var.devops_notification_topic_id != null ? var.devops_notification_topic_id : oci_ons_notification_topic.devops[0].id) : null
}

resource "oci_ons_notification_topic" "devops" {
  count          = local.devops_project_enabled && var.devops_notification_topic_id == null ? 1 : 0
  compartment_id = var.compartment_id
  name           = var.devops_notification_topic_name
}

resource "oci_devops_project" "mlflow_training" {
  count          = local.devops_project_enabled ? 1 : 0
  compartment_id = var.compartment_id
  name           = var.devops_project_name
  description    = "DevOps project for MLflow training pipeline."

  notification_config {
    topic_id = local.devops_notification_topic_id
  }
}

resource "oci_devops_connection" "github" {
  count           = var.create_devops_github_connection ? 1 : 0
  project_id      = oci_devops_project.mlflow_training[0].id
  connection_type = "GITHUB_ACCESS_TOKEN"
  display_name    = var.devops_github_connection_name
  description     = "Terraform-managed GitHub external connection backed by OCI Vault secret."
  access_token    = var.devops_github_access_token_secret_id

  lifecycle {
    precondition {
      condition     = try(trimspace(var.devops_github_access_token_secret_id) != "", false)
      error_message = "devops_github_access_token_secret_id must be set when create_devops_github_connection=true."
    }
  }
}

locals {
  managed_devops_github_connection_id   = var.create_devops_github_connection ? oci_devops_connection.github[0].id : null
  effective_devops_github_connection_id = var.devops_github_connection_id != null ? var.devops_github_connection_id : local.managed_devops_github_connection_id
}

resource "oci_devops_build_pipeline" "mlflow_training" {
  count        = var.create_devops_pipeline ? 1 : 0
  project_id   = oci_devops_project.mlflow_training[0].id
  display_name = var.devops_build_pipeline_name
  description  = "Build pipeline for packaging training code and triggering Data Science job."
}

resource "oci_devops_build_pipeline_stage" "build_and_deploy" {
  count                     = var.create_devops_pipeline ? 1 : 0
  build_pipeline_id         = oci_devops_build_pipeline.mlflow_training[0].id
  build_pipeline_stage_type = "BUILD"
  display_name              = var.devops_build_stage_name
  build_spec_file           = var.devops_build_spec_file_path
  image                     = var.devops_build_stage_image
  primary_build_source      = "github_source"

  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline.mlflow_training[0].id
    }
  }

  build_source_collection {
    items {
      name            = "github_source"
      connection_type = "GITHUB"
      connection_id   = local.effective_devops_github_connection_id
      repository_url  = var.devops_repository_url
      branch          = var.devops_repository_branch
    }
  }

  lifecycle {
    precondition {
      condition     = try(trimspace(local.effective_devops_github_connection_id) != "", false)
      error_message = "Provide devops_github_connection_id, or set create_devops_github_connection=true with devops_github_access_token_secret_id."
    }
    precondition {
      condition     = try(trimspace(var.devops_repository_url) != "", false)
      error_message = "devops_repository_url is required when create_devops_pipeline=true."
    }
  }
}

resource "oci_devops_trigger" "github_push_build" {
  count          = var.create_devops_pipeline ? 1 : 0
  project_id     = oci_devops_project.mlflow_training[0].id
  display_name   = "github-push-trigger"
  trigger_source = "GITHUB"
  connection_id  = local.effective_devops_github_connection_id

  actions {
    type              = "TRIGGER_BUILD_PIPELINE"
    build_pipeline_id = oci_devops_build_pipeline.mlflow_training[0].id

    filter {
      trigger_source = "GITHUB"
      events         = ["PUSH"]

      include {
        head_ref = "refs/heads/${var.devops_repository_branch}"

        dynamic "file_filter" {
          for_each = length(var.devops_trigger_file_paths) > 0 ? [1] : []
          content {
            file_paths = var.devops_trigger_file_paths
          }
        }
      }
    }
  }
}

data "oci_containerengine_cluster_kube_config" "oke" {
  cluster_id    = oci_containerengine_cluster.oke.id
  token_version = "2.0.0"
}

resource "local_sensitive_file" "kubeconfig" {
  content         = data.oci_containerengine_cluster_kube_config.oke.content
  filename        = "${path.module}/kubeconfig"
  file_permission = "0600"
}

provider "kubernetes" {
  config_path = local_sensitive_file.kubeconfig.filename
}

resource "kubernetes_namespace_v1" "mlflow" {
  metadata {
    name = var.mlflow_namespace
  }
}

resource "kubernetes_deployment_v1" "mlflow" {
  metadata {
    name      = "mlflow"
    namespace = kubernetes_namespace_v1.mlflow.metadata[0].name
    labels = {
      app = "mlflow"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mlflow"
      }
    }

    template {
      metadata {
        labels = {
          app = "mlflow"
        }
      }

      spec {
        container {
          name  = "mlflow"
          image = var.mlflow_image

          command = ["mlflow"]
          args = [
            "server",
            "--host", "0.0.0.0",
            "--port", "5000",
            "--backend-store-uri", "sqlite:///mlflow.db",
            "--serve-artifacts",
            "--artifacts-destination", "/mlflow/artifacts",
            "--default-artifact-root", "mlflow-artifacts:/"
          ]

          port {
            container_port = 5000
          }

          volume_mount {
            name       = "mlflow-data"
            mount_path = "/mlflow"
          }
        }

        volume {
          name = "mlflow-data"

          empty_dir {}
        }
      }
    }
  }

  depends_on = [oci_containerengine_node_pool.default]
}

resource "kubernetes_service_v1" "mlflow" {
  metadata {
    name      = "mlflow"
    namespace = kubernetes_namespace_v1.mlflow.metadata[0].name
  }

  spec {
    selector = {
      app = "mlflow"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 5000
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }

  depends_on = [kubernetes_deployment_v1.mlflow]
}

locals {
  mlflow_lb_hostname = try(kubernetes_service_v1.mlflow.status[0].load_balancer[0].ingress[0].hostname, "")
  mlflow_lb_ip       = try(kubernetes_service_v1.mlflow.status[0].load_balancer[0].ingress[0].ip, "")
  mlflow_host        = local.mlflow_lb_hostname != "" ? local.mlflow_lb_hostname : local.mlflow_lb_ip
}
