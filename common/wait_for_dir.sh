#!/usr/bin/env bash
# Exit codes: success=0, timeout/runtime failure=1, invalid arguments=2.
set -euo pipefail

TIMEOUT=60
INTERVAL=1

usage() {
    echo "Usage: $0 [-t TIMEOUT_SEC] [-i INTERVAL_SEC] [--] DIR"
    echo "  -t: integer seconds, 0..2147483647 (default: 60; 0 checks once)"
    echo "  -i: integer seconds, 1..2147483647 (default: 1)"
}

invalid_argument() {
    echo "[ERROR] $1" >&2
    usage >&2
    exit 2
}

while getopts ":t:i:h" opt; do
    case "$opt" in
        t) TIMEOUT="$OPTARG" ;;
        i) INTERVAL="$OPTARG" ;;
        h) usage; exit 0 ;;
        \?) invalid_argument "Unknown option: -$OPTARG" ;;
        :) invalid_argument "Option -$OPTARG requires an argument" ;;
    esac
done
shift $((OPTIND - 1))

[[ $# -eq 1 ]] || invalid_argument "Expected exactly one directory"
DIR="$1"
[[ -n "$DIR" ]] || invalid_argument "Directory must not be empty"

for value in "$TIMEOUT" "$INTERVAL"; do
    [[ "$value" =~ ^[0-9]{1,10}$ ]] || invalid_argument "Time values must be integers of at most 10 digits"
    (( 10#$value <= 2147483647 )) || invalid_argument "Time value exceeds 2147483647 seconds"
done
TIMEOUT=$((10#$TIMEOUT))
INTERVAL=$((10#$INTERVAL))
(( INTERVAL > 0 )) || invalid_argument "Interval must be greater than zero"

probe=""
cleanup() {
    if [[ -n "$probe" ]]; then
        rm -f -- "$probe"
    fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

is_usable() {
    [[ -d "$DIR" && -r "$DIR" && -w "$DIR" && -x "$DIR" ]] || return 1

    if ! probe="$(mktemp -- "$DIR/.rwcheck.XXXXXXXXXX" 2>/dev/null)"; then
        return 1
    fi
    if ! rm -- "$probe"; then
        echo "[ERROR] Cannot remove write probe: $probe" >&2
        exit 1
    fi
    probe=""
}

started=$SECONDS
while true; do
    if is_usable; then
        exit 0
    fi
    remaining=$((TIMEOUT - (SECONDS - started)))
    if (( remaining <= 0 )); then
        echo "Timeout: directory not usable within ${TIMEOUT}s -> $DIR" >&2
        exit 1
    fi
    delay=$INTERVAL
    (( delay <= remaining )) || delay=$remaining
    sleep "$delay"
done
