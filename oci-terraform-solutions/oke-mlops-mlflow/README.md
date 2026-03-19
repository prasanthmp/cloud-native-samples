# MLflow on OKE with Terraform

This Terraform stack creates all core resources needed to run MLflow on Oracle Kubernetes Engine (OKE):

- VCN, internet gateway, NAT gateway, public/private route tables, security lists, and 4 subnets (API, nodes, LB, Data Science)
- OKE cluster + node pool
- Optional IAM policy so OKE can provision OCI Load Balancers for Kubernetes `Service` type `LoadBalancer`
- Kubernetes namespace, MLflow deployment, and public LoadBalancer service
- OCI Data Science project + notebook session for quick MLflow validation
- Optional OCI Data Science training job resource
- Optional OCI DevOps project/build pipeline/stage/GitHub trigger resources
- Automatically selects the latest OKE Kubernetes version available in your region (unless you explicitly pin one)
- Uses `node_image_ocid` from your tfvars for worker nodes
- Output that prints the MLflow URL

## Prerequisites

- Terraform `>= 1.6`
- OCI account/API key with permissions to create networking, OKE, and IAM policy resources
- `oci` CLI available on your machine (used by generated kubeconfig auth flow)
- SSH public key for worker nodes

## Usage

1. Initialize files:

```bash
cp terraform.examples.tfvars terraform.tfvars
# Edit terraform.tfvars with your real OCIDs and values
```

2. Deploy:

```bash
terraform init
terraform apply
```

3. Read MLflow URL:

```bash
terraform output mlflow_url
```

If the output says the LoadBalancer is still provisioning, wait a few minutes and run `terraform output mlflow_url` again.

## Training Pipeline (GitHub -> OCI DevOps -> OCI Data Science Job)

This repo now includes a basic CI/CD training pipeline starter:

- Training code: `training/train.py`
- Training runner script: `training/run_training.sh`
- Training container Dockerfile: `training/Dockerfile`
- Dependencies: `training/requirements.txt`
- OCI DevOps build spec: `devops/build_spec.yaml`
- OCI image build/push helper: `scripts/build_and_push_ocir_image.sh`
- OCI DevOps deploy helper: `scripts/trigger_datascience_job_run.sh`

### 1) Push Training Code to GitHub

Commit and push this repository to your GitHub branch (for example, `main`).

### 2) OCI DevOps Build Pipeline

Create an OCI DevOps Build Pipeline that uses:

- Source: your GitHub connection/repository
- Build spec path: `devops/build_spec.yaml`

Build output artifact:

- `training_bundle` (zip with training and scripts)

Optional image build + push to OCIR is included in the build spec.
Set these build variables/secrets in OCI DevOps:

- `OCIR_REGION_CODE` (for example: `iad`)
- `OCIR_NAMESPACE`
- `OCIR_REPOSITORY` (for example: `mlflow-training`)
- `IMAGE_TAG` (for example: `1.0.0`)
- `OCIR_USERNAME` (format: `<namespace>/<username>`)
- `OCIR_AUTH_TOKEN` (auth token, secret variable)

This Terraform stack can also render `devops/build_spec.yaml` from tfvars values (OCIR and job settings) using `devops/build_spec.yaml.tftpl`.
For OCIR auth, you can pass either a direct token value or a Vault secret OCID (`devops_build_ocir_auth_token_secret_ocid`) that the build script resolves via OCI CLI.
It can also create the OCIR training repository with:
- `create_ocir_training_repository = true`
- `ocir_training_repository_name = "mlflow-training-test"`

### 3) OCI Data Science Job

Create an OCI Data Science Job (once) that runs:

```bash
bash training/run_training.sh
```

Set environment variables in the job (or job run):

- `MLFLOW_TRACKING_URI=http://<your-mlflow-lb>`
- `MLFLOW_EXPERIMENT_NAME=basic-iris-training-pipeline`
- `MLFLOW_REGISTERED_MODEL_NAME=iris-logreg-model`

Set `datascience_job_container_image` in tfvars to the pushed OCIR image, for example:

```hcl
datascience_job_container_image = "iad.ocir.io/<namespace>/mlflow-training:1.0.0"
```

The script logs:

- params
- metrics
- model artifact
- model registration (MLflow Model Registry)

### 4) Trigger Data Science Job (Same Build Stage)

The main build spec includes a final step to trigger the Data Science Job Run.

### 5) Trigger Flow

Recommended trigger chain:

1. Dev pushes code to GitHub
2. OCI DevOps Build Pipeline is triggered
3. Build stage builds/packages training artifacts
4. Same build stage triggers Data Science Job Run
5. Job runs training and logs to MLflow + registers model

## Optional Terraform Resources For Pipeline

You can provision the pipeline resources from Terraform by setting:

- `create_datascience_job = true`
- `create_devops_pipeline = true`
- `devops_repository_url`
- optional `devops_trigger_file_paths` to trigger only on selected folders/files

For GitHub connection, choose one:

- Reuse existing connection: set `devops_github_connection_id`
- Create new connection from OCI Vault secret:
  - `create_devops_github_connection = true`
  - `devops_github_access_token_secret_id = "ocid1.vaultsecret..."`
  - optional `devops_github_connection_name`

Then run:

```bash
terraform apply -var-file=terraform.tfvars
```

Important:

- OCI DevOps build stage image/name options can vary by region/provider version.
- If apply reports validation errors on DevOps stage fields, keep `create_devops_pipeline=false` and use the provided `devops/build_spec.yaml` + scripts with manually created pipeline UI resources.

Data Science notebooks are placed in a private subnet by default, with internet egress via NAT gateway so package installs (for example from PyPI) work without assigning public IPs.

## Test MLflow From OCI Data Science Notebook

After apply, check:

```bash
terraform output datascience_notebook_session_url
terraform output mlflow_url
```

Inside the notebook, you can run:

```python
import mlflow

mlflow.set_tracking_uri("http://<mlflow-lb-ip-or-hostname>")
mlflow.set_experiment("oke-smoke-test")

with mlflow.start_run():
    mlflow.log_param("source", "oci-datascience-notebook")
    mlflow.log_metric("accuracy", 0.99)
```

## Model Serving (FastAPI on OKE)

Serving files are under `serving/`:

- API: `serving/app.py`
- Container: `serving/Dockerfile`
- Build/push helper: `scripts/build_and_push_serving_ocir_image.sh`
- K8s manifests: `serving/k8s/deployment.yaml`, `serving/k8s/service.yaml`

### Build and Push Serving Image to OCIR

```bash
export OCIR_REGION_CODE=iad
export OCIR_NAMESPACE=<namespace>
export OCIR_REPOSITORY=mlflow-serving
export IMAGE_TAG=latest
export OCIR_USERNAME=<namespace>/<username>
export OCIR_AUTH_TOKEN=<auth_token>

bash scripts/build_and_push_serving_ocir_image.sh
```

### Deploy Serving API to OKE

1. Update `serving/k8s/deployment.yaml` image field and env values.
2. Apply manifests:

```bash
kubectl apply -f serving/k8s/deployment.yaml
kubectl apply -f serving/k8s/service.yaml
```

3. Test:

```bash
kubectl -n mlflow get svc mlflow-serving
curl -X POST http://<serving-lb-ip>/predict \
  -H "Content-Type: application/json" \
  -d '{"inputs":[[5.1,3.5,1.4,0.2]]}'
```
