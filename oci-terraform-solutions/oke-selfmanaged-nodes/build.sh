#!/bin/bash

START=$(date +%s)

terraform init

terraform apply -var-file="terraform.local.tfvars" -parallelism=5 -auto-approve

END=$(date +%s)
DURATION=$((END - START))

echo "Kubeconfig is created and you can find the kubeconfig file at ~/.kube/config."
echo "You can then use kubectl to interact with your cluster."
echo "For example, to get the list of nodes, run:"
echo "kubectl get nodes"
echo ""
echo "---------------------------------"
echo "$(date '+%Y-%m-%d %H:%M:%S') Terraform run took $((DURATION / 60)) minutes and $((DURATION % 60)) seconds" | tee -a terraform_runtime.log
echo "---------------------------------"