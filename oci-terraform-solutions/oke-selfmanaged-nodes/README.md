# OKE — Self-managed Nodes (Terraform)

This folder contains Terraform code and helper scripts to provision an Oracle Kubernetes Engine (OKE) control plane and self-managed worker nodes on Oracle Cloud Infrastructure (OCI).

Unlike managed node pools (OCI-managed), self-managed nodes are compute instances you provision and configure (via cloud-init) to join the OKE cluster. This layout is useful when you need custom OS configuration, specialized drivers, or control over the node lifecycle.

What this workspace contains

- `main.tf`, `oke.tf` — Terraform resources for the OKE cluster control plane and networking.
- `instance.tf` — Terraform resources to create compute instances that will act as self-managed worker nodes.
- `cloud-init.sh.tpl` — cloud-init template used to bootstrap instances so they can join the cluster.
- `instance-ssh/` — SSH helper assets and tooling used by instance provisioning.
- `build.sh`, `delete.sh` — Helper scripts to apply and destroy the Terraform configuration.
- `variables.tf`, `terraform.tfvars`, `terraform.local.tfvars` — Variable definitions and example values. Put secrets/real OCIDs in `terraform.local.tfvars` and keep it out of Git.
- `outputs.tf` — Useful outputs (cluster id, kubeconfig path, instance IPs).

Prerequisites

- Terraform 1.x
- OCI CLI configured (`oci setup config`) and accessible from the machine running `build.sh` (used by some local-exec provisioners).
- kubectl (to interact with the created cluster)
- jq (optional; some helper scripts use it)
- A PEM-format private key readable by Terraform if SSH access to instances is required

Important configuration notes

- Make a copy of `terraform.tfvars` to `terraform.local.tfvars` and fill in real values for:
	- `tenancy_ocid`, `user_ocid`, `private_key_path`, `fingerprint`, `region`, `compartment_ocid`
	- `my_ipaddress` (your client IP in CIDR format; used to lock down SSH and API access)
	- `node_image_id` — region-specific image OCID suitable for your chosen shape

- Do not commit `terraform.local.tfvars` or private keys to version control.

How it works (high level)

1. Terraform provisions the VCN, subnets, NAT/IGW/SGW, security lists, and the OKE control plane.
2. Terraform creates compute instances (self-managed nodes) using `instance.tf`.
3. Instances are bootstrapped using the `cloud-init.sh.tpl` template to install Kubernetes components and join the cluster.
4. A generated `kubeconfig` is saved (or instructions are printed) so you can run `kubectl` against the cluster.

Quick start

```bash
cd oci-terraform-solutions/oke-selfmanaged-nodes
# copy and edit secrets/region-specific values
cp terraform.tfvars terraform.local.tfvars
# edit terraform.local.tfvars: set OCIDs, private_key_path, my_ipaddress, node_image_id, etc.
./build.sh
```

Or use Terraform manually:

```bash
terraform init
terraform plan -var-file=terraform.local.tfvars -out plan.tfplan
terraform apply plan.tfplan
```

After apply

- Terraform may create a `kubeconfig` inside the module and copy it to `$HOME/.kube/config` (check the output). If not present, create it manually with the OCI CLI:

```bash
oci ce cluster create-kubeconfig --cluster-id <cluster-ocid> --file $HOME/.kube/config --region <region> --kube-endpoint PUBLIC_ENDPOINT
chmod 600 $HOME/.kube/config
kubectl get nodes
```

Managing self-managed nodes

- The `cloud-init.sh.tpl` template is executed on instance boot. Inspect it to understand the packages installed, the kubelet configuration and how the instance fetches the cluster join tokens or kubeadm config.
- If you need to reconfigure nodes, update `cloud-init.sh.tpl` and recreate instances or run manual SSH commands.
- Use `instance-ssh/` helpers to SSH into instances for debugging.

Destroy resources

```bash
./delete.sh
# or
terraform destroy -var-file=terraform.local.tfvars
```

Troubleshooting

- Instances not joining the cluster: review instance console output and cloud-init logs (`/var/log/cloud-init-output.log`), ensure the kubelet service is running and the node can reach the control plane.
- SSH failures: verify `private_key_path` is correct and `my_ipaddress` is set to your current public IP in `terraform.local.tfvars`.
- Kubeconfig missing: run the `oci ce cluster create-kubeconfig` command manually (above).
- Networking issues: validate CIDR ranges in `terraform.local.tfvars` do not overlap with existing networks and check security list rules.

Security notes

- Self-managed nodes require you to manage OS updates, security patches and kubelet configuration. Treat instance private keys and bootstrap tokens as sensitive.
- Restrict access using `my_ipaddress` and do not expose SSH broadly.

License

See the repository `LICENSE` at the project root for license terms.