#!/usr/bin/env bash
set -euo pipefail

python3 -m pip install --upgrade pip
pip3 install -r training/requirements.txt

python3 training/train.py \
  --mlflow-tracking-uri "${MLFLOW_TRACKING_URI:-http://129.80.216.101}" \
  --experiment-name "${MLFLOW_EXPERIMENT_NAME:-basic-iris-training-pipeline}" \
  --registered-model-name "${MLFLOW_REGISTERED_MODEL_NAME:-iris-logreg-model}" \
  --max-iter "${MAX_ITER:-200}" \
  --test-size "${TEST_SIZE:-0.2}" \
  --random-state "${RANDOM_STATE:-42}"
