<!-- markdownlint-disable -->
# xc-fabric — Design

## 1. OVERVIEW

`xc-fabric` is a single `zsh` script (`~/.config/bin/xc-fabric`) with no external
helper files. It follows the exact conventions of `xc-git-log-fzf`:

- `#!/usr/bin/env zsh` shebang
- `#?` comment block for self-documenting help
- Subcommand dispatch via `case` on `$1`
- `fabric-ai` is the only hard dependency — the script exits fatally without it
- Tested via `tests/xc-fabric.spec.ts` + `mise run xc-fabric:specs`

The key design insight is a layered helper system:

- **`_boot_caps` + `_CAPS`** — once per process, `command -v` populates associative array
  `_CAPS[fabric|gum|glow|bat|fzf]` with `1`/`0`; all `_ui_*` paths read integers (no repeated PATH probes).
- **`_boot_clip` + `_CLIP_CMD`** — once per process, resolve Darwin `pbpaste` vs Linux
  `wl-paste` / `xclip` / `xsel` into argv array `_CLIP_CMD`; `_ui_clip` only executes it.
- **`_boot_paths`** — sets `_PATTERNS_DIR` from `FABRIC_PATTERNS_DIR` or default.
- **`_boot_preview_cmd`** — memoized fzf preview shell string (glow → bat → sed) built once.
- **`_ui_*` wrappers** — abstract gum interactions so `gum` is optional; **`_ui_filter` prefers `fzf`**
  (scrollable preview, custom binds; preview source chosen inside `_ui_filter` from `--no-preview`
  and optional `--preview` override) and falls back to `gum filter`, then plain `read`.
- **`_ui_clip`** — executes cached `_CLIP_CMD`; not gum-related.

When `gum` is absent the script degrades gracefully: logging → `printf`, pickers → `read`,
spinner → `printf` + direct exec. Non-interactive paths (`run --raw`, `ls --raw`, etc.)
work without `gum` or `fzf`.

**Installation vs checks:** The script **never** installs packages. Operators run
`mise run setup` to ensure `fabric-ai`, `bat`, `fzf`, and (on Linux) `xclip`
are available; the script only **checks** and warns via `_boot_check_deps`.

---

## 2. FOLDER STRUCTURE

```tree
~/.config/bin/
  ├── LICENSE
  ├── README.md                          ← must be updated
  ├── config.yml                         ← optional placeholder (not read by `xc-fabric`)
  ├── mise.toml                          ← must be updated (tasks only; see §11)
  ├── specs/
  │   └── xc-fabric/                     ← SDD docs
  │       ├── assets/
  │       ├── design.md
  │       ├── requirements.md
  │       └── tasks.md
  ├── tests/
  │   ├── fixtures/
  │   │   └── xc-fabric/
  │   │       └── patterns/              ← test fixture patterns
  │   ├── xc-git-log-fzf.spec.ts
  │   └── xc-fabric.spec.ts             ← new test file
  ├── xc-fabric                         ← the new script
  ├── xc-git-branch-preview
  └── xc-git-log-fzf
```

---

## 3. ARCHITECTURE

### Component Architecture

```text
xc-fabric
├── Section 0: constants          (flag mirrors: RAW, MODEL, …)
├── Section 1: helpers
│   ├── _boot_caps / _boot_clip / _boot_paths
│   ├── _CAPS / _CLIP_CMD / _PATTERNS_DIR / _PREVIEW_CMD globals
│   └── _ui_*  wrappers            (gum abstraction; _ui_filter = fzf → gum → read)
│   └── _ui_clip                   (clipboard via cached _CLIP_CMD)
├── Section 2: dependency check   (_boot_check_deps)
├── Section 3: pattern helpers    (`_pattern_list`, `_pattern_list_lines`, `_pattern_list_item_format`, `_pattern_file_extract_desc`, `_url_is_youtube`, `_url_pattern_implies_yt`)
├── Section 4: input helpers      (`_ui_input_read`)
├── Section 5: output + exec      (_ui_render_markdown, _fabric_build_yt_args, _fabric_exec_stdin, _fabric_exec_youtube, _fabric_exec_scrape)
├── Section 6: subcommands        (cmd_default, cmd_run, cmd_ls, cmd_update, cmd_show, cmd_strategies, cmd_scrape)
├── Section 7: arg parsing        (flag loop → dispatch)
└── Section 8: entrypoint         (main "$@")
```

### Data Flow

```text
stdin pipe / _ui_clip / YouTube or scrape URL
              │
              ▼
        _ui_input_read
              │
    ┌─────────┴──────────┬──────────────────┐
    ▼                    ▼                  ▼
_fabric_exec_stdin      _fabric_exec_youtube   _fabric_exec_scrape
(text input)      (URL + _fabric_build_yt_args)  (fabric-ai -u URL [pattern])
    │                    │                  │
    └─────────┬──────────┴──────────────────┘
              │
         fabric-ai CLI
              │
              ▼
       _ui_render_markdown (skipped when --raw or --output)
      (glow → bat → cat)
              │
              ▼
           stdout
```

### Technology Decisions

- **zsh** — consistent with all other `xc-*` scripts; no bash-isms needed.
- **`fabric-ai` is the only hard dependency** — exits fatally without it.
- **`fzf` optional, preferred for `_ui_filter`** — matches `xc-git-log-fzf` repo convention; `gum filter` remains tier-2.
- **`gum` is optional** — every gum call is wrapped in an `_ui_*` function with a plain-text fallback.
- **`set -euo pipefail` + ERR trap** — strict mode; `_ui_log_error` reports the failing line number before exiting.
- **No external helper files** — self-contained per project convention (D-1).

### Function naming (pointer)

- **Normative detail:** [§13 D-10](#d-10-private-function-naming-shell-style) (decision record).
- **External baseline:** [Google Shell Style Guide — Function names](https://google.github.io/styleguide/shellguide.html#s7.1-function-names) — lowercase, underscores between words; `package::func` is for **sourced libraries**, not a hard rule for every script.
- **This script:** private helpers use a **subsystem-first** `_*` prefix (leading `_` = implementation detail, not the public `cmd_*` / `main` CLI). We **do not** use `::` here because `xc-fabric` is a **single executable file**, not a package meant to be `source`d into another shell.
- **Implemented buckets** (see D-10): `_boot_*` (startup, deps, preview memo), `_ui_*` (terminal / gum / fzf / markdown render), `_pattern_*` (pattern catalog + picker rows), `_url_*` (YouTube / URL predicates), `_fabric_*` (`fabric-ai` argv + run matrix).

---

## 4. SCRIPT STRUCTURE

```zsh
#!/usr/bin/env zsh

#? xc-fabric - … (full #? block — see requirements.md §Requirement 1)

set -euo pipefail

# ── 0. constants ──────────────────────────────────────────────────────────────

# ── 1. helpers ────────────────────────────────────────────────────────────────
# _boot_paths / _boot_caps / _boot_clip / _boot_preview_cmd
# _CAPS / _CLIP_CMD / _PATTERNS_DIR / _PREVIEW_CMD
# _ui_log / _ui_log_info / _ui_log_warn / _ui_log_error / _ui_log_fatal
# _ui_clip
# _ui_prompt / _ui_confirm / _ui_spinner / _ui_table / _ui_filter

# ── 2. dependency check ───────────────────────────────────────────────────────
# _boot_check_deps

# ── 3. pattern helpers ────────────────────────────────────────────────────────
# _pattern_list / _pattern_list_lines / _pattern_list_header / _pattern_list_item_format
# _pattern_list_item_truncate_desc / _pattern_file_extract_desc
# _url_is_youtube / _url_pattern_implies_yt

# ── 4. input helpers ──────────────────────────────────────────────────────────
# _ui_input_read

# ── 5. output + exec ─────────────────────────────────────────────────────────
# _ui_render_markdown / _fabric_build_yt_args / _fabric_exec_stdin / _fabric_exec_youtube / _fabric_exec_scrape

# ── 6. subcommands ────────────────────────────────────────────────────────────
# cmd_default / cmd_run / cmd_ls / cmd_update / cmd_show / cmd_strategies / cmd_scrape

# ── 7. argument parsing & dispatch ───────────────────────────────────────────
# while loop over options (--raw, --model, --copy, --output, -v, --strategy, --yes, --no-preview, --yt-*)
# case "$1" in run|ls|update|show|strategies|scrape|-h|--help) … esac
# fallthrough → cmd_default

# ── 8. entrypoint ─────────────────────────────────────────────────────────────
main "$@"
```

**Help:** mirror `xc-git-log-fzf`: top-level `case "${1:-}" in -h|--help) … esac` **before** `main` definitions, or first lines inside `main` before `_boot_check_deps` — either is acceptable as long as `-h`/`--help` never call `_boot_check_deps` (Req-1).

---

## 5. SCRIPT ARGUMENTS

Flags are parsed with a manual `while` loop (no `getopt` — keeps zsh portability,
matches existing script style).

**Global options (available on all subcommands):**

```text
--raw / -r
--model <model>
--copy / -c
--output <file> / -o <file>
-v <value> / --variable=<value>   (repeatable; passed verbatim to fabric)
--strategy <name>
--no-preview
--yes / -y
--yt-timestamps
--yt-comments
--yt-metadata
--yt-playlist
-h / --help
```

**Parsing order:**

1. Global flags are consumed first by the `while` loop.
2. Remaining positional args are passed to the subcommand dispatcher.

**Passthrough policy (D-9):** The wrapper does not parse or validate `-v` / `--variable`
values; each token is appended to the `fabric` argv as received.

---

## 6. COMPONENT FUNCTIONS

### 6.0 Helpers: `_boot_*`, `_CAPS`, and `_ui_*()`

#### `_boot_caps()` / `_CAPS`

`main` calls `_boot_caps` once (also on `--reload-list` before listing). Each key
in associative array `_CAPS` is set to `1` or `0` via `command -v` for `fabric-ai`, `gum`,
`glow`, `bat`, `fzf`.

#### `_boot_clip()` / `_CLIP_CMD`

Runs once in `main`. Populates `_CLIP_CMD` as a zsh argv array (e.g. `(pbpaste)` or
`(wl-paste --no-newline)`) or leaves it empty.

#### `_ui_clip` — clipboard read

```zsh
_ui_clip() {
  (( ${#_CLIP_CMD[@]} )) || return 1
  "${_CLIP_CMD[@]}"
}
```

**REQUIREMENTS:** Req-2, Req-4, Req-5

#### `_ui_log` … `_ui_filter`

`_ui_log`, `_ui_log_info`, `_ui_log_warn`, `_ui_log_error`, `_ui_log_fatal`, `_ui_prompt`, `_ui_confirm`,
`_ui_spinner`, `_ui_table` behave as before but branch on `((_CAPS[gum]))` instead of
per-call `command -v`.

#### `_ui_filter [args…]` — fuzzy search picker (fzf → gum → read)

**Purpose:** Present a fuzzy-searchable list; preview string resolved inside `_ui_filter`.

**Tier 1 — `((_CAPS[fzf]))`:**

```zsh
local header pprev bin_self reload_cmd
bin_self="${XC_FABRIC:-$XC_SCRIPT}"
[[ -z "$header" ]] && header=$(_pattern_list_header)
# pprev: explicit --preview arg, else sed-only if NO_PREVIEW, else $(_boot_preview_cmd)
reload_cmd="env FABRIC_PATTERNS_DIR=${(q)_PATTERNS_DIR} zsh ${(q)bin_self} --reload-list"
fzf … --header="$header" --preview="$pprev" … \
  --bind "ctrl-o:execute(${EDITOR:-vi} \"${_PATTERNS_DIR}/{1}/system.md\" </dev/tty >/dev/tty 2>&1)" \
  --bind "ctrl-r:reload(${reload_cmd})" …
```

Stdin to `fzf` is one line per pattern: `pattern<TAB>display`, where `display` is the dimmed description (from `system.md` via `_pattern_list`, passed through `_pattern_list_sanitize_desc` to strip TAB/newline characters, then truncated for the list column). Each row **must** be a single physical line ending with newline (no embedded newlines in `display`, or `fzf` shows blank rows). With `--delimiter=$'\t'`, preview and `ctrl-o` paths **must** use fzf `{1}` (pattern name only), not `{}` (entire line), or file paths break.

**`ctrl-r:reload` note:** `reload` runs without in-process zsh functions. The implementation invokes `env FABRIC_PATTERNS_DIR=… zsh "$XC_SCRIPT" --reload-list`, which prints fresh `pattern<TAB>display` lines to stdout for `fzf` to consume (see `reload_cmd` in source).

**Tier 2 — `((_CAPS[gum]))` only:** `gum filter "$@"` (unchanged).

**Tier 3 — neither:** print header + list to stderr; `read` one line → stdout.

**REQUIREMENTS:** Req-2 AC-2.13, Req-4 AC-4.2

---

### 6.1 `_boot_check_deps()`

Called once at the top of `main` before any subcommand dispatch (except help).

- `fabric-ai` — fatal if missing.
- `gum`, `glow`, `bat` — warn only; same messages as requirements Req-3.
- **Optional:** warn when `((_CAPS[fzf]))` is false that the picker will use `gum filter` or
  plain `read` (implementation choice; not normative).

The script does **not** run `mise` or install packages (D-9 / §11).

**REQUIREMENTS:** Req-3

---

### 6.2 `_pattern_list()`

Emits one TSV line per pattern: `name\tdescription`.

- Source: `"${_PATTERNS_DIR}/<name>/system.md"`
- Description extraction (priority order):
  1. First non-empty, non-heading line of `system.md`
  2. Fallback: pattern directory name

Picker formatting (`_pattern_list_lines`, `_pattern_list_sanitize_desc`, `_pattern_list_item_format`, `_pattern_list_item_truncate_desc`) builds the second column for `fzf` / `gum filter` from that same TSV; there is no external metadata overlay.

**REQUIREMENTS:** Req-4, Req-6

---

### 6.3 `_ui_input_read()`

```zsh
_ui_input_read() {
  if [[ ! -t 0 ]]; then
    cat -
  else
    local clip
    clip=$(_ui_clip) || _ui_log_fatal "no input available (clipboard empty or unsupported)"
    [[ -n "$clip" ]] || _ui_log_fatal "no input available (clipboard empty or unsupported)"
    printf '%s' "$clip"
  fi
}
```

**REQUIREMENTS:** Req-4, Req-5

---

### 6.4 `cmd_default()`

1. `_boot_check_deps` (after `_boot_paths`, `_boot_caps`, `_boot_clip`)
2. `patterns_tsv` ← `_pattern_list`
3. If `--raw`: print TSV and return
4. Build `picker_lines` ← `_pattern_list_lines` on `patterns_tsv`; `header_body` ← `_pattern_list_header` (two-line string: title + keybinding summary; passed as `--header` to `_ui_filter`)
5. `selected` ← `picker_lines | _ui_filter --header "$header_body" | awk -F'\t' '{print $1}'` (`_ui_filter` applies preview from `--no-preview` / memoized chain internally)
6. `[[ -z "$selected" ]] && exit 0`
7. `input` ← `_ui_input_read`
8. `_fabric_exec_stdin "$selected" "$input"`

**REQUIREMENTS:** Req-4

---

### 6.5 `cmd_run()`

```zsh
cmd_run() {
  local pattern="${1:-}" url="" input
  [[ -n "$pattern" ]] || _ui_log_fatal "pattern is required"
  shift || true
  if [[ -n "${1:-}" ]] && _url_is_youtube "$1"; then
    url="$1"; shift || true
  elif [[ -n "${1:-}" && "$1" =~ '^https?://' ]]; then
    url="$1"; shift || true
  fi
  if [[ -n "$url" ]] && _url_is_youtube "$url"; then
    _ui_log_info "YouTube URL detected - using -y mode"
    _fabric_exec_youtube "$pattern" "$url"
  elif [[ -n "$url" ]]; then
    _fabric_exec_scrape "$url" "$pattern"
  elif _url_pattern_implies_yt "$pattern"; then
    url=$(_ui_prompt "YouTube URL: ")
    [[ -n "$url" ]] || return 0
    _fabric_exec_youtube "$pattern" "$url"
  else
    input=$(_ui_input_read)
    _fabric_exec_stdin "$pattern" "$input"
  fi
}
```

**REQUIREMENTS:** Req-5

---

### 6.6 `_fabric_exec_stdin <pattern> <input>`

Build `args=(--pattern "$pattern")`, then append shared flags via `_fabric_merge_common_flags` into `_fabric_common_argv_tail` (`--model`, `--copy`, `--output`, each `-v` / `--variable`, `--strategy`). Execution and the RAW / OUTPUT / spinner / `_ui_render_markdown` matrix are handled by `_fabric_run_tui` (see source).

**Notes:**

- **No `sh -c` + `printf %q`** — use `printf '%s' "$input" | …` to preserve multiline input (D-8 / I1).
- **`--output` path:** `fabric-ai` writes the file; do not call `_ui_render_markdown` (D-8).

**REQUIREMENTS:** Req-4, Req-5, Req-8, Req-9, Req-10–Req-12 passthroughs

---

### 6.7 `_fabric_exec_youtube <pattern> <url>`

Same argv-building rules as `_fabric_exec_stdin` for `--model`, `--copy`, `--output`, `-v`,
`--strategy`, plus `yt_args` from `_fabric_build_yt_args`.

```zsh
_fabric_exec_youtube() {
  local pattern="$1" url="$2"
  local yt_args=("${(@f)$(_fabric_build_yt_args)}")
  local args=(-y "$url" --pattern "$pattern" "${yt_args[@]}")
  …
  if [[ "${RAW:-0}" == "1" ]]; then
    fabric-ai "${args[@]}"
  elif [[ -n "${OUTPUT:-}" ]]; then
    _ui_spinner "Running ${pattern} on YouTube URL" -- fabric-ai "${args[@]}"
  else
    local result
    result=$(_ui_spinner "Running ${pattern} on YouTube URL" -- fabric-ai "${args[@]}")
    _ui_render_markdown "$result"
  fi
}
```

**REQUIREMENTS:** Req-5, Req-7

---

### 6.8 `_fabric_exec_scrape <url> <pattern>`

```zsh
_fabric_exec_scrape() {
  local url="$1" pattern="${2:-}"
  local args=(-u "$url")
  [[ -n "$pattern" ]] && args+=(--pattern "$pattern")
  … same RAW / OUTPUT / spinner / _ui_render_markdown matrix as `_fabric_exec_stdin`
}
```

**REQUIREMENTS:** Req-5, Req-13

---

### 6.9 `cmd_ls()`, `cmd_update()`, `cmd_show()`, `cmd_strategies()`, `cmd_scrape()`

- **`cmd_ls`** — `_pattern_list` piped through `_ui_table_show` (which calls `_ui_table` unless `--raw`).
- **`cmd_update`:** `_ui_spinner "Updating patterns" -- fabric-ai -U` unless `--raw` → `fabric-ai -U` direct.
- **`cmd_show`:** `fabric-ai --readpattern "$1"` → `_ui_render_markdown` unless `--raw`.
- **`cmd_strategies`:** `fabric-ai --liststrategies | _ui_table` unless `--raw`.
- **`cmd_scrape`:** `local url="${1:?}" pat="${2:-}"`; if `_url_is_youtube "$url"` then
  `_fabric_exec_youtube "${pat:-extract_wisdom}" "$url"` else `_fabric_exec_scrape "$url" "$pat"` (second
  positional pattern optional for non-YouTube URLs; omit `--pattern` when absent).

**REQUIREMENTS:** Req-6, Req-10–Req-13

---

### 6.10 `_ui_render_markdown <result>`

```zsh
_ui_render_markdown() {
  local result="$1"
  if (( _CAPS[glow] )); then
    ( unset NO_COLOR 2>/dev/null; printf '%s\n' "$result" | glow -s "${GLOW_STYLE:-dark}" - )
  elif (( _CAPS[bat] )); then
    printf '%s\n' "$result" | bat --language=md --style=plain --color=always --paging=never
  else
    printf '%s\n' "$result"
  fi
}
```

**REQUIREMENTS:** Req-8

---

## 7. USAGE MAP (GUM + PICKER)

### Table A — TUI helpers (gum)

| `_ui_*` wrapper | gum call                  | Fallback (no gum)               | Where used                                        |
| --------------- | ------------------------- | ------------------------------- | ------------------------------------------------- |
| `_ui_prompt`    | `gum input`               | `read -r -p`                    | YouTube URL prompt                                |
| `_ui_confirm`   | `gum confirm`             | `read -r -p` + `[[ … == "y" ]]` | *(available for future interactive flows)*        |
| `_ui_spinner`   | `gum spin --spinner dot`  | `printf` + direct exec          | Fabric execution wrapper                          |
| `_ui_table`     | `gum table`               | `cat` (raw TSV)                 | `cmd_ls`, `cmd_strategies` (via `_ui_table_show`) |
| `_ui_log`       | `gum log --time DateTime` | `printf` to stderr              | All log output                                    |

Direct `gum` invocations appear only inside these wrappers.

### Table B — Picker (`_ui_filter`)

| Tier | Condition                 | Behaviour                                                                                                                                                                                                                                                                                                           |
| ---- | ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | `((_CAPS[fzf]))`          | `fzf` with `--ansi`, `--delimiter=$'\t'`, `--with-nth=2`, `--layout=default`, `--height=75%`, `--border=rounded`, `--header="$header"`, `--preview`, `--preview-window 'right:42%:wrap,border-rounded'`, `--color` including `preview-bg` / `header-bg` (fzf **0.27+** COLSPEC), binds `ctrl-/`, `ctrl-o`, `ctrl-r` |
| 2    | not fzf, `((_CAPS[gum]))` | `gum filter "$@"`                                                                                                                                                                                                                                                                                                   |
| 3    | neither                   | header + list on stderr; `read` selection                                                                                                                                                                                                                                                                           |

**Used by:** `cmd_default` pattern step.

---

## 8. ENVIRONMENT VARIABLES (TEST SEAMS)

| Variable              | Purpose                                                                                                                           | Default                           |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------- | --------------------------------- |
| `XC_FABRIC`           | Path to script itself (set by mise task)                                                                                          | `$0`                              |
| `XC_SCRIPT`           | Absolute path to `xc-fabric` at parse time                                                                                        | derived from `%x` expansion       |
| `FABRIC_PATTERNS_DIR` | Override patterns directory                                                                                                       | `~/.config/fabric/patterns`       |
| `_PATTERNS_DIR`       | Resolved at runtime (same as env or default)                                                                                      | *(internal)*                      |
| `GLOW_STYLE`          | `glow -s` theme for picker preview (`_boot_preview_cmd`) and result render (`_ui_render_markdown` uses default `dark` when unset) | picker: `dracula`; render: `dark` |

No persistent application state beyond Fabric’s own pattern directory. No history file.

---

## 9. ERROR HANDLING

| Mechanism                                                      | Detail                                                                         |
| -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `set -euo pipefail`                                            | Strict mode; unset variables and pipe failures are errors                      |
| `trap '_ui_log_error "xc-fabric: failed at line $LINENO"' ERR` | Reports failing line before exit                                               |
| Esc on `_ui_filter` / `_ui_confirm`                            | `[[ -z "$selected" ]] && exit 0` — graceful abort                              |
| `fabric-ai` exit code                                          | Passed through unchanged via `$?`                                              |
| Missing `fabric-ai`                                            | `_ui_log_fatal` → exit 1                                                       |
| Missing `gum`                                                  | `_ui_log_warn` → execution continues with plain-text fallbacks                 |
| Missing input / clipboard                                      | `_ui_log_fatal "no input available (clipboard empty or unsupported)"` → exit 1 |

---

## 10. TESTING STRATEGY

### Test file

`tests/xc-fabric.spec.ts` — mirrors `xc-git-log-fzf.spec.ts` in structure (`usage_scenario`, `skipWhenOtherScenario`).

### Approach

`Bun.spawnSync(["zsh", script, …])` with `PATH` stubs in `mkdtempSync` dirs. Twenty-two
automated scenario IDs (mise `usage` `choices` MUST list all 22).

### Automated test scenarios

| Scenario ID              | What it tests                                                                    | REQUIREMENTS |
| ------------------------ | -------------------------------------------------------------------------------- | ------------ |
| `help`                   | `-h` / `--help` → stdout, exit 0                                                 | Req-1        |
| `missing_fabric`         | fabric absent → exit 1, stderr                                                   | Req-3        |
| `ls_raw`                 | `ls --raw` TSV                                                                   | Req-6        |
| `ls_table`               | `ls` with gum stub → `gum table` in argv                                         | Req-6        |
| `run_raw`                | `run … --raw` stdin → fabric                                                     | Req-5        |
| `run_youtube_url`        | second arg YouTube → `-y`                                                        | Req-5        |
| `run_youtube_pattern`    | `youtube_summary` + gum stub URL                                                 | Req-5        |
| `run_copy`               | `--copy` reaches fabric argv                                                     | Req-5        |
| `run_output`             | `--output` path reaches fabric; no glow in path when output set                  | Req-5, Req-8 |
| `run_variable`           | two `-v` tokens reach fabric                                                     | Req-5        |
| `yt_flags`               | `--yt-metadata` → `--metadata`; `--yt-playlist` → `--playlist` (extend existing) | Req-7        |
| `render_fallback`        | glow absent, bat stub → `bat` in pipeline                                        | Req-8        |
| `clip_macos`             | `uname` Darwin stub + `pbpaste` stub → clipboard path in run                     | Req-2, Req-5 |
| `clip_linux`             | `uname` Linux + `xclip` stub                                                     | Req-2, Req-5 |
| `update`                 | `update` → fabric `-U` in argv                                                   | Req-10       |
| `show`                   | `show pat` → `--readpattern`                                                     | Req-11       |
| `strategies`             | `strategies` → `--liststrategies` + table path                                   | Req-12       |
| `strategy_passthrough`   | `run … --strategy cot --raw` → `--strategy` on fabric                            | Req-12       |
| `scrape_url`             | `scrape https://example.com` → `-u` on fabric                                    | Req-13       |
| `picker_fzf_preferred`   | fzf stub receives `--ansi`, `--delimiter`, `--with-nth`, preview tuning, binds   | Req-2, Req-4 |
| `picker_fzf_stdin_lines` | fzf stdin is three single-line rows (`name<TAB>display`), no embedded newlines   | Req-2, Req-4 |
| `picker_gum_fallback`    | fzf absent, gum stub receives `filter`                                           | Req-2, Req-4 |

### Manual smoke only

Full interactive `_ui_filter` / `cmd_default` on a real TTY.

### Internal reload hook

`xc-fabric --reload-list` (undocumented user flag) prints the same tab-separated picker lines as the default pattern picker so `fzf` `ctrl-r:reload(...)` can refresh the list without sourcing zsh functions from the parent process.

---

## 11. MISE.TOML CHANGES

**Do not** add `fabric-ai` to `[tools]` for this feature alone — keep `[tools]` as the
repo already defines it; bootstrap is a **task**.

### `xc-fabric:specs`

Mirror `xc-git-log-fzf:specs`:

- `dir = "{{ config_root }}"`
- `env = { XC_FABRIC = "{{ config_root }}/xc-fabric" }`
- `usage` block with `flag "--scenario <scenario>"` and `choices` listing all **22** IDs from §10
- `run = "bunx bun test tests/xc-fabric.spec.ts"`

### `setup`

Idempotent install of missing CLIs (global `mise use -g` — adjust if project prefers project-local):

```toml
[tasks.setup]
description = "Ensure xc-fabric deps (fabric-ai, bat, fzf; Linux: xclip)"
dir = "{{ config_root }}"
run = """
command -v fabric-ai >/dev/null 2>&1 || mise use -g fabric-ai@latest
command -v bat    >/dev/null 2>&1 || mise use -g bat@latest
command -v fzf    >/dev/null 2>&1 || mise use -g fzf@latest
if [[ "$(uname -s)" == Linux ]]; then
  command -v xclip >/dev/null 2>&1 || mise use -g xclip@latest
fi
"""
```

---

## 12. README.MD CHANGES

Follow the same pattern as `xc-git-log-fzf`:

- Add `xc-fabric` to OVERVIEW script list.
- **DEPENDENCIES:** Fabric (required); FZF, Gum, Glow, Bat (optional — document roles).
- **LINKS** (allocate footnote ids after existing README refs — example indices; renumber to match file when editing):

  | ID  | URL                                        | Label  |
  | --- | ------------------------------------------ | ------ |
  | 20  | `https://github.com/danielmiessler/Fabric` | Fabric |
  | 21  | `https://github.com/junegunn/fzf`          | fzf    |
  | 22  | `https://github.com/charmbracelet/gum`     | Gum    |
  | 23  | `https://github.com/charmbracelet/glow`    | Glow   |
  | 24  | `https://github.com/sharkdp/bat`           | bat    |

- **RUNNING SPECS → WITH MISE:** `mise run setup` once; then all `mise run xc-fabric:specs --scenario <id>` for each of the 22 IDs; plus bare `mise run xc-fabric:specs`.
- **WITHOUT MISE:** `bunx bun test tests/xc-fabric.spec.ts`

---

## 13. DECISIONS

### D-1: Single self-contained script

**Context:** Separate `lib/xc-fabric-helpers.zsh`?
**Options considered:** (a) library file (b) single script.
**Decision:** (b) Single script.
**Rationale:** Matches other `xc-*` scripts.
**Implications:** Longer file; acceptable.

---

### D-2: `_ui_*` wrapper layer (gum optional)

**Context:** Direct `gum` vs wrapped.
**Decision:** Wrapped with fallbacks.
**Rationale:** True optional gum, not nominal.

---

### D-3: `fabric-ai` is the only hard dependency

**Context:** Which tools fatal if missing?
**Decision:** Only `fabric-ai` on `$PATH`.
**Rationale:** `_ui_*` layer exists to soften everything else.

---

### D-4: YouTube detection in `run` (and scrape redirect)

**Context:** Default picker auto-detect YouTube URLs?
**Decision:** No in `cmd_default`; yes in `cmd_run` / `cmd_scrape` routing.
**Rationale:** Default flow is text input; URL modes are explicit.

---

### D-5: `--yt-*` flags silently ignored without a URL

**Context:** Strict error vs ignore?
**Decision:** Ignore when not in YouTube path.
**Rationale:** Avoid failing harmless flag combinations.

---

### D-6: Cross-OS clipboard via `_ui_clip`

**Context:** macOS-only `pbpaste` vs portable helper.
**Options:** (a) pbpaste only (b) `_ui_clip` Darwin+Linux (c) Windows too.
**Decision:** (b).
**Rationale:** Matches Fabric README Linux guidance; Windows out of scope.
**Implications:** Linux needs `wl-paste` / `xclip` / `xsel` on PATH for TTY input.

---

### D-7: `--output` suppresses `_ui_render_markdown`

**Context:** Capture markdown then glow vs file output.
**Decision:** When `--output` is set, fabric owns the file; wrapper skips `_ui_render_markdown`.
**Rationale:** stdout is empty; glowing would hide errors.

---

### D-8: Passthrough flags and no installer in-script

**Context:** Validate `-v` / normalise model strings?
**Decision:** Verbatim passthrough; script never runs `mise install`.
**Rationale:** Thin wrapper; setup is operator concern (`setup` task).

---

### D-9: `fzf` for `_ui_filter`, `gum` elsewhere

**Context:** gum-only vs fzf-only vs hybrid picker.
**Decision:** Hybrid — `fzf` tier-1 for `_ui_filter` only; gum for spinner/table/log/etc.
**Rationale:** fzf gives scrollable preview + binds (`xc-git-log-fzf` precedent); gum still best for small prompts.
**Implications:** Optional `fzf` on PATH; `mise` task installs it for devs who want the rich picker.

---

### D-10: Private function naming (shell style)

<a id="d-10-private-function-naming-shell-style"></a>

**Context:** Helper names grew organically (`_ui_*`, `_boot_*`, `_pattern_*`, `_fabric_exec_stdin`, …), mixing medium, domain, and verb order.

**Options considered:** (a) leave historical names; (b) short abbreviated buckets (e.g. `_fab_*`); (c) **one logical family** of **full-word subject** prefixes and a stable skeleton
`_<subject>_<component>_<action>_<object>` (omit middle segments when obvious).

**Decision:** (c) as the **naming convention**. Prefer **`fabric` over `fab`** as the subject token for everything that orchestrates or presents the `fabric-ai` CLI contract. **Source** uses the shorter bucket set `_boot_*`, `_ui_*`, `_pattern_*`, `_url_*`, `_fabric_*` (see §3 pointer). Longer illustrative names remain valid targets for refactors, e.g. `_fabric_picker_execute_pattern`, `_fabric_picker_preview_render` — *subject* (`fabric`) + *component* (`picker`) + *action* + *object*.

**Rationale:** Aligns with the Google guide’s lowercase/underscore rule and keeps tokens in the **same part-of-speech family** (nouns for subjects/components; verbs in the action slot) so `grep '^_fabric_' xc-fabric` and similar stay predictable. Abbreviations like `fab` save characters but break “one family” readability.

**Implications:** Further renames toward longer `_fabric_picker_*`-style names are optional refactors; any such pass should grep stale symbols and keep this doc in sync. We still **avoid `::`** in this file (single executable, not a sourced package — see §3 pointer).

---

## 14. DESIGN QUALITY CHECKLIST

**Completeness:**

- [x] All REQUIREMENTS (Req-1 through Req-13) addressed in design
- [x] All major components defined with interfaces
- [x] Error handling covers all failure scenarios
- [x] Testing strategy lists 22 automated scenarios + manual TUI note
- [x] Graceful degradation documented for optional dependencies

**Clarity:**

- [x] Design decisions D-1–D-10 include context/options/rationale where applicable
- [x] Component responsibilities defined
- [x] `_ui_filter` tiering and `_fabric_exec_stdin` piping spelled out

**Feasibility:**

- [x] Achievable in one zsh script
- [x] PATH stubs cover non-TTY scenarios

**Traceability:**

- [x] Components reference Req-N in §6–§10 tables
- [x] Test scenario table maps to requirements
