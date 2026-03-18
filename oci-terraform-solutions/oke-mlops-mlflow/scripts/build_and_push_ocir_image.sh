#!/usr/bin/env bash
set -euo pipefail

: "${OCIR_REGION_CODE:?Set OCIR_REGION_CODE (for example: iad)}"
: "${OCIR_NAMESPACE:?Set OCIR_NAMESPACE}"
: "${OCIR_REPOSITORY:?Set OCIR_REPOSITORY (for example: mlflow-training)}"
: "${OCIR_USERNAME:?Set OCIR_USERNAME (format: <namespace>/<username>)}"
: "${OCIR_AUTH_TOKEN:?Set OCIR_AUTH_TOKEN}"

IMAGE_TAG="${IMAGE_TAG:-latest}"
OCIR_REGISTRY="${OCIR_REGION_CODE}.ocir.io"
IMAGE_URI="${OCIR_REGISTRY}/${OCIR_NAMESPACE}/${OCIR_REPOSITORY}:${IMAGE_TAG}"

echo "Logging in to OCIR registry: ${OCIR_REGISTRY}"
echo "${OCIR_AUTH_TOKEN}" | docker login "${OCIR_REGISTRY}" -u "${OCIR_USERNAME}" --password-stdin

echo "Building image: ${IMAGE_URI}"
docker build -f training/Dockerfile -t "${IMAGE_URI}" .

echo "Pushing image: ${IMAGE_URI}"
docker push "${IMAGE_URI}"

echo "Image pushed successfully: ${IMAGE_URI}"
