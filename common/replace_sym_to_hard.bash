#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <file-or-directory> [file-or-directory ...]" >&2
    exit 1
fi

replace_link() (
    local symlink="$1" target original current link_dir temp_dir=""
    trap '[[ -z "$temp_dir" ]] || rm -rf -- "$temp_dir"' EXIT

    IFS= read -r -d '' original < <(readlink -z -- "$symlink") || return 1
    IFS= read -r -d '' target < <(realpath -ez -- "$symlink") || {
        echo "[ERROR] Cannot resolve link: $symlink" >&2
        return 1
    }
    if [[ ! -f "$target" ]]; then
        echo "[SKIP] Not a regular file: $symlink" >&2
        return 0
    fi

    IFS= read -r -d '' link_dir < <(dirname -z -- "$symlink") || return 1
    temp_dir="$(mktemp -d -- "$link_dir/.sjsh-hardlink.XXXXXXXXXX")" || return 1
    if ! ln -- "$target" "$temp_dir/link"; then
        echo "[ERROR] Hard link creation failed; original link preserved: $symlink" >&2
        return 1
    fi

    if [[ ! -L "$symlink" ]] ||
       ! IFS= read -r -d '' current < <(readlink -z -- "$symlink") ||
       [[ "$current" != "$original" ]]; then
        echo "[ERROR] Link changed; refusing replacement: $symlink" >&2
        return 1
    fi
    if ! mv -fT -- "$temp_dir/link" "$symlink"; then
        echo "[ERROR] Replacement failed: $symlink" >&2
        return 1
    fi
    echo "[OK] $symlink"
)

status=0
for path in "$@"; do
    if [[ -L "$path" ]]; then
        if ! replace_link "$path"; then
            status=1
        fi
        continue
    fi
    if [[ -f "$path" ]]; then
        echo "[SKIP] Already a regular file: $path"
        continue
    fi
    if [[ ! -d "$path" ]]; then
        echo "[ERROR] Not a file or directory: $path" >&2
        status=1
        continue
    fi

    if ! IFS= read -r -d '' directory < <(realpath -ez -- "$path"); then
        status=1
        continue
    fi

    if ! find "$directory" -type l -print0 | (
        failures=0
        while IFS= read -r -d '' symlink; do
            if ! replace_link "$symlink"; then
                failures=1
            fi
        done
        exit "$failures"
    ); then
        status=1
    fi
done
exit "$status"
