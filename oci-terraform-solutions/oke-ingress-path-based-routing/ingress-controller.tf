provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
      kubernetes {
    config_path = "~/.kube/config"
  }
}

locals {
  rendered_app_yaml_data_python = templatefile("${path.module}/k8s/app.yaml.tpl",{
    docker_image      = var.python_webapp_docker_image
    docker_image_port = var.python_webapp_docker_image_port
    app_name          = "python-webapp"
  })

    rendered_service_yaml_data_python = templatefile("${path.module}/k8s/service.yaml.tpl",{
        docker_image_port = var.python_webapp_docker_image_port
        app_name          = "python-webapp"
        service_name      =   "python-webapp-service"
  })

  rendered_app_yaml_data_node = templatefile("${path.module}/k8s/app.yaml.tpl",{
    docker_image      = var.node_webapp_docker_image
    docker_image_port = var.node_webapp_docker_image_port
    app_name          = "node-webapp"
  })

    rendered_service_yaml_data_node = templatefile("${path.module}/k8s/service.yaml.tpl",{
        docker_image_port = var.node_webapp_docker_image_port
        app_name          = "node-webapp"
        service_name      = "node-webapp-service"
  })  
}

resource "local_file" "python_webapp_file_spec" {
  content  = local.rendered_app_yaml_data_python
  filename = "${path.module}/k8s/python-webapp.yaml"

  depends_on = [time_sleep.wait_for_kubeconfig]  
}

resource "local_file" "python_service_file_spec" {
  content  = local.rendered_service_yaml_data_python
  filename = "${path.module}/k8s/python-service.yaml"

  depends_on = [local_file.python_webapp_file_spec]  
}

resource "local_file" "node_webapp_file_spec" {
  content  = local.rendered_app_yaml_data_node
  filename = "${path.module}/k8s/node-webapp.yaml"

  depends_on = [time_sleep.wait_for_kubeconfig]  
}

resource "local_file" "node_service_file_spec" {
  content  = local.rendered_service_yaml_data_node
  filename = "${path.module}/k8s/node-service.yaml"

  depends_on = [local_file.node_webapp_file_spec]  
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

  depends_on = [local_file.python_service_file_spec, local_file.node_service_file_spec]
}

resource "time_sleep" "wait_for_ingress" {
  depends_on      = [helm_release.nginx_ingress]
  create_duration = "20s"
}

resource "kubectl_manifest" "python-webapp" {
  yaml_body = local_file.python_webapp_file_spec.content
  depends_on = [time_sleep.wait_for_ingress]
}

resource "kubectl_manifest" "python-service" {
  yaml_body = local_file.python_service_file_spec.content
  depends_on = [kubectl_manifest.python-webapp]
}

resource "kubectl_manifest" "node-webapp" {
  yaml_body = local_file.node_webapp_file_spec.content
  depends_on = [kubectl_manifest.python-service]
}

resource "kubectl_manifest" "node-service" {
  yaml_body = local_file.node_service_file_spec.content
  depends_on = [kubectl_manifest.node-webapp]
}

resource "kubectl_manifest" "ingress" {
  yaml_body = file("${path.module}/k8s/ingress.yaml")
  depends_on = [kubectl_manifest.node-service]
}
