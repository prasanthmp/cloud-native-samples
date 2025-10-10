provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
      kubernetes {
    config_path = "~/.kube/config"
  }
}

locals {
  rendered_app_yaml_data = templatefile("${path.module}/k8s/app.yaml.tpl",{
    docker_image      = var.webapp_docker_image
    docker_image_port = var.webapp_docker_image_port
  })

    rendered_service_yaml_data = templatefile("${path.module}/k8s/service.yaml.tpl",{
        docker_image_port = var.webapp_docker_image_port
  })
}

resource "local_file" "app_file_spec" {
  content  = local.rendered_app_yaml_data
  filename = "${path.module}/k8s/app.yaml"

  depends_on = [time_sleep.wait_for_kubeconfig]  
}

resource "local_file" "service_file_spec" {
  content  = local.rendered_service_yaml_data
  filename = "${path.module}/k8s/service.yaml"

  depends_on = [local_file.app_file_spec]  
}

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  create_namespace = true

  values = [
    yamlencode({
      controller = {
        service = {
          type = "LoadBalancer"
          annotations = {
            "oci.oraclecloud.com/load-balancer-shape" = "flexible"
            "oci.oraclecloud.com/load-balancer-shape-flex-min" = "10"
            "oci.oraclecloud.com/load-balancer-shape-flex-max" = "100"
          }
        }
      }
    })
  ]

  depends_on = [local_file.service_file_spec]
}

resource "kubectl_manifest" "app" {
  yaml_body = local_file.app_file_spec.content
  depends_on = [helm_release.nginx_ingress]
}

resource "kubectl_manifest" "service" {
  yaml_body = local_file.service_file_spec.content
  depends_on = [kubectl_manifest.app]
}

resource "kubectl_manifest" "ingress" {
  yaml_body = file("${path.module}/k8s/ingress.yaml")
  depends_on = [kubectl_manifest.service]
}
