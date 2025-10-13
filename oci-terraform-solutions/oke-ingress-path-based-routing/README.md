# OKE Ingress — Path-based Routing Sample

This workspace demonstrates path-based routing using an NGINX Ingress Controller on OKE. Two sample applications (a Python webapp and a Node webapp) are deployed and exposed behind a single Ingress that routes requests based on the path prefix (`/python` and `/node`).

## What this folder contains

- `main.tf`, `oke.tf` — Networking and OKE related Terraform resources.
- `ingress-controller.tf` — Installs the `ingress-nginx` Helm chart and renders templated Kubernetes manifests for the two sample apps.
- `k8s/app.yaml.tpl`, `k8s/service.yaml.tpl` — Templates used by Terraform `templatefile()` to generate per-app manifests.
- `k8s/ingress.yaml` — Ingress resource that defines path-based rules for `/python` and `/node`. It also includes the `rewrite-target` annotation so backends receive the stripped path.
- `build.sh`, `delete.sh` — Helper scripts to apply and destroy the Terraform configuration.
- `terraform.tfvars` — Example variable values (set your images/ports here or in `terraform.local.tfvars`).

## How it works

1. `ingress-controller.tf` uses `templatefile()` to render `app` and `service` manifests for both apps using variables for `docker_image` and `docker_image_port`.
2. The Helm provider installs the `ingress-nginx` controller with a `LoadBalancer` service (annotated for OCI flexible LB).
3. Terraform applies the rendered manifests and then the Ingress resource which routes `/python` to the Python app and `/node` to the Node app.

## Prerequisites

- Terraform >= 1.5.0
- OCI CLI configured and working
- kubeconfig at `~/.kube/config` with cluster admin permissions (the Terraform `kubernetes`/`helm` providers use this path by default)
- kubectl for debugging

## Configure images and ports

Edit `terraform.tfvars` or create `terraform.local.tfvars` with the following variables (examples present in `terraform.tfvars`):

- `python_webapp_docker_image` — Docker image for the Python app (e.g., `prasanthprasad/python-webapp:v1`).
- `python_webapp_docker_image_port` — The container port the Python app listens on (example: `5000`).
- `node_webapp_docker_image` — Docker image for the Node app.
- `node_webapp_docker_image_port` — The container port the Node app listens on.

## Quick start

```bash
cd oci-terraform-solutions/oke-ingress-path-based-routing
cp terraform.tfvars terraform.local.tfvars
# Edit terraform.local.tfvars: set OCI OCIDs, kubeconfig, and the two docker image names/ports
./build.sh
```

## Verify the deployment

1. Check pods, services and ingress:

```bash
kubectl get pods,svc,ing -A
kubectl -n ingress-nginx get svc
```

2. Terraform output will display the paths:

```bash
# Example (replace <LB-IP> with the controller's external address)
curl http://<LB-IP>/python/   # should route to the python-webapp
curl http://<LB-IP>/node/     # should route to the node-webapp
```

## Notes & tips

- The ingress file uses the `nginx.ingress.kubernetes.io/rewrite-target: /` annotation. This strips the path prefix when forwarding the request (so backends receive `/`). If your apps expect the full path, remove or adjust the annotation.
- The manifests are generated from templates; to change resource limits or replica counts, update `k8s/app.yaml.tpl`.
- If the Load Balancer never gets an external IP, check OCI Load Balancer quotas and the service annotations for shape selection.

## Troubleshooting

- Pods CrashLoopBackOff: `kubectl describe pod` and `kubectl logs` for the failing container.
- Ingress not routing: ensure the ingress class is `nginx` and the controller is deployed successfully.
- Template rendering errors: verify that all template variables are defined in `terraform.tfvars` or `terraform.local.tfvars`.

Destroy

```bash
./delete.sh
```

## License

See the repository `LICENSE` at the project root for terms.
