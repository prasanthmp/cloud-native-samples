# OKE + MLflow + OCI DevOps + Data Science (Terraform)

This reference implementation demonstrates how to run a practical MLOps platform on Oracle Cloud Infrastructure using Terraform as the control plane. It connects model training, tracking, artifact management, and serving into one automated lifecycle so teams can move from code changes to reproducible deployments with fewer manual handoffs.

The stack is designed for operators and platform engineers who want repeatable infrastructure, centralized secrets handling, and CI/CD-driven model updates. OCI DevOps pipelines, OCI Data Science jobs, and MLflow work together so you can run a single workflow from experiment to endpoint.

This solution provisions an end-to-end MLOps workflow on OCI:

- OKE cluster and networking
- MLflow tracking server on Kubernetes
- OCI Data Science training job (container-based)
- OCI DevOps build + deploy pipelines
- OCIR repositories for training and serving images
- OCI Object Storage for datasets/model backups/artifacts
- IAM policies for OKE, DevOps, and Data Science runtimes

## Quick Start Steps

1. Create required OCI Vault secrets:
   - GitHub PAT secret for `devops_github_access_token_secret_id`
   - OCIR auth token secret for `devops_build_ocir_auth_token_secret_ocid`
   - MLflow/Object Storage secrets for:
     - `mlflow_s3_access_key_id_secret_ocid`
     - `mlflow_s3_secret_access_key_secret_ocid`
2. Create and update `terraform.tfvars` with required values (OCIDs, region, image OCID, repo URL, OCIR settings, and secret OCIDs).
3. Initialize and apply Terraform:
   - `terraform init`
   - `terraform apply -var-file=terraform.tfvars`
4. Confirm post-apply outputs:
   - `terraform output mlflow_url`
   - `terraform output -raw serving_url`
   - `terraform output devops_build_pipeline_id`
5. Start the OCI DevOps build pipeline manually (Console or OCI CLI).
6. Confirm the build run triggers Data Science training and then the deploy pipeline.
7. Validate rollout in OKE.
8. Validate deployment:
   - health endpoint: `GET /health`
   - prediction endpoint: `POST /predict`
9. Optional but recommended:
   - accept ONS email subscription confirmations for `devops_notification_emails`
   - monitor build/deploy logs in OCI DevOps and `kubectl` if rollout fails

## Architecture Flow

1. Start the OCI DevOps build pipeline.
2. Build pipeline (`devops/build_spec.yaml`) installs dependencies, builds and pushes training/serving images, and triggers a Data Science job run.
3. Build pipeline triggers deploy pipeline.
4. Deploy stage (`devops/deploy_command_spec.yaml`) updates the serving app on OKE and prints the external serving URL.

## Repository Layout

- `main.tf`: core infrastructure and Kubernetes resources
- `oke.tf`: OKE provider/cluster bootstrap
- `devops.tf`: DevOps project and pipeline wiring
- `policies.tf`: IAM policies
- `variables.tf`: input variables
- `outputs.tf`: runtime outputs (URLs, IDs, repo names)
- `devops/build_spec.yaml.tftpl`: build spec template
- `devops/deploy_command_spec.yaml.tftpl`: deploy command spec template
- `scripts/build_and_push_ocir_image.sh`: training image build/push
- `scripts/build_and_push_serving_ocir_image.sh`: serving image build/push
- `scripts/trigger_datascience_job_run.sh`: manual Data Science job run trigger
- `training/`: training app/Dockerfile/scripts
- `serving/`: FastAPI serving app/Dockerfile/manifests

## Prerequisites

- Terraform `>= 1.6`
- OCI CLI configured
- Docker
- `kubectl`
- OCI permissions to create resources in the target compartment

Use OCI Vault for secrets and keep local `terraform.tfvars` out of version control.

## Configure

Create `terraform.tfvars` in this directory and set at least:

- OCI auth:
  - `tenancy_ocid`
  - `user_ocid`
  - `fingerprint`
  - `private_key_path`
  - `region`
- Infra:
  - `compartment_id`
  - `node_image_ocid`
  - `ssh_public_key_path`
- Data Science:
  - `datascience_job_container_image`
- DevOps/GitHub:
  - `devops_repository_url`
  - `devops_github_access_token_secret_id`
- OCIR:
  - `devops_build_ocir_namespace`
  - `devops_build_ocir_username`
  - `devops_build_ocir_auth_token_secret_ocid`
- MLflow artifact credentials:
  - `mlflow_s3_access_key_id` or `mlflow_s3_access_key_id_secret_ocid`
  - `mlflow_s3_secret_access_key` or `mlflow_s3_secret_access_key_secret_ocid`

Optional but useful:

- `devops_notification_emails = ["you@example.com"]`
- `object_storage_root_bucket_name = "oci-mlops"`

## Deploy

```bash
terraform init
terraform apply -var-file=terraform.tfvars
```

## Key Outputs

```bash
terraform output mlflow_url
terraform output -raw serving_url
terraform output datascience_job_id
terraform output devops_build_pipeline_id
terraform output devops_deploy_pipeline_id
```

`serving_url` is a helper command string that waits for the service endpoint.

## Validate End-to-End

1. Resolve serving URL:

```bash
BASE_URL="$(eval "$(terraform output -raw serving_url)")"
echo "$BASE_URL"
```

2. Health check:

```bash
curl -sS "$BASE_URL/health"
```

3. Prediction:

```bash
curl -sS -X POST "$BASE_URL/predict" \
  -H "Content-Type: application/json" \
  -d '{"inputs": [[6.0, 2.9, 4.5, 1.5]]}'
```

4. Optional multi-row prediction:

```bash
curl -sS -X POST "$BASE_URL/predict" \
  -H "Content-Type: application/json" \
  -d '{"inputs": [[5.1,3.5,1.4,0.2],[6.0,2.9,4.5,1.5],[6.9,3.1,5.4,2.1]]}'
```

The Iris class mapping is:

- `0 = setosa`
- `1 = versicolor`
- `2 = virginica`

## Manual Operations

### Trigger Data Science Job

```bash
export COMPARTMENT_OCID="<compartment_ocid>"
bash scripts/trigger_datascience_job_run.sh
```

### Build/Push Training Image

```bash
export OCIR_REGION_CODE=iad
export OCIR_NAMESPACE="<namespace>"
export OCIR_REPOSITORY="mlops-training"
export OCIR_USERNAME="<namespace>/<username>"
export OCIR_AUTH_TOKEN_SECRET_OCID="<vault_secret_ocid>"
bash scripts/build_and_push_ocir_image.sh
```

### Build/Push Serving Image

```bash
export OCIR_REGION_CODE=iad
export OCIR_NAMESPACE="<namespace>"
export OCIR_REPOSITORY="mlops-serving"
export OCIR_USERNAME="<namespace>/<username>"
export OCIR_AUTH_TOKEN_SECRET_OCID="<vault_secret_ocid>"
bash scripts/build_and_push_serving_ocir_image.sh
```

## Notes

- Default serving namespace: `mlflow`
- Default serving deployment/service name: `mlops-serving`
- Serving app reads:
  - `MLFLOW_TRACKING_URI`
  - `MLFLOW_MODEL_NAME` (default `iris-logreg-model`)
  - `MLFLOW_MODEL_STAGE` (default `Production`)

## Troubleshooting

### Data Science job run fails due to log group authorization

1. Confirm `datascience_job_log_group_id` exists and is active (if set).
2. If not set, confirm Terraform created the managed log group.
3. Verify `policies.tf` has been applied.
4. Re-run `terraform apply -var-file=terraform.tfvars`.

### Build pipeline does not start or fails

1. List recent build runs:

```bash
oci devops build-run list --project-id <devops_project_ocid> --limit 5 --output table
```

2. Inspect a build run:

```bash
oci devops build-run get --build-run-id <build_run_ocid> --output json
```

3. Verify required values are set:
  - `devops_repository_url`
  - `devops_github_access_token_secret_id`
  - `devops_build_ocir_auth_token_secret_ocid`

4. Review stage logs in OCI DevOps Console for build/deploy failures.

### `/predict` returns `{"detail":"Model not loaded"}`

Common causes:

1. No registered model exists yet in MLflow.
2. Missing Object Storage credentials in `mlflow-object-storage` secret.
3. Serving pod failed to load artifacts.

Useful checks:

```bash
curl -sS "$(terraform output -raw mlflow_url)/api/2.0/mlflow/registered-models/search"
kubectl -n mlflow logs deployment/mlops-serving --tail=200
```

### Serving image pull denied from OCIR

1. Confirm image exists in OCIR.
2. Confirm pull secret exists in `mlflow` namespace.
3. Confirm DevOps deploy stage can read OCIR auth token secret.

## Conclusion

This solution provides a complete baseline for running MLOps on OCI with clear separation of concerns across infrastructure, training, model registry, and serving. By combining Terraform-managed resources with DevOps automation and Vault-backed secrets, it reduces operational drift and makes deployments easier to audit, reproduce, and scale.

## Next Steps

1. Add environment promotion (dev/stage/prod) with separate state and variable files.
2. Add automated smoke tests in the build/deploy pipeline for `/health` and `/predict`.
3. Enable model quality gates (accuracy thresholds, drift checks) before production rollout.
4. Add observability dashboards and alerts for inference latency, error rate, and model/version usage.
