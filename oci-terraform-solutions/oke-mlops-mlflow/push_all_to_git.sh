#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   scripts/push_all_to_git.sh "commit message" [target_repo_path]
# Example:
#   scripts/push_all_to_git.sh "Update MLOps pipeline" oci-terraform-solutions/oke-mlops-mlflow

COMMIT_MESSAGE="${1:-chore: update project files}"
TARGET_PATH="${2:-oci-terraform-solutions/oke-mlops-mlflow}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "This script must be run inside a Git repository."
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_ABS="${REPO_ROOT}/${TARGET_PATH}"

mkdir -p "${TARGET_ABS}"

echo "Syncing project files to ${TARGET_PATH}/ ..."
rsync -a \
  --exclude ".git/" \
  --exclude ".terraform/" \
  --exclude ".terraform.lock.hcl" \
  --exclude "*.tfvars" \
  --exclude "*.tfvars.json" \
  --exclude "terraform.tfstate" \
  --exclude "terraform.tfstate.*" \
  --exclude "kubeconfig" \
  --exclude ".DS_Store" \
  --exclude ".ipynb_checkpoints/" \
  --exclude "__pycache__/" \
  --exclude "*.tmp" \
  --exclude "*.temp" \
  --exclude "*~" \
  "${PROJECT_DIR}/" "${TARGET_ABS}/"

echo "Staging files from ${TARGET_PATH}/ (excluding tfvars, Terraform state, and temp files)..."
git -C "${REPO_ROOT}" add -A -- "${TARGET_PATH}" \
  ":(glob,exclude)${TARGET_PATH}/**/*.tfvars" \
  ":(glob,exclude)${TARGET_PATH}/**/*.tfvars.json" \
  ":(glob,exclude)${TARGET_PATH}/**/.terraform/**" \
  ":(glob,exclude)${TARGET_PATH}/**/terraform.tfstate" \
  ":(glob,exclude)${TARGET_PATH}/**/terraform.tfstate.*" \
  ":(glob,exclude)${TARGET_PATH}/**/.terraform.lock.hcl" \
  ":(glob,exclude)${TARGET_PATH}/**/kubeconfig" \
  ":(glob,exclude)${TARGET_PATH}/**/*.tmp" \
  ":(glob,exclude)${TARGET_PATH}/**/*.temp" \
  ":(glob,exclude)${TARGET_PATH}/**/*~" \
  ":(glob,exclude)${TARGET_PATH}/**/.DS_Store" \
  ":(glob,exclude)${TARGET_PATH}/**/.ipynb_checkpoints/**" \
  ":(glob,exclude)${TARGET_PATH}/**/__pycache__/**"

if git -C "${REPO_ROOT}" diff --cached --quiet; then
  echo "No changes to commit after exclusions."
  exit 0
fi

STAGED_FILES="$(git -C "${REPO_ROOT}" diff --cached --name-only --relative)"

echo "Files selected for push:"
printf '%s\n' "${STAGED_FILES}"

echo "Committing changes..."
git -C "${REPO_ROOT}" commit -m "${COMMIT_MESSAGE}"

echo "Pushing commits to your configured upstream..."
if git -C "${REPO_ROOT}" push; then
  echo "Push complete."
  exit 0
fi

CURRENT_BRANCH="$(git -C "${REPO_ROOT}" branch --show-current)"

if git -C "${REPO_ROOT}" remote get-url origin >/dev/null 2>&1; then
  echo "No upstream set. Pushing with upstream: origin/${CURRENT_BRANCH}"
  git -C "${REPO_ROOT}" push -u origin "${CURRENT_BRANCH}"
  echo "Push complete."
  exit 0
fi

echo "Push failed: no upstream and no 'origin' remote configured."
echo "Configure a remote, then run either:"
echo "  git -C \"${REPO_ROOT}\" remote add origin <repo-url>"
echo "  git -C \"${REPO_ROOT}\" push -u origin ${CURRENT_BRANCH}"
exit 1
