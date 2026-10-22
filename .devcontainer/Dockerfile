# Author: SangJeong Kim
# Last Modified: 2026-08-14

FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-lc"]

# INSTALL DEPENDENCIES
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
  git sudo zsh curl python3 python3-pip ripgrep \
  && rm -rf /var/lib/apt/lists/*

# Agent tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-venv \
    poppler-utils \
    libreoffice \
    ghostscript \
    graphviz \
    libheif-examples \
    fonts-dejavu-core \
    fonts-liberation2 \
    fonts-noto-core \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    && rm -rf /var/lib/apt/lists/*

# LOAD SCRIPT
ARG SCRIPT_PATH=/tmp/scripts
COPY sjsh ${SCRIPT_PATH}
RUN find "${SCRIPT_PATH}" -name "*.sh" -exec chmod +x {} +

# SET AGENT TOOLS
ARG CODEX_OFFICE_VENV=/opt/codex-office
RUN ${SCRIPT_PATH}/root/install_codex_office_python.sh ${CODEX_OFFICE_VENV}
ENV CODEX_OFFICE_PYTHON=/opt/codex-office/bin/python

# ADD USER AND SETUP ZSH
ARG CONTAINER_USER
ARG CONTAINER_UID
ARG CONTAINER_HOME
RUN ${SCRIPT_PATH}/root/add_user_and_setup_sudo.sh ${CONTAINER_USER} ${CONTAINER_UID}
RUN ${SCRIPT_PATH}/root/setup_zsh_for_user.sh ${CONTAINER_USER}

# CLEANUP
RUN rm -rf /tmp/* || true

# SWITCH USER
USER ${CONTAINER_USER}
