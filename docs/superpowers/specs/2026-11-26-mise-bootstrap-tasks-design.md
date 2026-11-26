# mise bootstrap: current keys, file tasks, one doc

Status: approved (2026-11-26) · Branch: `feat/mise-bootstrap-tasks` · Task: `awGX` (TODO.yaml)

## Intent

`mise bootstrap` sets up this machine (and the Docker images) from `config/mise/`. Today most of its custom work
lives as long shell strings inside TOML: the `post-packages` hook (~80 lines), the global `bootstrap` task (~180 lines,
nine `# <name>: begin/end` blocks) and smaller hooks in `macos.toml`, `yabai.toml` and `dotfiles.toml`. The editor
also shows eight `deprecated-key` diagnostics.

The owner wants:

- **Organization and documentation:** each step is a small named unit with a description, findable and readable on
  its own.
- **Separation of concerns:** declarative config (`[bootstrap.*]`) stays in `config/mise/conf.d/`; shell code moves
  to scripts; hooks only hand over.
- **mise's task features where they fit:** ordered run steps and `depends`
  ([architecture](https://mise.jdx.dev/tasks/architecture.html)), `sources`/`outputs` and up-to-date skipping
  ([sources](https://mise.jdx.dev/tasks/task-configuration.html#sources),
  [outputs](https://mise.jdx.dev/tasks/task-configuration.html#outputs),
  [skipping](https://mise.jdx.dev/tasks/running-tasks.html#skip-tasks-that-are-up-to-date)), `skip_if`.
- **Run any step at will, from inside the repo:** `mise run bootstrap:gopass:keyring`, like `setup:git:filters`.
- **One doc:** `docs/BOOTSTRAP.md` is the single source of truth on `mise bootstrap`; other docs link to it.

## Goals

1. Zero `deprecated-key` (and `unknown-key`) diagnostics from `mise lsp` on every mise config in the repo, with a
   check that keeps it at zero.
2. Every bootstrap step is a bash file task under `.mise/tasks/bootstrap/`, idempotent, runnable alone, with a
   `#MISE description`, and the cheapest correct up-to-date check (`skip_if`, or `sources`/`outputs`).
3. Hooks and the global `bootstrap` task are one-line hand-overs to phase tasks.
4. `mise bootstrap` behaves as today on macOS (desktop, dev) and in the container images: same order, same
   warn-and-continue semantics, same hard failure for the core brew group, same prompts.
5. `docs/BOOTSTRAP.md` holds overview, rationale, the step reference, recipes, gotchas and troubleshooting.

## Non-goals

- Changing what bootstrap installs or configures (packages, links, defaults, LaunchAgents stay as they are).
- Running steps from outside the repo (owner's choice: inside the dots repo only).
- Moving `[bootstrap.*]` declarative keys into tasks, or `[dotfiles]` templates (`vscode-*`, `claude-skills`) out of
  `dotfiles.toml`.
- Windows.
- A shareable `mise bootstrap` skill: deferred to future work (owner, 2026-11-26).

## Anti-goals (a failure even if it works)

- A step that changes state on a second run with nothing to do (beyond the existing Dock/Finder restart).
- A soft step that now stops the bootstrap, or the core brew group that now only warns.
- Shell that shellcheck/shfmt cannot see.
- Docs that repeat each other: a fact about bootstrap lives in `BOOTSTRAP.md` only, others link.
- Tests that pin config values (see the repo's testing rules); specs test behaviour.

## Constraints found during recon

- **The new keys need mise ≥ 2026.11.8.** `bootstrap.settings.macos.*` is absent from the 2026.11.4 schema that
  `install` and both Dockerfiles pin (`MISE_VERSION`). Bump all three pins together, to the version this Mac runs
  (2026.11.14), in the same commit as the rename.
- **No CLI reports `deprecated-key`.** `mise doctor`, `bootstrap --dry-run|status|plan` are silent; only `mise lsp`
  publishes these diagnostics. A small client (LSP over stdio: `initialize`, `didOpen` each file, collect
  `publishDiagnostics`) reports them; a draft exists and found exactly the editor's eight.
- **Profile detection reads the parent process.** The `post-packages` hook finds the profile from `MISE_ENV`, then
  `$PPID`'s command line (`mise bootstrap -E …`), then `miserc.local.toml`. Inside `mise run` the parent is no
  longer `mise bootstrap`, so the hook resolves the profile itself and passes it on (`MISE_ENV`/`DOTS_PROFILE`).
- **Early phases run before dotfiles and before most tools.** The `post-packages` tasks run while `~/.local/bin` is
  not linked yet and Bun is not installed; they must be plain bash with no task `tools`. The repo is trusted through
  `trusted_config_paths` (global config, linked by `install`), and `auto_install` only touches task-declared tools.
- **Hooks only run shell** (schema `bootstrap_hook`: `run`, `run_windows`, `description`), so the hand-over is
  `run = 'mise run -C "$HOME/.local/share/dots" bootstrap:hook:<phase>'`.
- **Hooks and the `bootstrap` task run on every bootstrap** (mise's help); only declarative parts are diffed.
- **A failing task stops a mise run** unless `--continue-on-error`. Soft steps keep today's semantics by warning
  and exiting 0; `DOTS_STRICT`/`CI` turns soft failures into exit 1, as today.
- **sources/outputs resolve from the task dir** and must name files mise can stat; most bootstrap state is not a
  file (Keychain, a running yabai, brew's installed set), so `skip_if` is the usual check.
- **About ten specs** under `test/integration/bootstrap/` regex-extract `# <name>: begin/end` blocks from the TOML
  and run them with stubbed env (`DOTS_SSH_BIN`, `DOTS_CSRUTIL`, `DOTS_YABAI`, `DOTS_ACTIVATE_SETTINGS`, …).
- **Docker images run bootstrap** (`-E container --force-dotfiles --skip user`); changes here need the build and
  CST gates.

## Approaches

| | Approach | Trade-off | |
|---|---|---|---|
| A | Bash file tasks in `.mise/tasks/bootstrap/`, `#MISE` headers, phase tasks chain them with run steps; hooks hand over | More files and a shared preamble; gains shellcheck/shfmt, per-step tests, per-step docs, the full task feature set | **Picked** |
| B | TOML tasks in the repo `mise.toml` (or an included file) | Same graph, fewer files; shell stays in TOML strings, unlinted, config and code mixed | Rejected |
| C | Bun file tasks, like `.mise/tasks/blog/` | Typed and testable; Bun is not installed when the early phases run | Ruled out |

## Design

### Part 1: deprecated keys

Rename, keeping values, in `bootstrap.toml` and `macos.toml`:

| Deprecated | Current |
|---|---|
| `[bootstrap.macos.defaults]` (both files) | `[bootstrap.settings.macos.defaults]` |
| `[[bootstrap.macos.defaults_entries]]` | `[[bootstrap.settings.macos.defaults_entries]]` |
| `[bootstrap.macos.keyboard]`, `trackpad`, `dock`, `finder`, `login_items` | `[bootstrap.settings.macos.<same>]` |

`[bootstrap.macos.launchd.agents.*]` is not deprecated and stays. Proof of no behaviour change:
`mise bootstrap plan` and `mise bootstrap macos defaults status` are identical before and after (saved outputs,
diffed). Bump the `MISE_VERSION` pins (below). Add `.mise/tasks/mise/diagnostics.sh` (`mise run mise:diagnostics`):
the LSP client over `mise.toml`, `config/mise/**/*.toml`, `config/bin/mise.toml`; exits 1 on any
`deprecated-key`/`unknown-key`; wired into `hk check` (skip when `mise` is missing). Lands as its own commit.

**mise version drift (owner request).** mise is pinned in `install` (`MISE_VERSION=`) and twice in each Dockerfile
(`distros/{debian,ubuntu}/Dockerfile`, `MISE_VERSION=v…`); CI installs no mise of its own. The macOS machine's
`mise --version` is the reference ("macOS wins").

- `.mise/tasks/mise/version.sh` (`mise run mise:version`): lists every pin with its file and line next to the local
  version; `--check` exits 1 on any difference; `--sync` rewrites every pin to the local version (keeping each
  file's `v` prefix convention). It refuses `--sync` off macOS. Pins are found by pattern (`MISE_VERSION=…`), not by a
  hard-coded line list, so a new pin site is covered.
- `[doctor.checks.mise-version]` in the repo `mise.toml` (`os = "macos"`): `run = "mise run mise:version --check"`,
  `hint = "mise run mise:version --sync"`; shows up in `mise doctor project`. A second check,
  `[doctor.checks.mise-diagnostics]`, runs `mise:diagnostics` so one command reports both.
- `min_version = "2026.11.8"` in `config/mise/config.toml`, so an older mise fails with a clear message instead of
  misreading `bootstrap.settings`.

### Part 2: file tasks

Layout (task name = path; the builder may adjust names, not the split):

```text
.mise/tasks/bootstrap/
  _lib.sh                     # not executable, so not a task: PATH, brew shellenv, warn(), strict(), logging
  hook/post-packages.sh       # phase tasks: what each [bootstrap.hooks.*] / the global task runs
  hook/pre-dotfiles.sh
  hook/post-defaults.sh
  hook/final.sh               # what the global `bootstrap` task runs today
  brew/install.sh             # brew-sudo + installer        skip_if: brew found
  brew/config-link.sh         # brew-config                  skip_if: ~/.config/homebrew exists
  brew/bundle.sh              # core group (fatal), then the profile (warns; writes brew-bundle.failed)
  yabai/scripting-addition.sh # yb sa                        macOS
  dotfiles/move-aside.sh      # VS Code/Karabiner real files aside
  macos/activate.sh           # screenshots dir, duti, activateSettings, restart Dock/Finder/SystemUIServer
  macos/swiftbar.sh
  git/filters.sh              # or call the existing setup:git:filters
  zsh/warm-caches.sh
  dev/python-tools.sh         # dev only
  gopass/store.sh             # clone pass-store              skip_if: store/.git exists
  gopass/keyring.sh           # warn only
  gopass/pass-link.sh
  ssh/keychain.sh             # macOS, may prompt on /dev/tty
  tiling/checks.sh            # kb-raycast clone + SIP/yabai hints
  borders/build.sh            # JankyBorders at the pinned rev  sources: the script; outputs: bin/.rev (or skip_if on it)
  omlx/models.sh              # missing models only
  skills/restore.sh           # dev only, background
  nvim/providers.sh           # npm/gem neovim
  nvim/plugins.sh             # Lazy! restore                 sources: config/nvim/lazy-lock.json
```

- Phase tasks chain their steps with ordered run steps (`run = [{ task = "…" }, …]`); steps that are independent
  may run as a parallel `{ tasks = [...] }` group only where today's order does not matter and no step prompts.
- Each step: `#MISE description=…`, `skip_if` or `sources`/`outputs` where a cheap check exists, platform/profile
  guards at the top (`exit 0` when not applicable), `#USAGE` flags only where a step takes input.
- Hooks in `config/mise/conf.d/*.toml` keep their `description` and become
  `run = 'mise run -C "$HOME/.local/share/dots" bootstrap:hook:<phase>'`. The global `[tasks.bootstrap]` becomes the
  same hand-over to `bootstrap:hook:final`. The `post-packages` hook resolves the profile before handing over.
- Soft failure: `warn` and exit 0; hard (`brew/bundle.sh` core group, or any step under `DOTS_STRICT`/`CI`): exit 1.
  The `remind` trap for `brew-bundle.failed` moves to `hook/final.sh`.
- `_lib.sh` sources `script/bootstrap-log.sh` so every step still logs to `~/.local/state/dots/logs`.
- Existing `DOTS_*` test seams stay. Specs run the step scripts directly (bash, temp `HOME`, stubs on `PATH`)
  instead of regex-extracting TOML; one spec checks every executable under `.mise/tasks/bootstrap/` has a
  description and that each hook hands over to an existing phase task.

### Part 3: docs/BOOTSTRAP.md

Sections: **Overview** (what `install` does, then mise's nine phases with where each dots file and phase task plugs
in, as a diagram); **Rationale** (declarative first, thin hooks, why file tasks, why `skip_if` over outputs for
system state; link an ADR if one is written); **Profiles** (desktop, dev, container; `mise run setup`); **Steps**
(table: task, phase, platform/profile, what it does, up-to-date check, may prompt); **Recipes** (preview with
`status`/`plan`/`--dry-run`, run or force one step, `--only`/`--skip`, add a step, check diagnostics, macOS defaults
apply/undo commands, adopting history); **Gotchas**; **Troubleshooting** (brew bundle failures, prompts, SIP,
stale caches).

Move into it, leaving a one-line link behind: README install steps 5–7 detail, "Day to day" bootstrap commands and
the package-failure troubleshooting entry; MACOS.md's apply/status/plan command block (the preference catalogue and
undo notes stay in MACOS.md); REINSTALL.md's "bootstrap asks for two things" and `--only` finishing recipe;
TILING.md's "Done by mise bootstrap"; DOCKER.md and AGENTS.md (docs list) link to it.


## Verification

- `mise run mise:diagnostics` reports nothing; `mise doctor project` passes on macOS; a spec drives
  `mise:version --check/--sync` against temp copies of the pin files.
- `mise bootstrap plan` / `macos defaults status` identical before and after part 1.
- `mise run test:specs`, `hk check --all`, `mise run zsh:verify` (syntax).
- `mise bootstrap` on this Mac twice: the second run skips every step with an up-to-date check and prints no warnings
  beyond today's.
- `mise run build --local --distro debian|ubuntu` and the CST runs pass.
- Lida task `awGX` marked done before the PR.

## Calls made by the author (owner to check)

- mise pin → this Mac's version (2026.11.14) in `install` and both Dockerfiles, applied with `mise:version --sync`.
- `min_version` set to the first release with `bootstrap.settings` (2026.11.8), not to the pin.
- The diagnostics check is a mise task wired into `hk`.
- Task naming `bootstrap:<area>:<step>`, phase tasks under `bootstrap:hook:*`.
- `_lib.sh` lives beside the tasks, non-executable.
- MACOS.md keeps the preference catalogue; only bootstrap mechanics move.

## Left to the builder

Exact task names within the layout, which steps get `sources`/`outputs` vs `skip_if`, which independent steps run
in parallel, spec file names, the BOOTSTRAP.md diagram format.
