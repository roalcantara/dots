<!-- markdownlint-disable -->
# REQUIREMENTS: xc (launcher)

## OVERVIEW

Add **`config/bin/xc`**, a **launcher only** — all existing tools stay as **separate files**
(`xc-fabric`, `xc-git`, `xc-puts`, `xc-skills`, `xc-toast`, `xc-usage`). When the user runs
`xc` with no arguments (Enter), they browse **other** `xc-*` tools with **live stacked help
preview** (main + each subcommand, like repeated `-h`), optionally pick a **subcommand**, then
**run** the real executable.

Normative design: [design.md](./design.md). Depends on [xc-usage](../xc-usage/design.md) for
preview text (not hardcoded descriptions).

**Related:** [xc-portable-tools](../xc-portable-tools/design.md) (PATH-first `xc-*` bins).

---

## User Roles

- **Interactive user:** Runs `xc`, picks a tool, reads preview, confirms execution.
- **Maintainer:** Adds new `xc-*` script with `##?` header; launcher discovers it automatically.

---

### REQUIREMENT 1: Discover `xc-*` tools dynamically

**User Story:** As a user, I want the menu to list every installed `xc-*` tool without maintaining a manifest.

**Acceptance Criteria:**

1. WHEN `xc` scans for tools THEN it SHALL search `${XDG_CONFIG_HOME:-$HOME/.config}/bin` for executables matching `xc-*` and `xc-*/xc-*` package layout.
2. WHEN a symlink exists in `${XDG_LOCAL_BIN_DIR:-$HOME/.local/bin}` THEN deduplication SHALL prefer one entry per logical tool name.
3. WHEN the first `##?` line exists THEN the menu label SHALL use its one-line summary (text after `##? `, typically `name - description`).
4. WHEN no `##?` exists THEN the tool SHALL be listed with description `(no ##? help)` and preview SHALL show an error hint.
5. SHALL NOT hardcode tool names or descriptions in `xc` source (discovery + `xc-usage` / `-h` only).
6. SHALL NOT list **`xc`** itself in the menu.
7. SHALL NOT merge other `xc-*` scripts into `xc`; each tool remains its own file.

---

### REQUIREMENT 2: Interactive picker with preview (fzf preferred)

**User Story:** As a user, I want to see full help for the highlighted tool before I run it.

**Acceptance Criteria:**

1. WHEN `xc` runs with no arguments AND `fzf` is on PATH THEN it SHALL show an fzf list with a **right preview pane**.
2. WHEN the selection changes THEN preview SHALL show help equivalent to `-h` on that tool:
   - **Main** section: `xc-usage print <path>` (dispatcher / single-command help).
   - **Per subcommand** sections: for each entry under `##? Subcommands:`, append a labeled block
     (`<name> <sub> - Subcommand:`) using `command <name> <sub> -h` or `xc-usage print` on the
     module file — see [design.md §4.2](./design.md#42-preview-content-like-xc--h-stacked-for-subcommands).
3. WHEN the tool has no subcommands THEN preview SHALL be a single main section only.
4. WHEN the user runs `<tool> -h` directly THEN only **high-level** help SHALL be shown (not every subcommand’s Options).
5. WHEN the user runs `<tool> <sub> -h` directly THEN only that **subcommand’s** help SHALL be shown.
6. WHEN the user highlights `<tool>` in `xc` THEN preview SHALL call `xc-usage preview <path> --tool <name>` (stacked main + subs per [xc-usage design §5.8](../xc-usage/design.md#58-preview-output-shape-for-xc-launcher)).
7. All `xc-*` help text SHALL follow [xc-usage design §11.5](../xc-usage/design.md#115-xc-fabric-dispatcher-template-canonical) (xc-fabric main block + per-sub blocks; [docopt](http://docopt.org/) sections).
4. WHEN `fzf` is missing AND `gum` is available THEN a degraded UI (list + pager preview) MAY be used.
5. WHEN neither `fzf` nor `gum` is available THEN `xc` SHALL print a sorted tool list with paths and exit 1 with install hint.
6. Preview SHALL update on every highlight change (standard fzf `--preview`).

---

### REQUIREMENT 3: Execute selection (better than gitx paste)

**User Story:** As a user, I want Enter to run the tool, not only paste a command into my prompt.

**Acceptance Criteria:**

1. WHEN the user confirms a tool without subcommands THEN `xc` SHALL run `command <tool> [optional-args]` in the foreground and exit with that command's exit code.
2. WHEN the user confirms `xc-git` (or any tool with `##? Subcommands:` / `##? Commands:` block) THEN `xc` SHALL offer a **second** fzf step for subcommand (same preview pattern using full file help or subcommand slice).
3. WHEN optional extra arguments are needed THEN `xc` MAY prompt via `gum input` (or fzf `--print-query`) before execution; empty args SHALL be allowed.
4. SHALL NOT use `print -z` paste-only behavior as the primary path (gitx launcher pattern is explicitly not the goal).

---

### REQUIREMENT 4: `xc` self-help and meta commands

**Acceptance Criteria:**

1. WHEN `xc -h` or `xc --help` THEN output SHALL be `##?` help via `xc-usage guard`.
2. WHEN `xc list` THEN print machine-readable or plain table of discovered tools (no fzf) for scripts/CI.
3. `xc` itself SHALL have `#?` + `##?` headers per bin conventions.

---

### REQUIREMENT 5: Tests and documentation

**Acceptance Criteria:**

1. `tests/xc.spec.ts` SHALL cover: `list` output includes known tools; preview command succeeds on fixture; missing fzf fallback exit code.
2. `mise run xc:specs` task in `config/bin/mise.toml`.
3. `config/bin/README.md` SHALL document `xc` launcher and symlink `~/.local/bin/xc`.

---

## Traceability

| Requirement | Design | Task   |
| ----------- | ------ | ------ |
| Req-1       | §3     | T1     |
| Req-2       | §4     | T2     |
| Req-3       | §5     | T3     |
| Req-4       | §6     | T1, T4 |
| Req-5       | §7     | T4, T5 |
