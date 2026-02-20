#!/usr/bin/env bash
set -euo pipefail

# usage
usage() {
    echo "Usage: $0 [home]" >&2
    echo "  - [home]: Optional. Home directory for the user (default: ${HOME})" >&2
    exit 1
}

HOME_DIR="${1:-${HOME:-$(eval echo "~${USER}")}}"
export NVM_DIR="$HOME_DIR/.nvm"

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash

set +u

source "$NVM_DIR/nvm.sh"

# Install the latest LTS version of Node.js and set it as default
nvm install --lts

# Set the default Node.js version to the latest LTS
nvm alias default 'lts/*'

# Use the default Node.js version (latest LTS)
nvm use --lts
