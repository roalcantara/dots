#!/usr/bin/env bash
# Shared container bootstrap script called by distros/debian/Dockerfile and PR CI.
# Assumes the repository checkout is already at "$HOME/.local/share/dots" and runs as the image user.
set -euo pipefail

MISE_VERSION="v2026.11.14"
MISE_BIN="$HOME/.local/bin/mise"
want="${MISE_VERSION#v}"

have=""
if [ -x "$MISE_BIN" ]; then
  have="$("$MISE_BIN" --version 2> /dev/null | awk '{print $1}' || true)"
  have="${have#v}"
fi

if [ "$have" != "$want" ]; then
  curl -fsSL https://mise.run | MISE_VERSION="$MISE_VERSION" sh
fi

mkdir -p "$HOME/.config"
ln -sfn ../.local/share/dots/config/mise "$HOME/.config/mise"

DOTS_STRICT=1 "$MISE_BIN" bootstrap -E container --save-env --force-dotfiles --skip user --yes

# The container doctor checks learn their profile from the saved env; without it they all "do not apply" and pass.
grep -qF '"container"' "$HOME/.config/mise/miserc.local.toml" 2> /dev/null || {
  echo "bootstrap.sh: mise bootstrap did not save the container profile (~/.config/mise/miserc.local.toml)" >&2
  exit 1
}
