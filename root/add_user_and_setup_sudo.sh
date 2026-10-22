#!/usr/bin/env bash
set -euo pipefail

# Compatibility entry point; each operation can also be called separately.
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <username> <uid> [primary-gid] [extra-gid ...]" >&2
    exit 1
fi
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/add_user.sh" "$@"
bash "$SCRIPT_DIR/setup_sudo.sh" "$1"
