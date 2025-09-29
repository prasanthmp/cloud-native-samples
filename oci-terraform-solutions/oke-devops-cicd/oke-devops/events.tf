resource oci_events_rule Build-start {
  actions {
    actions {
      action_type = "ONS"
      is_enabled = "true"
      topic_id = oci_ons_notification_topic.devops-notifications.id
    }
  }
  compartment_id = var.compartment_ocid
  condition      = "{\"eventType\":[\"com.oraclecloud.devopsbuild.createbuildrun\"],\"data\":{}}"
  display_name = "Build start"
  is_enabled = "true"
}

resource oci_events_rule Deployment-start {
  actions {
    actions {
      action_type = "ONS"
      is_enabled = "true"
      topic_id = oci_ons_notification_topic.devops-notifications.id
    }
  }
  compartment_id = var.compartment_ocid
  condition      = "{\"eventType\":[\"com.oraclecloud.devopsdeploy.createdeployment\"],\"data\":{}}"
  display_name = "Deployment start"
  is_enabled = "true"
}

