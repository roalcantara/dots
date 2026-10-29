#!/usr/bin/env bash
set -euo pipefail

echo "=== Experiment 3: Fresh container B recovery via recovery identity ==="

# Fresh home has no .ssh or .gnupg
test ! -d ~/.ssh
test ! -d ~/.gnupg

mkdir -p ~/.config/mise
cp /origin/recovery.txt ~/.config/mise/age.txt
chmod 600 ~/.config/mise/age.txt

echo "Running mise bootstrap --adopt from origin repository..."
mise bootstrap --adopt /origin/history.git --yes

echo "--- Verifying checksums against Container A ---"
find ~/.ssh ~/.gnupg -type f -exec sha256sum {} + | sort > /tmp/restored-sha256.txt
diff -u /origin/expected-sha256.txt /tmp/restored-sha256.txt
echo "PASS: All restored files match Container A checksums bit-for-bit."

echo "--- Verifying modes and permissions ---"
find ~/.ssh ~/.gnupg ! -type s -exec stat -c "%a %n" {} + | sort > /tmp/restored-modes.txt
diff -u /origin/expected-modes.txt /tmp/restored-modes.txt
echo "PASS: Directory (700) and file (600) permissions match exactly."

echo "--- Verifying key usability ---"
echo "Testing SSH private key with ssh-keygen -y:"
SSH_PUB=$(ssh-keygen -y -f ~/.ssh/id_ed25519)
echo "  Public key derived: ${SSH_PUB}"
test -n "${SSH_PUB}"

echo "Testing GPG secret keys with gpg --list-secret-keys:"
gpg --list-secret-keys "throwaway@example.com"
echo "PASS: GPG secret keys unlocked and recognized."

echo "=== Experiment 3: Recovery succeeded ==="
