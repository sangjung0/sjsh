#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 [chsh|no-chsh]" >&2
    echo "  - default: chsh" >&2
    exit 1
}

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

USER_NAME="$(id -un)"
HOME="${HOME:-$(getent passwd "$USER_NAME" | cut -d: -f6)}"
export HOME
if [[ "$HOME" != /* || ! -d "$HOME" || ! -w "$HOME" ]]; then
    echo "[ERROR] HOME must be an existing writable absolute directory: $HOME" >&2
    exit 1
fi
TARGET_ZSH="$(command -v zsh)"

echo "[INFO] checking oh-my-zsh installation"
if [[ -f "${HOME}/.oh-my-zsh/oh-my-zsh.sh" ]]; then
    echo "[INFO] oh-my-zsh is already installed."
else
    echo "[INFO] installing oh-my-zsh"
    if ! curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | ZSH="$HOME/.oh-my-zsh" RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh; then
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

ZSHRC="$(realpath -e -- "$ZSHRC")"

sed -i '/^ZSH_THEME=/d; /^POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=/d' "$ZSHRC"
[[ -s "$ZSHRC" ]] || printf '\n' > "$ZSHRC"
sed -i '1i ZSH_THEME="powerlevel10k/powerlevel10k"\nPOWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' "$ZSHRC"

if ! grep -q 'alias ls=' "${ZSHRC}"; then
    echo 'alias ls="ls -lsaF"' >> "${ZSHRC}"
fi

if ! grep -Eq '^[[:space:]]*(source|[.])[[:space:]].*oh-my-zsh[.]sh' "$ZSHRC"; then
    printf '\nexport ZSH="$HOME/.oh-my-zsh"\nsource "$ZSH/oh-my-zsh.sh"\n' >> "$ZSHRC"
fi

if [[ "${DO_CHSH}" == "true" ]]; then
    echo "[INFO] checking default shell"
    CURRENT_SHELL=$(getent passwd "${USER_NAME}" | cut -d: -f7)

    if [[ "${CURRENT_SHELL}" != "${TARGET_ZSH}" ]]; then
        echo "[INFO] changing default shell to zsh"
        if ! chsh -s "${TARGET_ZSH}" "${USER_NAME}"; then
            echo "[ERROR] changing default shell failed" >&2
            exit 1
        fi
    else
        echo "[INFO] default shell is already zsh."
    fi
fi

echo "[INFO] zsh setup completed successfully"

