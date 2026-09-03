# `xc-skills ls` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the interactive `xc-skills ls` subcommand for browsing, previewing (glow/bat), editing (editor), copying names/paths (clipboard), and updating skills via `fzf`.

**Architecture:** Add `#USAGE cmd "ls"` spec, `cmd_ls` handler, and cross-platform clipboard helper (`_copy_to_clipboard` / `__clip`) to `config/bin/xc-skills`. `fzf` handles multi-selection (`tab`), right preview window (`glow -s dracula`), and custom keybindings (`ctrl-o`, `ctrl-n`, `ctrl-p`, `ctrl-u`, `esc`).

**Tech Stack:** `bash`, `usage` CLI, `fzf`, `glow`, `bat`, `skills` CLI, `bun:test`, `shellcheck`.

---

## Task 1: Add USAGE Definition and Clipboard Helper to `config/bin/xc-skills`

**Files:**

- Modify: `config/bin/xc-skills`

- [ ] **Step 1: Add `#USAGE cmd "ls"` block and `__clip` helper**

In `config/bin/xc-skills`:

1. Add the `#USAGE cmd "ls"` block under the USAGE header:

```bash
#USAGE cmd "ls" help="List, preview, and manage installed skills via fzf" {
#USAGE   flag "-s --source <PATH>" help="Source directory containing skills (default: ~/.agents/skills)"
#USAGE   flag "-l --local" help="Use project-local skills directory ($PWD/.agents/skills)"
#USAGE   flag "-r --raw" help="Print skill folder paths to stdout without launching fzf"
#USAGE   example "xc-skills ls"
#USAGE   example "xc-skills ls -l"
#USAGE   example "xc-skills ls -s ~/.config/agents/skills"
#USAGE   example "xc-skills ls --raw"
#USAGE }
```

1. Add `_copy_to_clipboard` helper function:

```bash
_copy_to_clipboard() {
  if command -v pbcopy >/dev/null 2>&1; then
    pbcopy
  elif [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy >/dev/null 2>&1; then
    wl-copy
  elif [[ -n "${DISPLAY:-}" ]] && command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard
  elif [[ -n "${DISPLAY:-}" ]] && command -v xsel >/dev/null 2>&1; then
    xsel --clipboard --input
  else
    local data
    data="$(base64 | tr -d '\n')"
    printf '\e]52;c;%s\a' "$data" >/dev/tty
  fi
}
```

- [ ] **Step 2: Verify USAGE lint**

Run: `usage lint config/bin/xc-skills`
Expected: `No issues found.`

- [ ] **Step 3: Commit**

```bash
git add config/bin/xc-skills
git commit -m "feat(xc-skills): Add ls command usage spec and clipboard helper"
```

---

## Task 2: Implement `cmd_ls` in `config/bin/xc-skills`

**Files:**

- Modify: `config/bin/xc-skills`

- [ ] **Step 1: Implement `cmd_ls` function**

Implement `cmd_ls` in `config/bin/xc-skills`:

```bash
cmd_ls() {
  local local_flag=0
  local raw=0
  local explicit_source=""

  while (($# > 0)); do
    case "$1" in
      -l|--local) local_flag=1 ;;
      -r|--raw) raw=1 ;;
      -s|--source)
        shift
        if (($# == 0)); then err "--source requires a PATH argument"; usage >&2; exit 1; fi
        explicit_source="$1"
        ;;
      -*) err "Unknown option: $1"; usage >&2; exit 1 ;;
      *)  err "Unexpected argument: $1"; usage >&2; exit 1 ;;
    esac
    shift
  done

  local source_dir=""
  if [[ -n "$explicit_source" ]]; then
    source_dir="$explicit_source"
  elif ((local_flag)); then
    source_dir="$PWD/.agents/skills"
  else
    source_dir="$HOME/.agents/skills"
  fi

  if [[ ! -d "$source_dir" ]]; then
    err "Skills directory not found: $source_dir"
    exit 1
  fi

  shopt -s nullglob
  local -a entries=("$source_dir"/*)
  shopt -u nullglob

  local -a skills=()
  for entry in "${entries[@]}"; do
    local base="${entry##*/}"
    [[ "$base" == .* ]] && continue
    if [[ -d "$entry" || -f "$entry" ]]; then
      skills+=("$entry")
    fi
  done

  if [[ ${#skills[@]} -eq 0 ]]; then
    log "No skills found in $source_dir"
    exit 0
  fi

  if ((raw)) || [[ ! -t 1 || ! -t 0 ]]; then
    printf '%s\n' "${skills[@]}"
    exit 0
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    err "fzf is required for interactive mode. Use --raw for script output."
    exit 1
  fi

  local preview_cmd='file="{}/SKILL.md"; [ ! -f "$file" ] && file="{}"; if command -v glow >/dev/null 2>&1; then glow -s dracula "$file"; elif command -v bat >/dev/null 2>&1; then bat --color=always -l md --paging=never "$file"; else cat "$file"; fi'
  local header="↵ select  Tab multi  ^O edit  ^N copy-name  ^P copy-path  ^U update  Esc exit"

  local scope_flag="-g"
  ((local_flag)) && scope_flag="-p"

  local selected
  selected=$(printf '%s\n' "${skills[@]}" | fzf \
    --multi \
    --height="100%" \
    --header="$header" \
    --preview="$preview_cmd" \
    --preview-window="right:60%:wrap:border-rounded" \
    --bind="tab:toggle+down,btab:toggle+up" \
    --bind="ctrl-o:execute(sh -c 'files=(); for p in {+}; do [ -f \"\$p/SKILL.md\" ] && files+=(\"\$p/SKILL.md\") || files+=(\"\$p\"); done; \${EDITOR:-nvim} \"\${files[@]}\"' >/dev/tty)" \
    --bind="ctrl-n:execute-silent(sh -c 'for p in {+}; do basename \"\$p\"; done | \"$SCRIPT_PATH\" __clip')" \
    --bind="ctrl-p:execute-silent(sh -c 'for p in {+}; do echo \"\$p\" | sed \"s|^$HOME|~|\"; done | \"$SCRIPT_PATH\" __clip')" \
    --bind="ctrl-u:execute(sh -c 'names=(); for p in {+}; do names+=(\"\$(basename \"\$p\")\"); done; if command -v skills >/dev/null 2>&1; then echo \"Updating skills: \${names[*]}\"; command skills update $scope_flag \"\${names[@]}\"; else echo \"ERROR: skills CLI not found on PATH\"; fi; read -n1 -r -p \"Press any key to continue...\"' >/dev/tty)" \
  ) || true

  if [[ -n "$selected" ]]; then
    printf '%s\n' "$selected"
  fi
}
```

- [ ] **Step 2: Wire `main` dispatch for `ls` and `__clip`**

In `main()`:

```bash
  case "$1" in
    ls)      shift; cmd_ls "$@" ;;
    sync)    shift; cmd_sync "$@" ;;
    collect) shift; cmd_collect "$@" ;;
    __clip)  _copy_to_clipboard; exit 0 ;;
    -*) err "Unknown option: $1"; usage >&2; exit 1 ;;
    *)  err "Unknown subcommand: $1"; usage >&2; exit 1 ;;
  esac
```

- [ ] **Step 3: Run shellcheck and usage lint**

Run:

```bash
usage lint config/bin/xc-skills
shellcheck config/bin/xc-skills
```

Expected: PASS with zero errors/warnings.

- [ ] **Step 4: Commit**

```bash
git add config/bin/xc-skills
git commit -m "feat(xc-skills): Implement ls command with fzf and preview"
```

---

## Task 3: Integration Tests for `xc-skills ls`

**Files:**

- Modify: `assets/integration/bin/xc-skills.spec.ts`

- [ ] **Step 1: Write integration tests for `ls`**

Add tests to `assets/integration/bin/xc-skills.spec.ts`:

- Help test (`xc-skills ls -h`, `xc-skills ls --help`).
- Raw list test (`xc-skills ls --raw`).
- Local raw list test (`xc-skills ls -l --raw`).
- Custom source raw list test (`xc-skills ls -s <dir> --raw`).
- Missing directory error handling test (exits 1).
- Empty directory handling test (exits 0 with `No skills found in <dir>`).

- [ ] **Step 2: Run tests**

Run: `bun test assets/integration/bin/xc-skills.spec.ts`
Expected: PASS (all tests pass).

- [ ] **Step 3: Commit**

```bash
git add assets/integration/bin/xc-skills.spec.ts
git commit -m "test(xc-skills): Add integration tests for ls subcommand"
```

---

## Task 4: Documentation & Quality Gate Verification

**Files:**

- Modify: `config/bin/README.md`
- Modify: `config/bin/HANDOFF-USAGE-MIGRATION.md`

- [ ] **Step 1: Update documentation**

Document `xc-skills ls` subcommand and keybindings in `config/bin/README.md` and `config/bin/HANDOFF-USAGE-MIGRATION.md`.

- [ ] **Step 2: Run whole-suite quality checks**

Run:

```bash
for f in config/bin/xc-md config/bin/xc-puts config/bin/xc-toast config/bin/xc-skills config/bin/xc-git; do
  usage lint "$f"
done
shellcheck config/bin/xc-md config/bin/xc-puts config/bin/xc-toast config/bin/xc-skills config/bin/xc-git
bun test assets/integration/bin/xc-md.spec.ts assets/integration/bin/xc-puts.spec.ts assets/integration/bin/xc-toast.spec.ts assets/integration/bin/xc-skills.spec.ts assets/integration/bin/xc-git.spec.ts
```

Expected: All checks pass.

- [ ] **Step 3: Commit**

```bash
git add config/bin/README.md config/bin/HANDOFF-USAGE-MIGRATION.md
git commit -m "docs(xc-skills): Document ls command and keybindings"
```
