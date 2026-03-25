# Simple Network with Subnets (OCI + Terraform)

Small Terraform example that provisions a VCN, public subnet, internet gateway, route table, security lists and an NGINX container instance on Oracle Cloud Infrastructure (OCI).

Files
- [main.tf](oci-terraform-basics/simple-network-with-subnets/main.tf) — Terraform configuration implementing the example.
- Key resources in the configuration:
  - [`oci_core_vcn.vcn`](oci-terraform-basics/simple-network-with-subnets/main.tf)
  - [`oci_core_subnet.public_subnet`](oci-terraform-basics/simple-network-with-subnets/main.tf)
  - [`oci_core_internet_gateway.igw`](oci-terraform-basics/simple-network-with-subnets/main.tf)
  - [`oci_core_route_table.public_rt`](oci-terraform-basics/simple-network-with-subnets/main.tf)
  - [`oci_core_default_security_list.default_security_list`](oci-terraform-basics/simple-network-with-subnets/main.tf)
  - [`oci_core_security_list.security_list`](oci-terraform-basics/simple-network-with-subnets/main.tf)
  - [`oci_container_instances_container_instance.nginx_container`](oci-terraform-basics/simple-network-with-subnets/main.tf)
  - [`oci_identity_availability_domains.ADs`](oci-terraform-basics/simple-network-with-subnets/main.tf)
  - Output: [`container_instance_id`](oci-terraform-basics/simple-network-with-subnets/main.tf)

Prerequisites
- Terraform (1.x recommended)
- OCI CLI configured or environment variables for Terraform authentication
- An OCI tenancy with quotas for VCN, compute/container instances and load balancers
- A PEM-format API private key and its fingerprint

Quickstart

1. Copy or create a local variables file:

```hcl
// filepath: oci-terraform-basics/simple-network-with-subnets/terraform.local.tfvars
tenancy_ocid     = "ocid1.tenancy.xxxx"
user_ocid        = "ocid1.user.xxxx"
private_key_path = "/path/to/your/private_key.pem"
fingerprint      = "aa:bb:cc:dd:ee:ff:..."
region           = "us-ashburn-1"
compartment_id   = "ocid1.compartment.xxxx"
```

2. Initialize, plan and apply:

```bash
cd oci-terraform-basics/simple-network-with-subnets
terraform init
terraform plan -var-file=terraform.local.tfvars -out plan.tfplan
terraform apply plan.tfplan
```

3. After apply finishes, get the created container instance OCID:

```bash
terraform output container_instance_id
```

Cleanup

```bash
terraform destroy -var-file=terraform.local.tfvars
```

Notes & tips
- The example assigns a public IP to the container; adjust security rules and subnet design for production.
- Do not commit `terraform.local.tfvars` or private keys to version control.
- Review the resources in [main.tf](oci-terraform-basics/simple-network-with-subnets/main.tf) before applying.