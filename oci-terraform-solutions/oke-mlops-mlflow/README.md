# OKE + MLflow + OCI DevOps + Data Science (Terraform)

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
   - `terraform output devops_github_trigger_id`
5. Create or verify the OCI DevOps GitHub push trigger is ACTIVE and targets the build pipeline.
6. Configure GitHub webhook to call the OCI DevOps trigger URL (or verify OCI-managed webhook registration if auto-created).
7. Push a change to `main` under `oci-terraform-solutions/oke-mlops-mlflow/**` to trigger the pipeline.
8. Validate deployment:
   - health endpoint: `GET /health`
   - prediction endpoint: `POST /predict`
9. Optional but recommended:
   - accept ONS email subscription confirmations for `devops_notification_emails`
   - monitor build/deploy logs in OCI DevOps and `kubectl` if rollout fails

## Architecture Flow

1. Push changes to `main`.
2. OCI DevOps GitHub trigger starts the build pipeline.
3. Build pipeline (`devops/build_spec.yaml`) installs dependencies, builds and pushes training/serving images, and triggers a Data Science job run.
4. Build pipeline triggers deploy pipeline.
5. Deploy stage (`devops/deploy_command_spec.yaml`) updates the serving app on OKE and prints the external serving URL.

## Repository Layout

- `main.tf`: core infrastructure and Kubernetes resources
- `oke.tf`: OKE provider/cluster bootstrap
- `devops.tf`: DevOps project, pipelines, trigger wiring
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
terraform output devops_github_trigger_id
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

### GitHub push does not trigger build pipeline

1. Verify trigger is active:

```bash
oci devops trigger get --trigger-id <trigger_ocid> --query 'data."lifecycle-state"' --raw-output
```

2. Verify trigger URL:

```bash
oci devops trigger get --trigger-id <trigger_ocid> --query 'data."trigger-url"' --raw-output
```

3. Check branch/path filters include:
  - `main`
  - `oci-terraform-solutions/oke-mlops-mlflow/**`

If webhook is missing, recreate the trigger/connection or add the webhook manually in GitHub using the trigger URL.

### Create OCI trigger and GitHub webhook (recommended flow)

Use OCI DevOps to manage webhook registration automatically. This avoids payload URL/secret mismatch issues.

1. In OCI Console, open:
   - `Developer Services` -> `DevOps` -> your project
2. Go to `Triggers` and create a new `GitHub` trigger.
3. Select:
   - the GitHub connection
   - repository: `prasanthmp/cloud-native-samples`
   - event: `PUSH`
   - branch: `main`
   - file filters:
     - `oci-terraform-solutions/oke-mlops-mlflow/**`
     - `README.md`
4. Set action to trigger build pipeline:
   - `mlflow-training-build-pipeline`
5. Save trigger and confirm it is `ACTIVE`.
6. Copy the secret and URL (Required for configuring GitHub webhook)
7. Wait ~1 minute for OCI to register webhook in GitHub.

Important:
- Prefer OCI-managed webhook registration.
- Avoid manual webhook edits unless required by policy.

### If you must configure GitHub webhook manually

Only do this if OCI cannot register webhook automatically and you have repo admin access.
On GitHub, navigate to the main page of the repository. Under your repository name, click Settings. If you cannot see the "Settings" tab, select the dropdown menu, then click Settings. In the left sidebar, click Webhooks.

1. In GitHub repo settings, open `Webhooks`.
2. Delete old/invalid OCI webhook entries first.
3. Create webhook with:
   - `Payload URL`: OCI trigger listener URL from OCI trigger details
   - `Content type`: `application/json`
   - `Secret`: trigger webhook secret (must match OCI; not your GitHub PAT)
   - Events: `Just the push event`
4. Save and test with a new push to `main`.

Notes:
- `GitHub PAT` is for OCI connection auth and is different from webhook `Secret`.
- If OCI UI does not expose a secret, use OCI-managed webhook flow instead of manual webhook setup.

### Common webhook errors

- `Invalid payload URL or secret`:
  - payload URL or webhook secret does not match trigger listener settings
- `Unable to parse message body`:
  - GitHub webhook content type is not `application/json`
- Trigger ACTIVE but no build runs:
  - check branch/path filters and webhook delivery status in GitHub

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
