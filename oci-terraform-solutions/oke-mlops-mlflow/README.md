# OKE + MLflow + OCI DevOps + Data Science (Terraform)

This project provisions an end-to-end MLOps flow on OCI:

- OKE cluster + networking
- MLflow tracking server on Kubernetes
- OCI Data Science training job (container-based)
- OCI DevOps build pipeline (GitHub push trigger)
- OCI DevOps deploy pipeline for serving rollout
- OCIR repositories for training and serving images
- OCI Object Storage buckets for datasets, model backups, and MLflow artifacts
- IAM policies required by OKE, DevOps, and Data Science runtimes

## Repository Layout

- `main.tf`: Core infra (network, OKE, Data Science, OCIR repos, Object Storage, MLflow k8s resources)
- `oke.tf`: Kubernetes/OKE provider and cluster bootstrap helpers
- `devops.tf`: DevOps project, build/deploy pipelines, trigger, command specs
- `policies.tf`: IAM policies for OKE, DevOps, Data Science
- `variables.tf`: All input variables
- `outputs.tf`: Useful runtime outputs (MLflow URL, pipeline IDs, repo names, etc.)
- `devops/build_spec.yaml.tftpl`: Build pipeline spec template
- `devops/deploy_command_spec.yaml.tftpl`: Deploy pipeline command spec template
- `scripts/build_and_push_ocir_image.sh`: Build/push training image
- `scripts/build_and_push_serving_ocir_image.sh`: Build/push serving image
- `scripts/trigger_datascience_job_run.sh`: Trigger latest ACTIVE Data Science job in compartment
- `serving/`: FastAPI serving app + Dockerfile + k8s manifests
- `training/`: Training code + Dockerfile + run script

## Current Pipeline Flow

1. Push to GitHub branch `main`.
2. DevOps GitHub trigger fires on path:
   - `oci-terraform-solutions/oke-mlops-mlflow/**`
3. Build pipeline stage executes `devops/build_spec.yaml`:
   - install training deps
   - build/push training image to OCIR
   - build/push serving image to OCIR
   - package training bundle artifact
   - trigger Data Science job run
4. Build stage triggers DevOps deploy pipeline stage.
5. Deploy shell stage:
   - resolves MLflow tracking URI at runtime (from `mlflow` service if not explicitly set)
   - creates/updates OCIR image pull secret
   - deploys `mlflow-serving` deployment/service to OKE
   - prints serving URL once load balancer endpoint is available

## Prerequisites

- Terraform `>= 1.6`
- OCI CLI configured locally
- Docker installed
- `kubectl` installed
- OCI IAM/API key access to create resources in target tenancy/compartment

## Configure

Use the provided sample:

```bash
cp terraform.examples.tfvars terraform.tfvars
```

Update required values in `terraform.tfvars`:

- tenancy/user auth fields
- `compartment_id`
- `node_image_ocid`, `ssh_public_key_path`
- `existing_datascience_project_id` (if reusing project)
- `datascience_job_container_image`
- `datascience_job_log_group_id`
- GitHub/DevOps values:
  - `devops_repository_url`
  - `devops_github_access_token_secret_id` (or existing connection ID via variable)
- OCIR values:
  - `devops_build_ocir_namespace`
  - `devops_build_ocir_username`
  - `devops_build_ocir_auth_token_secret_ocid`
- MLflow Object Storage secret OCIDs:
  - `mlflow_s3_access_key_id_secret_ocid`
  - `mlflow_s3_secret_access_key_secret_ocid`

## Deploy

```bash
terraform init
terraform apply -var-file=terraform.examples.tfvars
```

## Useful Outputs

```bash
terraform output mlflow_url
terraform output serving_url
terraform output datascience_job_id
terraform output devops_build_pipeline_id
terraform output devops_deploy_pipeline_id
terraform output devops_github_trigger_id
```

`serving_url` output is a helper command that waits for the external endpoint and prints full URL.

## Manual Ops Commands

### Trigger Data Science Job Run

```bash
export COMPARTMENT_OCID="<compartment_ocid>"
bash scripts/trigger_datascience_job_run.sh
```

The script auto-discovers:

- `JOB_OCID` from latest ACTIVE job in the compartment (unless provided)
- `PROJECT_OCID` from the selected job (unless provided)

### Build and Push Training Image

```bash
export OCIR_REGION_CODE=iad
export OCIR_NAMESPACE="<namespace>"
export OCIR_REPOSITORY="mlflow-training-test"
export OCIR_USERNAME="<namespace>/<username>"
export OCIR_AUTH_TOKEN="<token>" # or use OCIR_AUTH_TOKEN_SECRET_OCID
bash scripts/build_and_push_ocir_image.sh
```

### Build and Push Serving Image

```bash
export OCIR_REGION_CODE=iad
export OCIR_NAMESPACE="<namespace>"
export OCIR_REPOSITORY="mlflow-serving"
export OCIR_USERNAME="<namespace>/<username>"
export OCIR_AUTH_TOKEN="<token>" # or use OCIR_AUTH_TOKEN_SECRET_OCID
bash scripts/build_and_push_serving_ocir_image.sh
```

## Test Serving Endpoint

Get URL:

```bash
IP=$(kubectl -n mlflow get svc mlflow-serving -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "http://$IP/predict"
```

Health check:

```bash
curl -sS "http://$IP/health"
```

Predict:

```bash
curl -sS -X POST "http://$IP/predict" \
  -H "Content-Type: application/json" \
  -d '{"inputs": [[5.1,3.5,1.4,0.2],[6.0,2.9,4.5,1.5],[6.9,3.1,5.4,2.1]]}'
```

## MLflow Artifact Storage

MLflow artifacts are configured to use OCI Object Storage through the S3-compatible API.

- Endpoint format:
  - `https://<namespace>.compat.objectstorage.<region>.oraclecloud.com`
- Credential env names are AWS-style because MLflow/boto3 expects them:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
- Secrets are pulled from OCI Vault secret OCIDs in Terraform and injected into runtime env.

## IAM Policies

Policies are managed in `policies.tf` and include:

- OKE workload policy for load balancer/subnet/vnic operations
- DevOps build pipeline policy
- DevOps deploy pipeline policy
- Data Science runtime policy

Note: if you see tenancy policy statement quota errors, consolidate statements (this project already uses compact principal-scoped statements for DevOps build/deploy).

## Troubleshooting

### Data Science job run fails with log group authorization

Error:
- `The specified log group is not found or not authorized...`

Checks:

1. Confirm `datascience_job_log_group_id` exists and is ACTIVE.
2. Confirm job and log group are in expected region/compartment.
3. Ensure policies in `policies.tf` are applied:
   - Data Science runtime and DevOps build principal permissions.
4. Re-run:

```bash
terraform apply -var-file=terraform.examples.tfvars
```

### Serving pod image pull denied (OCIR)

- Ensure repo exists and image tag exists.
- Ensure image pull secret is created in `mlflow` namespace.
- Ensure deploy stage can read OCIR token secret and create docker-registry secret.

### Check latest job run status

```bash
oci data-science job-run get \
  --job-run-id <job_run_ocid> \
  --query 'data.{state:"lifecycle-state",details:"lifecycle-details"}' \
  --output json
```

