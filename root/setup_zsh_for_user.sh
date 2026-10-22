#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <username>" >&2
    echo "  - <username>: User to install and configure zsh/oh-my-zsh for" >&2
    exit 1
}

# check args
if [[ $# -ne 1 ]]; then
    usage
fi

# check root
if [[ "$(id -u)" -ne 0 ]]; then
    echo "[ERROR] This script must be run as root." >&2
    exit 1
fi

TARGET_USER="${1}"

if ! id "${TARGET_USER}" &>/dev/null; then
    echo "[ERROR] User '${TARGET_USER}' does not exist." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INNER_SCRIPT="${SCRIPT_DIR}/../user/setup_zsh.sh"

if [[ ! -f "${INNER_SCRIPT}" ]]; then
    echo "[ERROR] Inner script '${INNER_SCRIPT}' not found." >&2
    exit 1
fi

TARGET_ZSH="$(command -v zsh)"
sudo -n -H -u "$TARGET_USER" -- bash -lc 'exec bash "$@"' \
    setup_zsh_for_user "$INNER_SCRIPT" no-chsh

CURRENT_SHELL="$(getent passwd "$TARGET_USER" | cut -d: -f7)"
if [[ "$CURRENT_SHELL" != "$TARGET_ZSH" ]]; then
    echo "[INFO] chsh to zsh for user $TARGET_USER"
    chsh -s "$TARGET_ZSH" "$TARGET_USER"
fi
