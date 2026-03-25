#!/usr/bin/env bash
set -euo pipefail

: "${COMPARTMENT_OCID:?Set COMPARTMENT_OCID}"

DISPLAY_NAME="${DISPLAY_NAME:-ml-training-run-$(date +%Y%m%d-%H%M%S)}"
PROJECT_OCID="${PROJECT_OCID:-}"
JOB_OCID="${JOB_OCID:-}"

if [ -z "${JOB_OCID}" ]; then
  JOB_OCID="$(oci data-science job list \
    --compartment-id "${COMPARTMENT_OCID}" \
    --lifecycle-state ACTIVE \
    --query 'data[0].id' \
    --raw-output)"
fi

if [ -z "${JOB_OCID}" ] || [ "${JOB_OCID}" = "null" ]; then
  echo "No ACTIVE Data Science Job found in compartment ${COMPARTMENT_OCID}."
  exit 1
fi

if [ -z "${PROJECT_OCID}" ]; then
  PROJECT_OCID="$(oci data-science job get \
    --job-id "${JOB_OCID}" \
    --query 'data."project-id"' \
    --raw-output)"
fi

echo "Executing command:"
echo "oci data-science job-run create \\"
echo "  --job-id \"${JOB_OCID}\" \\"
echo "  --project-id \"${PROJECT_OCID}\" \\"
echo "  --compartment-id \"${COMPARTMENT_OCID}\" \\"
echo "  --display-name \"${DISPLAY_NAME}\" \\"
echo "  --query 'data.id' \\"
echo "  --raw-output"

JOB_RUN_OCID=$(oci data-science job-run create \
  --job-id "${JOB_OCID}" \
  --project-id "${PROJECT_OCID}" \
  --compartment-id "${COMPARTMENT_OCID}" \
  --display-name "${DISPLAY_NAME}" \
  --query 'data.id' \
  --raw-output)

echo "Started OCI Data Science Job Run: ${JOB_RUN_OCID}"
