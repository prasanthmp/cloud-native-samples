
# Build pipeline
resource oci_devops_build_pipeline webapp-build {
  display_name = "webapp-build"
  project_id = oci_devops_project.webapp-devops-project.id
  description = "Build pipeline to build and push Docker image to OCIR and deploy to OKE"

   build_pipeline_parameters {
    # Pipeline parameter -IMAGE_TAG
    items {
        name              = "IMAGE_TAG"
        description       = "Docker image tag to deploy"
        default_value     = "$OCI_BUILD_RUN_ID"
      }
      # Pipeline parameter -AUTH_TOKEN_OCI
    items {
        name              = "AUTH_TOKEN_OCI"
        description       = "Auth token for Docker login to OCIR"
        default_value     = var.oci_auth_token_vault
      }
    }
}

# Build stage to build and push the Docker image for the webapp
resource oci_devops_build_pipeline_stage build-and-push-image {
  build_pipeline_id = oci_devops_build_pipeline.webapp-build.id
  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline.webapp-build.id
    }
  }
  build_pipeline_stage_type = "BUILD"
  build_runner_shape_config {
    build_runner_type = "DEFAULT"
  }
  build_source_collection {
    items {
      branch = "main"
      connection_type = "DEVOPS_CODE_REPOSITORY"
      name            = var.devops.code_repository_name
      repository_id   = oci_devops_repository.webapp-private-code-repo.id
      repository_url  = oci_devops_repository.webapp-private-code-repo.http_url
    }
  }
  display_name = "build-and-push-image-to-ocir"
  image = var.devops.build_runner_image
  primary_build_source = var.devops.code_repository_name

  stage_execution_timeout_in_seconds = "36000"
}

# Build pipeline stage to trigger deployment to Kubernetes
resource oci_devops_build_pipeline_stage deploy-image-to-k8s {
  build_pipeline_id = oci_devops_build_pipeline.webapp-build.id
  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline_stage.build-and-push-image.id
    }
  }
  build_pipeline_stage_type = "TRIGGER_DEPLOYMENT_PIPELINE"
  deploy_pipeline_id = oci_devops_deploy_pipeline.deploy-to-oke.id
  display_name       = "deploy-image-to-k8s"
  is_pass_all_parameters_enabled = "true"
}
