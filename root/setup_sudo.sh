#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <username>" >&2
    exit 1
fi
TARGET_USER="$1"
if [[ ! "$TARGET_USER" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    echo "[ERROR] Invalid username: $TARGET_USER" >&2
    exit 1
fi
if ! id "$TARGET_USER" &>/dev/null; then
    echo "[ERROR] User does not exist: $TARGET_USER" >&2
    exit 1
fi
if [[ "$TARGET_USER" == root ]]; then
    echo "[INFO] root does not need a sudo rule"
    exit 0
fi
if (( EUID != 0 )); then
    echo "[ERROR] Run this script as root" >&2
    exit 1
fi
command -v visudo >/dev/null

temp_file="$(mktemp /etc/sudoers.d/.sjsh-sudo.XXXXXXXXXX)"
trap 'rm -f -- "$temp_file"' EXIT
printf '%s ALL=(ALL) NOPASSWD: ALL\n' "$TARGET_USER" > "$temp_file"
chmod 0440 "$temp_file"
visudo -cf "$temp_file"
mv -fT -- "$temp_file" "/etc/sudoers.d/$TARGET_USER"
echo "[INFO] User '$TARGET_USER' configured with passwordless sudo"
