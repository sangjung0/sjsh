#!/usr/bin/env bash
set -euo pipefail

NVM_VERSION="v0.40.4"
DEFAULT_NODE_VERSION="24"

usage() {
    echo "Usage: $0 [node-version|lts|latest] [home]"
    echo "  Default Node.js version: $DEFAULT_NODE_VERSION"
    echo "  A single existing home path is also accepted for compatibility."
}
fail() {
    echo "[ERROR] $1" >&2
    exit 1
}
if [[ "${1-}" == -h || "${1-}" == --help ]]; then
    usage
    exit 0
fi
(( $# <= 2 )) || { usage >&2; exit 1; }
NODE_REQUEST="${1-$DEFAULT_NODE_VERSION}"
HOME_DIR="${2-${HOME:-}}"
# Keep the old single-home argument form, without mistaking a version for a path.
if [[ $# -eq 1 && -d "$1" && ! "$1" =~ ^v?[0-9]+([.][0-9]+){0,2}$ && "$1" != lts && "$1" != latest ]]; then
    HOME_DIR="$1"
    NODE_REQUEST="$DEFAULT_NODE_VERSION"
fi
case "$NODE_REQUEST" in
    latest) NODE_SPEC="node" ;;
    lts) NODE_SPEC="lts/*" ;;
    *)
        [[ "$NODE_REQUEST" =~ ^v?[0-9]+([.][0-9]+){0,2}$ ]] || fail "Invalid Node.js version: $NODE_REQUEST"
        NODE_SPEC="$NODE_REQUEST"
        ;;
esac
if [[ -z "$HOME_DIR" ]]; then
    HOME_DIR="$(getent passwd "$(id -un)" | cut -d: -f6)"
fi
[[ -d "$HOME_DIR" && -w "$HOME_DIR" ]] || fail "Home must be an existing writable directory: $HOME_DIR"
HOME_DIR="$(realpath -e -- "$HOME_DIR")"
export HOME="$HOME_DIR"
export NVM_DIR="$HOME_DIR/.nvm"

if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    if [[ -e "$NVM_DIR" || -L "$NVM_DIR" ]]; then
        [[ -d "$NVM_DIR" ]] || fail "NVM path is not a directory: $NVM_DIR"
        contents="$(find "$NVM_DIR" -mindepth 1 -maxdepth 1 -print -quit)"
        [[ -z "$contents" ]] || fail "NVM directory is incomplete or contains other files: $NVM_DIR"
    fi
    mkdir -p -- "$NVM_DIR"
    installer="$(curl -fsSL --retry 2 --connect-timeout 15 --max-time 120 \
        "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh")"
    PROFILE=/dev/null NODE_VERSION= NVM_INSTALL_VERSION="$NVM_VERSION" bash -c "$installer"
else
    echo "[INFO] Reusing NVM: $NVM_DIR"
fi
[[ -s "$NVM_DIR/nvm.sh" ]] || fail "NVM installation did not create nvm.sh"

set +eu
source "$NVM_DIR/nvm.sh" --no-use || fail "Cannot load NVM"
nvm install "$NODE_SPEC" || fail "Cannot install Node.js: $NODE_REQUEST"
nvm use "$NODE_SPEC" || fail "Cannot activate Node.js: $NODE_REQUEST"
INSTALLED_NODE="$(node --version)" || fail "Node.js verification failed"
npm --version || fail "npm verification failed"

nvm alias default "$INSTALLED_NODE" || fail "Cannot set the default Node.js version"
set -eu

if [[ "${SHELL:-}" == */zsh || "${SHELL:-}" == zsh ]]; then
    PROFILE_FILE="$HOME_DIR/.zshrc"
else
    PROFILE_FILE="$HOME_DIR/.bashrc"
fi
if ! grep -Fq '# sjsh: load nvm' "$PROFILE_FILE" 2>/dev/null; then
    {
        printf '\n# sjsh: load nvm\n'
        printf 'export NVM_DIR=%q\n' "$NVM_DIR"
        printf '[ ! -s "$NVM_DIR/nvm.sh" ] || . "$NVM_DIR/nvm.sh"\n'
    } >> "$PROFILE_FILE"
fi
echo "[INFO] Node.js $INSTALLED_NODE is ready; startup configured in $PROFILE_FILE"
echo "[INFO] Open a new shell or source that startup file to activate it in your terminal."
