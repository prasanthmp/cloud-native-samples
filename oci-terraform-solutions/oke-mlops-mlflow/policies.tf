resource "oci_identity_policy" "oke_cluster" {
  count          = var.create_oke_workload_policy ? 1 : 0
  compartment_id = var.tenancy_ocid
  name           = "${var.cluster_name}-oke-workload-policy"
  description    = "Allows OKE cluster workloads to manage OCI resources needed by Kubernetes services."

  statements = [
    "Allow any-user to manage load-balancers in compartment id ${var.compartment_id} where all {request.principal.type = 'cluster', request.principal.compartment.id = '${var.compartment_id}'}",
    "Allow any-user to use subnets in compartment id ${var.compartment_id} where all {request.principal.type = 'cluster', request.principal.compartment.id = '${var.compartment_id}'}",
    "Allow any-user to manage vnics in compartment id ${var.compartment_id} where all {request.principal.type = 'cluster', request.principal.compartment.id = '${var.compartment_id}'}"
  ]
}

resource "oci_identity_policy" "devops_build_pipeline" {
  count          = var.create_project_iam_policies ? 1 : 0
  compartment_id = var.tenancy_ocid
  name           = "${var.cluster_name}-devops-build-policy"
  description    = "Allows OCI DevOps build pipeline principal to access required resources in the project compartment."

  statements = [
    "Allow any-user to manage all-resources in compartment id ${var.compartment_id} where all {request.principal.type = 'devopsbuildpipeline'}"
  ]
}

resource "oci_identity_policy" "devops_deploy_pipeline" {
  count          = var.create_project_iam_policies && var.create_devops_deploy_pipeline ? 1 : 0
  compartment_id = var.tenancy_ocid
  name           = "${var.cluster_name}-devops-deploy-policy"
  description    = "Allows OCI DevOps deploy pipeline principal to create shell stage container instances and deploy to OKE."

  statements = [
    "Allow any-user to manage all-resources in compartment id ${var.compartment_id} where all {request.principal.type = 'devopsdeploypipeline'}"
  ]
}

resource "oci_identity_policy" "datascience_runtime" {
  count          = var.create_project_iam_policies ? 1 : 0
  compartment_id = var.tenancy_ocid
  name           = "${var.cluster_name}-datascience-runtime-policy"
  description    = "Allows OCI Data Science notebook and job run principals to access required project resources."

  statements = [
    "Allow any-user to manage all-resources in compartment id ${var.compartment_id} where all {request.principal.type = 'datasciencejobrun'}",
    "Allow any-user to manage all-resources in compartment id ${var.compartment_id} where all {request.principal.type = 'datasciencenotebooksession'}",
    "Allow any-user to read log-groups in compartment id ${var.compartment_id} where all {request.principal.type = 'datasciencejobrun'}",
    "Allow any-user to manage logs in compartment id ${var.compartment_id} where all {request.principal.type = 'datasciencejobrun'}",
    "Allow any-user to use log-content in compartment id ${var.compartment_id} where all {request.principal.type = 'datasciencejobrun'}",
    "Allow service datascience to read log-groups in compartment id ${var.compartment_id}",
    "Allow service datascience to manage logs in compartment id ${var.compartment_id}",
    "Allow service datascience to use log-content in compartment id ${var.compartment_id}"
  ]
}
