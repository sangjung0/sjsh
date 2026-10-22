#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <username> <uid> [primary-gid] [extra-gid ...]" >&2
    exit 1
fi
USER_NAME="$1"
USER_ID="$2"
GROUP_ID="${3-$USER_ID}"

valid_id() {
    [[ "$1" =~ ^(0|[1-9][0-9]{0,9})$ ]] && (( 10#$1 <= 4294967294 ))
}
if [[ ! "$USER_NAME" =~ ^[a-z_][a-z0-9_-]*$ ]] ||
   ! valid_id "$USER_ID" || ! valid_id "$GROUP_ID"; then
    echo "[ERROR] Invalid username, UID or primary GID" >&2
    exit 1
fi
if [[ "$USER_NAME" == root && "$USER_ID" != 0 ]] ||
   [[ "$USER_NAME" != root && "$USER_ID" == 0 ]]; then
    echo "[ERROR] Only root may use UID 0, and root must use UID 0" >&2
    exit 1
fi

EXTRA_GIDS=()
declare -A SEEN_GIDS=(["$GROUP_ID"]=1)
for argument in "${@:4}"; do
    [[ "$argument" =~ ^[0-9]+(,[0-9]+)*$ ]] || {
        echo "[ERROR] Invalid additional GID list: $argument" >&2
        exit 1
    }
    IFS=, read -r -a values <<< "$argument"
    for gid in "${values[@]}"; do
        valid_id "$gid" || { echo "[ERROR] Invalid GID: $gid" >&2; exit 1; }
        if [[ ! ${SEEN_GIDS[$gid]+present} ]]; then
            EXTRA_GIDS+=("$gid")
            SEEN_GIDS[$gid]=1
        fi
    done
done

EXISTING=false
if id "$USER_NAME" &>/dev/null; then
    EXISTING=true
    if [[ "$(id -u "$USER_NAME")" != "$USER_ID" || "$(id -g "$USER_NAME")" != "$GROUP_ID" ]]; then
        echo "[ERROR] Existing user's UID or primary GID does not match: $USER_NAME" >&2
        exit 1
    fi
    if (( ${#EXTRA_GIDS[@]} == 0 )); then
        echo "[INFO] User '$USER_NAME' already has the requested UID and primary GID"
        exit 0
    fi
elif getent passwd "$USER_ID" >/dev/null; then
    echo "[ERROR] UID is already in use: $USER_ID" >&2
    exit 1
fi
if (( EUID != 0 )); then
    echo "[ERROR] Run this script as root" >&2
    exit 1
fi

CREATE_GIDS=()
CREATE_NAMES=()
for gid in "$GROUP_ID" "${EXTRA_GIDS[@]}"; do
    if getent group "$gid" >/dev/null; then
        continue
    else
        lookup_status=$?
        (( lookup_status == 2 )) || { echo "[ERROR] Group lookup failed: $gid" >&2; exit 1; }
    fi
    if [[ "$gid" == "$GROUP_ID" ]]; then
        group_name="$USER_NAME"
    else
        group_name="sjsh-gid-$gid"
    fi
    if getent group "$group_name" >/dev/null; then
        echo "[ERROR] Group name already exists with another GID: $group_name" >&2
        exit 1
    else
        lookup_status=$?
        (( lookup_status == 2 )) || { echo "[ERROR] Group lookup failed: $group_name" >&2; exit 1; }
    fi
    # The username could itself equal an automatically generated group name.
    for planned_name in "${CREATE_NAMES[@]}"; do
        [[ "$planned_name" != "$group_name" ]] || {
            echo "[ERROR] Planned group names conflict: $group_name" >&2
            exit 1
        }
    done
    CREATE_GIDS+=("$gid")
    CREATE_NAMES+=("$group_name")
done
for index in "${!CREATE_GIDS[@]}"; do
    groupadd --gid "${CREATE_GIDS[$index]}" "${CREATE_NAMES[$index]}"
done

extra_args=()
if (( ${#EXTRA_GIDS[@]} > 0 )); then
    printf -v extra_list '%s,' "${EXTRA_GIDS[@]}"
    extra_args=( -G "${extra_list%,}" )
fi
if [[ "$EXISTING" == true ]]; then
    # Append instead of replacing the user's existing supplementary groups.
    usermod -a "${extra_args[@]}" "$USER_NAME"
else
    useradd -u "$USER_ID" -g "$GROUP_ID" -N -m "${extra_args[@]}" "$USER_NAME"
fi
echo "[INFO] User '$USER_NAME' configured with UID $USER_ID, primary GID $GROUP_ID and requested additional groups"
