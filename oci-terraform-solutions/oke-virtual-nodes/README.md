# OKE - Virtual Nodes (Terraform)

This folder contains Terraform code and helper scripts to create an Oracle Kubernetes Engine (OKE) cluster with virtual node pools on Oracle Cloud Infrastructure (OCI). It also provisions the networking components (VCN, subnets, route tables, gateways), security lists, a node pool, and creates a kubeconfig you can use with `kubectl`.

## Files of interest

- `main.tf` — Primary Terraform resources (VCN, subnets, NAT/Internet/Service gateways, OKE cluster, node pool, kubeconfig generation).
- `variables.tf` — Terraform variable declarations.
- `terraform.tfvars` — Example variable values with clear TODO markers. Copy these values into a secure local file (terraform.local.tfvars) before running.
- `build.sh` — Helper script that runs `terraform init` and `terraform apply` (wraps the recommended workflow).
- `delete.sh` — Helper script to tear down the created resources.
- `outputs.tf` — Terraform outputs (cluster ID, dashboard URLs, etc.).
- `tag_oke_lbs.sh` — Helper to tag load balancers (optional).

## Prerequisites

- Terraform (recommended 1.0+; providers in `main.tf` require recent provider versions). Ensure `terraform` is available on PATH.
- OCI CLI configured (`oci setup config`) with valid credentials and a working profile.
- kubectl and helm (to interact with the created cluster and charts).
- jq (optional, used by some helper scripts).

## Important variables to set

Before you run anything, create `terraform.local.tfvars` (or pass `-var-file` on the CLI) and set the following fields at minimum:

- `tenancy_ocid`, `user_ocid`, `private_key_path`, `fingerprint`, `region`, `compartment_ocid` — OCI identity and auth pieces. These must match the values in your OCI CLI config.
- `my_ipaddress` — Your current public IP in CIDR form (e.g. `203.0.113.1/32`). Used to restrict access to the Kubernetes API and SSH access to nodes.
- `all_oci_services_gw` — Service gateway identifier for the region (e.g. `all-<region-key>-services-in-oracle-services-network`). See `terraform.tfvars` comments for examples.
- `cloud_network` and `kubernetes` maps — Define CIDR ranges, Kubernetes version, node count, node pool shape and sizes. Defaults are provided in the example file but review them for collisions with existing networks.

## Security notes

- The example `terraform.tfvars` contains placeholders. Do NOT commit real OCIDs, keys, or private values to version control. Use `terraform.local.tfvars` (or environment variables) with secure permissions.
- The security lists in the Terraform code restrict API access to `my_ipaddress`. Make sure this value is correct, otherwise you might lock yourself out.

## High-level flow

1. Create a `terraform.local.tfvars` file based on `terraform.tfvars`. Replace placeholders with your tenant-specific values.
2. Run the `build.sh` helper script or run Terraform commands manually (shown below).
3. Wait for resources to be created — the scripts create the kubeconfig and copy it to `$HOME/.kube/config`.
4. Use `kubectl` and `helm` to inspect the cluster and the running monitoring stack (if enabled).

## Try it — recommended commands

Create (recommended):

```bash
cd oci-terraform-solutions/oke-virtual-nodes
# copy example values to a local file and edit it (values below are placeholders)
cp terraform.tfvars terraform.local.tfvars
# Edit terraform.local.tfvars and set real OCIDs / private key path / my_ipaddress 
./build.sh
```

If you prefer the Terraform CLI directly:

```bash
cd oci-terraform-solutions/oke-virtual-nodes
terraform init
terraform plan -var-file=terraform.local.tfvars -out=plan.tfplan
terraform apply plan.tfplan
```

After successful apply

- The repository's `main.tf` creates a `kubeconfig` file inside this module and then copies it to `$HOME/.kube/config` with owner-only permissions. You can run:

```bash
kubectl get nodes
kubectl get namespaces
```

If the scripts didn't copy the kubeconfig, generate it manually with the OCI CLI:

```bash
oci ce cluster create-kubeconfig --cluster-id <cluster-ocid> --file $HOME/.kube/config --region <region> --kube-endpoint PUBLIC_ENDPOINT
chmod 600 $HOME/.kube/config
```

Destroy (cleanup)

```bash
cd oci-terraform-solutions/oke-virtual-nodes
./delete.sh
# or
terraform destroy -var-file=terraform.local.tfvars
```

## Notes, caveats and tips

- Timeouts: Provisioning node pools and copying kubeconfig can take several minutes. The Terraform configuration includes waits but be patient.
- Multiple runs: If you re-run after a failed apply, consider running `terraform refresh` and check the state before applying again.

## Troubleshooting

- Authentication errors: Verify your `~/.oci/config` profile and the values you set in `terraform.local.tfvars`.
- API endpoint not reachable: Ensure `my_ipaddress` is set correctly and includes the client IP in CIDR format.
- kubeconfig not created: Inspect the null_resource logs in Terraform output. You can run the `oci ce cluster create-kubeconfig` command manually (see above).

## License & attribution

This folder is part of the `cloud-native-samples` repository. See the top-level `LICENSE` file for license terms.
