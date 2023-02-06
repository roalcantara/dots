# syntax=docker/dockerfile:1
# hadolint ignore=DL3002

FROM gitpod/workspace-base:2023-01-16-03-31-28 as root
LABEL org.opencontainers.image.source=https://github.com/roalcantara/dots
LABEL org.opencontainers.image.description="Dots: System configuration files (Gitpod)"
LABEL org.opencontainers.image.licenses=MIT

ARG BRANCH=main
ENV BRANCH="$BRANCH"

# Setup dotfiles
USER gitpod
WORKDIR /home/gitpod
RUN mkdir ~/.ssh && echo 'IdentityFile ~/.ssh-local/id_rsa' > ~/.ssh/config \
  && export USER=gitpod BRANCH="$BRANCH" && curl -Lks https://raw.githubusercontent.com/roalcantara/dots/main/script/setup | bash -s

# Give back control
USER root
