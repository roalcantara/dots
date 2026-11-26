#!/usr/bin/env bash
#MISE description="Put the GitHub signing key in the agent, storing its passphrase in Keychain once"
#MISE raw=true
# macOS: git signs commits with the GitHub key (config/git/config) through the agent only; ssh-keygen -Y sign never
# reads Keychain. Load it from Keychain, or store its passphrase there once, asked on the terminal. Apple's ssh-add
# (Homebrew's has no --apple-* flags). At each login the dev.mise.ssh-add LaunchAgent (macos.toml) loads it again.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
has_profile desktop || exit 0
bootstrap_init
is_macos || exit 0

key="$HOME/.ssh/id_ed25519_github"
sshbin="${DOTS_SSH_BIN:-/usr/bin}"
if [ -r "$key" ] && [ -r "$key.pub" ]; then
  fp="$("$sshbin/ssh-keygen" -lf "$key.pub" 2> /dev/null | awk '{print $2}')"
  has_key()
            {
              [ -n "$fp" ] && "$sshbin/ssh-add" -l 2> /dev/null | grep -qF "$fp"
  }
  if ! has_key; then
    "$sshbin/ssh-add" --apple-load-keychain > /dev/null 2>&1 || true
    if has_key; then
      :
    elif (: < /dev/tty) 2> /dev/null; then
      echo "bootstrap: enter the passphrase for $key once; Keychain keeps it" >&2
      "$sshbin/ssh-add" --apple-use-keychain "$key" < /dev/tty || warn "ssh-add $key"
    else
      echo "bootstrap: $key is not in Keychain; run: ssh-add --apple-use-keychain $key" >&2
    fi
  fi
fi
