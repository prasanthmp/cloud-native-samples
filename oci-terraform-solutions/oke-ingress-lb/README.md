# OKE Ingress + Load Balancer

This workspace provisions an NGINX Ingress Controller on an OKE cluster and exposes a sample application through an OCI Load Balancer using the Kubernetes LoadBalancer service type. The Terraform configuration installs the ingress controller via Helm and deploys example Kubernetes manifests (deployment, service, ingress).

What this folder contains

- `main.tf`, `oke.tf` — Networking and OKE related Terraform resources.
- `ingress-controller.tf` — Installs the NGINX Ingress Controller via the Helm provider and applies sample `kubectl_manifest` resources.
- `k8s/app.yaml` — Sample Deployment for `hello-app`.
- `k8s/service.yaml` — ClusterIP Service for `hello-app`.
- `k8s/ingress.yaml` — Ingress resource bound to the NGINX ingress controller.
- `build.sh`, `delete.sh` — Helper scripts to apply and destroy the Terraform configuration.
- `terraform.tfvars`, `terraform.local.tfvars` — Variable examples (copy `terraform.tfvars` to `terraform.local.tfvars` and set your OCIDs / private key path / IPs).

Prerequisites

- Terraform >= 1.5.0
- OCI CLI configured and working
- A working kubeconfig with cluster admin permissions at `~/.kube/config` (the Terraform Kubernetes/Helm providers use this path)
- kubectl (for debugging)
- Helm CLI (optional, Terraform will install via provider)

What the Terraform does

- Installs the `ingress-nginx` Helm chart in the `ingress-nginx` namespace and configures the Controller Service as `LoadBalancer`.
- Creates the sample Deployment and Service.
- Applies the Ingress which relies on the NGINX controller's external Load Balancer IP.

Quick start

1. Copy and edit variables:

```bash
cd oci-terraform-solutions/oke-ingress-lb
cp terraform.tfvars terraform.local.tfvars
# Edit terraform.local.tfvars with your tenancy, region, compartment OCIDs and private_key_path
```

2. Run the helper script:

```bash
./build.sh
```

3. Wait for the Helm release and Load Balancer to provision. You can inspect resources with:

```bash
kubectl get ns,deploy,svc,ing -n ingress-nginx
kubectl get svc -A | grep ingress-nginx
```

4. Find the external IP or Hostname of the Load Balancer (the `ingress-nginx` controller service will be of type `LoadBalancer`). Use the external address to reach the app (the Terraform `outputs.tf` also expose the LB IP/OCID).

Example access flow

- Controller Service (LoadBalancer) receives traffic from OCI Load Balancer.
- Ingress routes traffic to the `hello-service` (ClusterIP) which forwards to pods on port 5100.

Notes & considerations

- Provider kubeconfig path: The `ingress-controller.tf` Terraform providers point to `~/.kube/config`. If you use a different kubeconfig, update the provider blocks accordingly.
- Load balancer shape: The Helm values set the OCI Load Balancer shape to `flexible` and provide minimum/maximum bandwidth annotations. Adjust these annotations if you need different LB sizing.
- Chart version: The Helm provider pulls the latest compatible chart by default; pin a specific chart version in `ingress-controller.tf` if you need reproducible installs.
- DNS and host rules: The provided `k8s/ingress.yaml` uses a rule for path `/`. For production, set `host` values and configure DNS records to point at the LB.

Troubleshooting

- Helm release pending/failing: Check `kubectl -n ingress-nginx describe pods` and the Terraform logs.
- Service never gets an external IP: Check OCI Console Load Balancer quotas and service limits. Also verify the `ingress-nginx` service annotated with `oci.oraclecloud.com/load-balancer-shape`.
- Ingress rules not routing: Verify the Ingress class and that the controller is reporting READY for endpoints.

Destroy

```bash
./delete.sh
```

License

See the repository `LICENSE` at the project root for license terms.
