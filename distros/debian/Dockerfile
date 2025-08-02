# syntax=docker/dockerfile:1.7

# https://mcr.microsoft.com/en-us/artifact/mar/devcontainers/ruby/tags
FROM mcr.microsoft.com/devcontainers/ruby:3.4-bookworm AS base

# Build arguments with defaults
ARG TZ=America/Sao_Paulo
ARG TERM=xterm-256color
ARG BRANCH=main
ARG USERNAME=vscode
ARG GROUPNAME=vscode
ARG GITHUB_REPO=roalcantara/dots

ENV CLICOLOR=1 \
    TZ=$TZ \
    TERM="$TERM" \
    COLORTERM=truecolor \
    DEBIAN_FRONTEND=noninteractive \
    USER="$USERNAME" \
    GROUP="$GROUPNAME" \
    HOME="/home/$USERNAME"

# Set working directory for dotfiles
WORKDIR /home/$USERNAME/.local/share/dots

# Stage for local dotfiles installation
FROM base AS local

# Copy the rest of the dotfiles
COPY --chown=$USERNAME:$GROUPNAME ../../. ./

# Install with selective caching strategy
RUN --mount=type=secret,id=github_token,target=/tmp/github_token,required=false \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=$HOME/.cache/pip,uid=1000,gid=1000 \
    --mount=type=cache,target=$HOME/.cache/gem,uid=1000,gid=1000 \
    --mount=type=cache,target=$HOME/.cache/mise,uid=1000,gid=1000 \
    --mount=type=cache,target=$HOME/.cache/nvim,uid=1000,gid=1000 \
    echo "[INFO] Using local dotfiles installation..." && \
    rm -rf .git config/nvim/.venv && \
    chown -R "$USERNAME:$GROUPNAME" "/home/$USERNAME/.local" && \
    chown "$USERNAME:$GROUPNAME" install && chmod +x install && \
    ./install -u "$USERNAME" -g "$GROUPNAME" -t "$TZ"

USER $USERNAME
WORKDIR $HOME
SHELL ["/usr/bin/zsh", "-c"]
ENTRYPOINT ["/usr/bin/zsh", "-il"]

# Stage for remote dotfiles installation
FROM base AS remote
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# Install with selective caching strategy
RUN --mount=type=secret,id=github_token,target=/tmp/github_token,required=false \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=$HOME/.cache/pip,uid=1000,gid=1000 \
    --mount=type=cache,target=$HOME/.cache/gem,uid=1000,gid=1000 \
    --mount=type=cache,target=$HOME/.cache/mise,uid=1000,gid=1000 \
    --mount=type=cache,target=$HOME/.cache/nvim,uid=1000,gid=1000 \
    echo "[INFO] Using remote dotfiles installation..." && \
    curl -fsSL "https://raw.githubusercontent.com/${GITHUB_REPO}/${BRANCH}/install?$(date +%s)" | bash -s -- -u "$USERNAME" -g "$GROUPNAME" -t "$TZ" -b "$BRANCH"

USER $USERNAME
WORKDIR $HOME
SHELL ["/usr/bin/zsh", "-c"]
ENTRYPOINT ["/usr/bin/zsh", "-il"]
