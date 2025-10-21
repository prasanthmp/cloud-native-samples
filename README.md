
# cloud-native-samples

A collection of small, focused examples demonstrating cloud-native patterns and tools. The repository contains containerized sample webapps (including AI/ML microservices), Oracle Cloud Infrastructure (OCI) example scripts, and Terraform solutions for common cloud scenarios.


## Contents

- `dockerized-apps/` — Containerized web applications and microservices:
  - `ai-ml/image-recognition-api/` — FastAPI-based image recognition API using TensorFlow/Keras ResNet50 (Python)
  - `web-app/dotnetcore-webapp/` — .NET Core sample with Dockerfile and docker-compose
  - `web-app/go-webapp/` — Go webapp example
  - `web-app/node-webapp/` — Node.js express sample
  - `web-app/python-webapp/` — Flask sample

- `oci-services/` — Lightweight OCI SDK/CLI examples grouped by service (compute, object-storage, etc.). These are typically runnable Python scripts.

- `oci-terraform-solutions/` — Terraform configurations and helper scripts for deploying infrastructure on OCI:
  - `oke-aiml-image-recognition-api/` — Deploys the AI/ML image recognition API to OKE
  - `oke-aiml-jupyterhub/` — JupyterHub on OKE with monitoring
  - `oke-devops-cicd/` — DevOps and CI/CD pipeline samples
  - `oke-ingress-lb/` — Ingress controller and load balancer setup
  - `oke-ingress-path-based-routing/` — Path-based routing with ingress
  - `oke-managed-nodes/` — OKE clusters and managed node pools
  - `oke-monitoring-prometheus-grafana/` — Monitoring stack with Prometheus and Grafana
  - `oke-selfmanaged-nodes/` — OKE with self-managed nodes
  - `oke-selfmanaged-nodes-monitoring/` — Monitoring for self-managed nodes
  - `oke-virtual-nodes/` — OKE with virtual nodes

- `LICENSE` — Project license.
- `cloud-native-samples.sln` — Solution file (for .NET samples).


## Quick start

These instructions assume you're on macOS (zsh). Adjust commands for other shells/OS as needed.

Prerequisites (install the ones you need):

- Docker & Docker Compose (for the containerized apps)
- Go (for the Go sample)
- Node.js & npm (for the Node sample)
- Python 3.8+ and virtualenv (for Python OCI samples)
- .NET SDK (for the .NET Core sample)
- Terraform (for the Terraform solutions)
- OCI CLI and configured credentials (for running OCI examples and Terraform against OCI)
- kubectl and helm (for Kubernetes/OKE related samples)

Example: run the Node.js sample app

```bash
cd dockerized-apps/web-app/node-webapp
npm install
docker build -t node-webapp .
docker run --rm -p 3000:3000 node-webapp
# Visit http://localhost:3000
```

Example: run the Python webapp locally (without Docker)

```bash
cd dockerized-apps/web-app/python-webapp
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python app.py
# Visit http://localhost:5000 (or whatever the app prints)
```

Example: run the AI/ML image recognition API (FastAPI + TensorFlow)

```bash
cd dockerized-apps/ai-ml/image-recognition-api
pip install -r requirements.txt
uvicorn app:app --reload --host 0.0.0.0 --port 5000
# Visit http://localhost:5000/docs for Swagger UI
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
  - ai-ml/
    - image-recognition-api/   # FastAPI + TensorFlow image recognition microservice
  - web-app/
    - dotnetcore-webapp/       # .NET sample with Dockerfile and docker-compose
    - go-webapp/               # Go webapp example
    - node-webapp/             # Node.js express sample
    - python-webapp/           # Flask sample

- oci-services/
  - python-samples/
    - compute/
    - object-storage/

- oci-terraform-solutions/
  - oke-aiml-image-recognition-api/         # Deploys image recognition API to OKE
  - oke-aiml-jupyterhub/                    # JupyterHub on OKE with monitoring
  - oke-devops-cicd/                        # DevOps and CI/CD pipeline samples
  - oke-ingress-lb/                         # Ingress controller and load balancer setup
  - oke-ingress-path-based-routing/         # Path-based routing with ingress
  - oke-managed-nodes/                      # OKE clusters and managed node pools
  - oke-monitoring-prometheus-grafana/      # Monitoring stack with Prometheus and Grafana
  - oke-selfmanaged-nodes/                  # OKE with self-managed nodes
  - oke-selfmanaged-nodes-monitoring/       # Monitoring for self-managed nodes
  - oke-virtual-nodes/                      # OKE with virtual nodes


## Testing and linting

This repository contains samples in multiple languages. Use the language-specific tooling in each sample directory:

- JavaScript/Node: npm test / eslint (if present)
- Python: pytest / flake8 (if present)
- .NET: dotnet test
- Go: go test



## License

This repository includes a `LICENSE` file at the project root. Review it for terms and conditions.