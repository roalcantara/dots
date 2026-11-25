# Secrets from gopass through fnox — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** zsh loads `OPENAI_API_KEY`, `ANTHROPIC_API_KEY` and `DEEPSEEK_API_KEY` from gopass
through a global fnox config, `config/.env` is gone, and `GUM_LOG_*` live in `env.zsh`.

**Architecture:** `config/fnox/config.toml` (linked as `~/.config/fnox`) maps the three variables to gopass entries;
`sys::secrets` in `config/zsh/opt/rc.d/sys.zsh` evaluates `fnox activate zsh`, whose prompt hook exports them in every
directory. The repo's `fnox.toml` keeps `DEVTO_TOKEN` for `fnox get` only (`env = false`).

**Tech Stack:** fnox 1.50.0 (Homebrew, `config/homebrew/Brewfile:75`), gopass, zsh, mise `[dotfiles]` links.

**Spec:** `docs/superpowers/specs/2026-11-24-secrets-fnox-design.md`

## Global Constraints

- Worktree `/Users/roalcantara/.local/share/dots-secrets-fnox`, branch `feat/secrets-fnox` (from `origin/main` at
  `f41199b`). Never push or open a pull request.
- Git through the wrapper: `g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }`. For `hk` and
  `mise run test:specs`, first
  `export GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=filter.sops.clean GIT_CONFIG_VALUE_0=cat GIT_CONFIG_KEY_1=filter.sops.smudge GIT_CONFIG_VALUE_1=cat`.
- Never print, log or commit a secret value. Allowed: `fnox check`, `fnox env --json --describe`, `fnox list` without
  `--values`, `[[ -n $VAR ]]` tests. Forbidden: `fnox get` on the three keys, `fnox export`, `env`/`printenv` dumps,
  `cat config/.env`. To read `config/.env`, only `grep '^GUM_LOG_' config/.env` (styling, not secrets).
- The three keys, exactly: `OPENAI_API_KEY` → `tokens/openai.com`, `ANTHROPIC_API_KEY` → `tokens/anthropic.com`,
  `DEEPSEEK_API_KEY` → `tokens/DEEPSEEK_API_KEY`; each `provider = "gopass"`, `line = 1`, `if_missing = "ignore"`.
  `WAKATIME_API_KEY` is not carried over: the wakatime CLI reads `config/wakatime/.wakatime.cfg`, left as is.
- Commits: Conventional, capitalised, subject ≤ 50 characters, body at 72, ending
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Exactly one `feat` commit on the branch (Task 2's), so the
  merge cuts one minor release.
- `mise run zsh:verify` reads `~/.config/zsh` (the main checkout), not this worktree: verify this branch's zsh with
  `ZDOTDIR=$PWD/config/zsh`, as the steps below do.
- No tests that pin config values (owner's rule); verify behaviour with the commands below.

## Review Focus

1. **gopass unavailable or failing** (Docker images, a fresh Mac before the store is cloned): a new shell prints
   nothing on stderr and simply lacks the keys. Task 2 Step 4 checks it with a failing `gopass` stub.
2. **`DEVTO_TOKEN` leaking into the shell inside dots.** Task 1 Step 3 checks `fnox env --json --describe`.
3. **Startup noise before p10k's instant prompt:** the hook must print nothing (`FNOX_SHELL_OUTPUT=none`). Task 2
   Step 3 checks a new shell's stderr and stdout are empty.
4. **Retired variables still set** from a stale `~/.config/.env` link on the Mac after the merge. Task 3 removes the
   link entry; Task 5 lists `rm ~/.config/.env` among the author's after-merge steps (mise `[dotfiles]` doesn't delete
   links it no longer lists; the builder confirms with `mise help dotfiles` or the docs and says so).
5. **A bootstrap or image break** from the link list change. Task 4 builds one image and runs its CST.

---

### Task 1: The global fnox config, its link, and `DEVTO_TOKEN` kept out of the shell

**Files:**

- Create: `config/fnox/config.toml`
- Modify: `config/mise/conf.d/dotfiles.toml` (add `"~/.config/fnox"` in alphabetical order, same shape as the
  `gopass` row), `fnox.toml` (`DEVTO_TOKEN` gains `env = false`)

**Interfaces:** Produces the global config Task 2's hook loads.

- [ ] **Step 1: Write `config/fnox/config.toml`**

A comment header (what it is, that values stay in gopass, that `~/.config/fnox` links here), `[providers.gopass]
type = "gopass"`, and the three `[secrets]` from Global Constraints, each with a `description` naming its consumer
(`OPENAI_API_KEY`/`ANTHROPIC_API_KEY`: "Neovim LLM providers and CLIs"; `DEEPSEEK_API_KEY`: "external tools").

- [ ] **Step 2: Check the config resolves, without values**

Run: `XDG_CONFIG_HOME=$PWD/config fnox check --all --non-interactive`
Expected: `✓ Configuration is healthy`, exit 0.

- [ ] **Step 3: Hide `DEVTO_TOKEN` from the shell and check it**

Add `env = false` to `DEVTO_TOKEN` in `fnox.toml`.
Run: `XDG_CONFIG_HOME=$PWD/config fnox env --json --describe | jq -c '.keys[] | {key, env, shell: .injectable.shell}'`
Expected: the three keys with `env: true, shell: true`; `DEVTO_TOKEN` with `env: false, shell: false`.
Run: `fnox get DEVTO_TOKEN >/dev/null && echo resolves` → `resolves` (the blog tasks' path still works).

- [ ] **Step 4: Lint and commit**

Run: `hk check --all` → exit 0 (taplo and tombi cover the TOML).

```bash
g add config/fnox/config.toml config/mise/conf.d/dotfiles.toml fnox.toml
g commit -m "chore(fnox): Map the API keys to gopass"
```

---

### Task 2: Load the keys in zsh with fnox; `GUM_LOG_*` in `env.zsh`

**Files:**

- Modify: `config/zsh/opt/rc.d/sys.zsh` (replace `sys::dotenv` and its call at the end with `sys::secrets`;
  `#DECLARES` and `#ABOUT` follow), `config/zsh/opt/rc.d/env.zsh` (new `env::gum` with the 16 `GUM_LOG_*` exports,
  called after `env::editor`; `#DECLARES` follows), `config/zsh/.zshrc:27,30` (the two comments),
  `config/zsh/README.md` (the `sys.zsh` and `env.zsh` rows)

**Interfaces:** Consumes Task 1's config. Produces `sys::secrets()`: no arguments; returns 0 without output when
`_has_command fnox` is false; otherwise sets `FNOX_SHELL_OUTPUT=none` (only if unset) and evaluates
`fnox activate zsh`.

- [ ] **Step 1: Copy the styling variables**

`grep '^GUM_LOG_' config/.env` gives the 16 lines; write them into `env::gum` as `export NAME=value`, same order.
Nothing else from `config/.env` is read.

- [ ] **Step 2: Write `sys::secrets` and drop `sys::dotenv`**

As in Interfaces. Keep the file's style (`#ABOUT`, `#ORDER` comments like its neighbours). Recompile nothing by hand:
the `.zwc` files are rebuilt at startup.

- [ ] **Step 3: Check a new shell of this branch has the keys, quietly**

```bash
export XDG_CONFIG_HOME=$PWD/config   # until the ~/.config/fnox link exists
ZDOTDIR=$PWD/config/zsh zsh -ic 'for f in $precmd_functions; do $f; done
  for k in OPENAI_API_KEY ANTHROPIC_API_KEY DEEPSEEK_API_KEY GUM_LOG_LEVEL_FOREGROUND; do
    [[ -n ${(P)k} ]] && echo "set $k" || echo "MISSING $k"; done
  for k in GEMINI_API_KEY BW_PASSWORD DEVTO_TOKEN; do [[ -z ${(P)k} ]] && echo "unset $k" || echo "LEAK $k"; done' \
  2>"$TMPDIR/secrets.err"; echo "stderr bytes: $(wc -c < "$TMPDIR/secrets.err")"
```

Expected: four `set` lines, three `unset` lines, `stderr bytes: 0`. Run it from the worktree root (inside dots) and
again from `$HOME` (outside): same result. If the live `~/.config/.env` still exports the retired names in this
shell, the `unset` lines prove only that this branch no longer sources it; that is the point.

- [ ] **Step 4: Check the shell stays quiet without gopass**

Create a stub `$TMPDIR/nogopass/gopass` (`#!/bin/sh` + `exit 1`, executable) and rerun Step 3's command with
`PATH="$TMPDIR/nogopass:$PATH"`.
Expected: the three keys `MISSING`, `GUM_LOG_LEVEL_FOREGROUND` `set`, `stderr bytes: 0`.

- [ ] **Step 5: Syntax and commit**

Run: `zsh -n config/zsh/opt/rc.d/sys.zsh config/zsh/opt/rc.d/env.zsh` → no output; `hk check --all` → exit 0.

```bash
g add config/zsh/opt/rc.d/sys.zsh config/zsh/opt/rc.d/env.zsh config/zsh/.zshrc config/zsh/README.md
g commit -m "feat(zsh): Load API keys from gopass with fnox"
```

Body: the three keys and where they come from; `GUM_LOG_*` moved to `env::gum`; the other secrets are retired (the
list of names from the spec's Goals 4, names only).

---

### Task 3: Retire `config/.env`

**Files:**

- Delete: `config/.env`
- Modify: `config/mise/conf.d/dotfiles.toml` (remove the `"~/.config/.env"` row), `README.md:140,221`,
  `AGENTS.md:46`, `docs/CONTRIBUTING.md:26` (the staging rule names `config/.env`), `.sops.yaml` and `.gitattributes`
  comments that name `config/.env` (keep any rule other files still need: check `.sops.yaml` creation rules and
  `.gitattributes` patterns for `*.env` before touching them)

- [ ] **Step 1: Delete and unlink**

`g rm config/.env`; remove the dotfiles row.

- [ ] **Step 2: Rewrite the references**

Run: `g grep -n 'config/\.env\|\.config/\.env' -- ':!docs/blog' ':!docs/superpowers' ':!config/kodexb'`
Fix each hit: secrets now come from gopass through fnox (`config/fnox/config.toml`); the remaining SOPS files are
the ones under `config/ssh/keys`, `config/gopass`, `config/age` (name what `.sops.yaml` actually covers).
Expected after: no hits.

- [ ] **Step 3: Check bootstrap specs and lint, then commit**

Run: `mise run test:specs` → all pass except the 16 `usage-completions.spec.ts` cases, which fail in any worktree
(they embed the absolute repo path); anything else failing is a finding to report. `hk check --all` → exit 0.

```bash
g add config/.env config/mise/conf.d/dotfiles.toml README.md AGENTS.md docs/CONTRIBUTING.md .sops.yaml .gitattributes
g commit -m "chore(secrets): Retire config/.env"
```

(Stage `.sops.yaml` and `.gitattributes` only if Step 2 changed them.)

---

### Task 4: One image and its structure tests

- [ ] **Step 1: Build and test Debian**

```bash
export DOCKER_HOST=$(docker context inspect --format '{{.Endpoints.docker.Host}}')
mise run build --local --distro debian
mise run test --image dots:debian-<tag printed by the build> --config distros/debian/container-structure-test.yml
```

Expected: the build succeeds and CST passes. A failure caused by this branch is fixed in the task that owns the
file, as a new commit; one that also fails on `origin/main` is reported, not fixed.

---

### Task 5: Hand back

- [ ] **Step 1: Check the branch**

Run: `g log --oneline origin/main..HEAD` → the spec and plan commit, then Tasks 1–3 (exactly one `feat`). Run:
`g status --short` → empty.

- [ ] **Step 2: Report**

Each commit; the outputs of Task 1 Steps 2–3 and Task 2 Steps 3–4 (they contain names, never values); the test,
lint and CST results; and the author's after-merge steps:

1. `mise run bootstrap` (or `mise dotfiles` apply) creates `~/.config/fnox`; `rm ~/.config/.env` if it remains.
2. A new terminal has the three keys (and still no `WAKATIME_API_KEY`: wakatime keeps working from its `.cfg`); `mise run zsh:verify` — expect parity diffs only for `sys::dotenv` →
   `sys::secrets`, the fnox precmd hook, and the retired variable names under ENV; recapture the baseline after
   checking them (`./script/zsh-verify.sh baseline`).
3. The release: the run on `main` cuts 1.52.0, the GitHub Release has the `feat(zsh)` entry, the PR gets the
   "included in version 1.52.0" comment, and `publish.yml` runs for `v1.52.0`.
4. Revoke the retired tokens that still work (spec, "For the author").
