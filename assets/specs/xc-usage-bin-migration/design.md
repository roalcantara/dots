# DESIGN: Migrate config/bin Scripts to USAGE CLI

## 1. Overview & Architecture

This design specifies adapting five `config/bin/` utility scripts from legacy `##?` docopt headers and `xc-usage` parsing to the **[USAGE CLI specification](https://usage.jdx.dev/cli/scripts)**:

1. `config/bin/xc-md`
2. `config/bin/xc-puts`
3. `config/bin/xc-toast`
4. `config/bin/xc-skills`
5. `config/bin/xc-git`

### Reference Model (`config/bin/xc`)
- Uses `#!/usr/bin/env -S usage (zsh|bash)` shebang.
- Documents tool metadata, arguments, flags, subcommands, and examples via `#USAGE` declarative comments.
- Runtime intercepts `--help` and `-h` automatically, emitting formatted help without executing script body.
- Exports validated arguments and flags as `usage_*` environment variables.

---

## 2. Component Specifications

### 2.1 `config/bin/xc-md` (Tier 1: Minimal Stdin Pipe)

#### Shebang & Header
```zsh
#!/usr/bin/env -S usage zsh
# shellcheck shell=bash disable=SC2154

#? dots 0.1.0
#? License RIT (Robot Institute of Technology)
#? This is free software: you are free to change and redistribute it.
#? There is NO WARRANTY, to the extent permitted by law.

#USAGE version "0.1.0"
#USAGE about "Render markdown from stdin: glow → bat → plain"
#USAGE example "xc-md < input.md"
#USAGE example "echo '# Title' | xc-md"
#USAGE example "xc-usage <target> --md"
```

#### Body Logic
```zsh
emulate -L zsh
setopt no_unset pipe_fail

if command -v glow >/dev/null 2>&1; then
  glow - 2>/dev/null || cat
elif command -v bat >/dev/null 2>&1; then
  bat -l md --paging=never 2>/dev/null || cat
else
  cat
fi
exit 0
```

---

### 2.2 `config/bin/xc-puts` (Tier 1: Flat Output Formatter)

#### Shebang & Header
```zsh
#!/usr/bin/env -S usage zsh
# shellcheck shell=bash disable=SC2154

#? puts 0.1.0
#? Copyright (C) 200X Thomas Light
#? License RIT (Robot Institute of Technology)
#? This is free software: you are free to change and redistribute it.
#? There is NO WARRANTY, to the extent permitted by law.

#USAGE version "0.1.0"
#USAGE about "Formats and prints a message"
#USAGE arg "[message]" help="The text message to print"
#USAGE flag "-p --prefix <prefix>" help="Print message with prefix"
#USAGE flag "-g --green" help="Print message in green"
#USAGE flag "-r --red" help="Print message in red"
#USAGE flag "-y --yellow" help="Print message in yellow"
#USAGE flag "-b --blue" help="Print message in blue"
#USAGE flag "-d --debug" help="Print log message in debug"
#USAGE flag "-e --error" help="Print log message in error"
#USAGE flag "-f --fatal" help="Print log message in fatal"
#USAGE flag "-i --info" help="Print log message in info"
#USAGE flag "-w --warn" help="Print log message in warn"
#USAGE example "xc-puts --green 'Success!'"
#USAGE example "xc-puts --red 'Error!'"
#USAGE example "xc-puts --yellow 'Warning!'"
#USAGE example "xc-puts --prefix 'SETUP' 'Message!'"
#USAGE example "xc-puts --prefix 'SETUP' --warn 'Message!'"
```

#### Body Logic
- Remove `zparseopts`, `_xc_usage_find`, and manual help checks.
- Empty input guard:
  ```zsh
  if [[ -z "${usage_message:-}" ]]; then
    usage zsh "${0:a}" --help >&2
    exit 1
  fi
  ```
- Map `usage_*` variables directly to `level`, `color`, and `zsh_color`.
- Format output using `gum log` / `gum style` when available, falling back to Zsh prompt formatting.

---

### 2.3 `config/bin/xc-toast` (Tier 1: Positional & Flag Notification)

#### Shebang & Header
```zsh
#!/usr/bin/env -S usage zsh
# shellcheck shell=bash disable=SC2154

#? toast 0.1.0
#? License RIT (Robot Institute of Technology)
#? This is free software: you are free to change and redistribute it.
#? There is NO WARRANTY, to the extent permitted by law.

#USAGE version "0.1.0"
#USAGE about "Display a terminal toast notification overlay"
#USAGE arg "[message]" help="The message to display"
#USAGE arg "[duration_pos]" help="The duration of the toast in seconds"
#USAGE arg "[type_pos]" help="The type of toast to display (info|success|error|warning)"
#USAGE flag "-d --duration <duration>" help="Duration in seconds" default="3"
#USAGE flag "-t --type <type>" help="Type of toast (info|success|error|warning)" default="info"
#USAGE example "xc-toast 'Hello, world!'"
#USAGE example "xc-toast 'Hello, world!' 5"
#USAGE example "xc-toast 'Hello, world!' 5 error"
#USAGE example "xc-toast 'Process started' -d 3 -t info"
```

#### Body Logic
- Remove `_xc_usage_find` and `##?` docopt blocks.
- Guard missing message:
  ```zsh
  if [[ -z "${usage_message:-}" ]]; then
    usage zsh "${0:a}" --help >&2
    exit 1
  fi
  ```
- Resolve values with fallback:
  ```zsh
  local message="$usage_message"
  local duration="${usage_duration_pos:-${usage_duration:-3}}"
  local type="${usage_type_pos:-${usage_type:-info}}"
  ```
- Render toast using `tput` with async background clear subshell.

---

### 2.4 `config/bin/xc-skills` (Tier 2: Multi-Command Bash Dispatcher)

#### Shebang & Header
```bash
#!/usr/bin/env -S usage bash
# shellcheck shell=bash disable=SC2154

#USAGE cmd "sync" help="Mirror symlinks from source to one or more target or agent paths" {
#USAGE   flag "--dry-run" help="Print actions without making filesystem changes"
#USAGE   flag "--prune" help="Remove destination symlinks not present in source"
#USAGE   flag "-s --source <path>" help="Source directory (default: ~/.claude/skills)"
#USAGE   flag "-a --agent <name>" help="Agent name; resolved via lookup table (repeatable)"
#USAGE   flag "-t --target <path>" help="Target directory path (repeatable)"
#USAGE   flag "-l --local" help="Use project/local path instead of global path for agents"
#USAGE   example "xc-skills sync"
#USAGE   example "xc-skills sync --dry-run"
#USAGE   example "xc-skills sync --prune"
#USAGE   example "xc-skills sync -s ~/.claude/skills -a antigravity"
#USAGE   example "xc-skills sync -s ~/.claude/skills -t ~/.gemini/antigravity/skills --dry-run --prune"
#USAGE }
#USAGE cmd "collect" help="Bring regular files from agent dirs into source; replace with symlinks" {
#USAGE   flag "--dry-run" help="Print actions without making filesystem changes"
#USAGE   flag "-s --source <path>" help="Source directory (default: ~/.agents/skills)"
#USAGE   flag "-a --agent <name>" help="Agent name; resolved via lookup table (repeatable)"
#USAGE   flag "-t --target <path>" help="Target directory path (repeatable)"
#USAGE   flag "-l --local" help="Use project/local path instead of global path for agents"
#USAGE   example "xc-skills collect --dry-run"
#USAGE }
#USAGE version "0.1.0"
#USAGE about "Synchronize skill symlinks across AI agent directories"
#USAGE example "xc-skills sync"
#USAGE example "xc-skills collect --dry-run"
#USAGE example "xc-skills sync -a cursor -a codex"
```

#### Body Logic
- Remove all `##?` docopt blocks.
- Update `usage()` function:
  ```bash
  usage() {
    usage bash "$SCRIPT_PATH" --help
  }
  ```
- Subcommand execution: dispatch via `case "$1"` to `cmd_sync` or `cmd_collect`.
- Keep the internal option loop for multi-value repeatable flags (`-a`, `-t`) since bash shebang variables only preserve the scalar tail.

---

### 2.5 `config/bin/xc-git` (Tier 2: Multi-Command Zsh Dispatcher)

#### Shebang & Header
```zsh
#!/usr/bin/env -S usage zsh
# shellcheck shell=bash disable=SC2296,SC2298,SC2154

#USAGE cmd "branch-preview" help="Display branch metadata and recent commits" {
#USAGE   arg "<branch>" help="Local branch name to preview"
#USAGE   example "xc-git branch-preview main"
#USAGE }
#USAGE cmd "fixup-suggest" help="Fixup into latest branch commit that touched a path" {
#USAGE   arg "[paths...]" help="Paths to analyze for fixup"
#USAGE   flag "-b --base <ref>" help="Upstream integrated branch (default: origin/main)" default="origin/main"
#USAGE   flag "-n --top <count>" help="Show at most N ranked commits (default: 10)" default="10"
#USAGE   flag "-q --best" help="Print only the top commit short hash (for scripts)"
#USAGE   flag "--dry-run" help="Do not run git commit when no fixup target exists"
#USAGE   example "xc-git fixup-suggest --dry-run config/bin/README.md"
#USAGE }
#USAGE cmd "log-fzf" help="Interactive git log (fzf); pick a commit, optional gitx actions" {
#USAGE   arg "[action]" help="Optional gitx action: rebase-from, fix, reword, edit, drop, reset-soft, reset-hard"
#USAGE   example "xc-git log-fzf fix"
#USAGE }
#USAGE version "0.1.0"
#USAGE about "Git helpers (branch preview, fixup suggest, log fzf)"
#USAGE example "xc-git branch-preview main"
#USAGE example "xc-git fixup-suggest --dry-run config/bin/README.md"
#USAGE example "xc-git log-fzf fix"
```

#### Body Logic
- Remove `_xc_git_xc_usage`, `_xc_git_subhelp`, and all `##?` blocks.
- Top-level help and subcommand `--help` are handled automatically by `usage zsh`.
- Subcommand handler functions (`_xc_git_branch_preview`, `_xc_git_fixup_suggest`, `_xc_git_log_fzf`) read their `usage_*` variables or positional arguments directly.
- Dispatch at root:
  ```zsh
  if [[ -z "${1:-}" ]]; then
    usage zsh "${0:a}" --help >&2
    exit 1
  fi

  subcommand="$1"
  shift

  case "$subcommand" in
    branch-preview) _xc_git_branch_preview "$@" ;;
    fixup-suggest)  _xc_git_fixup_suggest "$@" ;;
    log-fzf)        _xc_git_log_fzf "$@" ;;
    *)
      echo "xc-git: unknown subcommand: ${subcommand}" >&2
      usage zsh "${0:a}" --help >&2
      exit 1
      ;;
  esac
  ```

---

## 3. Integration Testing & Quality Gates

Each migrated script must pass:
1. **`usage lint config/bin/<script>`**: Validates that all `#USAGE` blocks conform to specification.
2. **Direct Execution in Bun Integration Tests**:
   - `assets/integration/bin/xc-md.spec.ts`
   - `assets/integration/bin/xc-puts.spec.ts`
   - `assets/integration/bin/xc-toast.spec.ts`
   - `assets/integration/bin/xc-skills.spec.ts`
   - `assets/integration/bin/xc-git.spec.ts`
   - Note: all tests invoke `[scriptPath, ...]` directly without `["zsh", scriptPath]` so that the shebang executes.
3. **Every `#USAGE example` line verified**: Direct smoke test or test assertion for every documented example.
4. **ShellCheck**: Pass `shellcheck` with zero warnings/errors.
