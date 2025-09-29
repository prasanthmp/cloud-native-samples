resource oci_ons_notification_topic devops-notifications {
  compartment_id = var.compartment_ocid
  name = "flaskapp-notifications"
}

resource oci_ons_subscription ons_subscription {
  compartment_id = var.compartment_ocid
  delivery_policy = "{\"backoffRetryPolicy\":{\"maxRetryDuration\":7200000,\"policyType\":\"EXPONENTIAL\"}}"
  endpoint        = var.notification_email
  protocol = "EMAIL"
  topic_id = oci_ons_notification_topic.devops-notifications.id
}

