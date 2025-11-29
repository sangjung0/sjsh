#!/usr/bin/env bash
# wait-for-dir.sh
# 사용법: wait-for-dir.sh [-t TIMEOUT_SEC] [-i INTERVAL_SEC] DIR
# 성공: 0, 타임아웃: 1, 잘못된 인자: 2

set -euo pipefail

TIMEOUT=60
INTERVAL=1

usage() {
    echo "Usage: $0 [-t TIMEOUT_SEC] [-i INTERVAL_SEC] DIR" >&2
    exit 2
}

while getopts ":t:i:h" opt; do
    case "$opt" in
        t) TIMEOUT="${OPTARG}" ;;
        i) INTERVAL="${OPTARG}" ;;
        h) usage ;;
        \?) echo "Unknown option: -$OPTARG" >&2; usage ;;
        :)  echo "Option -$OPTARG requires an argument" >&2; usage ;;
    esac
done
shift $((OPTIND - 1))

[ $# -eq 1 ] || usage
DIR="$1"

is_usable() {
    local d="$1"
    # 존재 + 디렉터리
    [ -d "$d" ] || return 1
    # 읽기/쓰기 확인
    [ -r "$d" ] && [ -w "$d" ] || return 1
    # 실질적 R/W 체크(터치 후 삭제)
    local probe="$d/.rwcheck.$$"
    if touch "$probe" 2>/dev/null; then
        rm -f "$probe" 2>/dev/null || return 1
        return 0
    fi
    return 1
}

deadline=$(( $(date +%s) + TIMEOUT ))
while true; do
    if is_usable "$DIR"; then
        exit 0
    fi
    if [ "$(date +%s)" -ge "$deadline" ]; then
        echo "Timeout: directory not usable within ${TIMEOUT}s -> $DIR" >&2
        exit 1
    fi
    sleep "$INTERVAL"
done
