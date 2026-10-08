<!-- markdownlint-disable -->
# gitx fza — Design

## 1. OVERVIEW

`gitx fza` opens an fzf picker listing every file that `git add` would change in the current
repository. The user toggles files with `Tab`, sees the keymap in a bordered `keys` box, and
stages the selection with `Enter` (or runs `git add -p` on it with `Ctrl-P`).

Scope: `config/bin/gitx` only. `fzu` / `fzus` are unchanged.

### Problems with the current implementation

```zsh
fza)
  git status -s | fzf -m | awk '{print $2}' | xargs git add
```

- The keymap isn't shown, so nothing tells the user that `Tab` toggles a file.
- Fully-staged files are listed even though adding them is a no-op.
- Untracked directories collapse into `dir/` instead of individual files.
- `awk '{print $2}'` breaks on renames (`R a -> b`) and on paths with spaces or quotes.
- There's no preview of the change being staged.
- An empty selection still runs `git add` with no arguments.

---

## 2. APPROACH

The rewrite stays inside the `fza)` case of `config/bin/gitx`, with one new helper defined next to
`_gitx_branches`. It doesn't add hidden self-invoked subcommands: `gitx` parses its arguments with
`usage`, which rejects undeclared commands. The preview and patch actions are inline fzf commands.

The rejected alternatives were delegating to `xc-git add-fzf`, which needs two files and a USAGE
block for about 30 lines, and an `xcg`-style standalone script, which is only justified for live
staging.

---

## 3. COMPONENTS

### 3.1 `_gitx_add_candidates`

- **Input:** none. It runs in the current repo.
- **Source:** `git status --porcelain=v1 -z --untracked-files=all`.
- **Rule:** keep an entry when its worktree column `Y` is not a space. This includes:
  - ` M`, `MM`, `AM`: unstaged modifications, including partially-staged files
  - ` D`: unstaged deletions
  - `??`: untracked files, each one listed individually
  - `RM`, `CM`: renamed or copied files with further edits (the new path is used)
- **Excluded:** entries with a blank `Y` (`M `, `A `, `D `, `R `), which are fully staged.
- **Rename/copy parsing:** when `X` or `Y` is `R` or `C`, the next NUL field is the original path.
  It's consumed and discarded.
- **Output:** one line per file, `XY<TAB>path`.

### 3.2 Picker (`fza)` case)

```zsh
fza)
  h::needs_command fzf
  git rev-parse --git-dir &>/dev/null || { h::puts error "Not a git repository"; exit 1; }
  candidates=$(_gitx_add_candidates)
  [[ -z "$candidates" ]] && { h::puts info "Nothing to add"; exit 0; }

  keys='select  tab toggle  ⇧tab toggle↑  ^a all  ^d none'$'\n'
  keys+='act     enter add  ^p patch  ^/ preview  esc cancel'

  selected=$(print -r -- "$candidates" | fzf --multi --ansi \
    --delimiter=$'\t' --accept-nth=2 \
    --header="$keys" --header-border=rounded --header-label=' keys ' \
    --color='header:bold,header-border:dim' \
    --prompt='add ❯ ' \
    --preview='[[ {1} == "??" ]] && git diff --no-index --color=always -- /dev/null {2}; git diff --color=always -- {2}' \
    --preview-window='right,60%,border-left,nohidden' \
    --bind='ctrl-a:select-all,ctrl-d:deselect-all,ctrl-/:toggle-preview' \
    --bind='ctrl-p:become(git add -p -- {+2})') || exit 0

  [[ -z "$selected" ]] && exit 0
  git add -- "${(@f)selected}" && git status -s
  ;;
```

This needs fzf 0.60 or newer for `--accept-nth`; the installed version is 0.74.4. The snippet shows the intended shape. During implementation, check the quoting of `{1}` / `{2}`
and the preview command, which fzf runs under `$SHELL`. The preview MUST be visible when fzf opens: `nohidden` pins this even if `FZF_DEFAULT_OPTS` sets `hidden`.

### 3.3 Keymap

| Key        | Action                                            |
| ---------- | ------------------------------------------------- |
| `Tab`      | Toggle the current file and move down             |
| `Shift-Tab`| Toggle the current file and move up               |
| `Ctrl-A`   | Select all                                        |
| `Ctrl-D`   | Deselect all                                      |
| `Enter`    | `git add --` the selection, then print `git status -s` |
| `Ctrl-P`   | Replace fzf with `git add -p -- <selection>`      |
| `Ctrl-/`   | Toggle the preview (open on start)                |
| `Esc`      | Cancel without staging anything                   |

The `keys` header box lists every binding, following the `xcg` pattern.

---

## 4. DATA FLOW

```text
git status --porcelain -z -uall
  → _gitx_add_candidates   (filter Y != ' ', "XY\tpath")
  → fzf --multi            (user toggles; preview shows diff)
  → Enter:  selected paths → git add -- … → git status -s
  → Ctrl-P: become(git add -p -- …)
  → Esc:    exit 0
```

---

## 5. ERROR HANDLING AND EDGE CASES

| Case                         | Behavior                                              |
| ---------------------------- | ----------------------------------------------------- |
| fzf not installed            | `h::needs_command fzf` fails                          |
| Not inside a git repo        | `h::puts error`, exit 1                               |
| No candidates                | `h::puts info "Nothing to add"`, exit 0, fzf never opens |
| `Esc` / no selection         | Nothing is staged, exit 0                             |
| Paths with spaces or quotes  | Safe: NUL-parsed input, `${(@f)…}` array to `git add --` |
| Paths containing newlines    | Not supported (known limitation)                      |
| `Ctrl-P` on untracked files  | `git add -p` skips them. The user stages untracked files with `Enter` instead |

---

## 6. TESTING

**Candidate helper.** Build a temporary repo containing:

- a modified tracked file
- an untracked file inside an untracked subdirectory
- a deleted tracked file
- a staged rename with further edits (`RM`)
- a partially-staged file (`MM`)
- a fully-staged file (`M `)
- a file whose name contains a space

Assert that `_gitx_add_candidates` lists everything except the fully-staged file, that the
subdirectory file appears by its full path, and that the rename appears under its new path.

**Manual pass.** Exercise each key in §3.3, including `Esc`, an empty selection, and running in a
clean repo.

**Gate.** Run the repo's shell lint and quality gate (`dots-quality-gate`) on `config/bin/gitx`.
