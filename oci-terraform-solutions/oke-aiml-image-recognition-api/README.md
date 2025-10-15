# OKE AI/ML — Image Recognition API (Terraform)

This project demonstrates how to deploy a scalable, containerized Image Recognition API on Oracle Kubernetes Engine (OKE). Using a pre-trained ResNet50 deep learning model, the application can classify images into various categories with high accuracy. The model is served through a FastAPI backend running inside a Docker container, enabling users to upload images and receive real-time predictions via a REST API endpoint. The entire solution showcases how AI/ML inference workloads can be efficiently hosted and managed on Oracle Cloud Infrastructure (OCI) using OKE for container orchestration, ensuring scalability and high availability.

## What this folder contains

- `main.tf`, `oke.tf`, `app.tf` — Terraform resources for networking, OKE cluster, and application wiring.
- `variables.tf`, `terraform.tfvars`, `terraform.local.tfvars` — Variables and example values. Copy `terraform.tfvars` to `terraform.local.tfvars` and set your real OCIDs and keys.
- `k8s/app.yaml.tpl` — Template for the Deployment; Terraform renders this using the configured `docker_image` variable.
- `k8s/app.yaml` — Example rendered manifest (includes a sample image `prasanthprasad/image-recognition-api:v1.1`).
- `k8s/service.yaml` — Service of type `LoadBalancer` that exposes the application on port 80.
- `build.sh`, `delete.sh` — Helper scripts to apply and tear down the Terraform configuration.

## Prerequisites

- Terraform (>= 1.0)
- OCI CLI configured (or environment variables for Terraform authentication)
- kubectl (to interact with the cluster)
- Ensure your OCI account has quotas to create OKE clusters, compute instances and Load Balancers

## Configure the application image

By default `k8s/app.yaml` contains the sample image `prasanthprasad/image-recognition-api:v1.1`. To use a different image, either:

- Edit `k8s/app.yaml` before applying; or
- Update `terraform.tfvars` / `terraform.local.tfvars` to set the `docker_image` variable so Terraform renders `k8s/app.yaml.tpl` with your image.

## Quick start

1. Copy example variables and edit them:

```bash
cd oci-terraform-solutions/oke-aiml-image-recognition-api
cp terraform.tfvars terraform.local.tfvars
# Edit terraform.local.tfvars: set tenancy_ocid, user_ocid, fingerprint, private_key_path, region, compartment_ocid, my_ipaddress, node_image_id, etc.
```

2. (Optional) Set your docker image in `terraform.local.tfvars`:

```hcl
docker_image = "yourrepo/your-image:tag"
```

3. Apply the Terraform configuration (helper script):

```bash
./build.sh
```

Or use Terraform directly:

```bash
terraform init
terraform plan -var-file=terraform.local.tfvars -out plan.tfplan
terraform apply plan.tfplan
```

4. After apply completes, find the external address of the service:

```bash
kubectl get svc image-recognition-service -o wide
# or
terraform output
```

## Test the API

Once the Load Balancer IP or hostname is available, test the service:

```bash
# Basic health check
curl http://<LB-IP>/health

# Submit an image for recognition (example endpoint - adjust per implementation)
curl -X POST "http://<LB-IP>/predict" -F "file=@/path/to/image.jpg"
```

## Troubleshooting

- Service remains `<pending>`: check OCI Load Balancer quotas and whether the service annotations (LB shape) require special permissions or limits.
- `kubectl` can't connect: ensure kubeconfig was generated and `$KUBECONFIG` points to it or copy it to `$HOME/.kube/config`.
- Pod crashes: `kubectl describe pod` and `kubectl logs` to inspect container errors.

## Security notes

- Do not commit `terraform.local.tfvars` or private keys to Git. Keep secrets in OCI Vault or environment variables.
- The example app may accept file uploads; validate inputs and add authentication before using in production.

## License

See the repository `LICENSE` at the project root for license terms.
