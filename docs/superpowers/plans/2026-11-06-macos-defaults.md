# macOS defaults Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** `mise bootstrap` applies a commented, documented set of macOS preferences tuned for keyboard-driven
development, plus noTunes so a Bluetooth headset no longer opens Apple Music.

**Architecture:** A new `config/mise/conf.d/macos.toml` holds mise's native `bootstrap.macos` sections (named keys
first, raw `defaults` next, `defaults_entries` for `-currentHost`/nested keys), a `post-defaults` hook and the
screenshots directory. `docs/MACOS.md` documents it. A Bun spec pins the values Raycast/yabai rely on.

**Tech Stack:** mise 2026.11.3 (`mise bootstrap macos defaults`), TOML, Homebrew Brewfile, Bun test.

**Spec:** [`docs/superpowers/specs/2026-11-06-macos-defaults-design.md`](../specs/2026-11-06-macos-defaults-design.md)

## Global Constraints

- Worktree `~/Work/dots-macos`, branch `feat/macos-defaults`. Git via `g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }`; stage named paths only.
- Preferences only: no `sudo`, no `defaults write` scripts. Values exactly as in the spec's Settings table.
- Every setting has a one-line *why* comment above it (repo comment style: plain sentences, no headers banners).
- Nothing may change Linux bootstraps or Docker images; the hook exits 0 on non-macOS and never fails.
- The existing `org.gpgtools.common` entry stays in `bootstrap.toml`.
- Conventional Commits, capitalized description; end each commit with the attribution trailer.
- Test the worktree's config, not the linked one: run `mise bootstrap macos …` from a scratch project whose
  `.config/mise/conf.d/macos.toml` links to the worktree file (mise ignores `MISE_CONFIG_DIR` for `conf.d`).

## Review Focus

- A key that macOS 27 renamed or ignores: dry-run must show no warnings; the doc lists anything dropped.
- Integers vs booleans vs floats: mise treats `1` ≠ `true`, so a wrong TOML type re-applies on every bootstrap
  (`status --missing` exits 1 right after apply). Pinned by Task 1's type assertions and Task 3's status check.
- The hotkey dictionary: `key = "AppleSymbolicHotKeys"`, `path = ["64"]` (path is relative to key) replaces only key 64; other symbolic hotkeys survive.
  Checked in Task 3 by reading key `65` (or any other present key) before and after apply.
- Hook on a machine where Dock/Finder are not running or `activateSettings` is missing: still exits 0 (Task 1 test).
- Screenshot `location` must be an absolute path that exists; mise writes values verbatim (no `~`, no templates), so
  the hook writes it with `$HOME`. Pinned by Task 1 (hook test; directory declared, macOS only).

---

### Task 1: `macos.toml` preferences, hook, and spec

**Files:**
- Create: `config/mise/conf.d/macos.toml`
- Create: `test/integration/bootstrap/macos-defaults.spec.ts`

**Interfaces:**
- Produces: `config/mise/conf.d/macos.toml` with `bootstrap.macos.{keyboard,trackpad,dock,finder,defaults,login_items}`,
  `[[bootstrap.macos.defaults_entries]]`, `[bootstrap.hooks.post-defaults] run`, and
  `[bootstrap.directories."~/Pictures/Screenshots"]`. Tasks 2–3 rely on these table names.

- [x] **Step 1: Write the failing spec** (`describe("macOS defaults (config/mise/conf.d/macos.toml)")`, parse with
  `Bun.TOML.parse` as in `gopass-keyring.spec.ts`):
  - `keyboard`: `key_repeat === 2`, `initial_key_repeat === 15`, `press_and_hold === false`.
  - `dock`: `autohide === true`, `mru_spaces === false`, `show_recents === false`.
  - `trackpad.three_finger_drag === false`, `trackpad.tap_to_click === true`.
  - `defaults["com.apple.WindowManager"]`: `EnableTilingByEdgeDrag`, `EnableTopTilingByEdgeDrag`,
    `EnableTilingOptionAccelerator`, `GloballyEnabled`, `EnableStandardClickToShowDesktop` all `=== false`.
  - `defaults["com.apple.spaces"]["spans-displays"] === false`.
  - an entry in `defaults_entries` with `domain === "com.apple.symbolichotkeys"`,
    `key === "AppleSymbolicHotKeys"`, `path` equal to `["64"]`, value
    `{ enabled: true, value: { parameters: [32, 49, 524288], type: "standard" } }`, and
    `Number.isInteger` on each parameter.
  - an entry `domain === "com.apple.ImageCapture"`, `key === "disableHotPlug"`, `host === "current"`, `value === true`.
  - `defaults.NSGlobalDomain["com.apple.trackpad.scaling"] === 3` and `["com.apple.mouse.scaling"] === 3`
    (written as `3.0` in TOML so it is a real); `AppleKeyboardUIMode === 3`.
  - `com.apple.screencapture` has no `location`; `bootstrap.directories."~/Pictures/Screenshots"` has `os = "macos"`;
    the hook writes `location` as `$HOME/Pictures/Screenshots`.
  - `login_items.apps` contains `"/Applications/noTunes.app"` and `login_items.exclusive` is not `true`.
  - hook: run `bootstrap.hooks["post-defaults"].run` via `Bun.spawnSync(["bash","-c", run])` with
    `PATH` set to an empty temp `bin` plus `/usr/bin:/bin` minus `killall` (stub `killall` and `uname` there:
    `uname` prints `Linux`) → exit 0 and stub `killall` never called; with `uname` printing `Darwin` and a
    `killall` stub that exits 1 → still exit 0.
- [x] **Step 2: Run it, expect FAIL** — `bun test test/integration/bootstrap/macos-defaults.spec.ts` (file not found).
- [x] **Step 3: Write `macos.toml`** with every row of the spec's Settings table, one *why* comment each. Use named
  keys where mise has them; `[bootstrap.macos.defaults]` for the rest (quote dotted domains; `NSGlobalDomain`
  for globals); `defaults_entries` for the hotkey (`path`) and `disableHotPlug` (`host = "current"`). Screenshot
  location written by the hook (mise does not render templates in values). Hook:
  `#!/usr/bin/env bash`, `[ "$(uname)" = Darwin ] || exit 0`, the screenshot `defaults write`, then
  `/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u` and
  `killall Dock Finder SystemUIServer`, each `|| true`.
- [x] **Step 4: Run it, expect PASS** — same command.
- [x] **Step 5: Dry-run** — `mise bootstrap macos defaults apply --dry-run`. Expected: one write per declared
  preference, `-currentHost` on `disableHotPlug`, **no warnings**. For any warning: fix the type, or drop the key
  and note it for Task 2.
- [x] **Step 6: Commit** — `g add config/mise/conf.d/macos.toml test/integration/bootstrap/macos-defaults.spec.ts`;
  `feat(macos): Declare macOS defaults for keyboard-driven development`.

### Task 2: noTunes and `docs/MACOS.md`

**Files:**
- Modify: `config/homebrew/Brewfile` (desktop casks, alphabetical, near `cask "raycast"`)
- Create: `docs/MACOS.md`
- Modify: `README.md` (task table near line 181, docs list near line 223), `AGENTS.md` (Docs list)

**Interfaces:**
- Consumes: Task 1's `login_items.apps` entry for `/Applications/noTunes.app`.

- [x] **Step 1:** Add `cask "notunes" if OS.mac?  # Stops Apple Music opening when headphones connect`.
- [x] **Step 2:** Confirm the order: `mise bootstrap --help` / docs show packages before defaults, so the app exists
  when login items apply. If not, note in the doc that the first bootstrap may warn and a rerun fixes it.
- [x] **Step 3: Write `docs/MACOS.md`** with sections: *What is managed* (point to `macos.toml`; areas, one line
  each, † items for Raycast/yabai); *Preview, apply, check* (`apply --dry-run`, `apply`, `status --missing`,
  `mise doctor`); *Needs a logout* (key repeat); *Undo a setting* (mise never deletes: remove it from
  `macos.toml`, then `defaults delete <domain> <key>`; `-currentHost` for host entries); *Apple Music and
  headphones* (why no preference exists, noTunes, quit it to open Music); *Manual checklist* (hostname via
  `scutil`, FileVault, firewall, `pmset`, Raycast login item/hotkey, hot corners, Dock apps); *Dropped keys*
  (from Task 1 Step 5, or "none").
- [x] **Step 4:** Link it: README task table row "Set or check macOS preferences → [macOS guide](docs/MACOS.md)",
  README and AGENTS.md docs lists.
- [x] **Step 5: Gate** — `hk check --all` passes (markdownlint, taplo, Brewfile untouched by linters otherwise).
- [x] **Step 6: Commit** — named paths; `feat(macos): Add noTunes and document the macOS defaults`.

### Task 3: Apply on this Mac and verify

- [x] **Step 1:** `brew install --cask notunes`.
- [x] **Step 2:** Record a non-64 hotkey: `defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys` (save output).
- [x] **Step 3:** `mise bootstrap macos defaults apply --yes`, then run the hook body once by hand (or
  `mise bootstrap` if it can target only the defaults step).
- [x] **Step 4:** `mise bootstrap macos defaults status --missing` → exit 0. Rerun `apply --dry-run` → no writes.
- [x] **Step 5:** Hotkeys other than `64` still present and unchanged versus Step 2.
- [x] **Step 6 (owner):** Log out/in; check key repeat speed, ⌥Space → Spotlight, ⌘Space → Raycast (set in
  Raycast if not yet), Dock autohides, tap-to-click, screenshot lands in `~/Pictures/Screenshots`, headset
  connect leaves Music closed. Record anything off in `docs/MACOS.md` and fix in `macos.toml`.

### Task 3b: SSH key in Keychain (added after review)

**Files:** Modify `config/mise/conf.d/bootstrap.toml` (`# ssh-keychain` snippet after `# gopass-keyring: end`),
`config/mise/conf.d/macos.toml` (`[bootstrap.macos.launchd.agents.ssh-add]`), `docs/MACOS.md`, `config/ssh/README.md`.
Test: `test/integration/bootstrap/ssh-keychain.spec.ts`, `macos-defaults.spec.ts`.

- [x] **Step 1:** Failing specs: snippet after `$desktop || exit 0`; off macOS / no key file → no `ssh-add` calls; key in
  agent → silent; in Keychain → `--apple-load-keychain`, no prompt; neither and no terminal → prints
  `ssh-add --apple-use-keychain <key>`, exit 0. Agent: program `/usr/bin/ssh-add`, args `["--apple-load-keychain"]`,
  `run_at_load = true`.
- [x] **Step 2:** Implement (stub dir via `DOTS_SSH_BIN`, default `/usr/bin`); specs green.
- [x] **Step 3:** `mise bootstrap macos launchd-agents apply`; status `loaded`.
- [x] **Step 4 (owner):** `ssh-add --apple-use-keychain ~/.ssh/id_ed25519_github` once; `ssh-add -l` lists it.

### Task 3c: Touch ID for sudo, default apps, Dock and login items (added after review)

**Files:** `config/mise/conf.d/macos.toml` (`[bootstrap.files."/etc/pam.d/sudo_local"]`, `dock.apps`, `login_items`,
duti in the hook), `config/duti/defaults.duti`, `config/mise/conf.d/dotfiles.toml`, `config/homebrew/Brewfile`,
`docs/MACOS.md`. Tests: `macos-defaults.spec.ts`, `duti.spec.ts`.

- [x] **Step 1:** Failing specs: sudo_local `{os: macos, owner: root, group: wheel, mode: 0444, phase: pre-packages}`
  with `auth sufficient pam_tid.so`; exact Dock and login-item lists, each a Brewfile cask; hook runs
  `duti ~/.config/duti/defaults.duti`; duti file format (tabs, role `all`, no `dyn.*`, no `.ts` video UTI).
- [x] **Step 2:** Implement; specs green; dry-run clean.
- [x] **Step 3:** Apply Dock, login items and duti on this Mac; `status --missing` exits 0.
- [x] **Step 4 (owner):** `mise bootstrap files apply` (sudo) for Touch ID; `sudo -k; sudo true` takes a fingerprint.

### Task 4: Gates and close-out

- [x] **Step 1:** `mise run test:specs` and `hk check --all` green (note pre-existing failures, if any, as such).
- [x] **Step 2:** Tick this plan's boxes; commit the plan and spec (`docs(macos): …`).
- [x] **Step 3:** Stop. Push/PR only when the owner asks.
