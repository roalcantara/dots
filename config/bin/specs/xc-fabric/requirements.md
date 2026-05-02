<!-- markdownlint-disable -->
# REQUIREMENTS: xc-fabric

## OVERVIEW

`xc-fabric` is an interactive [Fabric](https://github.com/danielmiessler/Fabric) pattern
runner for the terminal. It wraps `fabric` with a `gum`-powered TUI (spinners,
confirmations, tables), **`fzf` for the main pattern picker** when available (with
`gum filter` as fallback), `glow`/`bat`-rendered output, while remaining fully
functional without `gum` or `fzf` via plain-text fallbacks, and fully pipeable via `--raw`.

> *NOTE: `fabric` is the only hard dependency. `fzf`, `gum`, `glow`, and `bat` are all optional.*

---

## User Roles

- **Script author:** Who composes `xc-fabric` into shell pipelines, aliases, or automation scripts and requires predictable, parseable output.
- **Terminal user:** Who runs `xc-fabric` interactively from a shell to discover and run Fabric patterns against clipboard or piped content.

---

## REQUIREMENTS

### REQUIREMENT 1: Help

**User Story:**

As a terminal user
I want to see usage documentation at any time
so that I can understand available commands and options without reading source code

**Acceptance Criteria:**

1. WHEN the script is invoked with `-h` or `--help`
   THEN script SHALL print the `#?` header block to stdout and exit 0.
2. WHEN the script is invoked with no arguments and stdin is a TTY
   THEN script SHALL behave as the default interactive pattern picker (REQUIREMENT 4).

**Edge Cases:**

- `-h` and `--help` are both valid; either must work.
- Help must print to stdout (not stderr) so it can be piped or grepped.

---

### REQUIREMENT 2: Helpers (`_has_*` and `_h_*`)

**User Story:**

As a terminal user
I want consistent log messages and graceful TUI fallbacks
so that the script works correctly whether or not `gum` is installed and I can distinguish info, warnings, errors, and fatal failures at a glance

**Acceptance Criteria:**

1. GIVEN that `_has_gum` is called
   WHEN `gum` is present on `$PATH`
   THEN it SHALL return 0
   ELSE it SHALL return 1.
2. GIVEN that `_has_fabric` is called
   WHEN `fabric` is present on `$PATH`
   THEN it SHALL return 0
   ELSE it SHALL return 1.
3. GIVEN that `_has_glow` is called
   WHEN `glow` is present on `$PATH`
   THEN it SHALL return 0
   ELSE it SHALL return 1.
4. GIVEN that `_has_bat` is called
   WHEN `bat` is present on `$PATH`
   THEN it SHALL return 0
   ELSE it SHALL return 1.
5. GIVEN that `_has_fzf` is called
   WHEN `fzf` is present on `$PATH`
   THEN it SHALL return 0
   ELSE it SHALL return 1.
6. GIVEN that `_h_log` is called
   WHEN `_has_gum` returns 0
   THEN it SHALL delegate to `gum log --time DateTime --level <level> <message>`
   ELSE it SHALL print `YYYY-MM-DD HH:MM:SS <level> <message>` to stderr.
7. WHEN `_h_info` is called
   THEN it SHALL delegate to `_h_log "info" "$@"`
   AND it SHALL return 0 (the function SHALL NOT exit the script).
8. WHEN `_h_warn` is called
   THEN it SHALL delegate to `_h_log "warn" "$@"`
   AND it SHALL return 0 (the function SHALL NOT exit the script).
9. WHEN `_h_error` is called
   THEN it SHALL delegate to `_h_log "error" "$@"`
   AND it SHALL return 0 (the function SHALL NOT exit the script).
10. WHEN `_h_fatal` is called
    THEN it SHALL delegate to `_h_log "fatal" "$@"`
    AND it SHALL exit with code 1.
11. GIVEN that `_h_prompt <text>` is called
    WHEN `_has_gum` returns 0
    THEN it SHALL delegate to `gum input --prompt="<text>"` and return the entered value on stdout
    ELSE it SHALL use `read -r -p "<text>"` as fallback and return the entered value on stdout.
12. GIVEN that `_h_confirm <question>` is called
    WHEN `_has_gum` returns 0
    THEN it SHALL delegate to `gum confirm <question>` and return its exit code (0 = yes, 1 = no)
    ELSE it SHALL use `read -r -p "<question> [y/N]"` as fallback and return 0 only if the answer is `y`; otherwise return 1.
13. GIVEN that `_h_spinner <title> -- <command…>` is called
    WHEN `_has_gum` returns 0
    THEN it SHALL delegate to `gum spin --spinner dot --title "<title>…" -- <cmd…>` and return the exit code of the command
    ELSE it SHALL print `<title>...` to stderr and then run `<cmd…>` directly
14. GIVEN that `_h_table` is called
    WHEN `_has_gum` returns 0
    THEN it SHALL pipe stdin through `gum table --separator $'\t' --columns "PATTERN,DESCRIPTION" --widths "30,60"`
    ELSE it SHALL pipe stdin through `cat` (raw TSV passthrough).
15. GIVEN that `_h_choose <header>` is called
    WHEN `_has_gum` returns 0
    THEN `_h_choose` SHALL call `gum choose --header "<header>"` and return the selected item on stdout.
    ELSE it SHALL print the header and the list to stderr, read a line from stdin as the selection and return it on stdout.
16. GIVEN that `_h_filter [--header <header>] [--placeholder <placeholder>] [--preview <shell-cmd>]` is called
    WHEN `_has_fzf` returns 0
    THEN it SHALL invoke `fzf` with `--header`, `--preview`, `--preview-window 'right:60%:wrap'`
    AND it SHALL use the keybindings defined in `design.md` §6.0:

      | Key      | Action                        |
      | -------- | ----------------------------- |
      | `ctrl-/` | toggle preview                |
      | `ctrl-o` | open `system.md` in `$EDITOR` |
      | `ctrl-r` | reload list                   |
      | `?`      | help                          |

    AND it SHALL return the selected line on stdout.
    WHEN `_has_fzf` returns 1 AND `_has_gum` returns 0
    THEN it SHALL call `gum filter` with the given arguments and return the selected item on stdout.
    WHEN both `_has_fzf` and `_has_gum` return 1
    THEN it SHALL print the header and the list to stderr, read a line from stdin as the selection and return it on stdout.
17. GIVEN that `_h_write [<placeholder>]` is called
    WHEN `_has_gum` returns 0
    THEN it SHALL call `gum write --placeholder "<placeholder>"` and return the entered value on stdout
    ELSE it SHALL print a prompt to stderr and read all of stdin until EOF and return it on stdout.
18. GIVEN that `_h_clip` is called
    WHEN `uname` is `Darwin` AND `pbpaste` is on `$PATH`
    THEN it SHALL print clipboard contents to stdout AND return 0.
19. GIVEN that `_h_clip` is called
    WHEN `uname` is `Linux` AND any of `wl-paste`, `xclip`, or `xsel` is on `$PATH`
    THEN it SHALL print clipboard contents to stdout AND return 0.
20. GIVEN that `_h_clip` is called
    WHEN no supported clipboard tool is on `$PATH` for the current OS
    THEN it SHALL produce no stdout AND return 1.

**Edge Cases:**

- `_has_*` predicates must produce no stdout or stderr — they are pure boolean checks.
- `_h_*` log functions must be callable before `_check_deps` (i.e. before gum availability is confirmed), so each one checks `_has_gum` independently.
- `_h_fatal` must always exit 1.
- `_h_info`, `_h_warn`, and `_h_error` must never exit the script (they return only).
- `_h_choose`, `_h_filter`, and `_h_write` must return the selected item or entered value on stdout.

---

### REQUIREMENT 3: Dependency Guard (`_check_deps`)

**User Story:**

As a terminal user
I want clear messages when tools are missing
so that I know what is unavailable and what will degrade, rather than seeing cryptic failures

**Acceptance Criteria:**

1. GIVEN that `fabric` is the only hard dependency
   WHEN `_has_fabric` returns 1
   THEN script SHALL call `_h_fatal "fabric not found!"` and exit 1.
2. WHEN `_has_gum` returns 1
   THEN script SHALL call `_h_warn "gum not found! Interactive features disabled."` and continue execution.
3. WHEN `_has_glow` returns 1 AND `_has_bat` returns 0
   THEN script SHALL call `_h_warn "glow not found! Falling back to bat."` and continue execution.
4. WHEN `_has_glow` returns 1 AND `_has_bat` returns 1
   THEN script SHALL call `_h_warn "glow not found! Falling back to cat."` and continue execution.

**Edge Cases:**

- `_check_deps` is called once at the top of `main`, before any subcommand dispatch.
- Only missing `fabric` is fatal.
- Missing `gum`, `glow`, and `bat` are warnings only.
- When `_has_gum` returns 1, the `_h_warn` in AC-3.2 uses the plain `printf` fallback in `_h_log`
  so the warning is always printed regardless.
- Tool installation is **not** performed by the script; operators run `mise run setup` (see `design.md` §11).

---

### REQUIREMENT 4: Default invocation (no subcommand)

**User Story:**

As a terminal user
I want to list all available Fabric patterns interactively with a live preview when I run `xc-fabric`
so that I can discover, choose, and run Fabric patterns without remembering their names

**Acceptance Criteria:**

1. WHEN `xc-fabric` is invoked with no subcommand (and not only `-h`/`--help`)
   THEN script SHALL call `_h_filter` to show all available patterns with their descriptions.
2. WHEN `--no-preview` is NOT set
   THEN script SHALL pass a `--preview` pane showing each pattern's `system.md`
   AND it SHALL display the first 50 lines, or the full file with scroll when `fzf` is the active picker per AC-4.2 to `_h_filter`.
3. WHEN `--raw` is set
   THEN script SHALL print all patterns as TSV to stdout and exit 0 without opening any TUI.
4. WHEN a pattern is selected
   THEN script SHALL read input via `_read_input` (stdin when not a TTY, else `_h_clip`).
5. WHEN `--model <model>` is provided
   THEN script SHALL pass `--model <model>` to `fabric`.
6. WHEN fabric completes and `--raw` is NOT set and `--output` is NOT set
   THEN script SHALL render output via `_render_output`.
7. WHEN the user presses Esc in the picker
   THEN script SHALL exit 0 with no output.

**Edge Cases:**

- WHEN `~/.config/fabric/patterns/` is empty or missing,
  THEN `_h_filter` SHALL receive no input; script SHALL exit 0 gracefully.
- WHEN `_h_clip` fails (no clipboard tool or empty clipboard) AND stdin is a TTY,
  THEN script SHALL call `_h_fatal "no input available (clipboard empty or unsupported on $(uname))"` AND exit 1.
- WHEN `fzf` is the active picker,
  THEN the preview pane SHALL be scrollable and toggleable via the bindings in `design.md` §6.0;
  AND WHEN only `gum filter` is active,
  THEN the preview SHALL be static (no scroll/toggle).

---

### REQUIREMENT 5: Wizard subcommand

**User Story:**

As a terminal user
I want a step-by-step guided experience that collects pattern and placeholders interactively when I run `xc-fabric wizard`
so that I can run Fabric patterns interactively without remembering flags

**Acceptance Criteria:**

1. WHEN `wizard` is the first argument
   THEN script SHALL execute these steps in order:
   1. Open `_h_filter` over all patterns (always prompted, never skipped).
   2. For each `<PLACEHOLDER>` found in the selected pattern's `system.md`:
      1. prompt via `_h_prompt "  <NAME> › "`
         1. if the user submits an empty value
            1. prompt `_h_confirm "Leave <NAME> empty?"`
               1. if the answer is No, re-prompt for the same placeholder
               2. if the answer is Yes, continue to the next placeholder
   3. WHEN `--model <model>` is given
      THEN script SHALL pass `--model <model>` to `_exec_fabric`.
      ELSE script SHALL do nothing and Fabric SHALL use its configured default model (no interactive model picker).
   4. WHEN `--yes` is given
      THEN script SHALL skip the confirmation step
      ELSE script SHALL call `_h_confirm "Run <pattern>?"`
         1. WHEN the answer is No, exit 0.
         2. WHEN the answer is Yes, continue to the next step.
   5. Execute fabric wrapped in `_h_spinner "Running <pattern>"` with the input from stdin (with `--model <model>` if given).
   6. Render the result via `_render_output` (unless `--output` is set; see REQUIREMENT 6 AC-6.11).

**Edge Cases:**

- If the user presses Esc at any step, script SHALL exit 0.
- If the selected pattern has no `<PLACEHOLDER>` tokens, step 2 SHALL be skipped silently.
- If `_has_gum` returns 1, all interactive steps degrade to `read`/`head` fallbacks.

---

### REQUIREMENT 6: Run subcommand

**User Story:**

As a terminal user or script author
I want to run a named pattern directly from the command line when I run `xc-fabric run`
so that I can run Fabric patterns directly from the command line without opening the TUI picker

**Acceptance Criteria:**

1. WHEN `xc-fabric run <pattern>` is invoked
   THEN script SHALL call `_exec_fabric` with the given pattern and input from stdin (unless a URL branch applies per AC-6.5–AC-6.7).
2. WHEN `--model <model>` is given
   THEN script SHALL pass `--model <model>` to `_exec_fabric` or `_exec_fabric_youtube` as applicable.
3. WHEN stdin is not a TTY (e.g. pipe or file redirect)
   THEN script SHALL read input from stdin.
4. WHEN stdin is a TTY
   THEN script SHALL read input via `_h_clip`; if `_h_clip` fails, script SHALL call `_h_fatal` per REQUIREMENT 4 edge case.
5. WHEN a second positional argument after `<pattern>` is a YouTube URL (`https://(www.)?(youtube\.com|youtu\.be)`)
   THEN script SHALL call `_exec_fabric_youtube` with the given pattern and URL.
6. WHEN a second positional argument after `<pattern>` is an `https?://` URL that is **not** a YouTube URL
   THEN script SHALL call `_exec_fabric_scrape` with the given pattern and URL (fabric `-u`).
7. WHEN the pattern name contains `youtube` or `yt` (case-insensitive) AND no URL is provided
   THEN script SHALL call `_exec_fabric_youtube` with the given pattern and YouTube URL (from prompt or stdin as designed).
8. WHEN `--yes` is given
   THEN script SHALL skip any confirmation.
9. WHEN `--raw` is given
   THEN script SHALL print fabric output directly to stdout with no spinner and no renderer.
10. WHEN `--copy` or `-c` is given
    THEN script SHALL append `--copy` to the `fabric` invocation.
11. WHEN `--output <path>` or `-o <path>` is given
    THEN script SHALL append `--output <path>` to the `fabric` invocation AND SHALL NOT call `_render_output` for that execution.
12. WHEN `-v <value>` or `--variable=<value>` is given (repeatable)
    THEN script SHALL pass each occurrence through to `fabric` verbatim (wrapper does not validate fabric syntax).

**Edge Cases:**

- WHEN `xc-fabric run` is called with no pattern argument
  THEN script SHALL call `_h_fatal "pattern is required"` and exit 1.
- WHEN `_h_clip` fails and stdin is a TTY (or no input is available)
  THEN script SHALL call `_h_fatal "no input available (clipboard empty or unsupported on $(uname))"` and exit 1.
- WHEN `fabric` exits with a non-zero code
  THEN script SHALL pass that exit code through unchanged.
- WHEN `_exec_fabric_youtube` is called with no pattern or URL argument
  THEN script SHALL call `_h_fatal "pattern and URL are required"` and exit 1.

---

### REQUIREMENT 7: List subcommand (`ls`)

**User Story:**

As a terminal user
I want to list all available patterns with descriptions when I run `xc-fabric ls`
so that I can audit what is available without running any patterns

**Acceptance Criteria:**

1. WHEN `xc-fabric ls` is invoked
   THEN script SHALL display all patterns by piping `_list_patterns` output through `_h_table`.
2. WHEN `xc-fabric ls --raw` is invoked
   THEN script SHALL output plain TSV (`name\tdescription`), one pattern per line, with no headers.

**Edge Cases:**

- WHEN the patterns directory is empty or missing
  THEN script SHALL output nothing and exit 0 (not an error).
- Each line of TSV output SHALL contain exactly one tab character separating name from description.
- WHEN `_has_gum` returns 1
  THEN `_h_table` falls back to `cat` so the output is identical to `--raw` in terms of content but may differ in formatting.

---

### REQUIREMENT 8: YouTube processing (`_exec_fabric_youtube`)

**User Story:**

As a terminal user
I want to pass YouTube-specific options when processing YouTube URLs
so that I can control the transcript format, comments, and metadata

**Acceptance Criteria:**

1. GIVEN that a YouTube URL is being processed
   WHEN `--yt-timestamps` is given
   THEN script SHALL pass `--transcript-with-timestamps` to `fabric -y`.
2. GIVEN that a YouTube URL is being processed
   WHEN `--yt-comments` is given
   THEN script SHALL pass `--comments` to `fabric -y`.
3. GIVEN that a YouTube URL is being processed
   WHEN `--yt-metadata` is given
   THEN script SHALL pass `--metadata` to `fabric -y`.
4. GIVEN that a YouTube URL is being processed
   WHEN `--yt-playlist` is given
   THEN script SHALL pass `--playlist` to `fabric -y`.
5. GIVEN that no YouTube URL is being processed
   WHEN any `--yt-*` flag is given
   THEN script SHALL silently ignore the flag.

**Edge Cases:**

- Multiple `--yt-*` flags may be given simultaneously; all applicable SHALL be passed.
- `--yt-*` flags have no effect in non-YouTube execution paths.

---

### REQUIREMENT 9: Output Rendering (`_render_output`)

**User Story:**

As a terminal user
I want fabric output rendered in a readable format
so that Markdown results are presented clearly rather than as raw text

**Acceptance Criteria:**

1. GIVEN that `_has_glow` returns 0
   WHEN `_render_output` is called
   THEN script SHALL pipe the result through `glow`.
2. GIVEN that `_has_glow` returns 1 AND `_has_bat` returns 0
   WHEN `_render_output` is called
   THEN script SHALL pipe the result through `bat`.
3. GIVEN that `_has_glow` returns 1 AND `_has_bat` returns 1
   WHEN `_render_output` is called
   THEN script SHALL pipe the result through `cat`.
4. GIVEN that `--raw` is given
   WHEN output would otherwise be rendered
   THEN script SHALL NOT call `_render_output`
   AND fabric output SHALL go directly to stdout.

**Edge Cases:**

- The renderer is determined at runtime by `_render_output` checking `_has_*` predicates.
- An empty fabric result SHALL still be passed to the renderer so it can be rendered gracefully.
- WHEN `--output` is set, `_render_output` SHALL NOT be called (fabric writes to the file).

---

### REQUIREMENT 10: Spinner (`_h_spinner`)

**User Story:**

As a terminal user
I want a progress indicator while fabric runs
so that I know the script is working and not stalled

**Acceptance Criteria:**

1. GIVEN that `--raw` has NOT been given
   WHEN fabric is executing (non-`--output` path that uses capture + render)
   THEN script SHALL wrap the fabric invocation in `_h_spinner "Running <pattern>"` (or the equivalent title for YouTube).
2. GIVEN that `--raw` has been given
   WHEN fabric is executing
   THEN script SHALL NOT show a spinner around the fabric command.
3. GIVEN that `_has_gum` returns 1
   WHEN fabric is executing and a spinner would be shown per AC-10.1
   THEN `_h_spinner` SHALL print `<title>...` to stderr
   AND run fabric directly, without blocking or failing.

**Edge Cases:**

- The spinner title SHALL include the actual pattern name (or an equivalent descriptive title for YouTube).

---

### REQUIREMENT 11: Update patterns (`xc-fabric update`)

**User Story:**

As a terminal user
I want to refresh Fabric patterns from upstream when I run `xc-fabric update`
so that I stay current without memorising `fabric -U`

**Acceptance Criteria:**

1. WHEN `xc-fabric update` is invoked
   THEN script SHALL execute `fabric -U` wrapped in `_h_spinner "Updating patterns"` (unless `--raw` is given)
   AND SHALL pass fabric's exit code through unchanged.
2. WHEN `--raw` is given with `update`
   THEN script SHALL skip the spinner and stream `fabric -U` output directly to stdout.

---

### REQUIREMENT 12: Inspect pattern (`xc-fabric show`)

**User Story:**

As a terminal user
I want to read a pattern's definition without running it when I run `xc-fabric show <pattern>`
so that I can verify placeholders and instructions before spending API credits

**Acceptance Criteria:**

1. WHEN `xc-fabric show <pattern>` is invoked
   THEN script SHALL run `fabric --readpattern <pattern>` and pipe stdout through `_render_output` unless `--raw` is set.
2. WHEN `--raw` is given with `show`
   THEN script SHALL print `fabric --readpattern` output directly to stdout with no renderer.
3. WHEN `xc-fabric show` is invoked with no pattern argument
   THEN script SHALL call `_h_fatal "pattern is required"` and exit 1.

---

### REQUIREMENT 13: Strategies (`--strategy` and `xc-fabric strategies`)

**User Story:**

As a terminal user
I want to list and apply Fabric prompt strategies without memorising flags
so that I can combine strategies with patterns from the CLI

**Acceptance Criteria:**

1. WHEN `--strategy <name>` is given on a path that invokes `fabric`
   THEN script SHALL append `--strategy <name>` to the `fabric` invocation.
2. WHEN `xc-fabric strategies` is invoked
   THEN script SHALL run `fabric --liststrategies` and pipe output through `_h_table` when not `--raw`, else print raw to stdout.

---

### REQUIREMENT 14: URL scrape (`xc-fabric scrape`)

**User Story:**

As a terminal user
I want to scrape a web URL into markdown and send it through Fabric when I run `xc-fabric scrape <url>`
so that I can analyse pages without memorising `fabric -u`

**Acceptance Criteria:**

1. WHEN `xc-fabric scrape <url>` is invoked with a non-YouTube URL
   THEN it SHALL run `fabric -u <url>`
   AND WHEN a second positional `<pattern>` is given,
   THEN it SHALL append `--pattern <pattern>`;
   THEN it SHALL render via `_render_output` unless `--raw` is set.
2. WHEN `xc-fabric scrape <url>` is invoked with a URL matching the YouTube regex *(REQUIREMENT 6 / REQUIREMENT 8)*
   THEN it SHALL delegate to `_exec_fabric_youtube` (YouTube path owns that domain).
3. WHEN `xc-fabric scrape` is invoked with no URL
   THEN it SHALL call `_h_fatal "url is required"` AND exit 1.

**Edge Cases:**

- WHEN `xc-fabric scrape <youtube-url>` is invoked with no second positional pattern argument
  THEN it SHALL use the default pattern name `extract_wisdom` for the delegated `_exec_fabric_youtube` call *(see `design.md` §6.10)*.

---

## NON-FUNCTIONAL REQUIREMENTS

- **Hard dependency:** Only `fabric`. The script SHALL exit 1 WITHOUT it.
- **Optional dependencies:**
  - `fzf`, `gum`, `glow`, `bat`
  - absent tools are warned and degraded *(where applicable)*, never fatal except as documented for input.
- **Exit codes:**
  - Success → 0;
  - missing `fabric` or input error → 1;
  - fabric error → fabric's own exit code passed through unchanged;
  - user Esc/abort → 0.
- **Portability:** `#!/usr/bin/env zsh`
  - Clipboard: macOS (`pbpaste`) and Linux (`wl-paste` / `xclip` / `xsel`) via `_h_clip`.
  - Windows clipboard — out of scope.
- **ShellCheck compliance:** The script SHALL pass `shellcheck xc-fabric` with zero errors or warnings
- **Self-contained:** No external helper files or sourced libraries.
- **Strict mode:** `set -euo pipefail` enabled at top of script.

---

## OUT OF SCOPE

- History / favorites — deferred
- Windows clipboard — out of scope (`_h_clip` covers macOS and Linux only)
- Interactive model selection in any subcommand *(provider/model configured in Fabric)*
- `--stream` / `--dry-run` passthrough - *(deferred (execution-model / UX follow-up))*
- In-wrapper `fabric --setup` — operators use `mise run setup` and run `fabric -S` directly when needed
- Sessions, contexts, vendor-specific flags beyond documented passthroughs
- REST `--serve` / `--serveOllama`, image generation, audio/transcription flags
- extensions, `--search`, `--language` - *(use raw `fabric` for these)*
- `ctrl-y` yank-to-clipboard from `fzf` (requires `_h_clip` write-side) — deferred

---

## OPEN QUESTIONS

- None. All ambiguities resolved in design decisions D-1 through D-10 *(see `specs/xc-fabric/design.md`)*

---

## REQUIREMENTS VALIDATION CHECKLIST

**Completeness:**

- [x] All user roles identified and addressed (terminal user + script author)
- [x] Happy path scenarios covered for every subcommand
- [x] Edge cases documented per REQUIREMENT
- [x] Error cases handled (missing fabric, missing input, bad args)
- [x] Graceful degradation specified for every optional dependency
- [x] Business rules captured (renderer fallback chain, YouTube vs scrape routing, `_h_*` / `_h_clip` / fzf fallbacks)

**Clarity:**

- [x] Precise language used throughout
- [x] No ambiguous terms
- [x] Hard vs optional dependency distinction is explicit and consistent
- [x] Expected behaviours are specific and observable

**Consistency:**

- [x] EARS format used throughout acceptance criteria
- [x] Terminology consistent (`_has_*`, `_h_*`, `$PATH`, `_h_fatal`, `_h_clip`, `system.md`)
- [x] No contradictory REQUIREMENTS
- [x] `missing_fabric` → exit 1 throughout; optional-tool absence degrades with warnings where specified

**Testability:**

- [x] Each REQUIREMENT verifiable via `Bun.spawnSync` + env/PATH injection (or manual smoke where noted in `design.md` §10)
- [x] TUI-only paths (`cmd_default` / `cmd_wizard` full interactive flow) explicitly marked manual-smoke-test only in `design.md`
