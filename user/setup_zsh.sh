#!/usr/bin/env bash
set -euo pipefail

# usage
usage() {
    echo "Usage: $0 [chsh|no-chsh]" >&2
    echo "  - default: chsh" >&2
    exit 1
}

# default argument
DO_CHSH="true"
if [[ $# -gt 1 ]]; then
    usage
elif [[ $# -eq 1 ]]; then
    case "$1" in
        chsh|CHSH|true|TRUE|yes|YES)
            DO_CHSH="true"
            ;;
        no-chsh|NO-CHSH|false|FALSE|no|NO)
            DO_CHSH="false"
            ;;
        *)
            usage
            ;;
    esac
fi

USER=$(id -un)
HOME=${HOME:-$(eval echo "~${USER}")}

echo "[INFO] checking oh-my-zsh installation"
if [[ -d "${HOME}/.oh-my-zsh" ]]; then
    echo "[INFO] oh-my-zsh is already installed."
else
    echo "[INFO] installing oh-my-zsh"
    if ! curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | RUNZSH=no CHSH=no sh; then
        echo "[ERROR] oh-my-zsh installation failed" >&2
        exit 1
    fi
fi

echo "[INFO] setting up powerlevel10k theme for oh-my-zsh"
OHMYZSH_THEME="${HOME}/.oh-my-zsh/custom/themes"
mkdir -p "${OHMYZSH_THEME}"

if [[ ! -d "${OHMYZSH_THEME}/powerlevel10k" ]]; then
    if ! git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${OHMYZSH_THEME}/powerlevel10k"; then
        echo "[ERROR] powerlevel10k theme installation failed" >&2
        exit 1
    fi
else
    echo "[INFO] powerlevel10k theme already installed."
fi

echo "[INFO] configuring .zshrc"
ZSHRC="${HOME}/.zshrc"
touch "${ZSHRC}"

if grep -q '^ZSH_THEME=' "${ZSHRC}"; then
    sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "${ZSHRC}"
else
    echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "${ZSHRC}"
fi

if ! grep -q 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD' "${ZSHRC}"; then
    echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' >> "${ZSHRC}"
fi

if ! grep -q 'alias ls=' "${ZSHRC}"; then
    echo 'alias ls="ls -lsaF"' >> "${ZSHRC}"
fi

if [[ "${DO_CHSH}" == "true" ]]; then
    echo "[INFO] checking default shell"
    CURRENT_SHELL=$(getent passwd "${USER}" | cut -d: -f7)
    TARGET_ZSH=$(command -v zsh)

    if [[ "${CURRENT_SHELL}" != "${TARGET_ZSH}" ]]; then
        echo "[INFO] changing default shell to zsh"
        if ! chsh -s "${TARGET_ZSH}" "${USER}"; then
            echo "[ERROR] changing default shell failed" >&2
            exit 1
        fi
    else
        echo "[INFO] default shell is already zsh."
    fi
fi

echo "[INFO] zsh setup completed successfully"

