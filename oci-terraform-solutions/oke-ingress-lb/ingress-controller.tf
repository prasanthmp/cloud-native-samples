provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
      kubernetes {
    config_path = "~/.kube/config"
  }
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

  depends_on = [time_sleep.wait_for_kubeconfig]
}

resource "kubectl_manifest" "app" {
  yaml_body = local_file.app_file_spec.content
  depends_on = [local_file.app_file_spec]
}

resource "kubectl_manifest" "service" {
  yaml_body = local_file.service_file_spec.content
  depends_on = [local_file.service_file_spec]
}

resource "kubectl_manifest" "ingress" {
  yaml_body = file("${path.module}/k8s/ingress.yaml")
  depends_on = [kubectl_manifest.service]
}
