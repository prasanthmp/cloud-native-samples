resource oci_logging_log_group oke_devops_cicd_log_group {
  compartment_id = var.compartment_ocid
  display_name = var.log_group_name
}

resource oci_logging_log oke_devops_cicd_project_all {
  configuration {
    compartment_id = var.compartment_ocid
    source {
      category = "all"
      parameters = {
      }
      resource    = oci_devops_project.webapp-devops-project.id
      service     = "devops"
      source_type = "OCISERVICE"
    }
  }

  display_name = "oke_devops_cicd_project_all"
  is_enabled         = "true"
  log_group_id       = oci_logging_log_group.oke_devops_cicd_log_group.id
  log_type           = "SERVICE"
  retention_duration = "30"
}

