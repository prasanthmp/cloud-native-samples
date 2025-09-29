# OKE DevOps CI/CD (oke-devops)

This folder contains Terraform and helper scripts to provision an OKE cluster and Oracle DevOps CI/CD resources used by the `microservices-python-flask-app` sample. It bootstraps the infrastructure, DevOps project/pipelines, build artifacts and pipeline templates required to build, test and deploy sample microservices into OKE.

What this workspace does

- Creates an OKE cluster and node pool (networking, subnets, route tables, gateways, security lists).
- Provisions Oracle DevOps resources (project, build/deploy pipelines, repositories/artifacts) referenced by the sample pipelines.
- Produces a `kubeconfig` file to allow `kubectl` access to the newly provisioned cluster.
- Includes helper scripts to apply and destroy the environment (`build.sh`, `delete.sh`).

Key files

- `main.tf`, `oke.tf` — Terraform resources for OKE and supporting networking.
- `devops-*.tf` (if present) — DevOps project, pipelines, and artifact definitions.
- `kubeconfig` — (generated) kubeconfig for `kubectl`.
- `build.sh` — Wrapper to run `terraform init`/`apply` with recommended options.
- `delete.sh` — Wrapper to destroy the Terraform-managed infrastructure.
- `terraform.tfvars`, `terraform.local.tfvars` — Variable values. Copy and edit `terraform.local.tfvars` for local secrets/OCIDs and keep it out of Git.
- `microservices-python-flask-app/` — Sample application used by the pipelines (buildspec, Dockerfile, Kubernetes manifests).
- `.terraform/` — Provider plugins and cache (created after `terraform init`).

Prerequisites

- Terraform (1.x recommended).
- OCI CLI configured (`oci setup config`) with a profile that has permissions for OKE, DevOps, Compute, Networking and Load Balancer operations.
- kubectl and helm (for interacting with the cluster and deploying charts).
- Docker (for building images locally or in pipelines) and Git.
- jq (optional, used by helper scripts).

Before you run

1. Copy `terraform.tfvars` to `terraform.local.tfvars` and update the following required values:

   - `tenancy_ocid`, `user_ocid`, `private_key_path`, `fingerprint`, `region`, `compartment_ocid` — OCI identity values.
   - `my_ipaddress` — your public IP in CIDR format (used to restrict access to the K8s API and SSH).
   - Any DevOps-specific variables (e.g., repo names or image coordinates) required by pipeline templates.

2. Ensure `terraform.local.tfvars` is not committed to the repo (keep secrets local).

Recommended workflow

```bash
cd oci-terraform-solutions/oke-devops-cicd/oke-devops
# copy and edit variables
cp terraform.tfvars terraform.local.tfvars
# edit terraform.local.tfvars: set OCIDs, private_key_path, node image id, my_ipaddress, region, etc.
# apply via helper script
./build.sh

# after apply completes, verify kubeconfig (terraform may copy it to $HOME/.kube/config)
kubectl get nodes
kubectl get namespaces
```

If you prefer the Terraform CLI manually:

```bash
terraform init
terraform plan -var-file=terraform.local.tfvars -out plan.tfplan
terraform apply plan.tfplan
```

Destroying the environment

```bash
./delete.sh
# or
terraform destroy -var-file=terraform.local.tfvars
```

Notes and troubleshooting

- kubeconfig: The Terraform configuration contains a provisioner that calls the OCI CLI to create a kubeconfig and copies it to `$HOME/.kube/config`. If this fails, generate it manually with:

```bash
oci ce cluster create-kubeconfig --cluster-id <cluster-ocid> --file $HOME/.kube/config --region <region> --kube-endpoint PUBLIC_ENDPOINT
chmod 600 $HOME/.kube/config
```

- Permissions: Ensure the OCI user has policies to create DevOps resources, OKE clusters, compute, networking and load balancers in the target compartment.
- Pipeline failures: Review the DevOps Console and pipeline build logs. Verify repository addresses, image names, and credentials used by pipelines.
- Node image: Managed node pools require a compatible `node_image_id` for the selected `node_shape`. Find image OCIDs via the OCI Console or `oci compute image list` for your region.
- Timeouts: Node pools and DevOps resources can take several minutes to provision. Watch Terraform output and OCI Console for progress.
- State: If you share this repo, consider migrating Terraform state to remote backend (OCI Object Storage) and enable state locking for team use.

Suggested improvements

- Add `terraform.local.tfvars.example` with placeholders and document which fields are mandatory.
- Add a small verification script that runs `kubectl get nodes` and `kubectl get pods -A` to confirm cluster readiness after apply.
- Add CI checks to validate `terraform fmt` and `terraform validate` on PRs.

License

This workspace is part of the `cloud-native-samples` repository. See the top-level `LICENSE` file for licensing details.

