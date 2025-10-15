provider "kubernetes" {
  config_path = "~/.kube/config"
}

locals {
  rendered_app_yaml_data = templatefile("${path.module}/k8s/app.yaml.tpl",{
    docker_image      = var.docker_image
  })
}

resource "local_file" "app_file_spec" {
  content  = local.rendered_app_yaml_data
  filename = "${path.module}/k8s/app.yaml"

  depends_on = [time_sleep.wait_for_kubeconfig]  
}

resource "kubectl_manifest" "image-recognition-app" {
  yaml_body = local_file.app_file_spec.content
  depends_on = [local_file.app_file_spec]
}

resource "kubectl_manifest" "image-recognition-service" {
  yaml_body = file("${path.module}/k8s/service.yaml")
  depends_on = [kubectl_manifest.image-recognition-app]
}
