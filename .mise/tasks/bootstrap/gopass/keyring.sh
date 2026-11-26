#!/usr/bin/env bash
#MISE description="Warn when the gopass keyring still uses a passphrase or an identity file is missing"
# gopass's identity keyring should be locked to the age key (docs/REINSTALL.md, "One secret: the age key"), so gopass
# never asks for a PIN. Only warns: the switch is interactive and done once by the owner.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
has_profile desktop || exit 0
bootstrap_init

ids="$HOME/.config/gopass/age/identities"
if command -v gopass > /dev/null && [ -s "$ids" ]; then
  if head -n 3 "$ids" | grep -q -- '-> scrypt'; then
    echo "bootstrap: gopass keyring still uses a passphrase; switch it to the age key: see docs/REINSTALL.md#one-secret-the-age-key" >&2
  else
    # age.keyring-identities may list several files, comma-separated; each may start with ~.
    IFS=, read -ra kids <<< "$(gopass config age.keyring-identities 2> /dev/null || true)"
    for kid in "${kids[@]}"; do
      kid="${kid#"${kid%%[![:space:]]*}"}"
      kid="${kid%"${kid##*[![:space:]]}"}"
      kid="${kid/#\~/$HOME}"
      [ -z "$kid" ] || [ -s "$kid" ] || echo "bootstrap: gopass keyring identity file missing: $kid" >&2
    done
  fi
fi
