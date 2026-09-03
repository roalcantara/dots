# Design: `xc-skills ls`

## 1. Overview & Architecture

`xc-skills ls` is an interactive skill browser and utility dispatcher embedded within `config/bin/xc-skills`. It uses the `usage` CLI parser for command-line arguments and metadata, `fzf` for fuzzy finding and multi-selection, `glow` / `bat` for rich markdown rendering, and platform-native clipboard tools.

---

## 2. CLI Interface & USAGE Specification

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

---

## 3. Implementation Details

### 3.1 Directory Resolution Logic

```bash
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
```

### 3.2 Listing & Discovered Items

Skills in `$source_dir` are discovered via `find` or nullglob:

- Only directories or symlinks to directories (or `.md` files) directly in `$source_dir`.
- Filter out non-skill hidden directories (e.g. `.git`, `.DS_Store`).

### 3.3 Clipboard Helper (`_copy_to_clipboard`)

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

### 3.4 `fzf` UI & Keybindings

```bash
local preview_cmd='file="{}/SKILL.md"; [ ! -f "$file" ] && file="{}"; if command -v glow >/dev/null 2>&1; then glow -s dracula "$file"; elif command -v bat >/dev/null 2>&1; then bat --color=always -l md --paging=never "$file"; else cat "$file"; fi'

local header="↵ select  Tab multi  ^O edit  ^N copy-name  ^P copy-path  ^U update  Esc exit"

local selected
selected=$(printf '%s\n' "${skill_entries[@]}" | fzf \
  --multi \
  --height="100%" \
  --header="$header" \
  --preview="$preview_cmd" \
  --preview-window="right:60%:wrap:border-rounded" \
  --bind="tab:toggle+down,btab:toggle+up" \
  --bind="ctrl-o:execute(sh -c 'files=(); for p in {+}; do [ -f \"\$p/SKILL.md\" ] && files+=(\"\$p/SKILL.md\") || files+=(\"\$p\"); done; \${EDITOR:-nvim} \"\${files[@]}\"' >/dev/tty)" \
  --bind="ctrl-n:execute-silent(sh -c 'for p in {+}; do basename \"\$p\"; done | \"$SCRIPT_PATH\" __clip')" \
  --bind="ctrl-p:execute-silent(sh -c 'for p in {+}; do echo \"\$p\" | sed \"s|^$HOME|~|\"; done | \"$SCRIPT_PATH\" __clip')" \
  --bind="ctrl-u:execute(sh -c 'names=(); for p in {+}; do names+=(\"\$(basename \"\$p\")\"); done; if command -v skills >/dev/null 2>&1; then echo \"Updating skills: \${names[*]}\"; command skills update -g \"\${names[@]}\"; else echo \"ERROR: skills CLI not found on PATH\"; fi; read -n1 -r -p \"Press any key to continue...\"' >/dev/tty)+reload(printf '%s\n' \"${skill_entries[@]}\")"
)
```

Note: `__clip` is an internal helper command within `xc-skills` for piping data into `_copy_to_clipboard`.

---

## 4. Error Handling & Edge Cases

1. **Non-TTY & Piping (`[[ ! -t 1 || ! -t 0 ]]`):** If `--raw` is passed or stdout is a pipe without a TTY, output the paths separated by newlines directly.
2. **Missing `fzf`:** Print helpful error to stderr and exit `1`.
3. **Empty Directory:** If 0 items, print `No skills found in $source_dir` and exit `0`.
4. **Missing Directory:** Print `ERROR: Skills directory not found: $source_dir` and exit `1`.
