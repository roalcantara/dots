# DESIGN: `xc` Launcher Usage CLI Migration

## 1. Overview & Goals

Migrate **`config/bin/xc`** (the interactive launcher and dispatcher for `xc-*` tools) from legacy docopt `##?` headers and `xc-usage` parsing to the **`usage` CLI shebang pattern** (`#!/usr/bin/env -S usage zsh`).

### Goals

1. **Usage CLI Integration**: Shebang `#!/usr/bin/env -S usage zsh` with `#USAGE` annotations for metadata (`version`, `about`), commands (`list`, `up`), and usage examples.
2. **Pure Usage Tool Inspection**: Replace `xc-usage` calls with native `usage` CLI commands (`usage generate json -f <tool>` and `usage zsh <tool> --help`).
3. **Structured Metadata Extraction**: Use `usage generate json -f <tool>` and `jq` for robust tool summary and subcommand extraction without regex parsing.
4. **Shell Completion**: Leverage `usage generate completion-init zsh` (sourced in `config/zsh/.zshrc`) for automatic completion of `xc` and its subcommands.

---

## 2. Architecture & Component Roles

```
┌───────────────────────────────────────────────────────────┐
│                     User Invokes xc                       │
└─────────────────────────────┬─────────────────────────────┘
                              │
                (usage zsh shebang parses args)
                              │
     ┌────────────────────────┴────────────────────────┐
     ▼                                                 ▼
[xc list / xc up / --help]               [xc (default fzf launcher)]
  Executes subcommands                    │
  using $usage_* vars                     ├─ 1. Discover xc-* tools in XC_BIN_DIR
                                          ├─ 2. Extract metadata via `usage generate json`
                                          ├─ 3. Launch fzf with `usage zsh {2} --help` preview
                                          ├─ 4. Extract subcommands (if any) via JSON spec
                                          └─ 5. Run selected tool in foreground
```

### Components

- **`config/bin/xc`**: The executable launcher script written in zsh with `usage` shebang.
- **`usage` CLI**: Installed binary handling arg parsing, formatted help text, and JSON spec generation.
- **`jq`**: Lightweight JSON processor used by `xc` to parse `.about` and `.cmd.subcommands` from `usage generate json`.
- **`fzf`**: Interactive fuzzy finder rendering tool menu and live `usage zsh {2} --help` preview pane.

---

## 3. CLI Specification (`#USAGE` Header)

```zsh
#!/usr/bin/env -S usage zsh
# shellcheck shell=bash disable=SC2296,SC2298

#USAGE version "0.1.0"
#USAGE about "Interactive launcher for xc-* tools"

#USAGE cmd "list" help="Print discovered tools (name, path, summary)" {
#USAGE   example "xc list"
#USAGE }
#USAGE cmd "up" help="Run system and package maintenance updates" {
#USAGE   example "xc up"
#USAGE }

#USAGE example "xc"
#USAGE example "xc list"
#USAGE example "xc up"
```

### Dispatch Logic

- `xc --help`: Handled natively by `usage zsh` (stdout, exit 0).
- `xc list`: Outputs TSV table of discovered `xc-*` tools, paths, and descriptions.
- `xc up`: Runs system and package maintenance commands (`brew update`, `brew upgrade --greedy`, etc.) and exits 0.
- `xc` (no args): Launches interactive `fzf` tool picker.

---

## 4. Tool Discovery & Subcommand Resolution

### 4.1 Discovery (`_xc_discover`)

- Scans `XC_BIN_DIR` for executables matching `xc-*` (skipping `xc` itself).
- For each tool path:
  - Runs `usage generate json -f "$tool_path" 2>/dev/null`.
  - Extracts description using `jq -r '.about // "(no description)"'`.
  - Formats TSV row: `name <TAB> resolved_path <TAB> summary`.

### 4.2 Subcommand Detection & Listing

- **`_xc_has_subcommands`**:
  - Runs `usage generate json -f "$tool_path" 2>/dev/null`.
  - Returns 0 if `jq -e '.cmd.subcommands | length > 0'` succeeds.
- **`_xc_list_subcommands`**:
  - Extracts subcommands and summaries via `jq -r '.cmd.subcommands | to_entries[] | "\(.key)\t\(.value.help // .key)"'`.

### 4.3 `fzf` Interactive Picker & Execution

- **Tool Picker**:

  ```zsh
  fzf --delimiter=$'\t' --with-nth=1,3 \
      --prompt='xc ❯ ' \
      --header='Tool (↵ run, Esc cancel)' \
      --preview-window='right:60%:wrap' \
      --preview='usage zsh {2} --help'
  ```

- **Subcommand Picker**:

  ```zsh
  fzf --delimiter=$'\t' --with-nth=1,2 \
      --prompt="${name} ❯ " \
      --header='Subcommand (↵ run, Esc skip)' \
      --preview-window='right:60%:wrap' \
      --preview="usage zsh ${(q)tool_path} {1} --help"
  ```

- **Execution**: Runs selected binary directly in foreground: `command <name> [subcommand] [extra_args]`.

---

## 5. Test Plan & Acceptance Criteria

### Static Checks

1. `usage lint config/bin/xc`: Exit code 0.
2. `shellcheck config/bin/xc`: Passes cleanly.

### Integration Testing (`assets/integration/bin/xc.spec.ts`)

1. Direct script execution tests (`Bun.spawnSync([xc, ...])`).
2. Verification of `xc --help` output (exit code 0, contains Usage and subcommands).
3. Verification of `xc list` output (exit code 0, lists `xc-*` tools, excludes `xc` launcher itself).
4. Interactive fallback check: exit 1 with stderr hint when `fzf` and `gum` are absent.
5. Every `#USAGE example` has a corresponding integration test case.
