locals {
  rendered_build_spec_data = templatefile("${path.module}/templates/build_spec.yaml.tpl",{
    ocir_host      = var.ocir.host
    ocir_username  = "${var.oci_user_namespace}/${var.ocir.username}"
    ocir_image_id  = "${var.ocir.host}/${var.oci_user_namespace}/${var.webapp_image}" 

    oci_auth_token = var.oci_auth_token_vault
    # ocir.us-chicago-1.oci.oraclecloud.com/idxlfhtrvfsa/webapp-repo
    ocir_repo      = "${var.ocir.host}/${var.oci_user_namespace}/${var.webapp_image}"   
    })
}

resource "local_file" "buid_file_spec" {
  content  = local.rendered_build_spec_data
  filename = "../microservices-python-flask-app/build_spec.yaml"
}

