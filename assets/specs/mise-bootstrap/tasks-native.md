<!-- markdownlint-disable -->
# mise-bootstrap, native revision — implementation plan

> **For agentic workers:** execute task by task; steps use checkboxes. Spec: [design.md](./design.md) §10 (and §2,
> §4.1–4.3 for what stands). Evidence: [spike-native.md](./spike-native.md). Old plan: [tasks.md](./tasks.md)
> (Tasks 1–3 stand; the rest is replaced here).

**Goal:** a ~30-line `install`, secrets in mise's encrypted history (private `roalcantara/dots-history`), images
without `install` or secrets, and the old `install`/`prepare-secrets`/archive retired.

**Rules (all tasks):** never run `mise bootstrap` (except `status`/`plan`/`--dry-run`), `mise dot save|sync|apply`
or the new `install` on the host Mac — steps marked **owner** are run by the owner; everything else real runs in
Docker. Throwaway keys only in tests. Signed Conventional Commits (sentence case, ≤72), `git add <paths>`, then
`git commit`. Keep macOS bash 3.2 compatibility. Record one-line findings at the end of this file.

---

### N1: Secrets in the encrypted history (config; owner pushes)

**Files:** Modify `config/mise/config.desktop.toml`, `config/mise/conf.d/dotfiles.toml` (comments only).

- [x] **Step 1:** Append to `config/mise/config.desktop.toml` (recipient = the contents of
  `config/age/recipient.txt`):
```toml
# The SOPS age key is the single root secret: it decrypts this repo's SOPS files and the mise history.
[settings]
age.key_file = "~/.config/age/keys.txt"

[history.encryption]
recipients = ["<contents of config/age/recipient.txt>"]

# Secrets that are not in this repo, synced encrypted to the private origin (design.md §10).
[dotfiles]
"~/.config/ssh" = { mode = "track", encrypt = true, exclude = ["S.*", "s.*", "agent"] }
"~/.config/gnupg" = { mode = "track", encrypt = true, exclude = ["S.*", ".#lk*", "random_seed", "*~"] }
"~/.config/gh/hosts.yml" = { mode = "track", encrypt = true }
```
- [x] **Step 2:** Check read-only on this Mac: `cd ~ && mise dot status -E desktop 2>&1 | tail -20`. Expected: the
  three track entries are listed (not yet saved); no parse error. If `[settings]`/`[history]` are rejected in an
  environment file, move those two tables to `config/mise/config.toml` (containers then know the recipient but
  have no track entries, which is fine) and record it.
- [x] **Step 3:** Commit (`feat(mise): Track ssh, gnupg and gh secrets encrypted`).
- [x] **Step 4 (owner):** connect the origin and push the encrypted history:
```bash
mise dot origin set https://github.com/roalcantara/dots-history.git --sync manual -E desktop
mise dot save -E desktop && mise dot sync -E desktop
```
- [x] **Step 5:** Verify the origin holds no plaintext:
  `d=$(mktemp -d) && git clone -q https://github.com/roalcantara/dots-history.git "$d" && ! git -C "$d" log -p --all | grep -qE 'BEGIN (OPENSSH|PGP) PRIVATE|oauth_token' && echo clean; rm -rf "$d"`.

### N2: Minimal `install` (rewrite)

**Files:** Replace `install`. Delete `assets/integration/install/install.spec.ts` (its cases test the retired
script; N4 tests the new one end to end).

- [x] **Step 1:** Replace `install` with:
```bash
#!/usr/bin/env bash
# Sets up this machine: mise, the dots checkout, the age key, then mise bootstrap (design.md §10).
# curl -fsSL https://raw.githubusercontent.com/roalcantara/dots/main/install | bash
# Env: DOTS_BRANCH (main), DOTS_HISTORY (the private history origin), DOTS_PROFILE (desktop),
#      DOTS_AGE_KEY (the key, for tests; otherwise it is read from the terminal).
set -euo pipefail

MISE_VERSION="2026.10.22"
DOTS="$HOME/.local/share/dots"
KEY="$DOTS/config/age/keys.txt"
BRANCH="${DOTS_BRANCH:-main}"
HISTORY="${DOTS_HISTORY:-https://github.com/roalcantara/dots-history.git}"
PROFILE="${DOTS_PROFILE:-desktop}"
export PATH="$HOME/.local/bin:$PATH"

command -v mise >/dev/null || curl -fsSL https://mise.run | MISE_VERSION="v$MISE_VERSION" sh
[ -d "$DOTS/.git" ] || git clone --branch "$BRANCH" https://github.com/roalcantara/dots.git "$DOTS"

if [ ! -s "$KEY" ]; then
  key="${DOTS_AGE_KEY:-}"
  if [ -z "$key" ]; then
    printf 'Paste the age key (AGE-SECRET-KEY-1...) and press Enter: ' >/dev/tty
    IFS= read -rs key </dev/tty
    printf '\n' >/dev/tty
  fi
  case "$key" in AGE-SECRET-KEY-1*) ;; *) echo "install: that is not an age secret key" >&2; exit 2 ;; esac
  (umask 077 && printf '%s\n' "$key" >"$KEY")
fi

mkdir -p "$HOME/.config"
ln -sfn ../.local/share/dots/config/mise "$HOME/.config/mise"

case "$HISTORY" in
  https://github.com/*)
    mise exec gh@latest -- gh auth status >/dev/null 2>&1 ||
      mise exec gh@latest -- gh auth login --hostname github.com --git-protocol https --web
    mise exec gh@latest -- gh auth setup-git --hostname github.com
    ;;
esac

mise bootstrap --adopt "$HISTORY" -E "$PROFILE" --yes
mise bootstrap -E "$PROFILE" --yes
```
- [x] **Step 2:** `shellcheck install && /bin/bash -n install`. Commit (`refactor(install): Reduce install to mise bootstrap`).

### N3: Images without `install`

**Files:** `distros/{debian,ubuntu}/Dockerfile`, both `container-structure-test.yml`, `config/mise/config.toml`.

- [x] **Step 1:** In both Dockerfiles: base stage installs `tzdata` as root (`apt-get update && apt-get install
  -y --no-install-recommends tzdata && rm -rf /var/lib/apt/lists/*`); drop `DOTS_CONTAINER`. The `local` stage:
```dockerfile
FROM base AS local
USER $USERNAME
COPY --chown=$USERNAME:$USERNAME . /home/$USERNAME/.local/share/dots
RUN --mount=type=secret,id=github_token,uid=1000 \
    export GITHUB_TOKEN="$(cat /run/secrets/github_token 2>/dev/null || true)"; \
    curl -fsSL https://mise.run | MISE_VERSION=v2026.10.22 sh && \
    mkdir -p ~/.config && ln -sfn ../.local/share/dots/config/mise ~/.config/mise && \
    ~/.local/bin/mise bootstrap -E container --force-dotfiles --skip user --yes
WORKDIR /home/$USERNAME
SHELL ["/usr/bin/zsh", "-c"]
ENTRYPOINT ["/usr/bin/zsh", "-il"]
```
  The `remote` stage is the same with `git clone --branch "$BRANCH" https://github.com/${GITHUB_REPO}.git
  ~/.local/share/dots` instead of `COPY`; `publish` stays `FROM local`. `USERNAME` must already exist in the base
  image (`vscode`); drop other user support.
- [x] **Step 2:** CST: repo path `~/Work/dots` → `~/.local/share/dots` (SOPS check), keep the mise and core-tools
  checks; restore the `~/.config/nvim/.venv` and `~/.local/state/nvim` checks.
- [x] **Step 3:** Pipx tools fail on Python 3.15 (Linux arm64, missing wheels): pin `python = "3.13"` in
  `config/mise/config.toml` `[tools]` (check `mise ls python` on the host first, read-only) and make sure the pipx
  backend uses it (`mise settings pipx.uvx`/docs); record what worked.
- [x] **Step 4:** hadolint, yamllint; commit (`refactor(distros): Build images with mise bootstrap alone`).

### N4: End-to-end `install` test in Docker (throwaway history)

**Files:** `assets/specs/mise-bootstrap/e2e/{Dockerfile,run.sh}` (adapt `spike/`).

- [x] Container A: generate a throwaway age key; build a bare history origin on a volume holding encrypted
  throwaway `~/.config/ssh` and `~/.config/gnupg` (as spike experiment 1, recipient = the throwaway key).
- [x] Container B (fresh `vscode` home, branch pushed or `git bundle` of HEAD served as `DOTS_BRANCH`/clone URL —
  if `install` needs a URL override for the repo, add `DOTS_REPO` with default `https://github.com/roalcantara/dots.git`):
  run `DOTS_AGE_KEY=<throwaway> DOTS_HISTORY=/origin/history.git DOTS_PROFILE=container bash install` — expected:
  exit 0; restored secrets byte-identical with modes 700/600; `~/.config/mise` linked; a second run exits 0 and
  writes nothing (`Wrote 0 file(s)`).
- [x] Commit (`test(install): Add an end-to-end run in Docker`).

### N5: Build and verify the images (replaces old Task 7)

- [x] `mise run build --local --distro debian --tag local` (commit first: builds use `git archive HEAD`), then the
  CST (`mise run test --image dots:debian-local --config distros/debian/container-structure-test.yml`), then
  Ubuntu. Formulae failing on Linux arm64 → `env = "desktop"` in `packages.toml`. Record findings.

### N6: Retire the old pieces (after N1 Step 5 and N4 pass)

- [x] Delete `script/prepare-secrets`, `assets/integration/install/prepare-secrets.spec.ts`, `[tasks.prepare]` in
  `mise.toml`, and (owner confirms first) `assets/dump.zip.enc`; keep `*.zip.enc` in `.gitignore`.
- [x] Remove the `--secrets`/`prepare` text from README and DOCKER_GUIDE; describe the new one-liner, the key
  prompt and `dots-history`. Fix DOCKER_GUIDE leftovers (GROUPNAME/`--group`, `wget`, layer caching).
- [x] Remove `flox-environments` from `assets/guides/SKILLS.yml` and run `mise run -C assets skill sync`.
- [x] Commit (`refactor: Retire the secrets archive and the old install`).
- [ ] Owner: delete `assets/dump.zip.enc` once a VM run (N7 or N8) restores the secrets from `dots-history`.

### N7–N9 (owner, manual)

- [x] **N7 Ubuntu VM** (Parallels, snapshot first): `curl -fsSL https://raw.githubusercontent.com/roalcantara/dots/<branch>/install | DOTS_BRANCH=<branch> bash`; paste the key; sign in to GitHub when asked; check links, secrets (modes 700/600), flatpak apps, zsh; rerun (nothing changes).
- [ ] **N8 macOS VM:** the same on a fresh macOS guest.
- [ ] **N9 Reinstall this Mac:** merge to `main`; verify every backup at its destination; reinstall; run the
  one-liner; then delete `config/flox`, `config/bin/purge_flox`, `config/homebrew`, `config/apt`,
  `config/flatpak`, `config/snap`, `distros/alpine` (or port it), and their `dotfiles.toml` exclusions.

## Findings
- N1: mise rejects [dotfiles] tracking in environment files ("tracking is enrolled from the global configuration only"); moved [settings] age.key_file, [history.encryption], and [dotfiles] tracking to config/mise/config.toml.
- N3: pinned python = "3.13" in config/mise/config.toml [tools] and set [settings.pypi] uvx = true (aliased from pipx.uvx) so pipx installs use uvx under Python 3.13.
- N4: Full end-to-end install test passes in Docker; configured [settings.age] identity_files = ["~/.config/age/keys.txt"], skip user shell in container profile, and preserved config.local.toml across adopt.
- N5: Both dots:debian-local and dots:ubuntu-local built and passed all 39 CST tests. Added skills.fetch = false in config.toml to avoid 404s on upstream tool skills, and aligned CST directory permissions for .cache, .local/state, and .local/share with standard 0755.
- N6: Removed the archive builder and the retired install secrets task, kept `assets/dump.zip.enc` as instructed, and updated the install docs to the `curl …/install | bash` flow with the age-key prompt and `dots-history` restore path. `GROUPNAME`/`--group`, `wget`, and layer-caching leftovers were removed from the active docs.
- N6: Removed `flox-environments` from `assets/guides/SKILLS.yml`; `mise run -C assets skill sync` refreshed the registry without unrelated churn.
- N7: Ubuntu 26.04 arm64 VM ran install end to end (secrets restored from dots-history, packages, flatpak apps, zsh, Neovim plugins) after fixes for git, dpkg prompts, /etc/flatpak, Discord (x64 only), chsh under curl|bash, cc for cargo, pynvim (pipx:pynvim), brew tools off PATH in the task and in shells, and flatpak installed before mise.
