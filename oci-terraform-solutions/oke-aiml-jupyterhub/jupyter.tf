provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
    kubernetes = {
    config_path = "~/.kube/config"
  }
}

# Helm release for JupyterHub
resource "helm_release" "jupyterhub" {
  name       = "jhub"
  repository = var.helm.jupyterhub_repo
  chart      = "jupyterhub"
  version    = var.helm.jupyterhub_version
  namespace  = "jhub"
  create_namespace = true

  values = [
    yamlencode({
      proxy = {
        secretToken = "${var.jupyterhub_token}"
      }
      singleuser = {
        image = {
          name = "jupyter/tensorflow-notebook"
          tag  = "latest"
        }
        memory = {
          limit     = "2G"
          guarantee = "1G"
        }
      }
    })
  ]

  depends_on = [ null_resource.install_grafana ]
}
