#!/usr/bin/env bash

set -euo pipefail

usage() {
    echo "Usage: $0 <absolute-venv-path>" >&2
    echo "  <absolute-venv-path>: Path where the Python virtual environment will be created" >&2
    exit 1
}

if [[ $# -ne 1 ]]; then
    usage
fi

TARGET_PATH="${1}"

if [[ "${TARGET_PATH}" != /* ]]; then
    echo "[ERROR] Target path must be absolute: '${TARGET_PATH}'" >&2
    exit 1
fi

if [[ -e "${TARGET_PATH}" && ! -d "${TARGET_PATH}" ]]; then
    echo "[ERROR] Target path exists but is not a directory: '${TARGET_PATH}'" >&2
    exit 1
fi

mkdir -p "${TARGET_PATH}"
python3 -m venv "${TARGET_PATH}"

PYTHON_BIN="${TARGET_PATH}/bin/python"

"${PYTHON_BIN}" -m pip install \
    --no-cache-dir \
    --upgrade \
    pip \
    setuptools \
    wheel

"${PYTHON_BIN}" -m pip install \
    --no-cache-dir \
    reportlab \
    pdfplumber \
    pypdf \
    python-docx \
    lxml \
    pdf2image \
    pillow \
    openpyxl \
    pandas \
    numpy


