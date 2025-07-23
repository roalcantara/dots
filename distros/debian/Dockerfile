# syntax=docker/dockerfile:1.7

# https://mcr.microsoft.com/en-us/artifact/mar/devcontainers/ruby/tags
FROM mcr.microsoft.com/devcontainers/ruby:3.4-bookworm

# Build arguments with defaults
ARG TZ=America/Sao_Paulo
ARG TERM=xterm-256color
ARG BRANCH=main
ARG USERNAME=vscode
ARG GROUPNAME=vscode
ARG GITHUB_REPO_NAME=dots
ARG GITHUB_REPO=roalcantara/dots

# Essential environment variables only
ENV CLICOLOR=1 \
    TZ=$TZ \
    TERM="$TERM" \
    COLORTERM=truecolor \
    DEBIAN_FRONTEND=noninteractive \
    USER="$USERNAME" \
    HOME="/home/$USERNAME" \
    GROUP="$GROUPNAME"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN --mount=type=secret,id=github_token,target=/tmp/github_token,required=false \
    --mount=type=cache,target=$HOME/.cache,uid=1000,gid=1000 \
    curl -fsSL "https://raw.githubusercontent.com/${GITHUB_REPO}/${BRANCH}/install?$(date +%s)" | bash -s -- -u "${USERNAME}" -g "${GROUPNAME}" -t "${TZ}"

USER $USERNAME
WORKDIR $HOME

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD zsh -c 'echo "Container health check passed"' || exit 1

SHELL ["/usr/bin/zsh", "-c"]
ENTRYPOINT ["/usr/bin/zsh", "-il"]
