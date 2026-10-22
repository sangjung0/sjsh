#!/usr/bin/env bash

# Author: SangJeong Kim
# Last Modified: 2026-08-03

set -euo pipefail

CONTAINER_USER="${1:-$CONTAINER_USER}"
CONTAINER_HOME="${2:-$CONTAINER_HOME}"
CONTAINER_WORK_DIR="${3:-$CONTAINER_WORK_DIR}"

if ! id "${CONTAINER_USER}" &>/dev/null; then
  echo "User ${CONTAINER_USER} does not exist" >&2
  exit 1
elif [[ ! -d "${CONTAINER_HOME}" ]]; then
  echo "Home directory ${CONTAINER_HOME} does not exist" >&2
  exit 1
elif [[ ! -d "${CONTAINER_WORK_DIR}" ]]; then
  echo "Work directory ${CONTAINER_WORK_DIR} does not exist" >&2
  exit 1
fi

echo "[INFO] step 1/1: change ownership to ${CONTAINER_USER}"
if [[ "${CONTAINER_USER}" != "root" ]]; then
  sudo bash "${CONTAINER_WORK_DIR}/.devcontainer/sjsh/root/change_owner.sh" "${CONTAINER_USER}" \
    --target "${CONTAINER_HOME}" \
    --target "${CONTAINER_WORK_DIR}:${CONTAINER_WORK_DIR}/.agents"
fi

echo "[INFO] post-create command completed successfully."
