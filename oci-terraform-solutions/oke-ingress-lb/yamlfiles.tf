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
}

resource "local_file" "service_file_spec" {
  content  = local.rendered_service_yaml_data
  filename = "${path.module}/k8s/service.yaml"
}