data "oci_containerengine_cluster_kube_config" "oke" {
  cluster_id    = oci_containerengine_cluster.oke.id
  token_version = "2.0.0"
}

resource "local_sensitive_file" "kubeconfig" {
  content         = data.oci_containerengine_cluster_kube_config.oke.content
  filename        = "${path.module}/kubeconfig"
  file_permission = "0600"
}

provider "kubernetes" {
  config_path = local_sensitive_file.kubeconfig.filename
}

resource "kubernetes_namespace_v1" "mlflow" {
  metadata {
    name = var.mlflow_namespace
  }
}

resource "kubernetes_deployment_v1" "mlflow" {
  metadata {
    name      = "mlflow"
    namespace = kubernetes_namespace_v1.mlflow.metadata[0].name
    labels = {
      app = "mlflow"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mlflow"
      }
    }

    template {
      metadata {
        labels = {
          app = "mlflow"
        }
      }

      spec {
        container {
          name  = "mlflow"
          image = var.mlflow_image

          command = ["mlflow"]
          args = [
            "server",
            "--host", "0.0.0.0",
            "--port", "5000",
            "--backend-store-uri", "sqlite:///mlflow.db",
            "--serve-artifacts",
            "--artifacts-destination", "/mlflow/artifacts",
            "--default-artifact-root", "mlflow-artifacts:/"
          ]

          port {
            container_port = 5000
          }

          volume_mount {
            name       = "mlflow-data"
            mount_path = "/mlflow"
          }
        }

        volume {
          name = "mlflow-data"

          empty_dir {}
        }
      }
    }
  }

  depends_on = [oci_containerengine_node_pool.default]
}

resource "kubernetes_service_v1" "mlflow" {
  metadata {
    name      = "mlflow"
    namespace = kubernetes_namespace_v1.mlflow.metadata[0].name
  }

  spec {
    selector = {
      app = "mlflow"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 5000
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }

  depends_on = [kubernetes_deployment_v1.mlflow]
}

locals {
  mlflow_lb_hostname = try(kubernetes_service_v1.mlflow.status[0].load_balancer[0].ingress[0].hostname, "")
  mlflow_lb_ip       = try(kubernetes_service_v1.mlflow.status[0].load_balancer[0].ingress[0].ip, "")
  mlflow_host        = local.mlflow_lb_hostname != "" ? local.mlflow_lb_hostname : local.mlflow_lb_ip
}
