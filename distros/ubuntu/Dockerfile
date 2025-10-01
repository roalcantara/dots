# syntax=docker/dockerfile:1.7

# A simple Ubuntu container with Git and other common utilities installed
# https://github.com/devcontainers/images/tree/main/src/base-ubuntu
# https://mcr.microsoft.com/en-us/artifact/mar/devcontainers/base/tags
FROM mcr.microsoft.com/devcontainers/base:ubuntu AS base

# Build arguments with defaults
ARG TZ=America/Sao_Paulo
ARG TERM=xterm-256color
ARG BRANCH=main
ARG USERNAME=vscode
ARG GROUPNAME=vscode
ARG GITHUB_REPO=roalcantara/dots
ARG PACKAGE_MANAGER=flox

ENV CLICOLOR=1 \
    TZ=$TZ \
    TERM="$TERM" \
    COLORTERM=truecolor \
    USER="$USERNAME" \
    GROUP="$GROUPNAME" \
    HOME="/home/$USERNAME" \
    GITHUB_REPO="$GITHUB_REPO" \
    BRANCH="$BRANCH" \
    PACKAGE_MANAGER="$PACKAGE_MANAGER"

# Stage for local dotfiles installation
FROM base AS local
# Set working directory for dotfiles (MUST BE SET BEFORE COPYING THE REST OF THE DOTFILES!!)
WORKDIR /home/$USERNAME/.local/share/dots
# Copy the rest of the dotfiles
COPY --chown=$USERNAME:$GROUPNAME ../../. ./
# Install with selective caching strategy
RUN --mount=type=secret,id=github_token \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=$HOME/.cache/pip,uid=1000,gid=1000 \
    --mount=type=cache,target=$HOME/.cache/gem,uid=1000,gid=1000 \
    --mount=type=cache,target=$HOME/.cache/mise,uid=1000,gid=1000 \
    --mount=type=cache,target=$HOME/.cache/nvim,uid=1000,gid=1000 \
    echo "[INFO] Using local dotfiles installation..." && \
    chown -R "$USERNAME:$GROUPNAME" "/home/$USERNAME" && \
    ./install -u "$USERNAME" -g "$GROUPNAME" -t "$TZ" -p "$PACKAGE_MANAGER"

USER $USERNAME
WORKDIR /home/$USERNAME
SHELL ["/usr/bin/zsh", "-c"]
ENTRYPOINT ["/usr/bin/zsh", "-il"]

# Stage for remote dotfiles installation
FROM base AS remote
ARG CACHE_BUST=unknown
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# Install with selective caching strategy
RUN --mount=type=secret,id=github_token \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=$HOME/.cache/pip,uid=1000,gid=1000 \
    --mount=type=cache,target=$HOME/.cache/gem,uid=1000,gid=1000 \
    --mount=type=cache,target=$HOME/.cache/mise,uid=1000,gid=1000 \
    --mount=type=cache,target=$HOME/.cache/nvim,uid=1000,gid=1000 \
    echo "[INFO] Using remote dotfiles installation (commit: ${CACHE_BUST})..." && \
    curl -fsSL "https://raw.githubusercontent.com/${GITHUB_REPO}/${BRANCH}/install" | bash -s -- -u "$USERNAME" -g "$GROUPNAME" -t "$TZ" -p "$PACKAGE_MANAGER" -b "$BRANCH"

USER $USERNAME
WORKDIR /home/$USERNAME
SHELL ["/usr/bin/zsh", "-c"]
ENTRYPOINT ["/usr/bin/zsh", "-il"]
