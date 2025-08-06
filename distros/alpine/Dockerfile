# syntax=docker/dockerfile:1.7

FROM mcr.microsoft.com/devcontainers/base:alpine-3.18

# Build arguments with defaults
ARG TZ=America/Sao_Paulo
ARG TERM=xterm-256color
ARG BRANCH=main
ARG USERNAME=vscode
ARG GROUPNAME=vscode
ARG GITHUB_REPO=roalcantara/dots
ARG INSTALL_ARGS=""

# Essential environment variables only
ENV CLICOLOR=1 \
    TZ=$TZ \
    TERM="$TERM" \
    COLORTERM=truecolor \
    DEBIAN_FRONTEND=noninteractive \
    USER="$USERNAME" \
    HOME="/home/$USERNAME" \
    GROUP="$GROUPNAME" \
    INSTALL_ARGS="$INSTALL_ARGS --TZ=$TZ --USERNAME=$USERNAME --GROUPNAME=$GROUPNAME"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN --mount=type=secret,id=GITHUB_TOKEN,target=/tmp/github_token,required=false \
    --mount=type=cache,target=$HOME/.cache,uid=1000,gid=1000 \
    curl -fsSL "https://raw.githubusercontent.com/${GITHUB_REPO}/${BRANCH}/install?$(date +%s)" | bash -s -- $INSTALL_ARGS

# Health check to ensure the container is running correctly
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD zsh -c 'echo "Container health check passed"' || exit 1

USER $USERNAME
WORKDIR $HOME
SHELL ["/usr/bin/zsh", "-c"]

# Set the entrypoint to zsh in interactive login mode
ENTRYPOINT ["/usr/bin/zsh", "-il"]
