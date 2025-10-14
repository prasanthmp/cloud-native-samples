#!/bin/bash
START=$(date +%s)

terraform destroy -var-file="terraform.local.tfvars" -auto-approve \
 -target=null_resource.setup_prometheus \
 -target=null_resource.install_prometheus \
 -target=null_resource.install_grafana \
 -target=null_resource.prometheus_datasource \
 -target=null_resource.import_dashboard \
 -target=null_resource.cleanup_monitoring_ns \
 -target=helm_release.jupyterhub

terraform destroy -var-file="terraform.local.tfvars" -auto-approve

END=$(date +%s)
DURATION=$((END - START))

echo ""
echo "---------------------------------"
echo "$(date '+%Y-%m-%d %H:%M:%S') Terraform destroy took $((DURATION / 60)) minutes and $((DURATION % 60)) seconds" | tee -a terraform_destroy_runtime.log
echo "---------------------------------"