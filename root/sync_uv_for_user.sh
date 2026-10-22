#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <username> <workdir> [group1] [group2,group3...]" >&2
    exit 1
fi
if (( EUID != 0 )); then
    echo "[ERROR] This script must be run as root" >&2
    exit 1
fi
USER_NAME="$1"
WORK_DIR="$2"
shift 2
if ! id "$USER_NAME" &>/dev/null; then
    echo "[ERROR] User does not exist: $USER_NAME" >&2
    exit 1
fi
if [[ ! -d "$WORK_DIR" ]]; then
    echo "[ERROR] Work directory does not exist: $WORK_DIR" >&2
    exit 1
fi

WORK_DIR="$(realpath -e -- "$WORK_DIR")"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INNER_SCRIPT="$SCRIPT_DIR/../user/sync_uv.sh"
if [[ ! -f "$INNER_SCRIPT" ]]; then
    echo "[ERROR] Inner script not found: $INNER_SCRIPT" >&2
    exit 1
fi

exec sudo -n -H -u "$USER_NAME" -- bash -lc 'exec bash "$@"' \
    sync_uv_for_user "$INNER_SCRIPT" "$WORK_DIR" "$@"
