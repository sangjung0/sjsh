#!/usr/bin/env bash
set -euo pipefail

# usage
usage() {
    echo "Usage: $0 <username> <workdir> [group1] [group2,group3...]" >&2
    echo "  - <username>: Required user to perform uv sync as" >&2
    echo "  - <workdir>: Required directory" >&2
    echo "  - [groups...]: Optional. Can be space-separated or comma-separated" >&2
    exit 1
}

# check args
if [[ $# -lt 2 ]]; then
    usage
fi

# check root
if [[ "$(id -u)" -ne 0 ]]; then
    echo "[ERROR] This script must be run as root." >&2
    exit 1
fi

# args
TARGET_USER="${1}"
CONTAINER_WORK_DIR="${2}"
shift 2

if ! id "${TARGET_USER}" &>/dev/null; then
    echo "[ERROR] User '${TARGET_USER}' does not exist." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INNER_SCRIPT="${SCRIPT_DIR}/../user/sync_uv.sh"

if [[ ! -f "${INNER_SCRIPT}" ]]; then
    echo "[ERROR] Inner script '${INNER_SCRIPT}' not found." >&2
    exit 1
fi

chmod +rx "${INNER_SCRIPT}"

CMD="${INNER_SCRIPT} '${CONTAINER_WORK_DIR}' $*"
sudo -iu "${TARGET_USER}" bash -lc "${CMD}"
