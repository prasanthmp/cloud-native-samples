#!/bin/bash

START=$(date +%s)

terraform init

terraform apply -var-file="terraform.local.tfvars" -parallelism=5 -auto-approve

END=$(date +%s)
DURATION=$((END - START))

echo "You can find the kubeconfig file at ~/.kube/config"
echo ""
echo "---------------------------------"
echo "$(date '+%Y-%m-%d %H:%M:%S') Terraform run took $((DURATION / 60)) minutes and $((DURATION % 60)) seconds" | tee -a terraform_runtime.log
echo "---------------------------------"