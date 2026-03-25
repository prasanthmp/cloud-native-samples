#!/usr/bin/env bash
set -euo pipefail

: "${COMPARTMENT_OCID:?Set COMPARTMENT_OCID}"

DISPLAY_NAME="${DISPLAY_NAME:-ml-training-run-$(date +%Y%m%d-%H%M%S)}"
PROJECT_OCID="${PROJECT_OCID:-}"
JOB_OCID="${JOB_OCID:-}"
WAIT_FOR_JOB_RUN="${WAIT_FOR_JOB_RUN:-false}"
JOB_RUN_TIMEOUT_SECONDS="${JOB_RUN_TIMEOUT_SECONDS:-3600}"
JOB_RUN_POLL_SECONDS="${JOB_RUN_POLL_SECONDS:-20}"

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

if [ "${WAIT_FOR_JOB_RUN}" = "true" ]; then
  echo "Waiting for job run completion (timeout=${JOB_RUN_TIMEOUT_SECONDS}s, poll=${JOB_RUN_POLL_SECONDS}s)"
  START_TS="$(date +%s)"

  while true; do
    NOW_TS="$(date +%s)"
    ELAPSED="$((NOW_TS - START_TS))"

    STATE="$(oci data-science job-run get \
      --job-run-id "${JOB_RUN_OCID}" \
      --query 'data."lifecycle-state"' \
      --raw-output)"

    DETAILS="$(oci data-science job-run get \
      --job-run-id "${JOB_RUN_OCID}" \
      --query 'data."lifecycle-details"' \
      --raw-output)"

    echo "Job run ${JOB_RUN_OCID} state=${STATE} elapsed=${ELAPSED}s details=${DETAILS}"

    case "${STATE}" in
      SUCCEEDED)
        echo "Job run completed successfully."
        break
        ;;
      FAILED|CANCELED)
        echo "Job run ended in terminal failure state: ${STATE}"
        exit 1
        ;;
    esac

    if [ "${ELAPSED}" -ge "${JOB_RUN_TIMEOUT_SECONDS}" ]; then
      echo "Timed out waiting for job run completion after ${JOB_RUN_TIMEOUT_SECONDS}s."
      exit 1
    fi

    sleep "${JOB_RUN_POLL_SECONDS}"
  done
fi
