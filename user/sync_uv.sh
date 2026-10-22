#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <workdir> [group1] [group2,group3...]" >&2
    exit 1
fi
WORK_DIR="$1"
shift
if [[ ! -d "$WORK_DIR" ]]; then
    echo "[ERROR] Work directory does not exist: $WORK_DIR" >&2
    exit 1
fi
WORK_DIR="$(realpath -e -- "$WORK_DIR")"

UV_ARGS=()
declare -A SEEN_GROUPS=()
for argument in "$@"; do
    if [[ -z "$argument" || "$argument" == ,* || "$argument" == *, || "$argument" == *,,* || "$argument" =~ [[:space:]] ]]; then
        echo "[ERROR] Empty dependency group in: $argument" >&2
        exit 1
    fi
    IFS=, read -r -a groups <<< "$argument"
    for group in "${groups[@]}"; do
        if [[ ! "$group" =~ ^[A-Za-z0-9]([A-Za-z0-9._-]*[A-Za-z0-9])?$ ]]; then
            echo "[ERROR] Invalid dependency group: $group" >&2
            exit 1
        fi
        if [[ ! ${SEEN_GROUPS[$group]+present} ]]; then
            UV_ARGS+=( --group "$group" )
            SEEN_GROUPS[$group]=1
        fi
    done
done
if ! command -v uv >/dev/null 2>&1; then
    echo "[ERROR] uv is not in PATH for user $(id -un)" >&2
    exit 1
fi

cd -- "$WORK_DIR"
echo "[INFO] Running uv sync as $(id -un) in $WORK_DIR"
if uv sync "${UV_ARGS[@]}"; then
    echo "[INFO] uv sync completed successfully"
else
    status=$?
    echo "[ERROR] uv sync failed (exit $status): $WORK_DIR" >&2
    exit "$status"
fi
