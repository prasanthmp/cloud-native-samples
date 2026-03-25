#!/usr/bin/env bash
set -euo pipefail

: "${OCIR_REGION_CODE:?Set OCIR_REGION_CODE (for example: iad)}"
: "${OCIR_NAMESPACE:?Set OCIR_NAMESPACE}"
: "${OCIR_REPOSITORY:?Set OCIR_REPOSITORY (for example: mlflow-serving)}"
: "${OCIR_USERNAME:?Set OCIR_USERNAME (format: <namespace>/<username>)}"

if [ -z "${OCIR_AUTH_TOKEN:-}" ] && [ -n "${OCIR_AUTH_TOKEN_SECRET_OCID:-}" ]; then
  if ! command -v oci >/dev/null 2>&1; then
    echo "OCI CLI not found. Set OCIR_AUTH_TOKEN directly or install OCI CLI in build image."
    exit 1
  fi
  export OCI_CLI_AUTH="${OCI_CLI_AUTH:-resource_principal}"
  TOKEN_B64="$(oci secrets secret-bundle get --secret-id "${OCIR_AUTH_TOKEN_SECRET_OCID}" --query 'data."secret-bundle-content".content' --raw-output)"
  OCIR_AUTH_TOKEN="$(printf '%s' "${TOKEN_B64}" | base64 --decode)"
  export OCIR_AUTH_TOKEN
fi

: "${OCIR_AUTH_TOKEN:?Set OCIR_AUTH_TOKEN or OCIR_AUTH_TOKEN_SECRET_OCID}"

IMAGE_TAG="${IMAGE_TAG:-latest}"
OCIR_REGISTRY="${OCIR_REGION_CODE}.ocir.io"
IMAGE_URI="${OCIR_REGISTRY}/${OCIR_NAMESPACE}/${OCIR_REPOSITORY}:${IMAGE_TAG}"

echo "Logging in to OCIR: ${OCIR_REGISTRY}"
echo "${OCIR_AUTH_TOKEN}" | docker login "${OCIR_REGISTRY}" -u "${OCIR_USERNAME}" --password-stdin

echo "Building serving image: ${IMAGE_URI}"
docker build -f serving/Dockerfile -t "${IMAGE_URI}" .

echo "Pushing serving image: ${IMAGE_URI}"
docker push "${IMAGE_URI}"

echo "Serving image pushed: ${IMAGE_URI}"
