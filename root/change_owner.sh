#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <username> --target <path[:exclude1:exclude2:...]> [--target ...]" >&2
    echo "Paths are relative to the working directory; ':' is a separator." >&2
    exit 1
}
[[ $# -ge 1 ]] || usage
USER_NAME="$1"
shift
if ! USER_ID="$(id -u "$USER_NAME")" || ! GROUP_ID="$(id -g "$USER_NAME")"; then
    echo "[ERROR] User does not exist: $USER_NAME" >&2
    exit 1
fi
OWNER="$USER_ID:$GROUP_ID"

# Resolve symlinks in parent directories, but preserve the final directory entry
# so chown -h can change a symlink itself instead of its referent.
normalize_entry() {
    local path="$1" parent name
    while [[ "$path" != / && "$path" == */ ]]; do
        path="${path%/}"
    done
    IFS= read -r -d '' name < <(basename -z -- "$path") || return 1
    if [[ "$name" == / || "$name" == . || "$name" == .. ]]; then
        IFS= read -r -d '' REPLY < <(realpath -mz -- "$path") || return 1
    else
        IFS= read -r -d '' parent < <(dirname -z -- "$path") || return 1
        IFS= read -r -d '' parent < <(realpath -mz -- "$parent") || return 1
        REPLY="${parent%/}/$name"
    fi
}

declare -a TARGETS=() EXCLUSIONS=()

while [[ $# -gt 0 ]]; do
    [[ "$1" == --target && $# -ge 2 && -n "$2" ]] || usage
    spec="$2"
    shift 2
    target="${spec%%:*}"
    [[ -n "$target" ]] || usage
    [[ -e "$target" || -L "$target" ]] || {
        echo "[ERROR] Target does not exist: $target" >&2
        exit 1
    }

    normalize_entry "$target"
    target="$REPLY"
    TARGETS+=("$target")
    if [[ "$spec" == *:* ]]; then
        EXCLUSIONS+=("${spec#*:}")
    else
        EXCLUSIONS+=("")
    fi
done
(( ${#TARGETS[@]} > 0 )) || usage

RUN=()
if (( EUID != 0 )); then
    sudo -n true
    RUN=(sudo -n --)
fi

escape_pattern() {
    REPLY="$1"
    REPLY="${REPLY//\\/\\\\}"
    REPLY="${REPLY//\*/\\*}"
    REPLY="${REPLY//\?/\\?}"
    REPLY="${REPLY//\[/\\[}"
    REPLY="${REPLY//\]/\\]}"
}

status=0
for index in "${!TARGETS[@]}"; do
    target="${TARGETS[$index]}"
    args=( -P "$target" )
    exclusions=()
    # Split only on colons, preserving literal newlines in paths.
    remaining_exclusions="${EXCLUSIONS[$index]}"
    while [[ "$remaining_exclusions" == *:* ]]; do
        exclusions+=("${remaining_exclusions%%:*}")
        remaining_exclusions="${remaining_exclusions#*:}"
    done
    exclusions+=("$remaining_exclusions")
    prune=()
    for excluded in "${exclusions[@]}"; do
        [[ -n "$excluded" ]] || continue
        normalize_entry "$excluded"
        excluded="$REPLY"
        escape_pattern "$excluded"
        (( ${#prune[@]} == 0 )) || prune+=( -o )
        prune+=( -path "$REPLY" )
    done
    if (( ${#prune[@]} > 0 )); then
        args+=( \( "${prune[@]}" \) -prune -o )
    fi
    args+=( \( ! -uid "$USER_ID" -o ! -gid "$GROUP_ID" \) )
    if ! "${RUN[@]}" find "${args[@]}" -exec chown -h -- "$OWNER" {} +; then
        echo "[ERROR] Ownership change failed: $target" >&2
        status=1
        continue
    fi
    if ! remaining="$("${RUN[@]}" find "${args[@]}" -print -quit)"; then
        echo "[ERROR] Cannot verify ownership: $target" >&2
        status=1
    elif [[ -n "$remaining" ]]; then
        echo "[ERROR] Ownership is still different after chown: $remaining" >&2
        echo "[ERROR] The filesystem may not support changing Unix ownership." >&2
        status=1
    else
        echo "[OK] Ownership verified ($OWNER): $target"
    fi
done
exit "$status"
