#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <username>" >&2
    echo "  - <username>: User to install and configure zsh/oh-my-zsh for" >&2
    exit 1
}

# check args
if [[ $# -lt 1 ]]; then
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

chmod +rx "${INNER_SCRIPT}"

CMD="${INNER_SCRIPT} no-chsh"
sudo -iu "${TARGET_USER}" bash -lc "${CMD}"

echo "[INFO] chsh to zsh for user ${TARGET_USER}"
TARGET_ZSH=$(command -v zsh)
sudo chsh -s "${TARGET_ZSH}" "${TARGET_USER}"
