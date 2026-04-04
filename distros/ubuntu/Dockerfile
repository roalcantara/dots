# syntax=docker/dockerfile:1.7

# A simple Ubuntu container with Git and other common utilities installed
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
# Disabling syscall filtering tells Nix (and by extension, Flox) to skip applying a seccomp profile, which fails under QEMU/Docker-arm64 emulation
RUN mkdir -p /etc/nix && echo 'filter-syscalls = false' >> /etc/nix/nix.conf
ENV DOTS_EMBEDDED=1
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
# Disabling syscall filtering tells Nix (and by extension, Flox) to skip applying a seccomp profile, which fails under QEMU/Docker-arm64 emulation
RUN mkdir -p /etc/nix && echo 'filter-syscalls = false' >> /etc/nix/nix.conf
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# Install with selective caching strategy
RUN --mount=type=secret,id=github_token \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=$HOME/.cache/pip,uid=1000,gid=1000 \
    --mount=type=cache,target=$HOME/.cache/gem,uid=1000,gid=1000 \
    --mount=type=cache,target=$HOME/.cache/mise,uid=1000,gid=1000 \
    --mount=type=cache,target=$HOME/.cache/nvim,uid=1000,gid=1000 \
    echo "[INFO] Using remote dotfiles installation..." && \
    wget -qO- "https://raw.githubusercontent.com/${GITHUB_REPO}/${BRANCH}/install" | bash -s -- -u "$USERNAME" -g "$GROUPNAME" -t "$TZ" -p "$PACKAGE_MANAGER" -b "$BRANCH"

USER $USERNAME
WORKDIR /home/$USERNAME
SHELL ["/usr/bin/zsh", "-c"]
ENTRYPOINT ["/usr/bin/zsh", "-il"]

# Stage for publishing dotfiles (path build context: embedded install; no clone, keep .git)
# Cache: only install + the COPY'd config subtrees invalidate the heavy RUN; full tree COPY after.
# DOCKER_BUILDKIT=1 docker build --build-arg=BUILDKIT_INLINE_CACHE=1 --build-arg=USERNAME=vscode --build-arg=GROUPNAME=vscode --build-arg=PACKAGE_MANAGER=flox --secret=id=github_token,src=./.secrets/github_token.secret --platform=linux/arm64 --tag=dots:ubuntu-publish --no-cache --file=distros/ubuntu/Dockerfile --target=publish .
FROM base AS publish
# Disabling syscall filtering tells Nix (and by extension, Flox) to skip applying a seccomp profile, which fails under QEMU/Docker-arm64 emulation
RUN mkdir -p /etc/nix && echo 'filter-syscalls = false' >> /etc/nix/nix.conf
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set working directory for dotfiles (MUST BE SET BEFORE COPYING THE REST OF THE DOTFILES!!)
WORKDIR /home/$USERNAME/.local/share/dots
# Minimal config for embedded install (install does not read the rest until ~/.config symlinks):
# - .profile: required (backup targets $HOME/.config/.profile — lives at config/.profile, not under zsh/)
# - zsh: .zshenv backup + ZDOTDIR
# - nvim: prepare_tools_nvim / Lazy
# - flox: FLOX_PATH + optional chown of config/flox
# - mise: not referenced by install.sh; included so ~/.config/mise exists before final COPY
# Omitted here (picked up by final COPY): config/bin and all other config/* (~/.local/bin symlinks skipped in RUN if absent)
COPY --chown=$USERNAME:$GROUPNAME ../../install ./install
COPY --chown=$USERNAME:$GROUPNAME ../../config/.profile ./config/.profile
COPY --chown=$USERNAME:$GROUPNAME ../../config/nvim ./config/nvim
COPY --chown=$USERNAME:$GROUPNAME ../../config/zsh ./config/zsh
COPY --chown=$USERNAME:$GROUPNAME ../../config/mise ./config/mise
COPY --chown=$USERNAME:$GROUPNAME ../../config/flox ./config/flox

RUN --mount=type=secret,id=github_token \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=$HOME/.cache/pip,uid=1000,gid=1000 \
    --mount=type=cache,target=$HOME/.cache/gem,uid=1000,gid=1000 \
    --mount=type=cache,target=$HOME/.cache/mise,uid=1000,gid=1000 \
    --mount=type=cache,target=$HOME/.cache/nvim,uid=1000,gid=1000 \
    chown -R "$USERNAME:$GROUPNAME" "/home/$USERNAME" && \
    ./install -u "$USERNAME" -g "$GROUPNAME" -t "$TZ" -p "$PACKAGE_MANAGER" -e

# Remaining repo (distros, script, .git, docs, …); cheap layer — does not rerun install when only these change
COPY --chown=$USERNAME:$GROUPNAME ../../. ./

USER $USERNAME
WORKDIR /home/$USERNAME
SHELL ["/usr/bin/zsh", "-c"]
ENTRYPOINT ["/usr/bin/zsh", "-il"]
