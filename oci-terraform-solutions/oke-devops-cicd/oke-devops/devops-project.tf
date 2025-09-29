
# DevOps project
resource oci_devops_project webapp-devops-project {
  compartment_id = var.compartment_ocid
  name = var.devops.project_name
  notification_config {
    topic_id = oci_ons_notification_topic.devops-notifications.id
  }
}

# Private code repository
resource oci_devops_repository webapp-private-code-repo {
  default_branch = "refs/heads/main"
  name                 = var.devops.code_repository_name
  project_id           = oci_devops_project.webapp-devops-project.id
  repository_type      = "HOSTED"
}

# Deploy environment
resource oci_devops_deploy_environment oke-cluster_1 {
  cluster_id = oci_containerengine_cluster.oke-cluster.id
  deploy_environment_type = "OKE_CLUSTER"
  display_name            = "oke-cluster"
  description             = "Deploy environment for OKE cluster"
  project_id = oci_devops_project.webapp-devops-project.id

  network_channel {
    network_channel_type = "PRIVATE_ENDPOINT_CHANNEL"
    subnet_id = oci_core_subnet.oke-cluster-k8sApiEndpoint-subnet-regional.id
  }
}

# Trigger for code repository push events to start the build pipeline
resource oci_devops_trigger code-repo-push-trigger {
  actions {
    build_pipeline_id = oci_devops_build_pipeline.webapp-build.id
    filter {
      events = [
        "PUSH",
      ]
      trigger_source = "DEVOPS_CODE_REPOSITORY"
    }
    type = "TRIGGER_BUILD_PIPELINE"
  }

  display_name = "code-repo-push-trigger"
  project_id     = oci_devops_project.webapp-devops-project.id
  repository_id  = oci_devops_repository.webapp-private-code-repo.id
  trigger_source = "DEVOPS_CODE_REPOSITORY"
}

