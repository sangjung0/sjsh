#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <absolute-venv-path>" >&2
    exit 1
fi
TARGET_PATH="$1"
if [[ "$TARGET_PATH" != /* ]]; then
    echo "[ERROR] Virtual environment path must be absolute: $TARGET_PATH" >&2
    exit 1
fi
if [[ -L "$TARGET_PATH" ]]; then
    echo "[ERROR] Virtual environment path must not be a symlink: $TARGET_PATH" >&2
    exit 1
fi
TARGET_PATH="$(realpath -m -- "$TARGET_PATH")"
if [[ "$TARGET_PATH" == / ]]; then
    echo "[ERROR] Refusing to use the filesystem root as a virtual environment" >&2
    exit 1
fi
if [[ -e "$TARGET_PATH" && ! -d "$TARGET_PATH" ]]; then
    echo "[ERROR] Target is not a directory: $TARGET_PATH" >&2
    exit 1
fi

stage="checking target"
trap 'status=$?; echo "[ERROR] Failed while $stage (exit $status): $TARGET_PATH" >&2; exit "$status"' ERR
if [[ -d "$TARGET_PATH" && ! -f "$TARGET_PATH/pyvenv.cfg" ]]; then
    contents="$(find "$TARGET_PATH" -mindepth 1 -maxdepth 1 -print -quit)"
    if [[ -n "$contents" ]]; then
        echo "[ERROR] Refusing to overwrite a nonempty directory without pyvenv.cfg: $TARGET_PATH" >&2
        exit 1
    fi
fi

if [[ ! -f "$TARGET_PATH/pyvenv.cfg" ]]; then
    stage="creating virtual environment (python3-venv must be installed)"
    command -v python3 >/dev/null
    python3 -m venv "$TARGET_PATH"
else
    echo "[INFO] Reusing virtual environment: $TARGET_PATH"
fi

PYTHON_BIN="$TARGET_PATH/bin/python"
stage="validating virtual environment"
[[ -x "$PYTHON_BIN" ]]
"$PYTHON_BIN" -c '
import os, sys
if sys.prefix == sys.base_prefix or os.path.realpath(sys.prefix) != os.path.realpath(sys.argv[1]):
    raise SystemExit("Python does not belong to the requested virtual environment")
' "$TARGET_PATH"
"$PYTHON_BIN" -m pip --version

PACKAGES=(
    pip setuptools wheel
    reportlab pdfplumber pypdf python-docx lxml pdf2image pillow
    openpyxl pandas numpy
)
stage="installing Python packages"
# Keep already satisfied versions instead of unconditionally upgrading them.
"$PYTHON_BIN" -m pip --disable-pip-version-check --no-input install \
    --no-cache-dir "${PACKAGES[@]}"

stage="checking installed dependencies"
"$PYTHON_BIN" -m pip --disable-pip-version-check check
stage="checking package imports"
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" -c '
import reportlab, pdfplumber, pypdf, docx, lxml, pdf2image, PIL
import openpyxl, pandas, numpy
'
echo "[INFO] Python tools are ready: $PYTHON_BIN"
printf '[INFO] Configure the calling environment with: export CODEX_OFFICE_PYTHON=%q\n' "$PYTHON_BIN"
echo "[INFO] PDF rendering and document conversion also require system tools such as Poppler and LibreOffice."
