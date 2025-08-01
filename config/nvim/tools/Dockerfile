# syntax=docker/dockerfile:1.7

# Multi-stage Dockerfile for Lua development tools
# Builds both Busted (testing) and Selene (linting) in Alpine Linux

ARG RUST_VERSION="1.83"

# Stage 1: Build Selene (Lua linter)
FROM rust:${RUST_VERSION}-alpine AS selene
RUN apk add --no-cache \
      g++ \
      musl-dev \
      bash \
      && cargo install --branch main --git https://github.com/Kampfkarren/selene selene

WORKDIR /app
SHELL ["/bin/bash", "-c"]
ENTRYPOINT ["/usr/local/bin/selene"]

# Stage 3: Build Busted (Lua testing framework)
FROM alpine:3.19 AS busted
ENV LUAROCKS_VERSION=3.9.2

RUN apk add --no-cache \
      build-base \
      curl \
      git \
      readline-dev \
      unzip \
      wget \
      lua5.1 \
      lua5.1-dev \
      luajit \
      luajit-dev \
      bash

# Install LuaRocks
RUN wget --progress=dot:giga https://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz \
      && tar -xzf luarocks-${LUAROCKS_VERSION}.tar.gz \
      && cd luarocks-${LUAROCKS_VERSION} \
      && ./configure --with-lua=/usr \
      && make build \
      && make install \
      && cd .. \
      && rm -rf luarocks-${LUAROCKS_VERSION}*

# Install Busted
RUN luarocks install busted

WORKDIR /app
SHELL ["/bin/bash", "-c"]
ENTRYPOINT ["/usr/local/bin/busted", "--verbose"]

# Stage 6: Combined image with both Busted and Selene
FROM alpine:3.19 AS shell
RUN apk add --no-cache \
      lua5.1 \
      luajit \
      bash \
      libgcc

# Copy Busted
COPY --from=busted /usr/local/bin/busted /usr/local/bin/
COPY --from=busted /usr/local/lib/luarocks /usr/local/lib/luarocks
COPY --from=busted /usr/local/share/lua /usr/local/share/lua

# Copy Selene
COPY --from=selene /usr/local/cargo/bin/selene /usr/local/bin/

WORKDIR /app
SHELL ["/bin/bash", "-c"]

# Default command (can be overridden)
CMD ["/bin/bash"]
