<!-- markdownlint-disable -->
# xc-fabric — Design

## 1. OVERVIEW

`xc-fabric` is a single `zsh` script (`~/.config/bin/xc-fabric`) with no external
helper files. It follows the exact conventions of `xc-git-log-fzf`:

- `#!/usr/bin/env zsh` shebang
- `#?` comment block for self-documenting help
- Subcommand dispatch via `case` on `$1`
- `fabric` is the only hard dependency — the script exits fatally without it
- Tested via `tests/xc-fabric.spec.ts` + `mise run xc-fabric:specs`

The key design insight is a layered helper system:

- **`_has_*` predicates** — thin `command -v` wrappers for `fabric`, `gum`, `glow`, `bat`, `fzf`.
- **`_h_*` wrappers** — abstract gum interactions so `gum` is optional; **`_h_filter` prefers `fzf`**
  (scrollable preview, custom binds) and falls back to `gum filter`, then plain `read`.
- **`_h_clip`** — OS-specific clipboard read (Darwin / Linux); not gum-related.

When `gum` is absent the script degrades gracefully: logging → `printf`, pickers → `read`,
spinner → `printf` + direct exec. Non-interactive paths (`run --raw`, `ls --raw`, etc.)
work without `gum` or `fzf`.

**Installation vs checks:** The script **never** installs packages. Operators run
`mise run setup` to ensure `fabric-ai`, `bat`, `fzf`, `yq`, and (on Linux) `xclip`
are available; the script only **checks** and warns via `_check_deps`.

---

## 2. FOLDER STRUCTURE

```tree
~/.config/bin/
  ├── LICENSE
  ├── README.md                          ← must be updated
  ├── config.yml                         ← optional shared script metadata (`xc-fabric`)
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
├── Section 0: constants          (SCRIPT_NAME, flag mirrors: RAW, MODEL, …)
├── Section 1: helpers
│   ├── _has_* predicates         (fabric, gum, glow, bat, fzf)
│   └── _h_*  wrappers            (gum abstraction; _h_filter = fzf → gum → read)
│   └── _h_clip                   (clipboard read — OS-specific)
├── Section 2: dependency check   (_check_deps)
├── Section 3: pattern helpers    (_patterns_dir, _list_patterns, _is_youtube_url, _is_youtube_pattern)
├── Section 4: input helpers      (_read_input)
├── Section 5: output + exec      (_render_output, _build_yt_args, _exec_fabric, _exec_fabric_youtube, _exec_fabric_scrape)
├── Section 6: subcommands        (cmd_default, cmd_wizard, cmd_run, cmd_ls, cmd_update, cmd_show, cmd_strategies, cmd_scrape)
├── Section 7: arg parsing        (flag loop → dispatch)
└── Section 8: entrypoint         (main "$@")
```

### Data Flow

```text
stdin pipe / _h_clip / YouTube or scrape URL
              │
              ▼
        _read_input
              │
    ┌─────────┴──────────┬──────────────────┐
    ▼                    ▼                  ▼
_exec_fabric      _exec_fabric_youtube   _exec_fabric_scrape
(text input)      (URL + _build_yt_args)  (fabric -u URL [pattern])
    │                    │                  │
    └─────────┬──────────┴──────────────────┘
              │
         fabric CLI
              │
              ▼
       _render_output (skipped when --raw or --output)
      (glow → bat → cat)
              │
              ▼
           stdout
```

### Technology Decisions

- **zsh** — consistent with all other `xc-*` scripts; no bash-isms needed.
- **`fabric` is the only hard dependency** — exits fatally without it.
- **`fzf` optional, preferred for `_h_filter`** — matches `xc-git-log-fzf` repo convention; `gum filter` remains tier-2.
- **`gum` is optional** — every gum call is wrapped in an `_h_*` function with a plain-text fallback.
- **`set -euo pipefail` + ERR trap** — strict mode; `_h_error` reports the failing line number before exiting.
- **No external helper files** — self-contained per project convention (D-1).

---

## 4. SCRIPT STRUCTURE

```zsh
#!/usr/bin/env zsh

#? xc-fabric - … (full #? block — see requirements.md §Requirement 1)

set -euo pipefail

readonly SCRIPT_NAME="${0:t}"

# ── 0. constants ──────────────────────────────────────────────────────────────

# ── 1. helpers ────────────────────────────────────────────────────────────────
# _has_fabric / _has_gum / _has_glow / _has_bat / _has_fzf
# _h_log / _h_info / _h_warn / _h_error / _h_fatal
# _h_clip
# _h_prompt / _h_confirm / _h_spinner / _h_table / _h_choose / _h_filter / _h_write

# ── 2. dependency check ───────────────────────────────────────────────────────
# _check_deps

# ── 3. pattern helpers ────────────────────────────────────────────────────────
# _patterns_dir / _list_patterns / _is_youtube_url / _is_youtube_pattern

# ── 4. input helpers ──────────────────────────────────────────────────────────
# _read_input

# ── 5. output + exec ─────────────────────────────────────────────────────────
# _render_output / _build_yt_args / _exec_fabric / _exec_fabric_youtube / _exec_fabric_scrape

# ── 6. subcommands ────────────────────────────────────────────────────────────
# cmd_default / cmd_wizard / cmd_run / cmd_ls / cmd_update / cmd_show / cmd_strategies / cmd_scrape

# ── 7. argument parsing & dispatch ───────────────────────────────────────────
# while loop over options (--raw, --model, --copy, --output, -v, --strategy, --yes, --no-preview, --yt-*)
# case "$1" in wizard|run|ls|update|show|strategies|scrape|-h|--help) … esac
# fallthrough → cmd_default

# ── 8. entrypoint ─────────────────────────────────────────────────────────────
main "$@"
```

**Help:** mirror `xc-git-log-fzf`: top-level `case "${1:-}" in -h|--help) … esac` **before** `main` definitions, or first lines inside `main` before `_check_deps` — either is acceptable as long as `-h`/`--help` never call `_check_deps` (Req-1).

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

### 6.0 Helpers: `_has_*()` and `_h_*()`

#### `_has_*()` — dependency predicates

Simple `command -v` wrappers. Return 0 (true) if the tool is on `$PATH`, 1 otherwise.
No stdout or stderr output — pure boolean.

```zsh
_has_fabric() { command -v fabric >/dev/null 2>&1; }
_has_gum()    { command -v gum    >/dev/null 2>&1; }
_has_glow()   { command -v glow   >/dev/null 2>&1; }
_has_bat()    { command -v bat    >/dev/null 2>&1; }
_has_fzf()    { command -v fzf    >/dev/null 2>&1; }
```

#### `_h_clip` — clipboard read

**Purpose:** Read the system clipboard to stdout; return 1 if unsupported or no tool.

```zsh
_h_clip() {
  case "$(uname)" in
    Darwin)
      command -v pbpaste >/dev/null 2>&1 && pbpaste
      ;;
    Linux)
      if   command -v wl-paste >/dev/null 2>&1; then wl-paste --no-newline
      elif command -v xclip  >/dev/null 2>&1; then xclip -selection clipboard -o
      elif command -v xsel   >/dev/null 2>&1; then xsel --clipboard --output
      else return 1
      fi
      ;;
    *) return 1 ;;
  esac
}
```

**REQUIREMENTS:** Req-2 (AC-2.18–2.20), Req-4, Req-6

#### `_h_log` … `_h_write`

(Same as prior design for `_h_log`, `_h_info`, `_h_warn`, `_h_error`, `_h_fatal`,
`_h_prompt`, `_h_confirm`, `_h_spinner`, `_h_table`, `_h_choose`, `_h_write` — see
previous revision; `_h_info`/`_h_warn`/`_h_error` return without exiting the script.)

#### `_h_filter [args…]` — fuzzy search picker (fzf → gum → read)

**Purpose:** Present a fuzzy-searchable list; optional preview.

**Tier 1 — `_has_fzf`:**

```zsh
local pat_dir header preview bin_self reload_cmd
pat_dir=$(_patterns_dir)
bin_self="${XC_FABRIC:-$XC_SCRIPT}"
header=$(_fzf_pattern_header_body)
preview=$(_fzf_pattern_system_preview "$pat_dir")
reload_cmd="env FABRIC_PATTERNS_DIR=${(q)pat_dir} zsh ${(q)bin_self} --xc-picker-lines"
fzf \
  --ansi \
  --layout=reverse \
  --height=90% \
  --border=rounded \
  --delimiter=$'\t' \
  --with-nth=2 \
  --header="$header" \
  --preview="$preview" \
  --preview-window 'right:60%:wrap' \
  --bind 'ctrl-/:toggle-preview' \
  --bind "ctrl-o:execute(${EDITOR:-vi} \"${pat_dir}/{1}/system.md\" </dev/tty >/dev/tty 2>&1)" \
  --bind "ctrl-r:reload(${reload_cmd})" \
  --bind '?:execute(printf "%s\n" "Keys: Enter run  Ctrl-/ toggle preview  Ctrl-O editor  Ctrl-R reload  ? help  Esc cancel" | less >/dev/tty 2>&1)'
```

Stdin to `fzf` is one line per pattern: `pattern<TAB>display`, where `display` may include ANSI dim for description and `#tag` suffixes from `config.yml` when `yq` is available. With `--delimiter=$'\t'`, preview and `ctrl-o` paths **must** use fzf `{1}` (pattern name only), not `{}` (entire line), or file paths break.

**`ctrl-r:reload` note:** `reload` runs in a subshell without zsh functions. Either
**export -f _list_patterns** (and dependencies) before `fzf`, or inline a self-contained
shell one-liner in `--bind` that only uses `awk`/`ls` on `FABRIC_PATTERNS_DIR`. The
implementation SHALL pick one approach and document it in code comments.

**Tier 2 — `_has_gum` only:** `gum filter "$@"` (unchanged).

**Tier 3 — neither:** print header + list to stderr; `read` one line → stdout.

**REQUIREMENTS:** Req-2 AC-2.16, Req-4 AC-4.2

---

### 6.1 `_check_deps()`

Called once at the top of `main` before any subcommand dispatch (except help).

- `fabric` — fatal if missing.
- `gum`, `glow`, `bat` — warn only; same messages as requirements Req-3.
- **Optional:** warn when `_has_fzf` is false that the picker will use `gum filter` or
  plain `read` (implementation choice; not normative).

The script does **not** run `mise` or install packages (D-9 / §11).

**REQUIREMENTS:** Req-3

---

### 6.2 `_list_patterns()`

Emits one TSV line per pattern: `name\tdescription`.

- Source: `$(_patterns_dir)/<name>/system.md`
- Description extraction (priority order):
  1. First non-empty, non-heading line of `system.md`
  2. Fallback: pattern directory name

**Interactive picker overlay:** When `yq` is on `PATH` and `config.yml` resolves (`XC_BIN_CONFIG` or `${XC_SCRIPT:h}/config.yml`), descriptions and `tags` from `scripts.xc-fabric.patterns.<name>` replace the TSV description for display only. Tags render as `#tag` (at most two). `--raw` / `ls --raw` still emit the original TSV from `system.md` only.

**REQUIREMENTS:** Req-4, Req-7

---

### 6.3 `_read_input()`

```zsh
_read_input() {
  if [[ ! -t 0 ]]; then
    cat -
  else
    _h_clip || _h_fatal "no input available (clipboard empty or unsupported on $(uname))"
  fi
}
```

**REQUIREMENTS:** Req-4, Req-6

---

### 6.4 `cmd_default()`

1. `_check_deps`
2. `patterns_tsv` ← `_list_patterns`
3. If `--raw`: print TSV and return
4. Build `picker_lines` ← `_pattern_emit_picker_lines` on `patterns_tsv`; `header` ← `_fzf_pattern_header_body`; `preview` ← `_fzf_pattern_system_preview` unless `--no-preview`
5. `selected` ← `picker_lines | _h_filter --header "$header" [--preview "$preview"] | awk -F'\t' '{print $1}'`
6. `[[ -z "$selected" ]] && exit 0`
7. `input` ← `_read_input`
8. `_exec_fabric "$selected" "$input"`

**REQUIREMENTS:** Req-4

---

### 6.5 `cmd_wizard()`

| Step                   | Always?                               | Skip / condition                                                     | Mechanism                       |
| ---------------------- | ------------------------------------- | -------------------------------------------------------------------- | ------------------------------- |
| Pattern picker         | ✓                                     | —                                                                    | `_h_filter`                     |
| Placeholder collection | If any `<PLACEHOLDER>` in `system.md` | none found → skip                                                    | `_h_prompt` + `_h_confirm`      |
| Model flag             | —                                     | `--model` already set → pass through only; **no interactive picker** | append to `_exec_fabric`        |
| Confirmation           | —                                     | `--yes`                                                              | `_h_confirm "Run <pattern>?"`   |
| Execution              | ✓                                     | —                                                                    | `_exec_fabric` via `_h_spinner` |
| Render                 | ✓                                     | skip if `--output`                                                   | `_render_output`                |

**REQUIREMENTS:** Req-5

---

### 6.6 `cmd_run()`

```zsh
cmd_run() {
  local pattern="${1:?pattern required}"; shift
  local url=""
  [[ -n "${1:-}" ]] && _is_youtube_url "$1" && { url="$1"; shift; }
  [[ -z "$url" && -n "${1:-}" && "${1}" =~ ^https?:// ]] && { url="$1"; shift; }

  if [[ -n "$url" ]] && _is_youtube_url "$url"; then
    _h_info "YouTube URL detected — using -y mode"
    _exec_fabric_youtube "$pattern" "$url"
  elif [[ -n "$url" ]]; then
    _exec_fabric_scrape "$url" "$pattern"
  elif _is_youtube_pattern "$pattern" && [[ -z "$url" ]]; then
    url=$(_h_prompt "YouTube URL: ")
    _exec_fabric_youtube "$pattern" "$url"
  else
    local input
    input=$(_read_input)
    _exec_fabric "$pattern" "$input"
  fi
}
```

**REQUIREMENTS:** Req-6

---

### 6.7 `_exec_fabric <pattern> <input>`

Build `args=(--pattern "$pattern")`; append `--model`, `--copy`, `--output`, each `-v`,
`--strategy` from globals when set.

```zsh
_exec_fabric() {
  local pattern="$1" input="$2"
  local args=(--pattern "$pattern")
  [[ -n "${MODEL:-}" ]]    && args+=(--model "$MODEL")
  [[ -n "${OUTPUT:-}" ]]   && args+=(--output "$OUTPUT")
  [[ "${COPY:-0}" == "1" ]] && args+=(--copy)
  [[ -n "${STRATEGY:-}" ]] && args+=(--strategy "$STRATEGY")
  # append "${VARS[@]}" as separate -v/--variable argv pieces

  if [[ "${RAW:-0}" == "1" ]]; then
    printf '%s' "$input" | fabric "${args[@]}"
  elif [[ -n "${OUTPUT:-}" ]]; then
    printf '%s' "$input" | _h_spinner "Running ${pattern}" -- fabric "${args[@]}"
  else
    local result
    result=$(printf '%s' "$input" | _h_spinner "Running ${pattern}" -- fabric "${args[@]}")
    _render_output "$result"
  fi
}
```

**Notes:**

- **No `sh -c` + `printf %q`** — use `printf '%s' "$input" | …` to preserve multiline input (D-8 / I1).
- **`--output` path:** fabric writes the file; do not call `_render_output` (D-8).

**REQUIREMENTS:** Req-4, Req-6, Req-9, Req-10, Req-11–Req-13 passthroughs

---

### 6.8 `_exec_fabric_youtube <pattern> <url>`

Same argv-building rules as `_exec_fabric` for `--model`, `--copy`, `--output`, `-v`,
`--strategy`, plus `yt_args` from `_build_yt_args`.

```zsh
_exec_fabric_youtube() {
  local pattern="$1" url="$2"
  local yt_args=("${(@f)$(_build_yt_args)}")
  local args=(-y "$url" --pattern "$pattern" "${yt_args[@]}")
  …
  if [[ "${RAW:-0}" == "1" ]]; then
    fabric "${args[@]}"
  elif [[ -n "${OUTPUT:-}" ]]; then
    _h_spinner "Running ${pattern} on YouTube URL" -- fabric "${args[@]}"
  else
    local result
    result=$(_h_spinner "Running ${pattern} on YouTube URL" -- fabric "${args[@]}")
    _render_output "$result"
  fi
}
```

**REQUIREMENTS:** Req-6, Req-8

---

### 6.9 `_exec_fabric_scrape <url> <pattern>`

```zsh
_exec_fabric_scrape() {
  local url="$1" pattern="${2:-}"
  local args=(-u "$url")
  [[ -n "$pattern" ]] && args+=(--pattern "$pattern")
  … same RAW / OUTPUT / spinner / _render_output matrix as `_exec_fabric`
}
```

**REQUIREMENTS:** Req-6, Req-14

---

### 6.10 `cmd_ls()`, `cmd_update()`, `cmd_show()`, `cmd_strategies()`, `cmd_scrape()`

- **`cmd_ls`** — unchanged from prior design (`_list_patterns` + `_h_table` / raw).
- **`cmd_update`:** `_h_spinner "Updating patterns" -- fabric -U` unless `--raw` → `fabric -U` direct.
- **`cmd_show`:** `fabric --readpattern "$1"` → `_render_output` unless `--raw`.
- **`cmd_strategies`:** `fabric --liststrategies | _h_table` unless `--raw`.
- **`cmd_scrape`:** `local url="${1:?}" pat="${2:-}"`; if `_is_youtube_url "$url"` then
  `_exec_fabric_youtube "${pat:-extract_wisdom}" "$url"` else `_exec_fabric_scrape "$url" "$pat"` (second
  positional pattern optional for non-YouTube URLs; omit `--pattern` when absent).

**REQUIREMENTS:** Req-7, Req-11–Req-14

---

### 6.11 `_render_output <result>`

```zsh
_render_output() {
  local result="$1"
  if _has_glow; then
    printf '%s\n' "$result" | glow
  elif _has_bat; then
    printf '%s\n' "$result" | bat
  else
    printf '%s\n' "$result"
  fi
}
```

**REQUIREMENTS:** Req-9

---

## 7. USAGE MAP (GUM + PICKER)

### Table A — TUI helpers (gum)

| `_h_*` wrapper | gum call                  | Fallback (no gum)               | Where used                                |
| -------------- | ------------------------- | ------------------------------- | ----------------------------------------- |
| `_h_choose`    | `gum choose`              | `cat >&2` + `read`              | *(reserved — no current call site)*       |
| `_h_write`     | `gum write`               | `printf` prompt + `cat`         | Future wizard multi-line step             |
| `_h_prompt`    | `gum input`               | `read -r -p`                    | Placeholders, YouTube URL prompt          |
| `_h_confirm`   | `gum confirm`             | `read -r -p` + `[[ … == "y" ]]` | Wizard confirm, leave-placeholder confirm |
| `_h_spinner`   | `gum spin --spinner dot`  | `printf` + direct exec          | Fabric execution wrapper                  |
| `_h_table`     | `gum table`               | `cat` (raw TSV)                 | `cmd_ls`, `cmd_strategies`                |
| `_h_log`       | `gum log --time DateTime` | `printf` to stderr              | All log output                            |

Direct `gum` invocations appear only inside these wrappers.

### Table B — Picker (`_h_filter`)

| Tier | Condition           | Behaviour                                                                                                                                                                                                   |
| ---- | ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | `_has_fzf`          | `fzf` with `--ansi`, `--delimiter=$'\t'`, `--with-nth=2`, `--layout=reverse`, `--height=90%`, `--border=rounded`, `--preview`, `--preview-window 'right:60%:wrap'`, binds `ctrl-/`, `ctrl-o`, `ctrl-r`, `?` |
| 2    | not fzf, `_has_gum` | `gum filter "$@"`                                                                                                                                                                                           |
| 3    | neither             | header + list on stderr; `read` selection                                                                                                                                                                   |

**Used by:** `cmd_default`, `cmd_wizard` pattern step.

---

## 8. ENVIRONMENT VARIABLES (TEST SEAMS)

| Variable              | Purpose                                      | Default                     |
| --------------------- | -------------------------------------------- | --------------------------- |
| `XC_FABRIC`           | Path to script itself (set by mise task)     | `$0`                        |
| `XC_SCRIPT`           | Absolute path to `xc-fabric` at parse time   | derived from `%x` expansion |
| `XC_BIN_CONFIG`       | Override path to shared `config.yml` (tests) | `${XC_SCRIPT:h}/config.yml` |
| `FABRIC_PATTERNS_DIR` | Override patterns directory                  | `~/.config/fabric/patterns` |

Optional metadata lives in `config/bin/config.yml` under `scripts.xc-fabric` (see §6.2). No history. No other persistent state.

---

## 9. ERROR HANDLING

| Mechanism                                                 | Detail                                                                                |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| `set -euo pipefail`                                       | Strict mode; unset variables and pipe failures are errors                             |
| `trap '_h_error "xc-fabric: failed at line $LINENO"' ERR` | Reports failing line before exit                                                      |
| Esc on `_h_filter` / `_h_confirm`                         | `[[ -z "$selected" ]] && exit 0` — graceful abort                                     |
| `fabric` exit code                                        | Passed through unchanged via `$?`                                                     |
| Missing `fabric`                                          | `_h_fatal` → exit 1                                                                   |
| Missing `gum`                                             | `_h_warn` → execution continues with plain-text fallbacks                             |
| Missing input / clipboard                                 | `_h_fatal "no input available (clipboard empty or unsupported on $(uname))"` → exit 1 |

---

## 10. TESTING STRATEGY

### Test file

`tests/xc-fabric.spec.ts` — mirrors `xc-git-log-fzf.spec.ts` in structure (`usage_scenario`, `skipWhenOtherScenario`).

### Approach

`Bun.spawnSync(["zsh", script, …])` with `PATH` stubs in `mkdtempSync` dirs. Twenty-two
automated scenario IDs (mise `usage` `choices` MUST list all 22).

### Automated test scenarios

| Scenario ID            | What it tests                                                                    | REQUIREMENTS |
| ---------------------- | -------------------------------------------------------------------------------- | ------------ |
| `help`                 | `-h` / `--help` → stdout, exit 0                                                 | Req-1        |
| `missing_fabric`       | fabric absent → exit 1, stderr                                                   | Req-3        |
| `ls_raw`               | `ls --raw` TSV                                                                   | Req-7        |
| `ls_table`             | `ls` with gum stub → `gum table` in argv                                         | Req-7        |
| `run_raw`              | `run … --raw` stdin → fabric                                                     | Req-6        |
| `run_youtube_url`      | second arg YouTube → `-y`                                                        | Req-6        |
| `run_youtube_pattern`  | `youtube_summary` + gum stub URL                                                 | Req-6        |
| `run_copy`             | `--copy` reaches fabric argv                                                     | Req-6        |
| `run_output`           | `--output` path reaches fabric; no glow in path when output set                  | Req-6, Req-9 |
| `run_variable`         | two `-v` tokens reach fabric                                                     | Req-6        |
| `yt_flags`             | `--yt-metadata` → `--metadata`; `--yt-playlist` → `--playlist` (extend existing) | Req-8        |
| `render_fallback`      | glow absent, bat stub → `bat` in pipeline                                        | Req-9        |
| `clip_macos`           | `uname` Darwin stub + `pbpaste` stub → clipboard path in run                     | Req-2, Req-6 |
| `clip_linux`           | `uname` Linux + `xclip` stub                                                     | Req-2, Req-6 |
| `update`               | `update` → fabric `-U` in argv                                                   | Req-11       |
| `show`                 | `show pat` → `--readpattern`                                                     | Req-12       |
| `strategies`           | `strategies` → `--liststrategies` + table path                                   | Req-13       |
| `strategy_passthrough` | `run … --strategy cot --raw` → `--strategy` on fabric                            | Req-13       |
| `scrape_url`           | `scrape https://example.com` → `-u` on fabric                                    | Req-14       |
| `picker_fzf_preferred` | fzf stub receives `--ansi`, `--delimiter`, `--with-nth`, preview tuning, binds   | Req-2, Req-4 |
| `picker_fzf_metadata`  | `XC_BIN_CONFIG` + `yq` overlay → stdin rows include `#tags` and config title     | Req-2, Req-4 |
| `picker_gum_fallback`  | fzf absent, gum stub receives `filter`                                           | Req-2, Req-4 |

### Manual smoke only

Full interactive `_h_filter` / `cmd_wizard` / `cmd_default` on a real TTY.

### Internal reload hook

`xc-fabric --xc-picker-lines` (undocumented user flag) prints the same tab-separated picker lines as the default pattern picker so `fzf` `ctrl-r:reload(...)` can refresh the list without sourcing zsh functions from the parent process.

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
command -v yq    >/dev/null 2>&1 || mise use -g yq@latest
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

### D-2: `_h_*` wrapper layer (gum optional)

**Context:** Direct `gum` vs wrapped.
**Decision:** Wrapped with fallbacks.
**Rationale:** True optional gum, not nominal.

---

### D-3: `fabric` is the only hard dependency

**Context:** Which tools fatal if missing?
**Decision:** Only `fabric`.
**Rationale:** `_h_*` layer exists to soften everything else.

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

### D-6: Cross-OS clipboard via `_h_clip`

**Context:** macOS-only `pbpaste` vs portable helper.
**Options:** (a) pbpaste only (b) `_h_clip` Darwin+Linux (c) Windows too.
**Decision:** (b).
**Rationale:** Matches Fabric README Linux guidance; Windows out of scope.
**Implications:** Linux needs `wl-paste` / `xclip` / `xsel` on PATH for TTY input.

---

### D-7: No interactive model picker in wizard

**Context:** `fabric --listmodels | gum choose` vs configured default only.
**Decision:** Never offer interactive model pick; only `--model` passthrough.
**Rationale:** Provider/model must match Fabric config; interactive pick risks invalid model IDs.

---

### D-8: `--output` suppresses `_render_output`

**Context:** Capture markdown then glow vs file output.
**Decision:** When `--output` is set, fabric owns the file; wrapper skips `_render_output`.
**Rationale:** stdout is empty; glowing would hide errors.

---

### D-9: Passthrough flags and no installer in-script

**Context:** Validate `-v` / normalise model strings?
**Decision:** Verbatim passthrough; script never runs `mise install`.
**Rationale:** Thin wrapper; setup is operator concern (`setup` task).

---

### D-10: `fzf` for `_h_filter`, `gum` elsewhere

**Context:** gum-only vs fzf-only vs hybrid picker.
**Decision:** Hybrid — `fzf` tier-1 for `_h_filter` only; gum for spinner/table/log/etc.
**Rationale:** fzf gives scrollable preview + binds (`xc-git-log-fzf` precedent); gum still best for small prompts.
**Implications:** Optional `fzf` on PATH; `mise` task installs it for devs who want the rich picker.

---

## 14. DESIGN QUALITY CHECKLIST

**Completeness:**

- [x] All REQUIREMENTS (Req-1 through Req-14) addressed in design
- [x] All major components defined with interfaces
- [x] Error handling covers all failure scenarios
- [x] Testing strategy lists 22 automated scenarios + manual TUI note
- [x] Graceful degradation documented for optional dependencies

**Clarity:**

- [x] Design decisions D-1–D-10 include context/options/rationale where applicable
- [x] Component responsibilities defined
- [x] `_h_filter` tiering and `_exec_fabric` piping spelled out

**Feasibility:**

- [x] Achievable in one zsh script
- [x] PATH stubs cover non-TTY scenarios

**Traceability:**

- [x] Components reference Req-N in §6–§10 tables
- [x] Test scenario table maps to requirements
