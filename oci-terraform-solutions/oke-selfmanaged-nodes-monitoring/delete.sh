#!/bin/bash

START=$(date +%s)

terraform destroy -var-file="terraform.local.tfvars" -auto-approve \
 -target=null_resource.install_grafana \
 -target=null_resource.cleanup_monitoring_ns

terraform destroy -var-file="terraform.local.tfvars" -auto-approve

END=$(date +%s)
DURATION=$((END - START))

echo ""
echo "---------------------------------"
echo "$(date '+%Y-%m-%d %H:%M:%S') Terraform destroy took $((DURATION / 60)) minutes and $((DURATION % 60)) seconds" | tee -a terraform_destroy_runtime.log
echo "---------------------------------"
