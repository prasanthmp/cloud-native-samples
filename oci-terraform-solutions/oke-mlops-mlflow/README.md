# OKE + MLflow + OCI DevOps + Data Science (Terraform)

This project is a reference MLOps implementation on Oracle Cloud Infrastructure that automates the full lifecycle from training to serving. Architecturally, GitHub pushes trigger an OCI DevOps build pipeline that builds and publishes training/serving images to OCIR, triggers an OCI Data Science job to train and register models in MLflow, and then invokes a deploy pipeline that rolls the latest serving image to OKE through Kubernetes. Supporting services such as Object Storage (datasets, MLflow artifacts, backups), Vault secrets, and IAM policies are provisioned and wired together through Terraform so the platform can be reproducible, secure, and easy to operate.

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

Required secret keys/credentials for this stack:

- OCI API signing key config (used by Terraform provider authentication):
  - `tenancy_ocid`
  - `user_ocid`
  - `fingerprint`
  - `private_key_path` (path to your OCI private key PEM)
  - Optional if your key has a passphrase: `private_key_password`
- GitHub access token secret (used by OCI DevOps source connection when not using an existing connection):
  - `devops_github_access_token_secret_id` (Vault secret OCID)
- DevOps email notifications (optional but recommended):
  - `devops_notification_emails` (list of recipient email addresses)
- OCIR auth token for build/push and deploy image pull secret:
  - `devops_build_ocir_auth_token_secret_ocid` (Vault secret OCID)
- MLflow artifact storage credentials (OCI Object Storage S3-compatible):
  - `mlflow_s3_access_key_id` or `mlflow_s3_access_key_id_secret_ocid`
  - `mlflow_s3_secret_access_key` or `mlflow_s3_secret_access_key_secret_ocid`

Do not commit real secrets or private keys. Use OCI Vault and/or a local `terraform.tfvars` that is excluded from version control.

## Configure

Create a local `terraform.tfvars` file in this directory and populate it with the required values below.

Update required values in `terraform.tfvars`:

- tenancy/user auth fields
- `compartment_id`
- `node_image_ocid`, `ssh_public_key_path`
- Data Science project:
  - `datascience_project_name` (project creation is enabled internally)
- `datascience_job_container_image`
- Optional: `datascience_job_log_group_id` (if omitted, Terraform creates and uses a log group by default)
- `object_storage_root_bucket_name` (single root bucket, for example `oke-mlops`)
- GitHub/DevOps values:
  - `devops_repository_url`
  - `devops_github_access_token_secret_id` (or existing connection ID via variable)
  - Optional email notifications:
    - `devops_notification_emails = ["you@example.com"]`
- OCIR values:
  - `devops_build_ocir_namespace`
  - `devops_build_ocir_username`
  - `devops_build_ocir_auth_token` or `devops_build_ocir_auth_token_secret_ocid`
- MLflow Object Storage secret OCIDs:
  - `mlflow_s3_access_key_id_secret_ocid` (or direct value `mlflow_s3_access_key_id`)
  - `mlflow_s3_secret_access_key_secret_ocid` (or direct value `mlflow_s3_secret_access_key`)

## Deploy

```bash
terraform init
terraform apply -var-file=terraform.tfvars
```

## Useful Outputs

```bash
terraform output mlflow_url
terraform output serving_url
terraform output datascience_job_id
terraform output devops_build_pipeline_id
terraform output devops_deploy_pipeline_id
terraform output devops_github_trigger_id
terraform output devops_notification_topic_id
terraform output devops_notification_subscription_ids
```

`serving_url` output is a helper command that waits for the external endpoint and prints full URL.

DevOps notifications:

- The DevOps project publishes events to the configured ONS topic.
- Terraform subscribes each address in `devops_notification_emails` to that topic.
- After `terraform apply`, each recipient must accept the OCI email subscription confirmation before alerts start arriving.

`MLFLOW_TRACKING_URI` behavior:

- Data Science training job gets `MLFLOW_TRACKING_URI` dynamically from the live MLflow service endpoint (`mlflow_url` output), not from a hardcoded IP.
- Serving app reads `MLFLOW_TRACKING_URI` from environment (set by deploy pipeline). If not set, it falls back to `http://mlflow.mlflow.svc.cluster.local`.

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

## Application Overview and Validation

This application implements a practical MLOps loop: model training publishes metrics and model versions to MLflow, and the serving API loads a promoted model to provide real-time predictions. The deployment is exposed through a Kubernetes service (`mlflow-serving`) in the `mlflow` namespace, while MLflow provides the shared model source of truth across training and inference.

At runtime, the application predicts the Iris flower type from four input parameters: sepal length, sepal width, petal length, and petal width.

From an operator perspective, there are two runtime endpoints to validate after deployment:

- `GET /health`: confirms service readiness and shows loaded model metadata
- `POST /predict`: runs inference on numeric feature vectors and returns predicted class values

The model is trained on the Iris dataset. Each record has four numeric features in this exact order: sepal length (cm), sepal width (cm), petal length (cm), and petal width (cm). The serving endpoint expects the same order for every input row.

`/predict` input format is JSON with an `inputs` key containing a 2D array. Each inner array is one sample with 4 numeric values. Example:

```json
{"inputs": [[6.0, 2.9, 4.5, 1.5], [5.1, 3.5, 1.4, 0.2]]}
```

`/predict` response returns the loaded `model_uri` and a `predictions` array. Each output number is the flower type predicted by the model. Each prediction is a class index for the corresponding input row: `0 = setosa`, `1 = versicolor`, `2 = virginica`. In simple terms, if you send 3 rows, you get 3 outputs in the same order (first output for first row, second for second, and so on).

Use the following workflow to validate the app end-to-end:

1. Resolve service URL and set `BASE_URL`:

```bash
IP=$(kubectl -n mlflow get svc mlflow-serving -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -z "$IP" ]; then
  HOST=$(kubectl -n mlflow get svc mlflow-serving -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  BASE_URL="http://$HOST"
else
  BASE_URL="http://$IP"
fi
echo "$BASE_URL"
```

2. Verify service health:

```bash
curl -sS "$BASE_URL/health"
```

3. Run a prediction request:

```bash
curl -sS -X POST "$BASE_URL/predict" \
  -H "Content-Type: application/json" \
  -d '{"inputs": [[6.0, 2.9, 4.5, 1.5]]}'
```

4. Optional multi-row test:

```bash
curl -sS -X POST "$BASE_URL/predict" \
  -H "Content-Type: application/json" \
  -d '{"inputs": [[5.1,3.5,1.4,0.2],[6.0,2.9,4.5,1.5],[6.9,3.1,5.4,2.1]]}'
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

1. If you set `datascience_job_log_group_id`, confirm it exists and is ACTIVE.
2. If you do not set `datascience_job_log_group_id`, Terraform creates a managed log group automatically.
3. Confirm job and log group are in expected region/compartment.
4. Ensure policies in `policies.tf` are applied:
   - Data Science runtime and DevOps build principal permissions.
5. Re-run:

```bash
terraform apply -var-file=terraform.tfvars
```

### GitHub trigger does not start build pipeline

Symptoms:
- push to `main` does not start a build run
- `oci devops build-run list ...` only shows `MANUAL` runs

Checks:

1. Confirm trigger is ACTIVE:

```bash
oci devops trigger get --trigger-id <trigger_ocid> --query 'data."lifecycle-state"' --raw-output
```

2. Confirm the GitHub webhook exists in your repo and points to the trigger listener URL:

```bash
oci devops trigger get --trigger-id <trigger_ocid> --query 'data."trigger-url"' --raw-output
```

Then check your GitHub repository webhooks for that URL.

3. Validate connection health:

```bash
oci devops connection validate --connection-id <connection_ocid>
```

4. Confirm your commit matches trigger filters:
- branch: `main`
- changed files include:
  - `oci-terraform-solutions/oke-mlops-mlflow/**`
  - or `README.md`

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

### Serving `/predict` returns `{"detail":"Model not loaded"}`

Common causes:
1. No registered model exists in MLflow yet
2. Serving image missing `boto3` (required for S3-compatible artifact download)
3. Serving deployment missing Object Storage credential env vars

Checks:

```bash
curl -sS "$MLFLOW_URL/api/2.0/mlflow/registered-models/search"
kubectl -n mlflow logs deployment/mlflow-serving --tail=200
```

Expected serving env vars:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_DEFAULT_REGION`
- `MLFLOW_S3_ENDPOINT_URL`

These should come from `secret/mlflow-object-storage`.

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
