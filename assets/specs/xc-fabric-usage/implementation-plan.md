# `xc-fabric` Usage CLI Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate `config/bin/xc-fabric` from legacy docopt `##?` headers, `xc-usage` parsing, and `zparseopts` to the `usage` CLI shebang (`#!/usr/bin/env -S usage zsh`).

**Architecture:** Replace shebang and docopt blocks in `config/bin/xc-fabric` with `#USAGE cmd`, `#USAGE flag`, and `#USAGE example` declarations. Refactor option and argument consumption to use `$usage_*` environment variables directly, removing `zparseopts` and `_xc_usage_cmd` helpers.

**Tech Stack:** zsh, usage CLI, fzf, Bun (for integration tests).

---

## File Structure & Responsibilities

- **`config/bin/xc-fabric`**: Fabric pattern runner script. Responsibilities:
  - Shebang `#!/usr/bin/env -S usage zsh`.
  - `#USAGE` annotations for subcommands (`run`, `ls`, `update`, `show`, `strategies`, `scrape`), global flags, and metadata.
  - Subcommand dispatch reading `$usage_*` variables directly (no `zparseopts`).
- **`assets/integration/bin/xc-fabric.spec.ts`**: Integration test suite. Responsibilities:
  - Executes `xc-fabric` directly (`[script, ...]`).
  - Verifies subcommands, global flags, and `#USAGE` example cases.
- **`config/bin/HANDOFF-USAGE-MIGRATION.md`**: Progress tracking documentation. Responsibilities:
  - Mark `xc-fabric` migration complete (all scripts in the repo now 100% migrated!).

---

## Tasks

### Task 1: Update shebang and `#USAGE` header in `config/bin/xc-fabric`

**Files:**

- Modify: `config/bin/xc-fabric:1-135`

- [ ] **Step 1: Replace legacy docopt headers with `usage zsh` shebang and `#USAGE` spec**

Update lines 1–135 of `config/bin/xc-fabric`:

```zsh
#!/usr/bin/env -S usage zsh
# shellcheck shell=bash disable=SC2296,SC2298,SC2178,SC2206

#USAGE cmd "run" help="Run a named pattern against stdin, clipboard, or URL" {
#USAGE   arg "[pattern]" help="Fabric pattern name"
#USAGE   arg "[url]" help="Optional URL; omit to use stdin or clipboard"
#USAGE   example "echo \"Hello\" | xc-fabric run summarize --raw"
#USAGE   example "xc-fabric run summarize https://youtu.be/example --yt-metadata"
#}
#USAGE cmd "ls" help="List Fabric patterns with descriptions" {
#USAGE   example "xc-fabric ls --raw"
#}
#USAGE cmd "update" help="Refresh Fabric patterns with fabric -U" {
#USAGE   example "xc-fabric update"
#}
#USAGE cmd "show" help="Show a pattern definition" {
#USAGE   arg "<pattern>" help="Fabric pattern name"
#USAGE   example "xc-fabric show summarize"
#}
#USAGE cmd "strategies" help="List Fabric strategies" {
#USAGE   example "xc-fabric strategies"
#}
#USAGE cmd "scrape" help="Scrape a URL with fabric -u, optionally through a pattern" {
#USAGE   arg "<url>" help="URL to scrape"
#USAGE   arg "[pattern]" help="Optional Fabric pattern to apply after scrape"
#USAGE   example "xc-fabric scrape https://example.com"
#}
#USAGE flag "-r --raw" help="Print raw output without TUI rendering"
#USAGE flag "--model <model>" help="Pass a model to fabric"
#USAGE flag "-c --copy" help="Pass --copy to fabric"
#USAGE flag "-o --output <file>" help="Pass --output to fabric and skip rendering"
#USAGE flag "-v <value>" help="Pass a fabric variable token verbatim"
#USAGE flag "--strategy <name>" help="Pass a fabric strategy to fabric"
#USAGE flag "--no-preview" help="Disable picker previews"
#USAGE flag "-y --yes" help="Skip confirmations"
#USAGE flag "--yt-timestamps" help="Use YouTube transcript timestamps"
#USAGE flag "--yt-comments" help="Include YouTube comments"
#USAGE flag "--yt-metadata" help="Include YouTube metadata"
#USAGE flag "--yt-playlist" help="Process a YouTube playlist"
#USAGE flag "--debug" help="Log fzf preview template and a dry-run sample to stderr"
#USAGE version "0.1.0"
#USAGE about "Interactive Fabric pattern runner with fzf/gum fallbacks"
#USAGE example "xc-fabric"
#USAGE example "xc-fabric ls --raw"
#USAGE example "echo \"Hello\" | xc-fabric run summarize --raw"
#USAGE example "xc-fabric run summarize https://youtu.be/example --yt-metadata"
```

- [ ] **Step 2: Verify spec with `usage lint`**

Run: `usage lint config/bin/xc-fabric`
Expected output: No issues found, exit code 0.

---

### Task 2: Refactor argument parsing and subcommand dispatch in `config/bin/xc-fabric`

**Files:**

- Modify: `config/bin/xc-fabric`

- [ ] **Step 1: Replace `zparseopts` and manual flag parsing with `$usage_*` variables**

Remove `zparseopts` parsing and initialize variables directly from `$usage_*`:

```zsh
RAW="${usage_raw:-0}"
COPY="${usage_copy:-0}"
YES="${usage_yes:-0}"
NO_PREVIEW="${usage_no_preview:-0}"
YT_TIMESTAMPS="${usage_yt_timestamps:-0}"
YT_COMMENTS="${usage_yt_comments:-0}"
YT_METADATA="${usage_yt_metadata:-0}"
YT_PLAYLIST="${usage_yt_playlist:-0}"
DEBUG="${usage_debug:-0}"
MODEL="${usage_model:-}"
OUTPUT="${usage_output:-}"
VAR="${usage_v:-}"
STRATEGY="${usage_strategy:-}"
```

- [ ] **Step 2: Update subcommand dispatch block**

Replace the main dispatch block:

```zsh
case "${1:-}" in
  run)
    _xc_fabric_cmd_run "$usage_pattern" "$usage_url"
    ;;
  ls)
    _xc_fabric_cmd_ls
    ;;
  update)
    _xc_fabric_cmd_update
    ;;
  show)
    if [[ -z "$usage_pattern" ]]; then
      usage zsh "${0:a}" show --help >&2
      exit 1
    fi
    _xc_fabric_cmd_show "$usage_pattern"
    ;;
  strategies)
    _xc_fabric_cmd_strategies
    ;;
  scrape)
    if [[ -z "$usage_url" ]]; then
      usage zsh "${0:a}" scrape --help >&2
      exit 1
    fi
    _xc_fabric_cmd_scrape "$usage_url" "$usage_pattern"
    ;;
  '')
    _xc_fabric_interactive
    ;;
  *)
    usage zsh "${0:a}" --help >&2
    exit 1
    ;;
esac
```

- [ ] **Step 3: Remove obsolete `_xc_usage_cmd` helper function**

Remove `_xc_usage_cmd` function from `config/bin/xc-fabric`.

- [ ] **Step 4: Test help output**

Run: `config/bin/xc-fabric --help` and `config/bin/xc-fabric run --help`.
Expected output: Formatted usage help displayed.

---

### Task 3: Update Integration Test Suite (`assets/integration/bin/xc-fabric.spec.ts`)

**Files:**

- Modify: `assets/integration/bin/xc-fabric.spec.ts`

- [ ] **Step 1: Ensure direct script execution in tests**

Verify test invocations in `xc-fabric.spec.ts` execute `xc-fabric` directly (`[scriptPath, ...]`) without `"zsh"` wrapper.

- [ ] **Step 2: Run integration test suite**

Run: `bun test assets/integration/bin/xc-fabric.spec.ts`
Expected output: All 30+ tests pass with 0 failures.

---

### Task 4: Final Verification & Progress Documentation

**Files:**

- Modify: `config/bin/HANDOFF-USAGE-MIGRATION.md`

- [ ] **Step 1: Run Full Verification Suite**

Run:

1. `usage lint config/bin/xc-fabric`
2. `shellcheck config/bin/xc-fabric`
3. `bun test assets/integration/bin/xc-fabric.spec.ts`
4. `bun test assets/integration/bin/*.spec.ts`

Expected output: 100% of tests pass across all files.

- [ ] **Step 2: Update `HANDOFF-USAGE-MIGRATION.md`**

Update progress table in `config/bin/HANDOFF-USAGE-MIGRATION.md` to mark `xc-fabric` migration as complete (100% complete!).

---

## Execution Handoff

Plan complete and saved to `assets/specs/xc-fabric-usage/implementation-plan.md`.
