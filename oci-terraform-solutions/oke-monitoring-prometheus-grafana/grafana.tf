# -----------------------------
# Null resource: Install Grafana
# -----------------------------
resource "null_resource" "install_grafana" {
  provisioner "local-exec" {
    command = <<EOT
      export KUBECONFIG=${path.module}/kubeconfig

      helm repo add grafana ${var.helm.grafana_repo}
      helm repo update

      helm upgrade --install grafana grafana/grafana \
        -n monitoring \
        --set service.type=LoadBalancer \
        --set adminPassword=${var.grafana_pass} \
        --set adminUser=${var.grafana_user} \
        --set datasources."datasources\.yaml".apiVersion=1 \
        --set datasources."datasources\.yaml".datasources[0].name=Prometheus \
        --set datasources."datasources\.yaml".datasources[0].type=prometheus \
        --set datasources."datasources\.yaml".datasources[0].url=${var.prometheus_url} \
        --set datasources."datasources\.yaml".datasources[0].access=proxy \
        --set datasources."datasources\.yaml".datasources[0].isDefault=true
        --set grafana.sidecar.dashboards.enabled=true \
        --set grafana.sidecar.dashboards.searchNamespace=ALL \
        --set dashboardsProvider.default.enabled=true

      # Wait for Grafana pod to be ready
      kubectl rollout status deployment grafana -n monitoring
    EOT
  }
  depends_on = [null_resource.install_prometheus]
}

# === Fetch dashboard JSON ===
data "http" "dashboard" {
  url = var.dashboard_url
}

# === Patch dashboard JSON (Prometheus will always be the datasource) ===
locals {
  # Replace datasource with Prometheus UID placeholder (will resolve after datasource creation)
  dashboard_patched = replace(
    data.http.dashboard.response_body,
    "(\"datasource\":\\s*(null|\"[^\"]*\"))",
    "{\"type\":\"prometheus\",\"uid\":\"PROM_UID_PLACEHOLDER\"}"
  )
}

# === Create Prometheus datasource in Grafana ===
resource "null_resource" "prometheus_datasource" {
  provisioner "local-exec" {
    command = <<EOT
curl -s -u ${var.grafana_user}:${var.grafana_pass} \
  -X POST "http://${data.external.grafana_ip.result.external_ip}/api/datasources" \
  -H "Content-Type: application/json" \
  -d '{
    "name":"Prometheus",
    "type":"prometheus",
    "url":"http://prometheus:9090",
    "access":"proxy",
    "basicAuth":false
  }'
EOT
  }
  depends_on = [null_resource.install_grafana]
}

# === Fetch Prometheus UID after creation ===
data "http" "prometheus_datasource" {
  depends_on = [null_resource.prometheus_datasource]

  url = "http://${data.external.grafana_ip.result.external_ip}/api/datasources"
  request_headers = {
    Authorization = "Basic ${base64encode("${var.grafana_user}:${var.grafana_pass}")}"
  }
}

locals {
  datasources = jsondecode(data.http.prometheus_datasource.response_body)
  prom_uid    = [for ds in local.datasources : ds.uid if ds.type == "prometheus"][0]

  dashboard_final = replace(
    local.dashboard_patched,
    "$${DS__VICTORIAMETRICS-PROD-ALL}",
    local.prom_uid
  )
}

# === Import patched dashboard into Grafana ===
resource "null_resource" "import_dashboard" {
  depends_on = [null_resource.prometheus_datasource]

  provisioner "local-exec" {
    command = <<EOT
curl -s -u ${var.grafana_user}:${var.grafana_pass} \
  -X POST "http://${data.external.grafana_ip.result.external_ip}/api/dashboards/db" \
  -H "Content-Type: application/json" \
  -d '${jsonencode({
    dashboard = jsondecode(local.dashboard_final)
    overwrite = true
  })}'
EOT
  }
}

# Update tags for OKE Load Balancers created by the cluster
# This is needed to ensure that the Load Balancers created by OKE are tagged with the correct cluster information
resource "null_resource" "tag_oke_lbs_prometheus" {
  provisioner "local-exec" {
    command = "chmod +x ${path.module}/tag_oke_lbs.sh"
  }

  provisioner "local-exec" {
    command = "${path.module}/tag_oke_lbs.sh ${var.compartment_ocid} ${oci_containerengine_cluster.oke-mon-cluster.id} ${var.kubernetes.cluster_name}-prometheus ${data.external.prometheus_ip.result.external_ip}"
  }


  depends_on = [
    null_resource.import_dashboard
  ]
}

resource "null_resource" "tag_oke_lbs_grafana" {
  provisioner "local-exec" {
    command = "chmod +x ${path.module}/tag_oke_lbs.sh"
  }

  provisioner "local-exec" {
    command = "${path.module}/tag_oke_lbs.sh ${var.compartment_ocid} ${oci_containerengine_cluster.oke-mon-cluster.id} ${var.kubernetes.cluster_name}-grafana ${data.external.grafana_ip.result.external_ip}"
    }
  
  depends_on = [
    null_resource.tag_oke_lbs_prometheus
  ]
}