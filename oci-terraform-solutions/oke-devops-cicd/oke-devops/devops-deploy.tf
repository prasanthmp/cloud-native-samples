# Deploy pipeline
resource oci_devops_deploy_pipeline deploy-to-oke {
  description  = ""
  display_name = "deploy-to-oke"
  project_id = oci_devops_project.webapp-devops-project.id
}

# Deploy pipeline stage to create secrets to pull the container image from OCIR
resource oci_devops_deploy_stage deploy-secrets-to-oke { 
  deploy_pipeline_id = oci_devops_deploy_pipeline.deploy-to-oke.id
  deploy_stage_predecessor_collection {
    items {
      id = oci_devops_deploy_pipeline.deploy-to-oke.id
    }
  }
  deploy_stage_type = "OKE_DEPLOYMENT"
  display_name = "deploy-ocir-secrets-to-oke"
 
  kubernetes_manifest_deploy_artifact_ids = [
    oci_devops_deploy_artifact.ocir-secrets.id,
  ]
  
  namespace = "default"
  oke_cluster_deploy_environment_id = oci_devops_deploy_environment.oke-cluster_1.id
    rollback_policy {
    policy_type = "NO_STAGE_ROLLBACK_POLICY"
  }
}

# Deploy pipeline stage to deploy the application to OKE
resource oci_devops_deploy_stage deploy-app-to-oke { 
  deploy_pipeline_id = oci_devops_deploy_pipeline.deploy-to-oke.id
  deploy_stage_predecessor_collection {
    items {
      id = oci_devops_deploy_stage.deploy-secrets-to-oke.id
    }
  }
  deploy_stage_type = "OKE_DEPLOYMENT"
  description  = ""
  display_name = "deploy-app-to-oke"
 
  kubernetes_manifest_deploy_artifact_ids = [
    oci_devops_deploy_artifact.webapp.id,
  ]
  
  namespace = "default"
  oke_cluster_deploy_environment_id = oci_devops_deploy_environment.oke-cluster_1.id
    rollback_policy {
    policy_type = "NO_STAGE_ROLLBACK_POLICY"
  }
}

# Deploy pipeline stage to deploy service to OKE
resource oci_devops_deploy_stage deploy-webapp-service-to-oke {
  deploy_pipeline_id = oci_devops_deploy_pipeline.deploy-to-oke.id
  deploy_stage_predecessor_collection {
    items {
      id = oci_devops_deploy_stage.deploy-app-to-oke.id
    }
  }
  deploy_stage_type = "OKE_DEPLOYMENT"
  display_name = "deploy-service-to-oke"

  kubernetes_manifest_deploy_artifact_ids = [
    oci_devops_deploy_artifact.webapp-service.id,
  ]

  namespace = "default"
    oke_cluster_deploy_environment_id = oci_devops_deploy_environment.oke-cluster_1.id

  rollback_policy {
    policy_type = "NO_STAGE_ROLLBACK_POLICY"
  }
}