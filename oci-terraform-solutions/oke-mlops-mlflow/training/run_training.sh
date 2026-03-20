#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

python3 "${APP_DIR}/training/train.py" \
  --mlflow-tracking-uri "${MLFLOW_TRACKING_URI:-}" \
  --experiment-name "${MLFLOW_EXPERIMENT_NAME:-basic-iris-training-pipeline}" \
  --registered-model-name "${MLFLOW_REGISTERED_MODEL_NAME:-iris-logreg-model}" \
  --object-storage-namespace "${OBJECT_STORAGE_NAMESPACE:-}" \
  --dataset-bucket-name "${DATASET_BUCKET_NAME:-}" \
  --dataset-object-name "${DATASET_OBJECT_NAME:-}" \
  --dataset-target-column "${DATASET_TARGET_COLUMN:-target}" \
  --model-backup-bucket-name "${MODEL_BACKUP_BUCKET_NAME:-}" \
  --model-backup-object-prefix "${MODEL_BACKUP_OBJECT_PREFIX:-models}" \
  --max-iter "${MAX_ITER:-200}" \
  --test-size "${TEST_SIZE:-0.2}" \
  --random-state "${RANDOM_STATE:-42}"
