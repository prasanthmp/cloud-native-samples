locals {
  devops_build_compartment_ocid_value         = var.devops_build_compartment_ocid != null ? var.devops_build_compartment_ocid : var.compartment_id
  devops_build_training_ocir_repository_value = var.create_ocir_training_repository ? var.ocir_training_repository_name : var.devops_build_ocir_repository
  devops_build_serving_ocir_repository_value  = var.create_ocir_serving_repository ? var.ocir_serving_repository_name : var.devops_build_serving_ocir_repository
  devops_deploy_subnet_id_value               = var.devops_deploy_stage_subnet_id != null ? var.devops_deploy_stage_subnet_id : oci_core_subnet.datascience.id
}

resource "local_file" "devops_build_spec" {
  filename = "${path.module}/devops/build_spec.yaml"
  content = templatefile("${path.module}/devops/build_spec.yaml.tftpl", {
    project_root                = var.devops_project_root
    compartment_ocid            = local.devops_build_compartment_ocid_value
    ocir_region_code            = var.devops_build_ocir_region_code
    ocir_namespace              = coalesce(var.devops_build_ocir_namespace, "")
    ocir_training_repository    = local.devops_build_training_ocir_repository_value
    ocir_serving_repository     = local.devops_build_serving_ocir_repository_value
    image_tag                   = var.devops_build_image_tag
    ocir_username               = var.devops_build_ocir_username != null ? var.devops_build_ocir_username : ""
    ocir_auth_token_secret_ocid = var.devops_build_ocir_auth_token_secret_ocid != null ? var.devops_build_ocir_auth_token_secret_ocid : ""
  })
}

resource "local_file" "devops_deploy_command_spec" {
  count    = var.create_devops_deploy_pipeline ? 1 : 0
  filename = "${path.module}/devops/deploy_command_spec.yaml"
  content = templatefile("${path.module}/devops/deploy_command_spec.yaml.tftpl", {
    region                         = var.region
    cluster_id                     = oci_containerengine_cluster.oke.id
    timeout_in_seconds             = var.devops_deploy_stage_timeout_in_seconds
    serving_namespace              = var.serving_k8s_namespace
    serving_deployment             = var.serving_k8s_deployment_name
    serving_service                = var.serving_k8s_service_name
    mlflow_namespace               = var.mlflow_namespace
    mlflow_tracking_uri            = var.serving_mlflow_tracking_uri != null ? var.serving_mlflow_tracking_uri : ""
    mlflow_model_name              = var.serving_mlflow_model_name
    mlflow_model_stage             = var.serving_mlflow_model_stage
    ocir_region_code               = var.devops_build_ocir_region_code
    ocir_namespace                 = coalesce(var.devops_build_ocir_namespace, "")
    ocir_repository                = local.devops_build_serving_ocir_repository_value
    image_tag                      = var.devops_build_image_tag
    ocir_username                  = var.devops_build_ocir_username != null ? var.devops_build_ocir_username : ""
    ocir_auth_token_secret_ocid    = var.devops_build_ocir_auth_token_secret_ocid != null ? var.devops_build_ocir_auth_token_secret_ocid : ""
    serving_image_pull_secret_name = var.serving_image_pull_secret_name
  })
}

locals {
  devops_project_enabled         = true
  devops_project_logging_enabled = true
  devops_notification_topic_id   = var.devops_notification_topic_id != null ? var.devops_notification_topic_id : oci_ons_notification_topic.devops[0].id
  devops_notification_emails     = toset([for email in var.devops_notification_emails : trimspace(email) if trimspace(email) != ""])
}

resource "oci_ons_notification_topic" "devops" {
  count          = var.devops_notification_topic_id == null ? 1 : 0
  compartment_id = var.compartment_id
  name           = var.devops_notification_topic_name
}

resource "oci_devops_project" "mlflow_training" {
  count          = 1
  compartment_id = var.compartment_id
  name           = var.devops_project_name
  description    = "DevOps project for MLflow training pipeline."

  notification_config {
    topic_id = local.devops_notification_topic_id
  }
}

resource "oci_ons_subscription" "devops_email" {
  for_each       = local.devops_notification_emails
  compartment_id = var.compartment_id
  endpoint       = each.value
  protocol       = "EMAIL"
  topic_id       = local.devops_notification_topic_id
}

resource "oci_logging_log_group" "devops" {
  count          = local.devops_project_logging_enabled && var.devops_log_group_id == null ? 1 : 0
  compartment_id = var.compartment_id
  display_name   = var.devops_log_group_name
}

locals {
  managed_devops_log_group_id   = local.devops_project_logging_enabled && var.devops_log_group_id == null ? oci_logging_log_group.devops[0].id : null
  effective_devops_log_group_id = local.devops_project_logging_enabled ? (var.devops_log_group_id != null ? var.devops_log_group_id : local.managed_devops_log_group_id) : null
}

resource "oci_logging_log" "devops_project" {
  count              = local.devops_project_logging_enabled && var.devops_project_log_id == null ? 1 : 0
  display_name       = var.devops_project_log_name
  log_group_id       = local.effective_devops_log_group_id
  log_type           = "SERVICE"
  is_enabled         = true
  retention_duration = var.devops_project_log_retention_duration

  configuration {
    compartment_id = var.compartment_id

    source {
      service     = "devops"
      resource    = oci_devops_project.mlflow_training[0].id
      source_type = "OCISERVICE"
      category    = "all"
    }
  }
}

locals {
  managed_devops_project_log_id   = local.devops_project_logging_enabled && var.devops_project_log_id == null ? oci_logging_log.devops_project[0].id : null
  effective_devops_project_log_id = local.devops_project_logging_enabled ? (var.devops_project_log_id != null ? var.devops_project_log_id : local.managed_devops_project_log_id) : null
}

resource "oci_devops_connection" "github" {
  count           = 1
  project_id      = oci_devops_project.mlflow_training[0].id
  connection_type = "GITHUB_ACCESS_TOKEN"
  display_name    = var.devops_github_connection_name
  description     = "Terraform-managed GitHub external connection backed by OCI Vault secret."
  access_token    = var.devops_github_access_token_secret_id

  lifecycle {
    precondition {
      condition     = try(trimspace(var.devops_github_access_token_secret_id) != "", false)
      error_message = "Set devops_github_access_token_secret_id so Terraform can create the GitHub connection."
    }
  }
}

locals {
  effective_devops_github_connection_id = oci_devops_connection.github[0].id
}

resource "oci_devops_build_pipeline" "mlflow_training" {
  count        = 1
  project_id   = oci_devops_project.mlflow_training[0].id
  display_name = var.devops_build_pipeline_name
  description  = "Build pipeline for packaging training code and triggering Data Science job."
}

resource "oci_devops_deploy_pipeline" "serving" {
  count        = var.create_devops_deploy_pipeline ? 1 : 0
  project_id   = oci_devops_project.mlflow_training[0].id
  display_name = var.devops_deploy_pipeline_name
  description  = "Deploy pipeline to roll out latest MLflow serving image on OKE."
}

resource "oci_devops_deploy_artifact" "serving_command_spec" {
  count                      = var.create_devops_deploy_pipeline ? 1 : 0
  project_id                 = oci_devops_project.mlflow_training[0].id
  display_name               = var.devops_deploy_command_artifact_name
  argument_substitution_mode = "NONE"
  deploy_artifact_type       = "COMMAND_SPEC"

  deploy_artifact_source {
    deploy_artifact_source_type = "INLINE"
    base64encoded_content = base64encode(templatefile("${path.module}/devops/deploy_command_spec.yaml.tftpl", {
      region                         = var.region
      cluster_id                     = oci_containerengine_cluster.oke.id
      timeout_in_seconds             = var.devops_deploy_stage_timeout_in_seconds
      serving_namespace              = var.serving_k8s_namespace
      serving_deployment             = var.serving_k8s_deployment_name
      serving_service                = var.serving_k8s_service_name
      mlflow_namespace               = var.mlflow_namespace
      mlflow_tracking_uri            = var.serving_mlflow_tracking_uri != null ? var.serving_mlflow_tracking_uri : ""
      mlflow_model_name              = var.serving_mlflow_model_name
      mlflow_model_stage             = var.serving_mlflow_model_stage
      ocir_region_code               = var.devops_build_ocir_region_code
      ocir_namespace                 = coalesce(var.devops_build_ocir_namespace, "")
      ocir_repository                = local.devops_build_serving_ocir_repository_value
      image_tag                      = var.devops_build_image_tag
      ocir_username                  = var.devops_build_ocir_username != null ? var.devops_build_ocir_username : ""
      ocir_auth_token_secret_ocid    = var.devops_build_ocir_auth_token_secret_ocid != null ? var.devops_build_ocir_auth_token_secret_ocid : ""
      serving_image_pull_secret_name = var.serving_image_pull_secret_name
    }))
  }
}

resource "oci_devops_deploy_stage" "deploy_serving_shell" {
  count                           = var.create_devops_deploy_pipeline ? 1 : 0
  deploy_pipeline_id              = oci_devops_deploy_pipeline.serving[0].id
  display_name                    = var.devops_deploy_stage_name
  deploy_stage_type               = "SHELL"
  command_spec_deploy_artifact_id = oci_devops_deploy_artifact.serving_command_spec[0].id
  timeout_in_seconds              = var.devops_deploy_stage_timeout_in_seconds

  deploy_stage_predecessor_collection {
    items {
      id = oci_devops_deploy_pipeline.serving[0].id
    }
  }

  container_config {
    container_config_type = "CONTAINER_INSTANCE_CONFIG"
    compartment_id        = var.compartment_id
    availability_domain   = data.oci_identity_availability_domains.ads.availability_domains[0].name
    shape_name            = var.devops_deploy_stage_shape_name

    shape_config {
      ocpus         = var.devops_deploy_stage_shape_ocpus
      memory_in_gbs = var.devops_deploy_stage_shape_memory_in_gbs
    }

    network_channel {
      network_channel_type = "SERVICE_VNIC_CHANNEL"
      subnet_id            = local.devops_deploy_subnet_id_value
    }
  }
}

resource "oci_devops_build_pipeline_stage" "build_and_deploy" {
  count                     = 1
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
      error_message = "Set devops_github_access_token_secret_id so Terraform can create the GitHub connection."
    }
    precondition {
      condition     = try(trimspace(var.devops_repository_url) != "", false)
      error_message = "devops_repository_url is required."
    }
  }
}

resource "oci_devops_build_pipeline_stage" "trigger_serving_deploy" {
  count                          = var.create_devops_deploy_pipeline ? 1 : 0
  build_pipeline_id              = oci_devops_build_pipeline.mlflow_training[0].id
  build_pipeline_stage_type      = "TRIGGER_DEPLOYMENT_PIPELINE"
  display_name                   = var.devops_trigger_deploy_stage_name
  deploy_pipeline_id             = oci_devops_deploy_pipeline.serving[0].id
  is_pass_all_parameters_enabled = true

  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline_stage.build_and_deploy[0].id
    }
  }
}
