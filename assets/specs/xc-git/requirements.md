<!-- markdownlint-disable -->
# REQUIREMENTS: xc-git

## OVERVIEW

Merge three existing `config/bin` helpers — `xc-git-branch-preview`, `xc-git-fixup-suggest`,
and `xc-git-log-fzf` — into one entrypoint script **`xc-git`** with subcommands. Behavior of
each legacy script MUST be preserved. Thin wrapper scripts MUST keep old command names working
for fzf previews and existing muscle memory.

Normative CLI contracts, exit codes, package layout (`config/bin/xc-git/`), argument parsing
(`zparseopts`), and migration steps live in [design.md](./design.md).

---

## User Roles

- **Terminal user:** Runs `xc-git` interactively or in fzf preview strings; uses fixup
  suggestions and log picker from daily git workflow.
- **Script author:** Pipes `xc-git fixup-suggest -q` into `git fix`; depends on stable exit
  codes and stdout-only hash output in quiet mode.
- **gitx consumer:** Invokes log-fzf via `_gitx_fzlog` in `config/zsh/etc/functions/gitx`.

---

## REQUIREMENTS

### REQUIREMENT 1: Top-level help and dispatch

**User Story:**

As a terminal user
I want one command with subcommands
so that git helpers are discoverable without remembering three binary names

**Acceptance Criteria:**

1. WHEN `xc-git` is invoked with `-h` or `--help`
   THEN it SHALL print top-level usage listing all subcommands to stdout and exit 0.
2. WHEN `xc-git` is invoked with no arguments
   THEN it SHALL print top-level usage to stdout and exit 1.
3. WHEN `xc-git` is invoked as `xc-git <subcommand> …`
   THEN it SHALL dispatch to exactly one subcommand handler per
   [design.md §4 Subcommand registry](./design.md#4-subcommand-registry).
4. WHEN `<subcommand>` is unknown
   THEN it SHALL print `xc-git: unknown subcommand: <name>` to stderr, print top-level usage
   to stderr, and exit 1.

**Edge Cases:**

- Subcommand help (`xc-git <subcommand> -h`) MUST NOT require git repository (except where the
  subcommand itself requires git — see per-subcommand requirements).

---

### REQUIREMENT 2: Subcommand `branch-preview`

**User Story:**

As a terminal user browsing branches in fzf
I want a rich preview of the selected branch
so that I can see last commit, recent history, and diff before checkout

**Acceptance Criteria:**

1. WHEN `xc-git branch-preview <branch>` is invoked with a valid local branch name
   THEN it SHALL print three sections to stdout: last commit (formatted), recent history
   (15 oneline graph lines), and diff of last commit via `delta --pager=never`.
2. WHEN `branch` is missing
   THEN it SHALL print subcommand usage from `#?` header and exit 1.
3. WHEN `-h` or `--help` is passed as first argument after `branch-preview`
   THEN it SHALL print subcommand `#?` help to stdout and exit 0.
4. WHEN `gum` is on `$PATH` and stdout is a TTY
   THEN section headings SHALL use `gum style` via the shared helper in
   [design.md §4.1](./design.md#41-shared-optional-gum-_commonzsh).
5. WHEN `gum` is absent or stdout is not a TTY
   THEN section headings SHALL use plain `printf` (same text, no failure).

**Edge Cases:**

- Invalid branch: `git show` / `git log` may fail silently (current behavior); no change required.

---

### REQUIREMENT 3: Subcommand `fixup-suggest`

**User Story:**

As a terminal user with local changes
I want the safest fixup target on the current branch
so that I avoid rebase conflicts and do not guess unrelated commits

**Acceptance Criteria:**

1. WHEN a path has `git log <base>..HEAD -n 1 -- <path>`
   THEN the suggested fixup target SHALL be that commit hash (direct touch).
2. WHEN a path has no direct touch but parent directory `p:h` is not `.`
   THEN the suggested fixup target SHALL be `git log <base>..HEAD -n 1 -- <p:h>` (directory touch).
3. WHEN no direct or directory touch exists on the branch
   THEN the subcommand SHALL NOT invent a semantic/related commit; it SHALL treat the path as
   needing a new commit per [design.md §5 fixup-suggest](./design.md#5-subcommand-fixup-suggest).
4. WHEN all analyzed paths need a new commit and `--dry-run` is not set
   THEN it SHALL `git add` those paths and `exec git commit` (editor opens).
5. WHEN `-q` / `--best` is set and every path has a fixup target
   THEN it SHALL print only the top-ranked short hash to stdout and exit 0.
6. WHEN `-q` is set and any path lacks a fixup target
   THEN it SHALL exit 1 with stderr instructing to run without `-q` to open the commit editor.
7. WHEN `--dry-run` is set and paths lack fixup targets
   THEN it SHALL NOT run `git commit`; it SHALL print `would run: git commit` and listed paths
   to stderr and exit 0.
8. GIVEN default base ref
   WHEN `-b` / `--base` is omitted
   THEN `<base>` SHALL be `origin/main` per design.
9. WHEN not inside a git work tree
   THEN it SHALL exit 1 with message containing `not inside a git repository`.

**Edge Cases:**

- Mixed batch: some paths with fixup targets, some without — print suggestions then `git commit`
  only orphan paths (current `xc-git-fixup-suggest` behavior).
- No uncommitted paths when called with no path args: exit 0 with message (not error).

---

### REQUIREMENT 4: Subcommand `log-fzf`

**User Story:**

As a terminal user
I want an interactive git log with gitx actions
so that I can fix, reword, rebase-from, or reset without memorizing hashes

**Acceptance Criteria:**

1. WHEN `xc-git log-fzf` runs without optional action argument
   THEN Enter SHALL print selected short hash to stdout (via `gitx grep-commit` pipeline).
2. WHEN `xc-git log-fzf <action>` runs with action in the allowed set per design
   THEN Enter SHALL run that gitx action on the picked commit.
3. WHEN gitx is not found at `${XDG_CONFIG_HOME}/zsh/etc/functions/gitx`
   THEN it SHALL exit 127 with stderr containing `gitx`.
4. WHEN `-h` or `--help` is first argument after `log-fzf`
   THEN it SHALL print subcommand help to stdout and exit 0.
5. fzf keybindings and preview command string SHALL match current `xc-git-log-fzf` behavior
   (no regression in header text or bind map).

**Edge Cases:**

- Empty fzf selection: exit 0 (no output).
- Requires interactive terminal for fzf; non-TTY behavior unchanged from legacy script.

---

### REQUIREMENT 5: Backward-compatible wrappers

**User Story:**

As a user with existing fzf config
I want old script names to keep working
so that I do not break `gitx fzb` previews or aliases mid-migration

**Acceptance Criteria:**

1. WHEN `xc-git-branch-preview` is invoked
   THEN it SHALL `exec xc-git branch-preview "$@"` with identical exit code.
2. WHEN `xc-git-fixup-suggest` is invoked
   THEN it SHALL `exec xc-git fixup-suggest "$@"` with identical exit code.
3. WHEN `xc-git-log-fzf` is invoked
   THEN it SHALL `exec xc-git log-fzf "$@"` with identical exit code.
4. Each wrapper SHALL remain executable (`chmod +x`) and keep its own `#?` one-line pointer help
   OR delegate help to `xc-git <subcommand> -h` per design.

---

### REQUIREMENT 6: gitx integration

**User Story:**

As a gitx user
I want `gitx fzl` / `gitx lol` to use the unified helper
so that maintenance has a single implementation path

**Acceptance Criteria:**

1. WHEN `_gitx_fzlog` runs
   THEN it SHALL resolve helper in order: `command -v xc-git` → legacy `xc-git-log-fzf` path →
   `${XDG_CONFIG_HOME}/bin/xc-git-log-fzf` per [design.md §7](./design.md#7-external-integration).
2. WHEN helper is found
   THEN it SHALL invoke `xc-git log-fzf "$@"` (not the legacy filename when `xc-git` exists).
3. WHEN `gitx fzb` preview runs
   THEN preview command SHALL remain valid: either `xc-git branch-preview {}` or legacy name via
   wrapper (both MUST work after migration).

---

### REQUIREMENT 7: Tests and mise

**User Story:**

As a maintainer
I want automated specs for all subcommands
so that refactors do not regress help text, exit codes, or dispatch

**Acceptance Criteria:**

1. WHEN `mise run xc-git:specs` runs
   THEN it SHALL execute Bun tests covering help, dispatch, fixup-suggest, log-fzf gitx-missing,
   and branch-preview smoke per [tasks.md](./tasks.md).
2. Tests SHALL use env var `XC_GIT` pointing at `config/bin/xc-git` (not legacy paths).
3. Legacy wrapper specs MAY remain as thin `exec` delegation tests or be merged into `xc-git.spec.ts`.

---

### REQUIREMENT 10: Single package directory (`config/bin/xc-git/`)

**User Story:**

As a maintainer
I want all xc-git modules in one directory
so that PATH symlinks and imports stay obvious

**Acceptance Criteria:**

1. The executable SHALL live at `config/bin/xc-git` (chmod +x).
2. Subcommand modules SHALL live as siblings in the same directory (`_common.zsh`,
   `branch-preview.zsh`, `fixup-suggest.zsh`, `log-fzf.zsh`).
3. The tree `config/bin/lib/xc-git/` SHALL NOT exist after migration.
4. `XC_GIT_DIR` SHALL mean `${${(%):-%x}:a:h}` inside the executable and sourced modules.
5. Thin wrappers at `config/bin/xc-git-*` SHALL `exec "${0:h}/xc-git/xc-git" …"`.
6. `config/bin/README.md` symlink example SHALL target `~/.config/bin/xc-git`.

---

### REQUIREMENT 11: CLI options via `zparseopts`

**User Story:**

As a maintainer
I want consistent zsh option parsing
so that flags behave like other dotfiles functions (`psc`, `osx`)

**Acceptance Criteria:**

1. Runtime parsing SHALL NOT use mise [usage](https://mise.jdx.dev/tasks/task-arguments.html)
   (that applies to `mise run` tasks only). See [design.md §4.2](./design.md#42-cli-argument-parsing-zparseopts-not-mise-usage).
2. WHEN `xc-git fixup-suggest` parses argv
   THEN it SHALL use `zparseopts -D -F -E -A opts` for `-b`/`--base`, `-n`/`--top`, `-q`/`--best`,
   `--dry-run`, `-h`/`--help` per design §4.2.
3. WHEN an unknown flag is passed to `fixup-suggest`
   THEN it SHALL exit non-zero and print subcommand usage ( `-F` behavior).
4. WHEN `xc-git branch-preview` parses argv
   THEN it SHALL use `zparseopts` for `-h`/`--help` only, then require `<branch>` positional.
5. `log-fzf` MAY keep `case` parsing for `-h`/`--help` and optional action (design §4.2).
6. Mise task `xc-git:specs` MAY use mise `usage` for `--scenario` only (unchanged pattern).

---

### REQUIREMENT 9: Optional `gum` styling (shared)

**User Story:**

As a terminal user without `gum` installed (or in CI/pipes)
I want git helpers to work with plain text
so that optional UI polish never blocks git operations

**Acceptance Criteria:**

1. WHEN `xc-git` loads any subcommand that prints styled section headings
   THEN it SHALL `source` `"${XC_GIT_DIR}/_common.zsh"` per design §4.1.
2. WHEN `command -v gum` succeeds and stdout is a TTY
   THEN `_xc_git_emit <fg> <text>` SHALL call `gum style --foreground <fg> --bold <text>`.
3. WHEN `gum` is missing OR stdout is not a TTY
   THEN `_xc_git_emit` SHALL print `<text>` with `printf` only and exit 0 from the helper.
4. WHEN `gum style` fails at runtime
   THEN `_xc_git_emit` SHALL fall back to `printf` (same as fixup-suggest `_xcf_emit` today).
5. Subcommands `branch-preview` and `fixup-suggest` SHALL use `_xc_git_emit` for all section
   headings; `log-fzf` SHALL NOT call `gum` (fzf-only).
6. Gum SHALL NOT be used for argument parsing, git commands, or exit-code logic.

**Edge Cases:**

- fzf preview of `branch-preview` may run with non-TTY stdout → plain headings is correct.
- Mise lists `gum` in `config/bin` tooling; gum remains optional at runtime.

---

### REQUIREMENT 8: Documentation and integration surfaces

**User Story:**

As a dotfiles user
I want `xc-git` documented where I already look for git and shell workflows
so that I do not need to read source to discover subcommands and git aliases

**Acceptance Criteria:**

1. WHEN reading [config/bin/README.md](../../README.md)
   THEN it SHALL contain an **`xc-git`** section with subcommand table, examples, mise test
   command, and note that legacy `xc-git-*` names are thin wrappers per
   [design.md §14](./design.md#14-documentation-and-integration).
2. WHEN reading [README.md](../../../../README.md) (repo root)
   THEN it SHALL contain a **Terminal helpers (`config/bin`)** subsection listing `xc-git`
   subcommands with one-line purpose and example invocations (not only install/docker content).
3. WHEN reading [config/git/config](../../../git/config)
   THEN comment blocks for `fix`, `lol` / `fzl` / `fzlog`, and `fzb` SHALL reference the
   underlying `xc-git` subcommand where applicable; a `fixup-suggest` git alias SHALL be
   added per design §14.3.
4. WHEN reading [config/zsh/etc/functions/gitx](../../../zsh/etc/functions/gitx) `#?` help
   THEN `lol`, `fzl`, `fzlog`, and `fzb` entries SHALL state they delegate to `xc-git log-fzf`
   or `xc-git branch-preview` (via `_gitx_fzlog` / fzf preview).
5. WHEN running `dots git` or `dots git -h`
   THEN [config/zsh/etc/functions/dots](../../../zsh/etc/functions/dots) SHALL print `xc-git`
   top-level help (or forward `dots git <subcommand> …` to `xc-git` per design §14.4).

**Edge Cases:**

- Documentation MUST NOT claim semantic fixup guessing (latest-touch-only behavior).
- Root README lists `xc-git` only for merged helpers; other `xc-*` scripts MAY be one pointer
  to `config/bin/README.md` without full enumeration.

---

## Non-Goals

- Changing fixup-suggest algorithm (no semantic root pairing).
- Replacing gitx or reimplementing gitx actions inside `xc-git`.
- Adding new subcommands beyond the three merged scripts.
- Windows support beyond existing zsh/git assumptions.
