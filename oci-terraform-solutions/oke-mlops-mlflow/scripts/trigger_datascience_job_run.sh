#!/usr/bin/env bash
set -euo pipefail

: "${JOB_OCID:?Set JOB_OCID}"
: "${COMPARTMENT_OCID:?Set COMPARTMENT_OCID}"

DISPLAY_NAME="${DISPLAY_NAME:-ml-training-run-$(date +%Y%m%d-%H%M%S)}"

JOB_RUN_OCID=$(oci data-science job-run create \
  --job-id "${JOB_OCID}" \
  --compartment-id "${COMPARTMENT_OCID}" \
  --display-name "${DISPLAY_NAME}" \
  --query 'data.id' \
  --raw-output)

echo "Started OCI Data Science Job Run: ${JOB_RUN_OCID}"
