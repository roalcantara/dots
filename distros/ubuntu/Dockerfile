# syntax=docker/dockerfile:1.7

# An Ubuntu development container set up by mise bootstrap.
# Images never receive secrets; only GITHUB_TOKEN, from a build secret, for GitHub API limits.
# https://mcr.microsoft.com/en-us/artifact/mar/devcontainers/base/tags
FROM mcr.microsoft.com/devcontainers/base:ubuntu AS base

ARG TZ=America/Sao_Paulo
ARG TERM=xterm-256color
ARG BRANCH=main
# hadolint ignore=DL3064
ARG USERNAME=vscode
ARG GITHUB_REPO=roalcantara/dots

ENV CLICOLOR=1 \
    TZ=$TZ \
    TERM="$TERM" \
    COLORTERM=truecolor \
    USER="$USERNAME" \
    HOME="/home/$USERNAME" \
    GITHUB_REPO="$GITHUB_REPO" \
    BRANCH="$BRANCH" \
    DEBIAN_FRONTEND=noninteractive \
    PATH="/home/$USERNAME/.local/bin:/home/linuxbrew/.linuxbrew/bin:$PATH"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends tzdata && rm -rf /var/lib/apt/lists/*

# Committed tree (sent by `mise run build --local` as a git archive)
FROM base AS local
USER $USERNAME
COPY --chown=$USERNAME:$USERNAME . /home/$USERNAME/.local/share/dots
# hadolint ignore=DL4006
RUN --mount=type=secret,id=github_token,uid=1000 \
    export GITHUB_TOKEN="$(cat /run/secrets/github_token 2>/dev/null || true)"; \
    curl -fsSL https://mise.run | MISE_VERSION=v2026.10.22 sh && \
    mkdir -p ~/.config && ln -sfn ../.local/share/dots/config/mise ~/.config/mise && \
    ~/.local/bin/mise bootstrap -E container --force-dotfiles --skip user --yes
WORKDIR /home/$USERNAME
SHELL ["/usr/bin/zsh", "-c"]
ENTRYPOINT ["/usr/bin/zsh", "-il"]

# GitHub branch: mise run build (the default)
FROM base AS remote
USER $USERNAME
# hadolint ignore=DL4006
RUN --mount=type=secret,id=github_token,uid=1000 \
    export GITHUB_TOKEN="$(cat /run/secrets/github_token 2>/dev/null || true)"; \
    git clone --branch "$BRANCH" "https://github.com/${GITHUB_REPO}.git" "/home/$USERNAME/.local/share/dots" && \
    curl -fsSL https://mise.run | MISE_VERSION=v2026.10.22 sh && \
    mkdir -p ~/.config && ln -sfn ../.local/share/dots/config/mise ~/.config/mise && \
    ~/.local/bin/mise bootstrap -E container --force-dotfiles --skip user --yes
WORKDIR /home/$USERNAME
SHELL ["/usr/bin/zsh", "-c"]
ENTRYPOINT ["/usr/bin/zsh", "-il"]

# Docker Hub: mise run build --publish (the committed tree, as local)
FROM local AS publish
