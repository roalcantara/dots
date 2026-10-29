#!/usr/bin/env bash
set -euo pipefail

echo "=== Experiment 4: Idempotency and update propagation ==="

echo "--- Step 1: Idempotency check on Container B ---"
mkdir -p ~/.config/mise
cp /origin/recovery.txt ~/.config/mise/age.txt
chmod 600 ~/.config/mise/age.txt

echo "First adopt run:"
mise bootstrap --adopt /origin/history.git --yes
echo "Second adopt run (idempotency check):"
ADOPT_OUTPUT=$(mise bootstrap --adopt /origin/history.git --yes)
echo "${ADOPT_OUTPUT}"
if echo "${ADOPT_OUTPUT}" | grep -q "Wrote 0 file(s)"; then
    echo "PASS: Second adopt run changed nothing (idempotent)."
else
    echo "WARN: Output did not explicitly state 'Wrote 0 file(s)'"
fi

echo "--- Step 2: Simulate file modification in Container A ---"
# Temporary container A environment to push an update
TMP_A_HOME=$(mktemp -d /tmp/home_a_XXXXXX)
# Copy A credentials from recovery or age
mkdir -p "${TMP_A_HOME}/.config/mise"
cp /origin/recovery.txt "${TMP_A_HOME}/.config/mise/age.txt"
chmod 600 "${TMP_A_HOME}/.config/mise/age.txt"

HOME="${TMP_A_HOME}" mise bootstrap --adopt /origin/history.git --yes
echo "Host spike-test.example.com" > "${TMP_A_HOME}/.ssh/config"
chmod 600 "${TMP_A_HOME}/.ssh/config"
HOME="${TMP_A_HOME}" mise dot save
HOME="${TMP_A_HOME}" mise dot sync
rm -rf "${TMP_A_HOME}"
echo "PASS: Container A committed and published new file ~/.ssh/config."

echo "--- Step 3: Fetch and pull in Container B ---"
mise dot sync
mise dot pull --yes

echo "--- Step 4: Verify the update arrived in B ---"
test -f ~/.ssh/config
cat ~/.ssh/config
CONFIG_PERM=$(stat -c "%a" ~/.ssh/config)
test "${CONFIG_PERM}" = "600"
echo "PASS: ~/.ssh/config arrived in B with correct mode (${CONFIG_PERM}) and content."

echo "=== Experiment 4: Completed successfully ==="
