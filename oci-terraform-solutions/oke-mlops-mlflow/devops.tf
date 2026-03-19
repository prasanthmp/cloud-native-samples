locals {
  devops_build_compartment_ocid_value         = var.devops_build_compartment_ocid != null ? var.devops_build_compartment_ocid : var.compartment_id
  devops_build_training_ocir_repository_value = var.create_ocir_training_repository ? var.ocir_training_repository_name : var.devops_build_ocir_repository
  devops_build_serving_ocir_repository_value  = var.create_ocir_serving_repository ? var.ocir_serving_repository_name : var.devops_build_serving_ocir_repository
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
