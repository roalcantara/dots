#!/usr/bin/env bash
set -euo pipefail

echo "=== Experiment 5: Bootstrap dots repo directly with mise bootstrap --from ==="

BUNDLE_PATH="/origin/dots.bundle"
if [ ! -f "${BUNDLE_PATH}" ]; then
    echo "ERROR: ${BUNDLE_PATH} not found. Prepare the bundle on the volume before running." >&2
    exit 1
fi

echo "--- Part 1: Running the exact documented command ---"
set +e
EXACT_OUT=$(mise bootstrap --from "${BUNDLE_PATH}" --from-dir ~/Work/dots --config-dir config/mise -E container --skip user --yes 2>&1)
EXACT_CODE=$?
set -e

echo "${EXACT_OUT}"
echo "Exit code: ${EXACT_CODE}"

if [ "${EXACT_CODE}" -ne 0 ]; then
    echo "OBSERVATION: Exact command fails as anticipated."
    if echo "${EXACT_OUT}" | grep -q "sources do not exist"; then
        echo "Root cause: config/mise/conf.d/dotfiles.toml points to ~/.local/share/dots while --from-dir is ~/Work/dots."
  fi
    if echo "${EXACT_OUT}" | grep -q "refusing to overwrite existing files"; then
        echo "Root cause: Base image ~/.bashrc and ~/.profile require --force-dotfiles."
  fi
fi

echo "--- Part 2: Running with necessary workarounds to complete bootstrap ---"
mkdir -p ~/.local/share
ln -sfn ~/Work/dots ~/.local/share/dots

echo "Running bootstrap with --force-dotfiles and skipping failing pipx tools (Python 3.15 wheel compatibility)..."
mise bootstrap --from "${BUNDLE_PATH}" --from-dir ~/Work/dots --config-dir config/mise -E container --skip user,tools --yes --force-dotfiles

echo "--- Part 3: Verifying CST Command Checks ---"
for t in curl jq zsh git; do
    which "$t"
done

echo "Checking core tools installed by Homebrew/mise:"
for t in age bat eza fd fzf jq nvim rg sops starship zoxide; do
    command -v "$t" > /dev/null || {
                                    echo "FAIL: missing $t" >&2
                                                                 exit 1
  }
    echo "  $t: $(command -v "$t")"
done

echo "Checking SOPS-filtered private keys:"
ls ~/Work/dots/config/ssh/keys/*.key > /dev/null
if grep -q "BEGIN OPENSSH PRIVATE KEY" ~/Work/dots/config/ssh/keys/*.key; then
    echo "FAIL: SOPS key is unencrypted!" >&2
    exit 1
fi
echo "PASS: SOPS keys remain properly encrypted."

echo "--- Part 4: Verifying Key Directory and Symlink Structures ---"
test -L ~/.zshenv
test -L ~/.bashrc
test -L ~/.config/nvim
test -L ~/.config/git
test -L ~/.config/starship
test -d ~/Desktop && test "$(stat -c %a ~/Desktop)" = "700"
test -d ~/Documents && test "$(stat -c %a ~/Documents)" = "700"
test -d ~/Downloads && test "$(stat -c %a ~/Downloads)" = "700"
test -d ~/Work && test "$(stat -c %a ~/Work)" = "755"

echo "=== Experiment 5: Finished with evidence recorded ==="
