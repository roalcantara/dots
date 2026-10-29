FROM mcr.microsoft.com/devcontainers/base:debian

ARG MISE_VERSION=v2026.10.22
ENV MISE_VERSION=${MISE_VERSION}

# Install age and prerequisite packages
RUN apt-get update -qq \
    && apt-get install -y -qq --no-install-recommends \
        age \
        ca-certificates \
        curl \
        git \
        gnupg \
        openssh-client \
        sudo \
    && rm -rf /var/lib/apt/lists/*

# Pre-install pinned mise for vscode user
# hadolint ignore=DL3066
USER vscode
ENV HOME=/home/vscode
ENV PATH="/home/vscode/.local/bin:/home/linuxbrew/.linuxbrew/bin:${PATH}"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3066
RUN curl -fsSL https://mise.run | MISE_VERSION=${MISE_VERSION} sh -s -- -y

# Setup volume mount point permissions
# hadolint ignore=DL3066
USER root
RUN mkdir -p /origin && chown -R vscode:vscode /origin
# hadolint ignore=DL3066
USER vscode
WORKDIR /home/vscode
