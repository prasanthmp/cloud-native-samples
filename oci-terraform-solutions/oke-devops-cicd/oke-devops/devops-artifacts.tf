
# Get the secret bundle from OCI Vault
data "oci_secrets_secretbundle" "auth_secret" {
  secret_id = var.oci_auth_token_vault   # OCID of your secret
}

locals {

  auth_token_value = base64decode(data.oci_secrets_secretbundle.auth_secret.secret_bundle_content[0].content)

  image_id = "${var.ocir.host}/${var.oci_user_namespace}/${var.webapp_image}"
  ocir_user = "${var.oci_user_namespace}/${var.ocir.username}"

  app_deployment_yaml = templatefile("${path.module}/k8s/webapp.yaml.tpl", {
    #app_container_image_id = local.image_id
    app_container_image_id = "$${IMAGE_TAG}"
    webapp_name = var.webapp_name
    webapp_port = var.webapp_port
    time_stamp = timestamp()
  })

  service_deployment_yaml = templatefile("${path.module}/k8s/service.yaml.tpl", {
    webapp_name = var.webapp_name
    webapp_service_name = var.webapp_service_name
    webapp_port = var.webapp_port
  })

  docker_config_json = templatefile("${path.module}/k8s/dockerjson.json.tpl", {
    ocir_host     = var.ocir.host
    ocir_username = local.ocir_user
    ocir_password = local.auth_token_value
    ocir_image_id = local.image_id
    ocir_email = var.ocir.email
    ocir_auth = base64encode(
      "${local.ocir_user}:${local.auth_token_value}" # Use the auth token vault variable
    ) # Base64 encode the username:password for Docker config
  })

  secrets_deployment_yaml = templatefile("${path.module}/k8s/secrets.yaml.tpl", {
    dockerconfigjson = base64encode(local.docker_config_json) # Base64 encode the docker config JSON
  })
}

# Artifact - App docker image
resource oci_devops_deploy_artifact webapp-image {
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"

  deploy_artifact_source {
    deploy_artifact_source_type = "OCIR"
    image_uri    = local.image_id
  }
  deploy_artifact_type = "DOCKER_IMAGE"
  display_name         = "webapp-image"
  project_id = oci_devops_project.webapp-devops-project.id
}

# Artifact - Kubernetes manifest for webapp service deployment
resource oci_devops_deploy_artifact webapp-service {
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_source {
    #base64encoded_content = base64encode(var.flask_app_service_deployment)
    base64encoded_content = base64encode(local.service_deployment_yaml)
    deploy_artifact_source_type = "INLINE"
  }
  deploy_artifact_type = "KUBERNETES_MANIFEST"
  description          = ""
  display_name         = "webapp-service"
  freeform_tags = {
  }
  project_id = oci_devops_project.webapp-devops-project.id
}

# Artifact - Kubernetes manifest for Flask app deployment
resource oci_devops_deploy_artifact webapp {
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_source {
    #base64encoded_content = base64encode(var.flask_app_deployment)
    base64encoded_content = base64encode(local.app_deployment_yaml)
    deploy_artifact_source_type = "INLINE"
  }
  deploy_artifact_type = "KUBERNETES_MANIFEST"
  description          = ""
  display_name         = "webapp"
  freeform_tags = {
  }
  project_id = oci_devops_project.webapp-devops-project.id
}

# Artifact - Kubernetes manifest for creating secrets
resource oci_devops_deploy_artifact ocir-secrets {
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_source {
    #base64encoded_content = base64encode(var.flask_app_secret_deployment)
    base64encoded_content = base64encode(local.secrets_deployment_yaml)
    deploy_artifact_source_type = "INLINE"
  }
  deploy_artifact_type = "KUBERNETES_MANIFEST"
  description          = ""
  display_name         = "ocir-secrets"
  freeform_tags = {
  }
  project_id = oci_devops_project.webapp-devops-project.id
}

