#!/usr/bin/env bash
set -euo pipefail

echo "=== Experiment 1: Container A setup, encryption, and sync to origin ==="

mkdir -p ~/.config/mise
age-keygen -o ~/.config/mise/age.txt
chmod 600 ~/.config/mise/age.txt
PUB_MACHINE=$(age-keygen -y ~/.config/mise/age.txt)

mkdir -p /origin
rm -f /origin/recovery.txt
age-keygen -o /origin/recovery.txt
chmod 600 /origin/recovery.txt
PUB_RECOVERY=$(age-keygen -y /origin/recovery.txt)

echo "Machine age public key:  ${PUB_MACHINE}"
echo "Recovery age public key: ${PUB_RECOVERY}"

cat << EOF > ~/.config/mise/config.toml
[history.encryption]
recipients = ["${PUB_MACHINE}", "${PUB_RECOVERY}"]

[dotfiles]
"~/.ssh" = { mode = "track", encrypt = true }
"~/.gnupg" = { mode = "track", encrypt = true }
EOF

# Create throwaway SSH key
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub

# Create throwaway GPG key
mkdir -p ~/.gnupg
chmod 700 ~/.gnupg
gpg --batch --passphrase "" --quick-gen-key "Throwaway Key <throwaway@example.com>" default default never
find ~/.gnupg -type f -exec chmod 600 {} +
chmod 700 ~/.gnupg

# Record baseline checksums and permissions for comparison in Exp 3
find ~/.ssh ~/.gnupg -type f -exec sha256sum {} + | sort > /origin/expected-sha256.txt
find ~/.ssh ~/.gnupg ! -type s -exec stat -c "%a %n" {} + | sort > /origin/expected-modes.txt

# Setup bare origin repository
if [ ! -d /origin/history.git ]; then
    git init --bare /origin/history.git
    git -C /origin/history.git symbolic-ref HEAD refs/heads/main
fi

# Connect origin, save checkpoint, and sync
mise dot origin set /origin/history.git --sync manual -y
mise dot save
mise dot sync

echo "=== Experiment 1: Sync completed successfully ==="
