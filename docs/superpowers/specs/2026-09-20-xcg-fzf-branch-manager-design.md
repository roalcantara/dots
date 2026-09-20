# xcg — single fzf branch manager

- **Date:** 2026-09-20
- **Status:** Approved, ready for implementation planning
- **Target:** `config/bin/xcg`, `config/bin/src/helpers`, `assets/integration/bin/xcg.spec.ts`

## Problem

`xcg` today exposes one command per operation — `branches`, `cnb`, `clear-merged`,
`clear-gone`, `fzb`, `fzc`, `remote-branches`, `head-branch`. Every branch chore
means recalling which subcommand does it, and pruning several branches means
running a command per branch.

Collapse the interactive surface into a single fzf list that opens on local
branches, switches views by keystroke, and acts on the selection in place.

## Goals

- `xcg` with no arguments opens one fzf list, local branches shown immediately.
- Views switch by keystroke without leaving the list.
- Delete, checkout and copy act on the fzf selection.
- A preview pane answers "what is this branch" and "is it safe to delete".
- The non-interactive subcommands survive for scripting and non-TTY use.

## Non-goals

- Changing `gitx`. Its overlapping branch commands stay as they are; the
  duplication is accepted for now and is a separate decision.
- Creating branches from inside the fzf UI. `xcg cnb <branch>` keeps that job.
- Any rebase, commit or stash operation. This is branch management only.

## Command surface

```text
xcg                      # TTY  → fzf UI;  non-TTY → same as `xcg branches`
xcg branches             # local branch names, one per line
xcg remote-branches [r]  # remote branch names (default remote: origin)
xcg head-branch          # current branch
xcg cnb <branch>         # create + checkout
xcg clear-merged         # delete merged branches (unchanged)
xcg clear-gone           # delete branches whose upstream is gone (unchanged)
```

Five internal subcommands back the fzf bindings: `__list`, `__preview`,
`__delete`, `__checkout`, `__copy`. They are undocumented — absent from `--help`
— but runnable, which is what makes the data layer testable headlessly.

## Dropping the usage integration

`xcg` becomes a fzf-first tool, so the usage framework no longer earns its place
and is removed:

- shebang `#!/usr/bin/env -S usage zsh` → `#!/usr/bin/env zsh`
- all `#USAGE` comment lines deleted
- `${usage_branch:-${1:-}}` and friends collapse to plain positional `${1:-}`
- dispatch stays a `case "$1"`, which is what it already is
- `-h` / `--help` is hand-rolled: a heredoc listing the subcommands and the fzf
  keymap, exiting 0

Nothing currently wired depends on the spec, which was verified before deciding:

- `xc`, the launcher, only discovers `xc-*` executables, so it never introspects
  `xcg`
- there is no `_xcg` completion in `config/zsh/opt/completions/`
- no generic `usage generate completion-init` is sourced from `config/zsh/opt/rc.d/`

The only real loss is the generated help page, replaced by the heredoc. The
existing integration contract — `xcg -h` and `xcg --help` exit 0 and mention
`xcg` — must keep passing against the hand-rolled version.

### Shell option review

While the preamble is being touched, confirm whether each line still earns its
place rather than carrying it over by reflex:

```zsh
emulate -L zsh
setopt no_unset pipe_fail extended_glob
```

Points to settle, each with a decision recorded in the plan:

- `emulate -L zsh` — `-L` scopes options to the enclosing function; at script top
  level it is close to a no-op, and the script is no longer launched by `usage`
  as an interpreter argument, so the environment it was defending against has
  changed.
- `no_unset` — it forces defensive `${x:-}` everywhere. Most of those guards
  existed for `usage_*` variables that are going away.
- `pipe_fail` — it mattered for the old `git | grep | sed` branch pipelines.
  `__list` is a single `for-each-ref`, so check what pipelines actually remain.
- `extended_glob` — confirm any glob in the final script actually needs it.

Keep what a remaining line demonstrably protects; drop what nothing uses.

## Data layer

One row format for every view, produced by `git for-each-ref`, TSV:

```text
kind <TAB> ref <TAB> display
```

- `kind` — `local` or `remote`
- `ref` — `feat-x`, or `origin/feat-x` for remotes
- `display` — pre-padded, pre-coloured columns: branch, relative date, author,
  track status

fzf receives `--delimiter=$'\t' --with-nth=3..`, so fields 1 and 2 are neither
displayed nor searchable, but remain available to actions as `{1}` and `{2}`.

No `--nth` is passed. fzf applies `--nth` to the string *after* `--with-nth` has
transformed it, so a `--nth=3..` would index into a line that no longer has three
fields and would match nothing — verified against fzf 0.74.4. `--with-nth=3..`
alone already removes fields 1 and 2 from the search string.

**Each row carries its own kind.** This is the central simplification: `__delete`
reads the row to decide between `git branch -d` and `git push --delete`, so no
view state has to be threaded into the action, and a future combined view would
work without changes.

### Views

| View | Source |
| ---- | ------ |
| local | `for-each-ref refs/heads` |
| remote | `for-each-ref refs/remotes`, minus `*/HEAD` |
| merged | `for-each-ref --merged <default> refs/heads`, minus protected |
| gone | `refs/heads` where `%(upstream:track)` contains `[gone]` |

### Protected branches

Protected = default branch + `main` + `master` + `develop` + current `HEAD`.
They are excluded from the merged and gone views, and `__delete` refuses them
with a warning naming what it skipped.

Default branch resolution, in order: `git symbolic-ref --short
refs/remotes/origin/HEAD` with the `origin/` prefix stripped; then the first of
`main`, `master`, `develop` that exists; then the current branch.

## fzf UI

```text
ctrl-l  → change-header(…)+reload(xcg __list local)     [default view]
ctrl-r  → change-header(…)+reload(xcg __list remote)
ctrl-m  → change-header(…)+reload(xcg __list merged)
ctrl-g  → change-header(…)+reload(xcg __list gone)
ctrl-x  → execute(xcg __delete safe  {+})+reload(xcg __list)
alt-x   → execute(xcg __delete force {+})+reload(xcg __list)
ctrl-o  → become(xcg __checkout {1} {2})
ctrl-y  → execute-silent(xcg __copy {+})
alt-e   → execute(xcg __diag | less -R)
alt-c   → execute-silent(xcg __copy-diag)
preview → xcg __preview {1} {2}
```

### Script self-reference

The path the bindings call back into **must be captured at top level**:

```zsh
XCG_SELF="${${(%):-%x}:a}"
```

zsh sets `FUNCTION_ARGZERO` by default, so inside a function `$0` is the
function's own name. A `${0:a}` written inside `xcg::ui` resolves to
`$PWD/xcg::ui`, and every binding silently points at a file that does not exist
— fzf reports only a truncated `[Command failed: …]`. `%x` is the file being
executed and is correct in any scope. Same idiom as `config/bin/xc`.

### Diagnostics

`reload` and `preview` run without a terminal, so their stderr is otherwise
lost. Both are invoked with `2>>$XCG_LOG`, a `mktemp` file created alongside
`$XCG_STATE` and removed by the same `trap` (and by `__checkout`, which `become`
would otherwise leak).

- `__diag` prints the script path, cwd, resolved git dir, fzf version, active
  view, and the captured log
- `alt-e` pages that output; `alt-c` copies it to the clipboard
- `__copy-diag` honours `XCG_COPY_STDOUT` so it is testable without a clipboard

`--multi` is on. `{+}` passes each marked row verbatim as one shell-quoted
argument, tabs intact, so `__delete` and `__copy` re-split on tab.

`alt-x` rather than `ctrl-X` for force delete: terminals send the same byte for
`ctrl-x` and `ctrl-shift-x`, and fzf treats `ctrl-x` and `ctrl-X` as the same
binding, so the two cannot be distinguished.

### View state

The `reload` after a delete must restore the view that was active, and an fzf
binding has no way to know it. `xcg __list <view>` therefore writes the view name
to the file named by `$XCG_STATE`, and bare `xcg __list` reads it back.

`$XCG_STATE` is a `mktemp` file exported before fzf starts and removed by a
`trap` on `EXIT INT TERM`. `__checkout` removes it explicitly as well, because
`become` replaces the process and traps never fire.

## Actions

### Delete — `ctrl-x` (safe) and `alt-x` (force)

Every delete confirms, local and remote alike.

1. Split the rows; drop protected refs and warn which were skipped.
2. Print the exact operations to be run, then `gum confirm`, falling back to
   `read -q` when gum is absent.
3. Execute: local → `git branch -d` (safe) or `git branch -D` (force); remote →
   `git push --delete <remote> <branch>` for both modes.
4. On failure, wait for a keypress so the error survives fzf's redraw. On
   success, return and let `reload` refresh the list.

`execute` rather than `execute-silent` is required: it hands the terminal to the
child process, which is what lets `gum confirm` draw.

`XCG_YES=1` skips the confirmation. Required for headless tests, and useful in
scripts.

### Checkout — `ctrl-o`

Acts on the cursor row only; marked rows are ignored, since checking out several
branches has no meaning. `become` replaces the fzf process, so git's output lands
in the scrollback.

- local: `git switch <ref>`
- remote `origin/foo`: switch to local `foo` when it already exists, otherwise
  `git switch --track origin/foo`

A dirty working tree is left to git to refuse, with git's own message.

### Copy — `ctrl-y`

Copies every marked row (or the cursor row when nothing is marked), newline
joined, with the remote prefix stripped — `foo`, not `origin/foo`, since the
name is normally being pasted into another git command.

### Preview

```text
feat-add-shared-skills-and-updates
upstream: origin/feat-add-shared…   ↑3 ↓0
last:     2 hours ago · roalcantara
status:   not merged into main
────────────────────────────────────
* 278b130 chore(*): Add benchmark plan
* 60d0700 chore(zsh): Add zsh-history-filter
```

A metadata header — upstream, ahead/behind, last commit date and author, merged
or gone status — then `git log --oneline --graph --color=always` over
`<default>..<ref>`, falling back to a plain `log -n 20` when that range is empty.
For remote refs the merged check runs against `origin/<default>`.

## Helper change

`h::has_command` gates on `[[ -t 1 ]]`, conflating "is stdout a TTY" with "does
this binary exist". Two consequences block this feature:

- inside `execute-silent`, stdout is not a TTY, so `h::copy_to_clipboard` reports
  *"No clipboard utility found"* despite a working `pbcopy`;
- `h::needs_command fzf` claims fzf is not installed whenever `xcg` is piped.

Add `h::has_bin()` — a plain `command -v` with no TTY check — and point
`h::copy_to_clipboard` and `h::needs_command` at it. `h::has_command` keeps the
TTY check and keeps its remaining job: choosing between gum and plain output,
which is a presentation decision where TTY-awareness is correct.

This is scoped to what the feature needs; no other helper is touched.

## Error handling

| Condition | Behaviour |
| --------- | --------- |
| not a git repository | `h::puts fatal "not a git repository"` |
| fzf missing | fatal, with an install hint |
| empty view | header states the view is empty; the UI stays usable |
| delete of a protected branch | skipped, named in a warning |
| delete fails (unmerged under `-d`, rejected push) | git's error shown, keypress pause, list reloads |

## Testing

Follows the `dots-testing` layers. The data layer is testable because the
internal subcommands are runnable; the fzf binding layer is not reachable by any
harness and stays manually verified.

`assets/integration/bin/xcg.spec.ts`, with a fixture helper that builds a
throwaway git repo containing a merged branch, an unmerged branch, a branch whose
upstream is gone, and a remote-only branch:

- `__list local|remote|merged|gone` emits the expected rows in TSV, and the
  merged and gone views exclude protected branches
- `__delete` refuses protected branches and names them
- `__delete` under `XCG_YES=1` removes a merged branch, and `-d` refuses an
  unmerged one while `-D` removes it
- `__preview` prints the header fields for a known branch
- `branches` and `head-branch` keep their current contracts, and `-h` / `--help`
  still exit 0 and mention `xcg` now that the page is hand-rolled rather than
  generated by usage

Manual checklist for the fzf layer: each view key switches the list and header;
`ctrl-x` and `alt-x` prompt and reload into the same view; `ctrl-o` exits to the
checked-out branch; `ctrl-y` puts the name on the clipboard.

Gate: `mise run -C assets test bin`.

## Open risk

`alt-x` depends on the terminal sending `Esc`-prefixed Option. It works in
iTerm2, Ghostty and Kitty with the usual configuration; if it silently fails to
fire during manual verification, rebind force delete to `ctrl-d`, accepting the
loss of fzf's default half-page-down.
