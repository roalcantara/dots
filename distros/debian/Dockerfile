# syntax=docker/dockerfile:1.7

# A Debian development container set up by ./install (mise bootstrap).
# Images never receive a secrets archive; only GITHUB_TOKEN, from a build secret, for GitHub API limits.
# https://mcr.microsoft.com/en-us/artifact/mar/devcontainers/base/tags
FROM mcr.microsoft.com/devcontainers/base:debian AS base

ARG TZ=America/Sao_Paulo
ARG TERM=xterm-256color
ARG BRANCH=main
# hadolint ignore=DL3064
ARG USERNAME=vscode
ARG GITHUB_REPO=roalcantara/dots

# DOTS_CONTAINER=1: BuildKit has no /.dockerenv and cgroup v2 shows `0::/`, so install cannot detect the container.
ENV CLICOLOR=1 \
    TZ=$TZ \
    TERM="$TERM" \
    COLORTERM=truecolor \
    USER="$USERNAME" \
    HOME="/home/$USERNAME" \
    GITHUB_REPO="$GITHUB_REPO" \
    BRANCH="$BRANCH" \
    DEBIAN_FRONTEND=noninteractive \
    DOTS_CONTAINER=1 \
    PATH="/home/$USERNAME/.local/bin:/home/linuxbrew/.linuxbrew/bin:$PATH"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Committed tree (sent by `mise run build --local` as a git archive)
FROM base AS local
COPY . /home/$USERNAME/Work/dots
RUN --mount=type=secret,id=github_token \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    GITHUB_TOKEN="$(cat /run/secrets/github_token 2>/dev/null || true)" \
    "/home/$USERNAME/Work/dots/install" --user "$USERNAME" --tz "$TZ"
USER $USERNAME
WORKDIR /home/$USERNAME
SHELL ["/usr/bin/zsh", "-c"]
ENTRYPOINT ["/usr/bin/zsh", "-il"]

# GitHub branch: mise run build (the default)
FROM base AS remote
# hadolint ignore=DL4006
RUN --mount=type=secret,id=github_token \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    export GITHUB_TOKEN="$(cat /run/secrets/github_token 2>/dev/null || true)"; \
    curl -fsSL "https://raw.githubusercontent.com/${GITHUB_REPO}/${BRANCH}/install" \
      | bash -s -- --user "$USERNAME" --tz "$TZ" --branch "$BRANCH"
USER $USERNAME
WORKDIR /home/$USERNAME
SHELL ["/usr/bin/zsh", "-c"]
ENTRYPOINT ["/usr/bin/zsh", "-il"]

# Docker Hub: mise run build --publish (the committed tree, as local)
FROM local AS publish
