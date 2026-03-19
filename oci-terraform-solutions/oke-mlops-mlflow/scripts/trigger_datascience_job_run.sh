#!/usr/bin/env bash
set -euo pipefail

: "${JOB_OCID:?Set JOB_OCID}"
: "${COMPARTMENT_OCID:?Set COMPARTMENT_OCID}"

DISPLAY_NAME="${DISPLAY_NAME:-ml-training-run-$(date +%Y%m%d-%H%M%S)}"
PROJECT_OCID="${PROJECT_OCID:-}"

if [ -z "${PROJECT_OCID}" ]; then
  PROJECT_OCID="$(oci data-science job get \
    --job-id "${JOB_OCID}" \
    --query 'data."project-id"' \
    --raw-output)"
fi

JOB_RUN_OCID=$(oci data-science job-run create \
  --job-id "${JOB_OCID}" \
  --project-id "${PROJECT_OCID}" \
  --compartment-id "${COMPARTMENT_OCID}" \
  --display-name "${DISPLAY_NAME}" \
  --raw-output)

echo "Started OCI Data Science Job Run: ${JOB_RUN_OCID}"
