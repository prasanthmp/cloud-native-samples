# OKE AI/ML — Chat Agent (API + Frontend)

This project demonstrates a scalable, cloud-native AI Chat Agent deployed on Oracle Cloud Infrastructure (OCI) Container Engine for Kubernetes (OKE). It integrates a lightweight LLM-based conversational API with an intuitive Streamlit web frontend, providing an end-to-end example of building, deploying, and operating an AI-powered chat system in production-ready infrastructure.

The backend AI agent exposes an internal API (ClusterIP) and the frontend is exposed via a LoadBalancer service. Terraform templates render Kubernetes manifests from templates and apply them using the Kubernetes/Kubectl providers.

## What this folder contains

- `main.tf`, `oke.tf`, `ai-agent.tf`, `ai-agent-frontend.tf` — Terraform resources for OKE, Kubernetes manifests and app wiring.
- `variables.tf`, `terraform.tfvars`, `terraform.local.tfvars` — Variables and examples. Copy `terraform.tfvars` to `terraform.local.tfvars` and set your real OCIDs and keys.
- `k8s/ai-agent.yaml.tpl` — Template for the AI agent Deployment (container listens on port 8000).
- `k8s/ai-agent-service.yaml` — ClusterIP service exposing the backend on port 8002.
- `k8s/ai-agent-frontend.yaml.tpl` — Template for the Streamlit frontend (container listens on 8501).
- `k8s/ai-agent-frontend-service.yaml` — LoadBalancer service exposing frontend on port 8080.
- `build.sh`, `delete.sh` — Helper scripts to provision and destroy resources.

## Related source repositories (in this workspace)

- Backend agent source: `dockerized-apps/ai-ml/chatbot-agent-tinyllama`
- Frontend source: `dockerized-apps/ai-ml/chatbot-frontend`

## Key variables

- `ai_agent_docker_image` — Docker image for the backend AI agent (example set in `terraform.tfvars`).
- `ai_agent_frontend_docker_image` — Docker image for the Streamlit frontend.
- Standard OCI variables: `tenancy_ocid`, `user_ocid`, `private_key_path`, `fingerprint`, `region`, `compartment_ocid` and network/kubernetes maps.

## Prerequisites

- Terraform >= 1.0
- OCI CLI configured (`oci setup config`) or environment variables for Terraform
- kubectl installed and configured (the provisioning step generates a `kubeconfig`)
- Ensure sufficient OCI quotas for OKE, compute and Load Balancers

## High-level flow

1. Create a `terraform.local.tfvars` file based on `terraform.tfvars`. Replace placeholders with your tenant-specific values.
2. Run the `build.sh` helper script or run Terraform commands manually (shown below).
3. Wait for resources to be created — the scripts create the kubeconfig and copy it to `$HOME/.kube/config`.
4. Use `kubectl` to inspect the cluster.

## Quickstart

1. Copy and edit variables:

```bash
cd oci-terraform-solutions/oke-aiml-chat-agent
cp terraform.tfvars terraform.local.tfvars
# Edit terraform.local.tfvars: set tenancy_ocid, user_ocid, fingerprint, private_key_path, region, compartment_ocid, my_ipaddress, node_image_id, ai_agent_docker_image, ai_agent_frontend_docker_image
```

2. Deploy (helper script):

```bash
./build.sh
```

Or use Terraform directly:

```bash
terraform init
terraform plan -var-file=terraform.local.tfvars -out plan.tfplan
terraform apply plan.tfplan
```

3. After apply completes:

- The backend Service is `ai-agent-service` (ClusterIP) and the frontend Service is `ai-agent-frontend-service` (LoadBalancer).
- Find the frontend LoadBalancer external address with:

```bash
kubectl get svc ai-agent-frontend-service -o wide
```

## Testing

- Terraform output will display AI agent URL (API) and AI agent frontend application URL.
- ai_agent_app_url = "http://INTERNAL-IP:8002/chat"
- ai_agent_frontend_app_url = "http://FRONTEND-LB-IP:8080"

## Frontend environment variable

- The frontend template sets `CHATBOT_API_URL` using the backend service external IP constructed by a data provider; if the frontend can't reach the backend, verify the `ai-agent-service` is running and reachable from the frontend namespace.

## Troubleshooting

- Frontend LoadBalancer stuck in `<PENDING>`: check OCI LB quotas and service annotations/shape.
- Pod crashes: check `kubectl describe pod` and `kubectl logs` for the failing pod.
- Frontend can't reach backend: ensure the backend `ai-agent-service` selector labels match the backend Deployment labels and both are in the same cluster/namespace.

## Security notes

- Do not commit `terraform.local.tfvars` or private keys to source control.
- The example frontend and backend are demo apps; add authentication and input validation before using in production.

## License

See the repository `LICENSE` at the project root for license terms.
