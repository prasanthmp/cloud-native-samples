# JupyterHub Deployment on Oracle Kubernetes Engine (OKE) with Monitoring

This project deploys **JupyterHub** on an **Oracle Cloud Infrastructure (OCI) OKE cluster** using **Terraform** and **Helm**. It enables running AI/ML workloads interactively through Jupyter notebooks on Kubernetes. This also deploys a monitoring stack using Prometheus and Grafana.

The configurations in this workspace were designed to be a reproducible example you can adapt for your own OCI tenancy and VCN design.

## What this repo does
- Automated **JupyterHub deployment** via Terraform Helm provider  
- Configurable **dummy authentication** for testing  
- Uses **TensorFlow notebook image** (`jupyter/tensorflow-notebook`)  
- Easily extendable for GPU nodes or Kubeflow integration  
- Supports **OCI LoadBalancer** for external access
- Automated OKE cluster provisioning using Terraform
- Node pool configuration with customizable shape and size
- Automated kubeconfig generation and setup [Run kubectl from your local machine]
- Prometheus and Grafana deployment for cluster monitoring [Exposed both prometheus and grafana dashboards]
- Kubernetes dashboard imported from Grafana.com and configured datasource
- Includes helper scripts to build and destroy the deployment
- Creates full VCN network and OKE with node pool


## Repository layout
- `main.tf` - Root Terraform resources and module wiring
- `oke.tf` - OKE cluster and nodepool definitions
- `jupyter.tf` - Helm/manifest deployment for Jupyterhub
- `prometheus.tf` - Helm/manifest deployment for Prometheus
- `grafana.tf` - Helm/manifest deployment for Grafana and dashboards
- `variables.tf` - Input variable declarations
- `terraform.tfvars` / `terraform.local.tfvars` - Example variable values (edit locally)
- `outputs.tf` - Useful outputs (service endpoints, kubeconfig path, etc.)
- `kubeconfig` - (generated) kubeconfig file for the provisioned cluster
- `build.sh` - Convenience wrapper to run `terraform init` + `terraform apply` with recommended flags
- `delete.sh`, `delete-mon.sh` - Scripts to destroy resources / monitoring components
- `tag_oke_lbs.sh` - Helper script to tag load balancers (repo-specific helper)

## Prerequisites
- macOS / Linux / Windows with WSL
- [Terraform](https://www.terraform.io/downloads.html) >= 1.0 (recommended latest stable)
- [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)(for some helper scripts; optional if you only use Terraform)
- kubectl (to interact with the cluster)
- Helm (to inspect or modify Helm releases; deployment may be done via Terraform)
- An OCI tenancy with sufficient permissions to create VCNs, subnets, compute instances, OKE clusters, and load balancers
- OCI API keys configured (or environment variables set for Terraform to authenticate)


## Quickstart (typical flow)
1. Clone the repository and cd into it:

```zsh
   git clone <this-repo-url>
   cd terraform-oke-monitoring/oke-aiml-jupyterhub
```

2. Copy and edit variable files:

```zsh
   cp terraform.tfvars terraform.local.tfvars
   # Edit terraform.local.tfvars with your compartment OCID, region, SSH key, etc.
```

3. Init and apply the changes (or use the convenience script):

```zsh
   # JupyterHub on OKE with Monitoring

   This workspace provisions a JupyterHub deployment on an Oracle Kubernetes Engine (OKE) cluster and includes a Prometheus + Grafana monitoring stack. It uses Terraform (providers + Helm) to provision the OKE cluster, node pool, JupyterHub Helm chart, and monitoring components. The setup is intended as a reproducible example you can adapt to your OCI tenancy.

   Contents

   - `main.tf`, `oke.tf` — Core networking and OKE cluster resources.
   - `jupyter.tf` — Helm/manifest deployment for JupyterHub (configurable image and auth settings).
   - `prometheus.tf`, `grafana.tf` — Monitoring stack (Prometheus + Grafana) and dashboards.
   - `variables.tf`, `terraform.tfvars`, `terraform.local.tfvars` — Variables and example values. Keep secrets in `terraform.local.tfvars` and do not commit it.
   - `outputs.tf` — Useful outputs (endpoints, kubeconfig path, etc.).
   - `build.sh`, `delete.sh`, `delete-mon.sh` — Helper scripts to deploy and tear down the stack.
   - `kubeconfig` — (generated after apply) kubeconfig file for interacting with the cluster.

   Prerequisites

   - Terraform >= 1.0
   - OCI CLI configured (`oci setup config`) or environment variables for authentication
   - kubectl (to interact with the cluster)
   - Helm (optional; Terraform installs via provider)
   - Sufficient OCI quotas/permissions for VCNs, OKE, compute, and Load Balancers

   Quickstart

   1. Copy variables and set your values:

   ```bash
   cd oci-terraform-solutions/oke-aiml-jupyterhub
   cp terraform.tfvars terraform.local.tfvars
   # Edit terraform.local.tfvars and set tenancy/user/compartment OCIDs, private_key_path, region, my_ipaddress, etc.
   ```

   2. Deploy (helper script):

   ```bash
   ./build.sh
   ```

   Or run Terraform directly:

   ```bash
   terraform init
   terraform plan -var-file=terraform.local.tfvars -out plan.tfplan
   terraform apply plan.tfplan
   ```

   3. After apply completes:

   - A `kubeconfig` file will be generated in the workspace and may be copied to `$HOME/.kube/config` by the provisioning steps.
   - Check cluster state:

   ```bash
   kubectl get nodes
   kubectl -n jhub get pods
   kubectl -n monitoring get pods
   ```

   Accessing services

   - Use `terraform output` to find endpoints for JupyterHub, Grafana and Prometheus (if exposed via Load Balancer):

   ```bash
   terraform output
   ```

   - If an endpoint is private, ensure your client IP is included in `my_ipaddress` so you can access the cluster API and dashboards.

   Destroy (cleanup)

   ```bash
   ./delete.sh
   # or to remove monitoring only:
   ./delete-mon.sh
   ```

   Common troubleshooting

   - kubectl can't connect: ensure `KUBECONFIG` points to the generated kubeconfig or `$HOME/.kube/config`, and that your client IP is allowed if the API endpoint is private.
   - Terraform permission errors: verify IAM policies grant the user the ability to create OKE, networking, compute and load balancer resources.
   - Helm / chart failures: inspect pod logs (`kubectl -n <ns> logs <pod>`) and Helm release status (`helm -n <ns> status <release>`).
   - Load Balancers stuck in `<PENDING>`: check tenancy quotas and region limits in the OCI Console.

   Security notes

   - Do not commit `terraform.local.tfvars`, `kubeconfig` or private keys to source control.
   - Use OCI Vault for secrets where possible.
   - The monitoring stack in this example may expose dashboards without strong auth—treat this as a demo-only configuration unless you add access controls.

   Next steps / suggestions

   - Replace dummy auth in JupyterHub with a production identity connector (OAuth/LDAP) if using in real projects.
   - Add persistent storage classes and PVCs for user notebooks.
   - Migrate Terraform state to remote backend (OCI Object Storage) for team collaboration.

   License

   See the repository `LICENSE` file at the project root for license terms.
```

