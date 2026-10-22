#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    echo "Usage: source ${BASH_SOURCE[0]} <env-file>" >&2
    exit 1
fi

if [[ $# -ne 1 ]]; then
    echo "Usage: source ${BASH_SOURCE[0]} <env-file>" >&2
    return 1
fi

if declare -F __sjsh_load_env >/dev/null; then
    echo "[ERROR] Function '__sjsh_load_env' already exists." >&2
    return 1
fi

__sjsh_load_env() {
    local __sjsh_env_path="$1"
    local __sjsh_env_autoexport=0
    local __sjsh_env_status=0

    if [[ "$__sjsh_env_path" != /* ]]; then
        __sjsh_env_path="./$__sjsh_env_path"
    fi
    if [[ ! -f "$__sjsh_env_path" || ! -r "$__sjsh_env_path" ]]; then
        echo "[ERROR] Environment file is not a readable regular file: $1" >&2
        return 1
    fi

    [[ $- == *a* ]] && __sjsh_env_autoexport=1
    set -a

    if source "$__sjsh_env_path"; then
        __sjsh_env_status=0
    else
        __sjsh_env_status=$?
    fi
    if [[ $__sjsh_env_autoexport -eq 1 ]]; then
        set -a
    else
        set +a
    fi

    if [[ $__sjsh_env_status -ne 0 ]]; then
        echo "[ERROR] Environment file returned a failure: $1" >&2
        return "$__sjsh_env_status"
    fi
    echo "[INFO] Completed loading environment variables from '$1'"
}

if __sjsh_load_env "$@"; then
    unset -f __sjsh_load_env
    return 0
else
    unset -f __sjsh_load_env
    return 1
fi
