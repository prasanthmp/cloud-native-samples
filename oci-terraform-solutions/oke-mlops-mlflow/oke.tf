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

locals {
  # MLflow uses S3 protocol for artifact I/O; this points to OCI Object Storage's S3-compatible endpoint.
  mlflow_artifact_root                          = "s3://${var.mlflow_artifact_bucket_name}/${trim(var.mlflow_artifact_object_prefix, "/")}"
  mlflow_s3_endpoint                            = "https://${local.object_storage_namespace_value}.compat.objectstorage.${var.region}.oraclecloud.com"
  mlflow_use_object_storage_artifacts_effective = var.mlflow_use_object_storage_artifacts && try(trimspace(local.mlflow_s3_access_key_id_value) != "", false) && try(trimspace(local.mlflow_s3_secret_access_key_value) != "", false)
}

resource "kubernetes_namespace_v1" "mlflow" {
  metadata {
    name = var.mlflow_namespace
  }
}

resource "kubernetes_secret_v1" "mlflow_object_storage" {
  count = local.mlflow_use_object_storage_artifacts_effective ? 1 : 0

  metadata {
    name      = "mlflow-object-storage"
    namespace = kubernetes_namespace_v1.mlflow.metadata[0].name
  }

  type = "Opaque"
  data = {
    # These AWS_* keys are the standard env var names expected by MLflow/boto3 for S3-compatible storage.
    # Values come from OCI Customer Secret Keys, not AWS.
    AWS_ACCESS_KEY_ID      = local.mlflow_s3_access_key_id_value
    AWS_SECRET_ACCESS_KEY  = local.mlflow_s3_secret_access_key_value
    AWS_DEFAULT_REGION     = var.region
    MLFLOW_S3_ENDPOINT_URL = local.mlflow_s3_endpoint
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

          command = ["/bin/sh", "-c"]
          args = [
            "pip install --no-cache-dir boto3 && exec mlflow server --host 0.0.0.0 --port 5000 --backend-store-uri sqlite:///mlflow.db --serve-artifacts --artifacts-destination '${local.mlflow_use_object_storage_artifacts_effective ? local.mlflow_artifact_root : "/mlflow/artifacts"}' --default-artifact-root '${local.mlflow_use_object_storage_artifacts_effective ? local.mlflow_artifact_root : "mlflow-artifacts:/"}'"
          ]

          port {
            container_port = 5000
          }

          dynamic "env" {
            for_each = local.mlflow_use_object_storage_artifacts_effective ? [1] : []
            content {
              name = "AWS_ACCESS_KEY_ID"
              value_from {
                secret_key_ref {
                  name = "mlflow-object-storage"
                  key  = "AWS_ACCESS_KEY_ID"
                }
              }
            }
          }

          dynamic "env" {
            for_each = local.mlflow_use_object_storage_artifacts_effective ? [1] : []
            content {
              name = "AWS_SECRET_ACCESS_KEY"
              value_from {
                secret_key_ref {
                  name = "mlflow-object-storage"
                  key  = "AWS_SECRET_ACCESS_KEY"
                }
              }
            }
          }

          dynamic "env" {
            for_each = local.mlflow_use_object_storage_artifacts_effective ? [1] : []
            content {
              name = "AWS_DEFAULT_REGION"
              value_from {
                secret_key_ref {
                  name = "mlflow-object-storage"
                  key  = "AWS_DEFAULT_REGION"
                }
              }
            }
          }

          dynamic "env" {
            for_each = local.mlflow_use_object_storage_artifacts_effective ? [1] : []
            content {
              name = "MLFLOW_S3_ENDPOINT_URL"
              value_from {
                secret_key_ref {
                  name = "mlflow-object-storage"
                  key  = "MLFLOW_S3_ENDPOINT_URL"
                }
              }
            }
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

  depends_on = [oci_containerengine_node_pool.default, kubernetes_secret_v1.mlflow_object_storage]
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
