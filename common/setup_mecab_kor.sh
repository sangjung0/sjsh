#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 0 ]]; then
    echo "Usage: $0" >&2
    exit 1
fi
if (( EUID != 0 )); then
    echo "[ERROR] Run this script as root" >&2
    exit 1
fi
for tool in curl tar make gcc g++ autoconf automake libtoolize ldconfig; do
    command -v "$tool" >/dev/null || {
        echo "[ERROR] Required build tool is missing: $tool" >&2
        exit 1
    }
done

MECAB_NAME="mecab-0.996-ko-0.9.2"
DIC_NAME="mecab-ko-dic-2.1.1-20180720"
# Never reuse or remove unrelated /tmp/mecab-* paths.
work_dir="$(mktemp -d -- "${TMPDIR:-/tmp}/sjsh-mecab.XXXXXXXXXX")"
trap 'rm -rf -- "$work_dir"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

curl -fL --retry 2 --connect-timeout 15 --max-time 180 \
    -o "$work_dir/$MECAB_NAME.tar.gz" \
    "https://bitbucket.org/eunjeon/mecab-ko/downloads/$MECAB_NAME.tar.gz"
tar -xzf "$work_dir/$MECAB_NAME.tar.gz" -C "$work_dir"
cd -- "$work_dir/$MECAB_NAME"
./configure
make
make check
make install
ldconfig

curl -fL --retry 2 --connect-timeout 15 --max-time 180 \
    -o "$work_dir/$DIC_NAME.tar.gz" \
    "https://bitbucket.org/eunjeon/mecab-ko-dic/downloads/$DIC_NAME.tar.gz"
tar -xzf "$work_dir/$DIC_NAME.tar.gz" -C "$work_dir"
cd -- "$work_dir/$DIC_NAME"
./autogen.sh
./configure
make
make install
ldconfig

echo "[INFO] MeCab Korean engine and dictionary installed successfully"
