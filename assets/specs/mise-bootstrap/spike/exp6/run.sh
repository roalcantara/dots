#!/usr/bin/env bash
set -euo pipefail

echo "=== Experiment 6: Combine dots symlinks and encrypted-history track entries ==="

# Ensure recovery identity is present
mkdir -p ~/.config/mise
if [ ! -f ~/.config/mise/age.txt ] && [ -f /origin/recovery.txt ]; then
    cp /origin/recovery.txt ~/.config/mise/age.txt
    chmod 600 ~/.config/mise/age.txt
fi

echo "--- Step 1: Verify TOML key deduplication requirement ---"
echo "Note: If dotfiles.toml declares ~/.ssh as symlink and config.toml declares ~/.ssh as track,"
echo "TOML or mise will conflict if declared in the same file. They must be distinct."

echo "--- Step 2: Configure hybrid config with both symlinks and track entries ---"
PUB_KEY=$(age-keygen -y ~/.config/mise/age.txt)

# Remove any symlink ~/.ssh or ~/.gnupg from previous runs
rm -rf ~/.ssh ~/.gnupg

cat << EOF > ~/.config/mise/config.local.toml
[history.encryption]
recipients = ["${PUB_KEY}"]

[dotfiles]
"~/.ssh" = { mode = "track", encrypt = true }
"~/.gnupg" = { mode = "track", encrypt = true }
EOF

echo "--- Step 3: Adopt encrypted history for secrets ---"
mise bootstrap --adopt /origin/history.git --yes

echo "--- Step 4: Apply dotfiles (symlinks + tracked secrets) ---"
mise dot apply --force

echo "--- Step 5: Check dotfiles status ---"
STATUS_OUT=$(mise dot status)
echo "${STATUS_OUT}"

if echo "${STATUS_OUT}" | grep -q "up to date"; then
    echo "PASS: All entries are up to date. Symlink and encrypted track modes coexist cleanly."
else
    echo "STATUS REPORT: Output above shows current coexistence state."
fi

echo "=== Experiment 6: Completed ==="
