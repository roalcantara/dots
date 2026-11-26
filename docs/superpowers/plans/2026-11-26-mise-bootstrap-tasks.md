# mise bootstrap file tasks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Clear mise's `deprecated-key` diagnostics, catch mise version drift, move every bootstrap shell block into
small idempotent file tasks under `.mise/tasks/bootstrap/`, and make `docs/BOOTSTRAP.md` the single source on
`mise bootstrap`.

**Architecture:** Declarative `[bootstrap.*]` keys stay in `config/mise/conf.d/`. Each phase has exactly one hook (in
`bootstrap.toml`) plus the global `[tasks.bootstrap]`, and each only hands over to a repo phase task
(`bootstrap:hook:<phase>` in `.mise/tasks/bootstrap/phases.toml`). That phase task runs bash step tasks
(`.mise/tasks/bootstrap/<area>/<step>.sh`) in order, each with `#MISE` headers.

**Tech Stack:** mise 2026.11.14 (file tasks, TOML task files, run steps, `skip_if`, `sources`, `[doctor.checks]`,
`mise lsp`), bash, Bun specs (`bun:test`), hk.

**Spec:** [`docs/superpowers/specs/2026-11-26-mise-bootstrap-tasks-design.md`](../specs/2026-11-26-mise-bootstrap-tasks-design.md).
It is the only source of architectural decisions. Read it before Task 1. Where this plan and the spec disagree, the
spec wins: stop and report.

## Global Constraints

- Branch `feat/mise-bootstrap-tasks`, no worktree. Lida task `awGX` in `TODO.yaml`.
- git always through the SOPS wrapper: `g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }`. Stage
  named paths only, never `git add -A`/`.`. Conventional Commits, capitalized description, ending with the
  `Co-Authored-By` line from the session's attribution reminder. No push and no PR.
- mise pin: `2026.11.14` everywhere (`install`, `distros/{debian,ubuntu}/Dockerfile`). `min_version = "2026.11.8"`.
- Task names: steps `bootstrap:<area>:<step>` (from `.mise/tasks/bootstrap/<area>/<step>.sh`), phases
  `bootstrap:hook:post-packages|pre-dotfiles|post-dotfiles|post-defaults|final`.
- Every step: `#!/usr/bin/env bash`, executable, a `#MISE description="…"`, sources `../_lib.sh` with
  `. "${BASH_SOURCE%/*}/../_lib.sh"`, passes shellcheck (`.shellcheckrc`) and `shfmt -d`.
- Soft failure = `warn "<what>"` then continue, exit 0. Hard failure (core brew group, or `warn` while `DOTS_STRICT` or
  `CI` is non-empty) = exit 1.
- Platform/profile guards sit at the top of a step and `exit 0` when it does not apply. Profile names: `desktop`,
  `dev`, `container`. With no profile set, the default is `desktop`.
- Keep every existing `DOTS_*` test seam: `DOTS_SSH_BIN`, `DOTS_CSRUTIL`, `DOTS_YABAI`, `DOTS_ACTIVATE_SETTINGS`,
  `DOTS_VSCODE_USER`, `DOTS_VSCODE_STATE`, `DOTS_SKILLS_FOREGROUND`, `DOTS_DIR`, `DOTS_STRICT`.
- Specs test behaviour, never the owner's chosen config values (no asserting a theme, a model list or a commit pin).
- Gates before each commit: the task's specs, `hk check` on the touched files. Before the handoff:
  `mise run test:specs`, `hk check --all`, `mise run zsh:verify` syntax, the two distro builds plus CST.
- Out of scope: the `mise bootstrap` skill (deferred), Windows, changing what bootstrap installs.

## Review Focus

1. **Fresh machine, no Homebrew, no Bun.** The post-packages hand-over must work when `brew` and `bun` are absent and
   `~/.local/bin` is not linked. Test in Task 5: run the hand-over with `PATH=/usr/bin:/bin` and a stub `mise`.
2. **The profile reaches every step.** `mise bootstrap -E desktop,dev` must give `brew/bundle`, `dev/python-tools`
   and `skills/restore` the `dev` profile, even though their parent process is now `mise run`. Test in Task 4:
   `dots_profile` reads `-E dev` from a parent started with `exec -a`.
3. **One failed soft step must not stop the phase.** For example, a failed gopass store clone still lets the steps
   after it run, and the phase exits 0. Under `CI=1` it exits 1. Test in Task 4 (`warn`) and Task 8 (run the phase
   with a failing stub step).
4. **Prompting steps without a terminal.** `ssh/keychain` and `brew/install` with no `/dev/tty` print their
   instruction and do not hang. The existing ssh-keychain spec covers ssh. Task 5 adds the brew-sudo case.
5. **Running a step twice by hand changes nothing the second time** (`pass-link`, `brew/config-link`,
   `dotfiles/move-aside`). Test: run the step twice and assert the state and stderr match.

## Baseline (do first, before Task 1)

Save the outputs to `B="$(git rev-parse --git-common-dir)/wip/bootstrap-baseline"`. That folder is not committed, and
later tasks diff against it:

- [ ] `mise bootstrap plan > $B/plan.txt 2>&1`
- [ ] `mise bootstrap macos defaults status > $B/defaults-status.txt 2>&1`
- [ ] `(cd ~ && mise bootstrap --dry-run) > $B/dry-run.txt 2>&1`
- [ ] For each file in `test/integration/bootstrap/*.spec.ts`: `bun test <file>`. Record `<file> <pass> <skip>` in
  `$B/spec-counts.txt`.
- [ ] `g rev-parse HEAD > $B/base.txt`

---

### Task 1: mise version drift check and sync

**Files:**
- Create: `.mise/tasks/mise/version.sh`
- Modify: `mise.toml` (add `[doctor.checks.mise-version]`), `config/mise/config.toml` (`min_version`), `install:8`,
  `distros/debian/Dockerfile:37,51`, `distros/ubuntu/Dockerfile:37,51`
- Test: `test/integration/bootstrap/mise-version.spec.ts`

**Interfaces:**
- Produces: `mise run mise:version [--check|--sync]`.
  - No flag: prints one line per pin, `<path>:<line>\t<pinned>\t<local>`.
  - `--check`: exit 1 if any pin differs from the local `mise --version`.
  - `--sync`: rewrites each differing pin to the local version and keeps that pin's `v` prefix (or lack of one).
  - `#USAGE flag "--check"` and `flag "--sync"` (mutually exclusive).
  - Test seams: `DOTS_MISE_VERSION` overrides the local version, `DOTS_UNAME` overrides `uname`, `DOTS_DIR` sets the
    root to scan.
  - Finds pins with `git -C "$DOTS_DIR" grep -n -E 'MISE_VERSION="?v?[0-9]{4}\.[0-9]+\.[0-9]+'`, never a fixed file list.

- [ ] **Step 1: Write the failing spec** `mise-version.spec.ts`. Each case uses a temp git repo with copies of an
  `install` line and a Dockerfile line:
  - `lists every pin with file, line, pinned and local version`
  - `--check exits 0 when all pins match` / `--check exits 1 and names the drifting file when one differs`
  - `--sync rewrites install (no v) and Dockerfile (v prefix) to the local version`. Assert the exact file text after,
    e.g. `MISE_VERSION="2026.11.14"` and `MISE_VERSION=v2026.11.14`.
  - `--sync is idempotent`: a second run leaves the files byte-identical.
  - `--sync refuses off macOS`: `DOTS_UNAME=Linux` exits 1 with `run --sync on macOS`. Nothing is changed.
  - `finds a pin added in a new file`: add `ci.sh` containing `MISE_VERSION=v2026.1.1`. It is listed.
- [ ] **Step 2:** `bun test test/integration/bootstrap/mise-version.spec.ts`. Expected: FAIL (task missing).
- [ ] **Step 3:** Implement `version.sh` with headers `#MISE description="List mise version pins; --check fails on
  drift, --sync rewrites them to this Mac's version"` and the `#USAGE` flags above.
- [ ] **Step 4:** Spec passes.
- [ ] **Step 5:** Add to `mise.toml`:
  `[doctor.checks.mise-version]` with `description = "Every MISE_VERSION pin matches this Mac's mise"`,
  `run = "mise run mise:version --check"`, `hint = "mise run mise:version --sync"`, `os = "macos"`.
  Add `min_version = "2026.11.8"` at the top level of `config/mise/config.toml`, with a comment that it is the first
  release with `bootstrap.settings`.
- [ ] **Step 6:** `mise run mise:version --sync`, then `mise run mise:version --check`. Expected: exit 0, and all
  five pins read `2026.11.14`.
- [ ] **Step 7:** `mise doctor project`. Expected: `mise-version` passes.
- [ ] **Step 8: Commit:** `feat(mise): Check and sync mise version pins against this Mac`.

**Acceptance:**
- `git grep -n MISE_VERSION` shows only `2026.11.14`.
- `mise doctor project` exits 0 on macOS.
- The spec has ≥ 7 passing cases.

### Task 2: mise LSP diagnostics task

**Files:**
- Create: `.mise/tasks/mise/diagnostics.ts` (Bun, `//MISE description="Report mise config diagnostics from mise lsp
  (deprecated or unknown keys)"`)
- Create fixtures: `test/integration/bootstrap/fixtures/mise-deprecated.toml` (one `[bootstrap.macos.dock]`),
  `test/integration/bootstrap/fixtures/mise-clean.toml`
- Modify: `mise.toml` (`[doctor.checks.mise-diagnostics]`, not wired to hk yet)
- Test: `test/integration/bootstrap/mise-diagnostics.spec.ts`

**Interfaces:**
- Produces: `mise run mise:diagnostics [files…]`.
  - Default files: `mise.toml`, every `config/mise/**/*.toml`, `config/bin/mise.toml`.
  - Prints `<path>:<line>\t<code>\t<message>` for each diagnostic whose code is `deprecated-key` or `unknown-key`.
    Exits 1 when it prints any, 0 otherwise.
  - Exits 2 with `mise lsp did not answer` if no `publishDiagnostics` arrives within 10 s.
  - The approach is the verified probe: spawn `mise lsp`, send `initialize`, then `initialized`, then `didOpen` for
    each file. Collect `textDocument/publishDiagnostics` until every file has reported or the deadline passes.

- [ ] **Step 1: Failing spec.** Cases:
  - `reports deprecated-key with file and line for the fixture`. Assert the code is `deprecated-key`, the line is
    `1`, and the exit code is 1.
  - `prints nothing and exits 0 for a clean file`.
  - `default file set includes config/mise/conf.d/*.toml`. Run with no arguments against the repo, which still has
    deprecated keys before Task 3. Assert exit 1 and that the output names `config/mise/conf.d/macos.toml`. Rename
    this case in Task 3 to `default file set is clean`, asserting exit 0.
  - Skip the whole file when `Bun.which("mise")` is null.
- [ ] **Step 2:** It fails.
- [ ] **Step 3:** Implement. **Step 4:** It passes.
- [ ] **Step 5:** `[doctor.checks.mise-diagnostics]` with `run = "mise run mise:diagnostics"`,
  `hint = "see docs/BOOTSTRAP.md#gotchas (deprecated keys)"`, `timeout = "30s"`.
- [ ] **Step 6:** `mise run mise:diagnostics`. Expected: exactly the 8 diagnostics from the spec, exit 1.
- [ ] **Step 7: Commit:** `feat(mise): Report mise lsp diagnostics from the command line`.

**Acceptance:**
- Against the unmodified repo it lists exactly 8 `deprecated-key` lines: `bootstrap.toml:45` and `macos.toml` lines
  6, 16, 22, 44, 59, 70, 142.

### Task 3: Rename the deprecated keys

**Files:**
- Modify: `config/mise/conf.d/bootstrap.toml:45`, `config/mise/conf.d/macos.toml` (lines 6–170: every
  `bootstrap.macos.{defaults,defaults_entries,keyboard,trackpad,dock,finder,login_items}`),
  `config/mise/conf.d/yabai.toml` (any `bootstrap.macos.defaults`)
- Modify tests: `macos-defaults.spec.ts`, `yabai.spec.ts` (the key paths they read), `mise-diagnostics.spec.ts` (the
  rename from Task 2)
- Modify: `hk.pkl` (add the step)

**Interfaces:**
- Consumes: `mise:diagnostics` from Task 2.

- [ ] **Step 1:** Rename per the spec's Part 1 table: `bootstrap.macos.<k>` becomes `bootstrap.settings.macos.<k>`,
  values unchanged. `[bootstrap.macos.launchd.agents.*]` stays as it is.
- [ ] **Step 2:** Update the two specs' TOML paths (e.g. `parsed.bootstrap.settings.macos.dock`). Run them: they pass.
- [ ] **Step 3:** `mise run mise:diagnostics`. Expected: no output, exit 0.
- [ ] **Step 4: Behaviour unchanged.** Diff each new output against the baseline:
  - `mise bootstrap plan` vs `$B/plan.txt`
  - `mise bootstrap macos defaults status` vs `$B/defaults-status.txt`

  Expected: no diff. If timestamps differ, normalise them, and state that you did in the commit body.
- [ ] **Step 5:** Add the hk step `["mise-diagnostics"]` with `glob = List("mise.toml", "config/mise/**/*.toml",
  "config/bin/mise.toml")` and `check = "command -v mise >/dev/null || exit 0; mise run mise:diagnostics"`.
  `hk check --all` passes.
- [ ] **Step 6: Commit:** `fix(bootstrap): Move macOS preferences to bootstrap.settings.macos`.

**Acceptance:**
- `mise doctor project` passes both checks.
- The two baseline diffs are empty.
- The editor's Problems panel shows no `mise(deprecated-key)`. This is an owner check: list it in the handoff.

### Task 4: Bootstrap task foundation (`_lib.sh`, phases file, test helper, structure spec)

**Files:**
- Create: `.mise/tasks/bootstrap/_lib.sh` (not executable), `.mise/tasks/bootstrap/phases.toml` (empty phase stubs)
- Modify: `mise.toml`: add `[task_config] includes = [".mise/tasks", ".mise/tasks/bootstrap/phases.toml"]`
- Create: `test/integration/bootstrap/step.ts` (helper), `test/integration/bootstrap/bootstrap-lib.spec.ts`,
  `test/integration/bootstrap/bootstrap-structure.spec.ts`

**Interfaces (Produces, used by Tasks 5–9):**
- `_lib.sh`, when sourced, only defines things and sets no shell options:
  - `DOTS_DIR` (default `$HOME/.local/share/dots`).
  - `dots_profile`: prints a comma list. The first non-empty source wins, in this order: `$DOTS_PROFILE`,
    `$MISE_ENV`, the `-E/--env` value in the parent process's command line (`/proc/$PPID/cmdline` on Linux,
    `ps -o args= -p $PPID` elsewhere; the logic moves verbatim from today's post-packages hook), `env = [...]` in
    `$DOTS_DIR/config/mise/miserc.local.toml`, then `desktop`.
  - `has_profile <name>`: returns 0 if the name is in `dots_profile`'s list.
  - `is_macos`: returns 0 on Darwin, honouring `DOTS_UNAME`.
  - `warn <what>`: prints `bootstrap: <what> failed, continuing` to stderr. When `DOTS_STRICT` or `CI` is non-empty it
    prints `bootstrap: <what> failed` instead and exits 1.
  - `bootstrap_init`: puts `$HOME/.local/bin` first on PATH, runs `eval "$(brew shellenv)"` for the first brew found
    (`command -v brew`, `/opt/homebrew/bin/brew`, `/home/linuxbrew/.linuxbrew/bin/brew`), sources
    `$DOTS_DIR/script/bootstrap-log.sh` when readable, and exports `DOTS_PROFILE="$(dots_profile)"`.
- Hand-over body, the exact text every hook and the global task use in Tasks 5–8:

  ```bash
  #!/usr/bin/env bash
  . "$HOME/.local/share/dots/.mise/tasks/bootstrap/_lib.sh"
  DOTS_PROFILE="$(dots_profile)" exec mise run -C "$DOTS_DIR" bootstrap:hook:<phase>
  ```

- `step.ts` exports:
  - `STEPS: string`, the absolute path of `.mise/tasks/bootstrap`.
  - `header(rel: string): Record<string, unknown>`: parses `#MISE key=value` lines, each value TOML, via
    `Bun.TOML.parse`.
  - `runStep(rel: string, env: Record<string,string>, opts?: { stdin?: "ignore" }): { code: number; out: string;
    err: string }`. It runs `bash <STEPS>/<rel>` with only the given env plus `header(rel).env` defaults, and never
    inherits `process.env`.
  - `skipIf(rel: string, env: Record<string,string>): boolean`. It runs the header's `skip_if` with bash and returns
    true when it exits 0. It returns false when the step has no `skip_if`.

- [ ] **Step 1: Failing `bootstrap-lib.spec.ts`.** Cases:
  - `dots_profile prefers DOTS_PROFILE, then MISE_ENV`
  - `dots_profile reads -E from the parent command line` (Review Focus 2). The parent is a bash started with
    `exec -a "mise bootstrap -E desktop,dev --yes"`. It runs a child bash that sources `_lib.sh` and prints
    `dots_profile`, then `; true`, so the parent cannot exec-optimise itself away. The output must be `desktop,dev`,
    with `DOTS_PROFILE` and `MISE_ENV` unset and no miserc.
  - `dots_profile reads miserc.local.toml`; `dots_profile defaults to desktop`.
  - `has_profile matches whole names only`: `dev` does not match `devops`.
  - `warn continues and exits 0 normally`; `warn exits 1 under CI=1`; `warn exits 1 under DOTS_STRICT=1`
    (Review Focus 3).
  - `sourcing _lib.sh sets no shell options`: compare `$-` and `set -o` before and after.
- [ ] **Step 2: Failing `bootstrap-structure.spec.ts`.** Cases (some pass vacuously until Task 8):
  - `every executable under .mise/tasks/bootstrap has a description and a bash shebang`.
  - `every step sources _lib.sh`.
  - `phases.toml defines exactly the five bootstrap:hook:* tasks, and each run step names an existing task`. Check
    the names against `mise tasks ls --json`.
  - `each bootstrap hook phase is defined once, in bootstrap.toml, as the hand-over`. Parse every
    `config/mise/conf.d/*.toml`, collect `bootstrap.hooks.*`, and assert the run text equals the hand-over with that
    phase.
  - `the global bootstrap task is the hand-over to bootstrap:hook:final`.
  - `no "# <name>: begin" marker remains in config/mise/conf.d`.

  Mark the last three `it.todo` until Task 8, which turns them on.
- [ ] **Step 3:** Implement `_lib.sh`, `phases.toml` (five tasks with `description` and `run = []`: if mise rejects
  an empty list, use `run = "true"` until filled), the `task_config` include and `step.ts`.
- [ ] **Step 4:** Both specs pass. `mise tasks ls` still lists every `blog:*` and `theme:*` task: diff the names
  against `$B/` (capture `mise tasks ls` before the include).
- [ ] **Step 5: Commit:** `feat(bootstrap): Add the bootstrap task library and phase file`.

**Acceptance:**
- The lib spec has ≥ 9 cases.
- `mise tasks ls | grep -c '^bootstrap:hook:'` = 5.
- No `blog:*`/`theme:*` task is lost.

### Spec migration rule (applies to Tasks 5–8)

Existing specs keep every `it(…)` and its assertions. Only the loading changes: replace the TOML regex/`run`
extraction with `runStep("<area>/<step>.sh", env)`. A migrated file's pass count must be ≥ its count in
`$B/spec-counts.txt`. Each task adds one `skipIf` case per step it gives a `skip_if`: one state where the step is up to
date (true) and one where it is not (false).

### Task 5: post-packages phase

**Files:**
- Create steps:
  - `brew/install.sh` (brew-sudo plus the installer; `#MISE raw=true`; `skip_if="command -v brew || test -x
    /opt/homebrew/bin/brew || test -x /home/linuxbrew/.linuxbrew/bin/brew"`)
  - `brew/config-link.sh` (`skip_if='test -e "$HOME/.config/homebrew" || test -L "$HOME/.config/homebrew"'`)
  - `brew/bundle.sh`: the core group is hard and exits 1. For the `container` profile, clean up and exit 0. The rest
    of the profile warns and writes `brew-bundle.failed`/`.log`, as today. It uses `$DOTS_PROFILE`, never `$PPID`.
  - `yabai/scripting-addition.sh` (macOS, `yb sa || true`)
- Modify:
  - `phases.toml` `bootstrap:hook:post-packages`: run steps, in this order, `brew:install`, `brew:config-link`,
    `brew:bundle`, `yabai:scripting-addition`.
  - `bootstrap.toml`: the `[bootstrap.hooks.post-packages]` run becomes the hand-over. Keep its `description`, written
    as one line.
  - `yabai.toml`: remove its `[bootstrap.hooks.post-packages]`, and move its comment into the step.
- Test: migrate `post-packages.spec.ts` and the yabai post-packages part of `yabai.spec.ts`. Add `brew-steps.spec.ts`.

- [ ] **Step 1: Failing tests:**
  - Migrated cases.
  - `config-link is idempotent`: run it twice. Assert the link is the same and stderr is empty the second time
    (Review Focus 5).
  - `install without a terminal and without a sudo ticket exits 1 with "run 'sudo -v', then mise bootstrap"`:
    stdin ignored, stub `sudo` exits 1 (Review Focus 4).
  - `bundle uses DOTS_PROFILE`: stub brew records `HOMEBREW_DOTS_PROFILE`. With `DOTS_PROFILE=desktop,dev`, assert
    the calls are `container` then `desktop,dev`.
  - `post-packages hand-over runs with no brew and no bun on PATH` (Review Focus 1): `PATH=/usr/bin:/bin`, a stub
    `mise` on PATH records its argv. Assert the argv is `run -C <DOTS_DIR> bootstrap:hook:post-packages` and the env
    has `DOTS_PROFILE`.
- [ ] **Step 2:** They fail. **Step 3:** Implement. **Step 4:** They pass.
- [ ] **Step 5:** `(cd ~ && mise bootstrap --dry-run)` lists exactly one post-packages hook, and it is the hand-over.
- [ ] **Step 6: Commit:** `refactor(bootstrap): Run the post-packages phase as file tasks`.

### Task 6: pre-dotfiles and post-dotfiles phases

**Files:**
- Create steps:
  - `dotfiles/move-aside.sh` (moved from the `dotfiles.toml` pre-dotfiles hook)
  - `vscode/settings-sync.sh`, `bat/cache.sh`, `lig/zsh.sh` (from the post-dotfiles hook: each a soft step via
    `warn`)
- Modify:
  - `phases.toml`: `bootstrap:hook:pre-dotfiles` runs `dotfiles:move-aside`. `bootstrap:hook:post-dotfiles` runs, in
    order, `vscode:settings-sync`, `bat:cache`, `lig:zsh`.
  - `bootstrap.toml`: add both hooks as hand-overs, carrying today's descriptions.
  - `dotfiles.toml`: remove both hooks and keep their explanatory comments in the steps.
- Test: migrate `vscode-links.spec.ts` and `lig.spec.ts`, plus `yabai.spec.ts`'s pre-dotfiles part. Add
  `move-aside is idempotent` (Review Focus 5).
- [ ] Steps follow Task 5's cycle: failing tests, implement, pass, the dry-run shows one hook per phase. **Commit:**
  `refactor(bootstrap): Run the dotfiles phases as file tasks`.

### Task 7: post-defaults phase

**Files:**
- Create steps:
  - `macos/activate.sh` (from the `macos.toml` hook; runs every time, no `skip_if`, never fails)
  - `macos/swiftbar.sh` (from the `yabai.toml` hook)
- Modify:
  - `phases.toml`: `bootstrap:hook:post-defaults` runs `macos:activate` then `macos:swiftbar`.
  - `bootstrap.toml`: add the hand-over.
  - `macos.toml` and `yabai.toml`: remove their post-defaults hooks.
- Test: migrate `macos-defaults.spec.ts` (hook part, `DOTS_ACTIVATE_SETTINGS`), `duti.spec.ts` if it runs the hook,
  and `yabai.spec.ts`'s post-defaults part.
- [ ] Same cycle. **Commit:** `refactor(bootstrap): Run the post-defaults phase as file tasks`.

### Task 8: final phase (the global `bootstrap` task)

**Files:**
- Create steps, in today's order. Every step after `zsh:warm-caches` starts with `has_profile desktop || exit 0`, or
  `has_profile dev || exit 0` where marked:
  - `zsh/warm-caches.sh`
  - `dev/python-tools.sh` (dev)
  - `gopass/store.sh` (`skip_if='test -d "$HOME/.local/share/gopass/password-store/.git"'`)
  - `gopass/keyring.sh`
  - `gopass/pass-link.sh`
  - `ssh/keychain.sh` (`#MISE raw=true`)
  - `tiling/checks.sh`
  - `borders/build.sh`: the pin moves to `#MISE env={JB_REV="<today's rev>"}`, with
    `skip_if='test "$(cat "$HOME/.local/share/janky-borders/bin/.rev" 2>/dev/null)" = "$JB_REV"'`
  - `omlx/models.sh`
  - `skills/restore.sh` (dev)
  - `nvim/providers.sh`
  - `nvim/plugins.sh` (`sources=["config/nvim/lazy-lock.json"]`, default outputs)
  - `brew/remind.sh`: the `brew-bundle.failed` reminder. Always exits 0.
  - `git/filters.sh`: runs `mise run -C "$DOTS_DIR" setup:git:filters || warn "setup:git:filters"`, for every
    profile.
  - `git/hooks.sh`: `has_profile desktop || exit 0`, then `mise run -C "$DOTS_DIR" setup:hooks || warn "setup:hooks"`.
- Modify:
  - `phases.toml` `bootstrap:hook:final` run steps, in this order:
    1. `bootstrap:git:filters`
    2. `bootstrap:zsh:warm-caches`
    3. `bootstrap:git:hooks`
    4. the steps above, in their listed order
    5. `bootstrap:brew:remind`, last
  - The global `[tasks.bootstrap]` in `bootstrap.toml` becomes the hand-over to `bootstrap:hook:final`.
- Test:
  - Migrate `gopass-keyring`, `pass-link`, `ssh-keychain`, `tiling-checks`, `janky-borders` and `skills-snippet`.
  - `skipIf` cases for `gopass:store` and `borders:build`.
  - `phase-run.spec.ts`, `a phase continues past a failing soft step` (Review Focus 3). It builds a temp git repo
    with `mise.toml` (the same `task_config` include), a copy of `_lib.sh`, and a phases file with one phase of two
    stub steps: the first calls `warn x`, the second touches a file. It runs `mise run -C <tmp> <phase>` with
    `MISE_TRUSTED_CONFIG_PATHS=<tmp>`, then asserts exit 0 and that the file exists. Under `CI=1` it asserts exit 1
    and that the file is absent.
  - Turn on the three `it.todo` cases in `bootstrap-structure.spec.ts`.
- [ ] Same cycle. Then `mise run --dry-run bootstrap:hook:final` lists every step in order.
- [ ] **Commit:** `refactor(bootstrap): Run the final bootstrap phase as file tasks`.

**Acceptance (Tasks 5–8 together):**
- `bootstrap-structure.spec.ts` has no `todo` left and passes.
- `git grep -n "run = '''" config/mise/conf.d/` lists only the five hand-overs and the global task, each ≤ 4 lines.
  Dotfile templates are not hooks and stay.
- `(cd ~ && mise bootstrap --dry-run)` shows one hook per phase. Compared with `$B/dry-run.txt`, the same phases have
  hooks.
- Every migrated spec file's pass count is ≥ its baseline count.

### Task 9: docs/BOOTSTRAP.md, the single source

**Files:**
- Create: `docs/BOOTSTRAP.md`
- Modify (move the content out, leave a one-line link): `README.md` (install steps 5–7 detail, the bootstrap commands
  around lines 82–84 and 134, the "A package failed during `mise bootstrap`" entry), `docs/MACOS.md` (the
  apply/status/dry-run command block at lines 42–48 only), `docs/REINSTALL.md` (the "asks for two things" item and
  the `--only …` recipe, around lines 470–478), `docs/TILING.md` ("Done by `mise bootstrap`"), `docs/DOCKER.md` (add
  a link), `AGENTS.md` (add a Docs entry: `docs/BOOTSTRAP.md` — what `mise bootstrap` runs, its file tasks, recipes and
  gotchas)
- Test: `test/integration/bootstrap/bootstrap-docs.spec.ts`

- [ ] **Step 1: Failing spec:**
  - `every bootstrap:* task from mise tasks ls appears in BOOTSTRAP.md`
  - `README, MACOS, REINSTALL, TILING, DOCKER and AGENTS link docs/BOOTSTRAP.md`
  - `BOOTSTRAP.md has the sections Overview, Rationale, Profiles, Steps, Recipes, Gotchas, Troubleshooting`
- [ ] **Step 2:** Write BOOTSTRAP.md per the spec's Part 3:
  - The phase diagram is a mermaid fence: mise's order, with each hand-over and phase task.
  - The Steps table has the columns task, phase, platform/profile, what it does, up-to-date check, may prompt.
  - Recipes include `mise run bootstrap:<area>:<step>`, `--force`, `mise run --dry-run bootstrap:hook:final`,
    `mise doctor project`, `mise run mise:version --sync`, `mise run mise:diagnostics`, and "add a step".
  - Gotchas cover at least the seven in the spec's Constraints (pin vs schema, LSP-only diagnostics, the parent-process
    profile, early phases before tools, hooks only run shell, hooks run every time, one hook per phase).
- [ ] **Step 3:** Move the listed passages. Each source keeps one sentence plus a link. MACOS.md keeps its preference
  catalogue and undo notes.
- [ ] **Step 4:** The spec passes. `hk check` on the docs passes (markdownlint).
- [ ] **Step 5: Commit:** `docs(bootstrap): Make docs/BOOTSTRAP.md the single source on mise bootstrap`.

**Acceptance:**
- No moved passage still exists in its old file: diff each file's old text against the new.
- Every `bootstrap:*` task is documented.

### Task 10: Whole-branch verification, lida, handoff

- [ ] `mise run test:specs`. Expected: exit 0, with the total pass count ≥ the baseline total plus the new specs.
- [ ] `hk check --all`. Expected: exit 0.
- [ ] `mise run zsh:verify`. Expected: the syntax checks pass. The parity step's "no baseline" failure is known and
  predates this work: report it, don't fix it.
- [ ] `mise run mise:diagnostics`: empty, exit 0. `mise doctor project`: exit 0. `mise run mise:version --check`:
  exit 0.
- [ ] Containers (set `DOCKER_HOST` from `docker context inspect` first, or every CST check fails). For `d` in
  `debian ubuntu`:
  - `mise run build --local --distro $d`
  - then `mise run test --image dots:$d-local --config distros/$d/container-structure-test.yml`

  Expected: both pass. Record the log paths.
- [ ] **Owner checkpoint.** Run `mise bootstrap --dry-run` and `mise run --dry-run bootstrap:hook:final`, and save
  both outputs. Stop and ask the owner to run `mise bootstrap` twice on this Mac (it may ask for sudo and the SSH
  passphrase) and to share `~/.local/state/dots/logs/latest.log`. On the second run, every step with an up-to-date
  check must skip, and there must be no warnings beyond the baseline's. Do not mark the task done before the owner
  answers.
- [ ] `lida done awGX`. Commit `TODO.yaml`: `chore(todo): Close the mise bootstrap file tasks work`.
- [ ] `/wip:handoff`. No push and no PR.

**Definition of done:**
- Every box is ticked and every task's Acceptance is met.
- The owner checkpoint is answered.
- Lida `awGX` is Done.
- The branch is clean apart from files you did not write.
