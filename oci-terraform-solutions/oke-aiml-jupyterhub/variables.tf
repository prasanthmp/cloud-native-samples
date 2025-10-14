# Variables
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "private_key_path" {}
variable "fingerprint" {}
variable "region" {}
variable "compartment_ocid" {}
variable "kubernetes" {}
variable "cloud_network" {} 
variable "grafana_user" {}
variable "grafana_pass" {}
variable "prometheus_url" {}
variable "dashboard_url" {}
variable "my_ipaddress" {}
variable "node_image_id" {}
variable "node_shape" {}
variable "all_oci_services_gw" {}
variable "helm" {
  default = {
    prometheus_repo = "https://prometheus-community.github.io/helm-charts"
    grafana_repo    = "https://grafana.github.io/helm-charts"
  }
}
variable "jupyterhub_token" {
  
}
variable "jupyterhub_password" {

}