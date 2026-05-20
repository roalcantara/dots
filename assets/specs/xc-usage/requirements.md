<!-- markdownlint-disable -->
# REQUIREMENTS: xc-usage

## OVERVIEW

Introduce **`xc-usage`**, a single self-contained executable under `config/bin/` that reads
**docopt-style `##?` headers** from scripts and **fully handles `-h` / `--help`** for every
`config/bin` tool via a **`guard`** subcommand. This replaces duplicated `grep '^#?' | sed`
blocks and aligns bin help with the convention already used by Zsh autoload functions
(`show_usage` + `##?`).

Normative CLI contracts, exit codes, migration from `#?` → `##?`, adoption patterns, and
**standalone** operation (mise-inspired layout only — no mise runtime) live in
[design.md](./design.md).

**Phase 1:** `config/bin` executables. **Phase 2:** all Zsh autoload functions under
`config/zsh/etc/functions/` plus documentation clarifying `show_usage` → `xc-usage`.

### Implementation status (repo snapshot)

| Requirement               | Status       | Notes                                                                |
| ------------------------- | ------------ | -------------------------------------------------------------------- |
| Req-1–6, 6a, 8 (core)     | **Done**     | `config/bin/xc-usage`; `mise run xc-usage:specs`                     |
| Req-12 (`xc-usage`)       | **Done**     | `--scope`, `list-subs`, `preview`; bin `-h` wiring in Tasks 3–5      |
| Req-7 (full bin adoption) | **Partial**  | `xc-puts`/`xc-toast` use `guard`; fabric/skills/git lack scoped `-h` |
| Req-9–11                  | **Not done** | Phase 2: `show_usage`, Zsh inventory, `config/zsh/README.md`         |

Normative contracts for **pending** work remain in [design.md](./design.md) and [tasks.md](./tasks.md).

---

## User Roles

- **Terminal user:** Runs `xc-fabric -h`, `xc-git fixup-suggest --help`, etc.; expects
  consistent help text shaped like [docopt](http://docopt.org/) usage blocks.
- **Script author:** Maintains `##?` headers in bin scripts; calls `xc-usage guard` instead of
  inline help extraction.
- **CI / maintainer:** Runs `mise run xc-usage:specs` to verify guard, print, and error paths.

---

## REQUIREMENTS

### REQUIREMENT 1: Self-contained `xc-usage` on PATH

**User Story:**

As a maintainer
I want one executable with no `lib/` tree
so that symlinks and imports stay obvious

**Acceptance Criteria:**

1. The implementation SHALL be a single file at `config/bin/xc-usage` (chmod +x).
2. The tree `config/bin/lib/xc-usage/` SHALL NOT exist.
3. `~/.local/bin/xc-usage` SHALL symlink to `~/.config/bin/xc-usage` per
   [design.md §2](./design.md#2-folder-structure).
4. The shebang SHALL be `#!/usr/bin/env zsh`.

---

### REQUIREMENT 2: Top-level `xc-usage` help

**User Story:**

As a terminal user
I want `xc-usage -h` to work without subcommands
so that the tool is self-documenting

**Acceptance Criteria:**

1. WHEN `xc-usage` is invoked with `-h` or `--help` as the first argument
   THEN it SHALL print `xc-usage`’s own `##?` block to stdout and exit 0 **before** any
   `guard` / `print` dispatch per [design.md §5.1](./design.md#51-top-level-argv-routing).
2. WHEN `xc-usage` is invoked with no arguments
   THEN it SHALL print `xc-usage`’s own `##?` block to stdout and exit 0.
3. Top-level help SHALL NOT require a target script path.

---

### REQUIREMENT 3: `##?` extraction (docopt headers only)

**User Story:**

As a script author
I want one comment prefix and docopt-shaped help
so that bin tools match Zsh function conventions

**Acceptance Criteria:**

1. WHEN `xc-usage` prints help for a target file
   THEN it SHALL read lines matching `^##?` only and strip the prefix with
   `sed 's/^##?//'` (optional single leading space after `?` trimmed to one space) per
   [design.md §6](./design.md#6-help-extraction).
2. WHEN the target file exists but contains zero `^##?` lines
   THEN it SHALL print an error to stderr naming the file, stating that `##?` docopt headers
   are required, and referencing [docopt.org](http://docopt.org/) for `Usage:` / `Options:`
   layout; exit code SHALL be 1.
3. WHEN the target file contains `#?` lines but zero `##?` lines
   THEN it SHALL NOT fall back to `#?`; behavior SHALL match criterion 2 (strict `##?` only).
4. WHEN the target file does not exist or is not readable
   THEN it SHALL print an error to stderr and exit 1.

**Edge Cases:**

- Encouraged header shape: `##? Usage:`, `##? Options:`, `##? Examples:` per docopt; validation
  of docopt grammar is **not** required in v1 (presence of at least one `##?` line is sufficient).

---

### REQUIREMENT 4: `guard` — full `-h` / `--help` handling

**User Story:**

As a script author
I want `xc-usage` to own help detection and printing
so that I do not duplicate `case -h|--help` grep blocks

**Acceptance Criteria:**

1. WHEN `xc-usage guard [script] "$@"` is invoked and the first remaining argument after
   option parsing is `-h` or `--help`
   THEN it SHALL print the target script’s `##?` help to stdout and exit 0 per
   [design.md §5.2](./design.md#52-subcommand-guard).
2. WHEN `guard` is invoked without a help flag
   THEN it SHALL exit 2 without printing help (caller continues normal execution).
3. WHEN `script` is omitted
   THEN `guard` SHALL resolve the target path to `${(%):-%x}` inside `xc-usage` (the `xc-usage`
   binary itself). Top-level bin executables SHALL therefore pass an explicit script path:
   `command xc-usage guard "${0:a}" "$@"` per [design.md §4.2](./design.md#42-subcommand-guard).
4. WHEN `script` is provided as the first argument after `guard`
   THEN `guard` SHALL use that path (required when the help target is not the caller file, e.g.
   explicit path to `config/bin/xc-git` after `_xc_git_resolve_self`).
5. Exit codes for `guard` SHALL be exactly: 0 = help printed; 1 = error; 2 = not a help request.

**Edge Cases:**

- Only the **first** positional argument is treated as help (`-h` / `--help`). Global flags
  before subcommands (e.g. `xc-fabric -h run`) are **out of scope** for v1 unless the host
  script reorders argv or calls `guard` after its own top-level parse.

---

### REQUIREMENT 5: Standalone operation (no mise dependency)

**User Story:**

As a dotfiles user without mise installed
I want help to work from `xc-usage` on PATH alone
so that shell tools do not depend on the dev toolchain

**Acceptance Criteria:**

1. WHEN `xc-usage` runs `guard`, `print`, or `validate`
   THEN it SHALL use only `zsh`, `grep`, and `sed` — no `mise`, no `usage` CLI, no read of
   `mise.toml`, and no parsing of `#USAGE` / `#MISE` headers per
   [design.md §12](./design.md#12-standalone-vs-mise-inspired-conventions-only).
2. WHEN `show_usage` delegates to `xc-usage print`
   THEN it SHALL use `command xc-usage` only — not `mise run`.
3. Documentation SHALL describe three layers (script `##?`, `zparseopts`, mise task `usage`
   field) per [design.md §11.2](./design.md#112-three-layer-help-model-document-prominently).
4. Inspiration from [mise task arguments](https://mise.jdx.dev/tasks/task-arguments.html) SHALL
   be limited to **section layout** in `##?` comments, not shared implementation.

---

### REQUIREMENT 6: `print` — unconditional help output

**User Story:**

As a test author
I want to print help for a fixture path without simulating `-h`
so that Bun specs stay simple

**Acceptance Criteria:**

1. WHEN `xc-usage print [script]` is invoked
   THEN it SHALL print the target’s `##?` lines to stdout and exit 0.
2. WHEN `script` is omitted
   THEN it SHALL resolve `${(%):-%x}` the same way as `guard`.
3. `print` SHALL use the same `##?` extraction and missing-header errors as `guard`.
4. WHEN `print` runs and the `##?` text does not document `-h` or `--help`
   THEN it SHALL append the standard help footer per [design.md §5.4](./design.md#54-subcommand-print)
   unless `XC_USAGE_NO_HELP_FOOTER=1` or `--no-help-footer` is set.

---

### REQUIREMENT 6a: `validate` — lint `##?` headers

**User Story:**

As a maintainer
I want to verify scripts have complete docopt headers
so that incomplete help is caught in CI

**Acceptance Criteria:**

1. WHEN `xc-usage validate [script]` runs on a valid file per [design.md §5.5](./design.md#55-subcommand-validate)
   THEN it SHALL exit 0.
2. WHEN the file lacks `##?`, `Usage:`, or `-h`/`--help` documentation
   THEN it SHALL exit 1 with actionable stderr.
3. `validate` SHALL NOT invoke mise or parse KDL usage specs.
4. `mise run xc-usage:validate` MAY exist as a developer task that loops over bin scripts; the
   `xc-usage` binary itself remains standalone.

---

### REQUIREMENT 7: Bin script adoption

**User Story:**

As a terminal user
I want every `config/bin` executable to use the same help mechanism
so that behavior is predictable

**Acceptance Criteria:**

1. WHEN any primary `config/bin` executable handles help
   THEN it SHALL delegate to `xc-usage guard` per [design.md §7](./design.md#7-bin-script-adoption-pattern)
   and SHALL NOT use inline `grep '^#?'` or `grep '^##?'` for help (except inside `xc-usage` itself).
2. Phase 1 migration SHALL update at minimum:
   - `config/bin/xc-fabric`
   - `config/bin/xc-skills`
   - `config/bin/xc-git` (single flat executable; subcommand help via scoped `##?` blocks in the same file per [xc-portable-tools design](../xc-portable-tools/design.md))
   - `config/bin/xc-puts`, `config/bin/xc-toast`
   - `config/bin/xc-usage` (self)
3. Each migrated file SHALL convert `#?` header lines to `##?` and include a docopt-shaped
   `Usage:` section with `-h | --help` documented.
4. `config/bin/README.md` SHALL document `##?` + `xc-usage guard` as the canonical convention
   (replacing `#?` + inline grep).

**Edge Cases:**

- “No arguments → usage + exit 1” for missing required args SHALL remain **per-script** in v1
  (not centralized in `xc-usage`).

---

### REQUIREMENT 8: Automated tests and mise task

**User Story:**

As a maintainer
I want CI-friendly specs
so that help regressions are caught early

**Acceptance Criteria:**

1. WHEN `mise run xc-usage:specs` runs from `config/bin`
   THEN it SHALL execute `bunx bun test tests/xc-usage.spec.ts` with
   `XC_USAGE` set to `{{ config_root }}/xc-usage` per [design.md §9](./design.md#9-testing).
2. Tests SHALL cover at minimum: self `-h`, `guard` help exit 0, `guard` non-help exit 2,
   missing `##?` exit 1, `print` on fixture, and stderr message referencing docopt.
3. Tests MAY use `usage_scenario` + mise `--scenario` with the same pattern as `xc-git:specs`.

---

### REQUIREMENT 9: `show_usage` delegates to `xc-usage`

**User Story:**

As a Zsh user
I want `show_usage` to keep working
so that existing `autoload -Uz show_usage` call sites need minimal edits

**Acceptance Criteria:**

1. WHEN `show_usage` is invoked with no arguments
   THEN it SHALL resolve the calling function name from `funcstack[2]` and print that
   function file’s `##?` via `command xc-usage print <resolved-path>` per
   [design.md §10](./design.md#10-zsh-functions-and-show_usage).
2. WHEN `show_usage <name>` is invoked and `<name>` is an autoloaded function name
   THEN it SHALL resolve `functions_source[<name>]` (autoload `+X` if needed) and call
   `xc-usage print` on that path.
3. WHEN `show_usage <path>` is invoked and `<path>` is a readable file
   THEN it SHALL call `xc-usage print <path>` directly (supports `recase` passing `$src`).
4. WHEN resolution fails
   THEN it SHALL print an error to stderr and return 1 (same intent as today).
5. `show_usage` SHALL NOT duplicate `grep '^##?'` logic; extraction lives only in `xc-usage`.

---

### REQUIREMENT 10: Zsh autoload functions adopt `##?` + `xc-usage`

**User Story:**

As a maintainer
I want every loadable function in `config/zsh/etc/functions` to use the same help stack
so that bin tools and shell functions behave consistently

**Acceptance Criteria:**

1. Each file in the inventory in [design.md §10.3](./design.md#103-migration-inventory) SHALL
   expose help through `show_usage` and/or `command xc-usage print|guard` — not ad-hoc
   `echo` usage blocks, except where noted as intentional stderr usage text.
2. Files with `##?` headers SHALL pass `xc-usage print <file>` without error after migration.
3. Files listed as **custom usage** in §9.2 (`keyring`, `zsys`, `barrel`, `gen`) SHALL replace
   hand-written usage with `##?` docopt headers + `show_usage` / `xc-usage print`.
4. Functions that handle `-h` / `--help` via `zparseopts` SHALL call `show_usage` (or
   `command xc-usage print` with explicit path) on help — not inline `echo` help text.
5. `dots` SHALL handle top-level `-h` / `--help` by printing its `##?` block via `xc-usage`
   (in addition to existing subcommand cases).
6. Phase 2 SHALL NOT remove `show_usage` from `$fpath`; it remains the Zsh-facing name.

---

### REQUIREMENT 11: Documentation for Zsh + bin help

**User Story:**

As a new contributor
I want written conventions for `##?`, `xc-usage`, and `show_usage`
so that I know which tool to use in bin vs Zsh

**Acceptance Criteria:**

1. A new file `config/zsh/README.md` SHALL document:
   - Canonical `##?` template per [design.md §11.1](./design.md#111-canonical--template-authors-copy-this)
   - **Standalone `xc-usage`** — not mise; see [design.md §12](./design.md#12-standalone-vs-mise-inspired-conventions-only)
   - Three-layer help model per [design.md §11.2](./design.md#112-three-layer-help-model-document-prominently)
   - Command reference + worked example: [design.md §4](./design.md#4-command-reference); out of scope: [§13](./design.md#13-out-of-scope)
   - `show_usage` as the Zsh entrypoint delegating to `xc-usage print`
   - `command xc-usage` on `$PATH` via `~/.local/bin`
   - When to use `show_usage` vs `command xc-usage guard "${0:a}"` (bin only)
2. `config/bin/README.md` SHALL cross-link `config/zsh/README.md` and state mise `usage` field
   applies only to `mise run` tasks, not to `xc-usage`.
3. `config/zsh/etc/functions/show_usage` header comments SHALL state it delegates to `xc-usage`.
4. `assets/specs/xc-git/design.md` help note SHALL be updated from `#?` to `##?` + `xc-usage`
   when Task 10 runs (docs-only cross-reference).

---

### REQUIREMENT 12: Scoped docopt help (`xc-fabric` style)

**User Story:**

As a terminal user
I want `xc-fabric -h` to show the full dispatcher help and `xc-fabric run -h` to show run-specific help
so that help matches [docopt](http://docopt.org/) and stays focused per invocation

**Acceptance Criteria:**

1. All primary bin tools (`xc-fabric`, `xc-skills`, `xc-git`, `xc-puts`, `xc-toast`) SHALL use
   `##?` headers shaped per [design.md §11.5](./design.md#115-xc-fabric-dispatcher-template-canonical).
2. `xc-usage` SHALL implement `list-subs`, `print --scope main`, `print --scope sub:<name>`,
   and `preview` per [design.md §5.6–5.8](./design.md#56-scoped-help---scope-list-subs-preview).
3. WHEN `<tool> -h` is run on a dispatcher
   THEN stdout SHALL be `--scope main` only (Usage, Options, Subcommands, Examples as authored).
4. WHEN `<tool> <sub> -h` is run
   THEN stdout SHALL be `--scope sub:<sub>` only (that sub’s Usage, Options/Arguments, Examples).
5. WHEN `xc` launcher previews a dispatcher
   THEN stdout SHALL equal `xc-usage preview` (main + every sub), scrollable in fzf.
6. Flat tools (`xc-puts`, `xc-toast`) SHALL use a single block; `main` scope equals full help.
7. `validate` SHOULD warn when a dispatcher has `Subcommands:` but no matching `##? <tool> <sub> -`
   title line for each listed sub.

---

## Traceability

| Requirement | Design sections | Tasks         |
| ----------- | --------------- | ------------- |
| Req-1       | §2, §3          | Task 1        |
| Req-2       | §5.1            | Task 1        |
| Req-3       | §6              | Task 1, 2     |
| Req-4       | §5.2, §7        | Task 1, 3     |
| Req-5       | §12, §13        | Task 1, 9     |
| Req-6       | §5.4            | Task 1, 2     |
| Req-6a      | §5.5            | Task 1, 6     |
| Req-7       | §7              | Task 3–5      |
| Req-8       | §9              | Task 2, 6, 10 |
| Req-9       | §10.1–10.2      | Task 7        |
| Req-10      | §10.3–10.4      | Task 8        |
| Req-11      | §4, §11, §13    | Task 9        |
| Req-12      | §5.6–5.9, §11.5 | Task 1b, 3–5  |
