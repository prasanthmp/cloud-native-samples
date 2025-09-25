# cloud-native-samples

A collection of small, focused examples demonstrating cloud-native patterns and tools. The repository contains containerized sample webapps, Oracle Cloud Infrastructure (OCI) example scripts, and Terraform solutions for common cloud scenarios.

## Contents

- `dockerized-apps/` — Small web applications packaged with Docker. Languages include .NET Core, Go, Java, Node.js, Python and Rust. Each sample usually contains a `Dockerfile` and a `docker-compose.yml` where applicable.
- `oci-services/` — Lightweight OCI SDK/CLI examples grouped by service (compute, network, object-storage, etc.). These are typically runnable Python scripts.
- `oci-terraform-solutions/` — Terraform configurations and helper scripts for deploying infrastructure on OCI (examples: OKE/managed nodes, monitoring stacks, virtual nodes).
- `LICENSE` — Project license.
- `cloud-native-samples.sln` — Solution file (present if you're using the .NET samples).

## Quick start

These instructions assume you're on macOS (zsh). Adjust commands for other shells/OS as needed.

Prerequisites (install the ones you need):

- Docker & Docker Compose (for the containerized apps)
- Go (for the Go sample)
- Node.js & npm (for the Node sample)
- Python 3.8+ and virtualenv (for Python OCI samples)
- Rust & Cargo (for the Rust sample)
- .NET SDK (for the .NET Core sample)
- Terraform (for the Terraform solutions)
- OCI CLI and configured credentials (for running OCI examples and Terraform against OCI)
- kubectl and helm (for Kubernetes/OKE related samples)

Example: run the Node.js sample app

```bash
cd dockerized-apps/node-webapp
npm install
docker build -t node-webapp .
docker run --rm -p 3000:3000 node-webapp
# Visit http://localhost:3000
```

Example: run the Python webapp locally (without Docker)

```bash
cd dockerized-apps/python-webapp
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python app.py
# Visit http://localhost:5000 (or whatever the app prints)
```

Example: run an OCI Python sample (object storage upload)

```bash
cd oci-services/python-samples/object-storage
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python upload_object.py --bucket-name <your-bucket> --file testfile.txt
```

Example: preview Terraform OKE managed nodes

1. Inspect and set variables in `oci-terraform-solutions/oke-managed-nodes/terraform.tfvars` or use `-var`/`-var-file`.
2. Initialize and plan:

```bash
cd oci-terraform-solutions/oke-managed-nodes
terraform init
terraform plan -out plan.tfplan
terraform apply plan.tfplan
```

Always review Terraform files and variable values before applying, and ensure your OCI credentials and region are configured.

## Repository structure (high level)

- dockerized-apps/
  - dotnetcore-webapp/    # .NET sample with Dockerfile and docker-compose
  - go-webapp/            # Go webapp example
  - java-webapp/          # Java webapp (may contain Maven/Gradle configs)
  - node-webapp/          # Node.js express sample
  - python-webapp/        # Flask sample
  - rust-webapp/          # Actix/Rocket sample with Cargo files

- oci-services/
  - python-samples/       # Service-specific Python scripts for OCI SDK
    - compute/
    - object-storage/
    - network/

- oci-terraform-solutions/
  - oke-managed-nodes/    # Terraform code to create OKE clusters and managed node pools
  - oke-monitoring-prometheus-grafana/ # Terraform for monitoring stack
  - oke-virtual-nodes/    # Example for virtual nodes in OKE

## Testing and linting

This repository contains samples in multiple languages. Use the language-specific tooling in each sample directory:

- JavaScript/Node: npm test / eslint (if present)
- Python: pytest / flake8 (if present)
- .NET: dotnet test
- Go: go test
- Rust: cargo test

## License

This repository includes a `LICENSE` file at the project root. Review it for terms and conditions.