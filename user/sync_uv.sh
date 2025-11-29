#!/usr/bin/env bash
set -euo pipefail

# usage
usage() {
    echo "Usage: $0 <workdir> [group1] [group2,group3...]" >&2
    echo "  - <workdir>: Required directory" >&2
    echo "  - [groups...]: Optional. Can be space-separated or comma-separated" >&2
    exit 1
}


# check args
if [[ $# -lt 1 ]]; then
    usage
fi

# args
TARGET_USER="$(id -un)"
CONTAINER_WORK_DIR="${1}"
shift 1

if [[ ! -d "${CONTAINER_WORK_DIR}" ]]; then
    echo "[ERROR] Work directory '${CONTAINER_WORK_DIR}' does not exist." >&2
    exit 1
fi

# check uv installation in TARGET_USER's PATH
echo "[INFO] Checking uv installation for user ${TARGET_USER}..."
if ! command -v uv >/dev/null 2>&1; then
    echo "[ERROR] uv is not installed for user '${TARGET_USER}' (not in PATH)" >&2
    exit 1
fi
echo "[INFO] uv found for ${TARGET_USER}."

# parse optional groups
UV_CMD_ARGS=()
for group_arg in "$@"; do
    IFS=',' read -r -a parsed_groups <<< "${group_arg}"
    for g in "${parsed_groups[@]}"; do
        if [[ -n "${g}" ]]; then
            UV_CMD_ARGS+=(--group "${g}")
        fi
    done
done

# Run sync
echo "[INFO] Running uv sync in ${CONTAINER_WORK_DIR}..."
cd "${CONTAINER_WORK_DIR}" && uv sync "${UV_CMD_ARGS[@]}"

echo "[INFO] Setup complete."
