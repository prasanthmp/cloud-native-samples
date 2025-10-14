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
   ./build.sh
```

4. After apply completes, the `kubeconfig` file will be available in this workspace (and `outputs.tf` prints the path). Check cluster:

```zsh
   kubectl get nodes
```

5. Access Jupyterhub

Terraform outputs (or the Terraform state) will include the endpoints Jupyterhub. To list outputs:

```zsh
   terraform output
```

5. Access Grafana and Prometheus

Terraform outputs (or the Terraform state) will include the endpoints for Grafana and Prometheus. To list outputs:

```zsh
   terraform output
```

If a service is exposed via an OCI Load Balancer, the external IP/DNS will be shown in the outputs.

## Scripts
- `build.sh` — wrapper script that runs `terraform init` and `terraform apply` with recommended options. Use it for the full stack deployment.
- `delete.sh` — destroys all Terraform-managed resources in this workspace (full teardown).
- `delete-mon.sh` — destroys only monitoring-related resources (Prometheus/Grafana) if provided.
- `tag_oke_lbs.sh` — tags OCI load balancers created by OKE (useful for billing or identification).

Always read scripts before running them and ensure `terraform.tfvars` contains correct values.

## Cleanup
To destroy everything created by Terraform in this workspace:

```zsh
./delete.sh
```

To destroy only monitoring components (if available):

```zsh
./delete-mon.sh
```

If you prefer Terraform commands directly:

```zsh
terraform destroy
```

## Common variables and outputs
- Edit `terraform.tfvars` or `terraform.local.tfvars` to provide values like `compartment_ocid`, `region`, `ssh_public_key`, and `cluster_name`.
- After apply, check `terraform output` to find:
  - `kubeconfig_path` (path to generated kubeconfig)
  - `grafana_endpoint` (external URL or IP)
  - `prometheus_endpoint`

If those outputs are missing, the project may be configured to create resources with no external LB — check `grafana.tf` and `prometheus.tf` to see whether services are NodePort / ClusterIP / LoadBalancer.

## Troubleshooting
- "kubectl can't connect": ensure `KUBECONFIG` points to `./kubeconfig` or `$HOME/.kube/config` after the build and that your local IP (if using private endpoints) is allowed.
- "Terraform apply fails with permission denied": verify OCI user has the required IAM policies and API key configuration.
- Helm release issues: describe pods and check Helm releases with `helm list -n monitoring` or  `helm list -n jhub` or the namespace used by the manifests.


Useful commands:

```zsh
kubectl -n jhub get pods
kubectl -n monitoring get pods
kubectl -n monitoring logs deployment/<prometheus-or-grafana-deployment>
helm -n monitoring status <release-name>
terraform show
terraform output
```

## Security notes
- Do not commit sensitive files (like real `kubeconfig` or `terraform.tfvars` with secret values) into version control.
- Use OCI Vault or environment variables for secrets where possible.
- Do not use this in production as the prometheus (no authentication) and grafana (unsecure authentication) is exposed to the configued IP.

## License
This repository is provided under the MIT License. See `LICENSE` if included in the workspace.

## Practical usage examples

Here are concrete commands and examples you can copy/paste to work with this repository.

1) Initialize and preview the plan:

```zsh
terraform init
terraform plan -out tfplan
terraform show -no-color tfplan
```

2) Apply (full stack) using the convenience script:

```zsh
./build.sh
```

Or with Terraform directly:

```zsh
terraform apply -var-file="terraform.local.tfvars" -auto-approve
```

3) Cluster checks:

```zsh
kubectl get nodes
kubectl -n monitoring get pods
```

4) Check Terraform outputs (example template):

```zsh
terraform output
# Example output format (values will differ):
# grafana_endpoint = "http://GRAFANA_IP"
# prometheus_endpoint = "http://PROMETHEUS_IP"
# jupyterhub_endpoint = "http://JUPYTERHUB_IP"
# kubeconfig_path = "./kubeconfig"
```

Jupyterhub/Prometheus/Grafana services are exposed via an OCI Load Balancer, the external DNS/IP will be present in the outputs.

## Scripts reference

This repo includes a few helper scripts. Read them before running; brief descriptions follow.

- `build.sh`
   - Runs `terraform apply -var-file="terraform.local.tfvars" -parallelism=5 -auto-approve` and logs the run time to `terraform_runtime.log`.
   - After a successful run a `kubeconfig` file will be present in the workspace and set to default path $HOME/.kube/config.
   - Logs runtime to `terraform_runtime.log`.   

- `delete.sh`
   - Runs `terraform destroy` with the `terraform.local.tfvars` file. The script first attempts to target monitoring-related null_resources to tear down monitoring pieces, then runs a full destroy.
   - Logs runtime to `terraform_destroy_runtime.log`.

- `delete-mon.sh`
   - Destroys only the monitoring-related resources (Prometheus/Grafana) by targeting the same null_resources used during install. Useful when you want to re-create monitoring without destroying the cluster.
   - Logs runtime to `terraform_destroy_partial_runtime.log`.

- `tag_oke_lbs.sh`
   - Uses the OCI CLI to discover Load Balancers created by an OKE cluster (searches defined-tags / CreatedBy) and updates each LB with a freeform tag and a standardized display name `OKE-<tag>-LB-#`.

## terraform.tfvars.example

To make onboarding easier, a `terraform.tfvars.example` file has been added to this workspace. Copy it to `terraform.tfvars` (or `terraform.local.tfvars`) and replace placeholders with your real OCIDs, key paths and IP ranges before running Terraform.

```zsh
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars and then run
```

## Notes & troubleshooting references
- If a Load Balancer shows `<PENDING>`, check limits in the OCI console for the tenancy and region.
- Prometheus requires managed nodes (not virtual nodes) for DaemonSets; if using virtual nodes, adjust the Prometheus deployment accordingly.
- If `kubectl` cannot connect, verify `KUBECONFIG`, network ACLs (your IP may need to be allowed in cluster API ingress CIDR), and that the cluster kubelet nodes are in `Ready` state.


## Actual Terraform outputs (from current state)
Below are the current Terraform outputs captured from the workspace. Sensitive values have been redacted where appropriate.

- cluster_id: `ocid1.cluster.oc1.us-chicago-1.xxxxxxxxxx`
- compartment_ocid: `ocid1.compartment.oc1..xxxxxxxxxxx`
- grafana_admin_username: `admin`
- grafana_admin_password: (sensitive, not displayed)
- grafana_url: `http://207.207.207.207`
- prometheus_url: `http://170.9.9.9`

If you want the full unredacted outputs or machine-readable JSON, run:

```zsh
terraform output -json
```

