# todo completion and fzf-tab alignment — design

Small change, same branch as the root TODO.yaml: `chore/add-todos`.

## Intent

`todo <Tab>` in a new zsh prints `error: unexpected argument '-f' found` four times, then `-- no matches found --`.
Fix it so Tab completes `todo`'s commands, flags and the tasks in `./TODO.yaml` through fzf-tab, and bring the
fzf-tab setup in line with fzf-tab's own README, so other completions do not break in similar ways.

## Cause

No `_todo` exists, so compinit binds `todo` to zsh's bundled `_devtodo` (`#compdef devtodo todo tda tde tdd tdr`,
for devtodo 0.1.20). Its `_todo_index` runs `todo … -f +children --format …` (line 91), which RayanBO/todo rejects.
fzf-tab only displays the result.

## Goals

- `todo` completes with a committed `config/zsh/opt/completions/_todo`, which shadows `_devtodo` (that directory
  precedes zsh's functions in `$fpath`; tested: the first `#compdef todo` on `$fpath` wins).
- Task IDs complete with their descriptions (`vVZO  Sample task`); `--tag` offers the tags in use; `--priority`
  offers `low medium high`; `status --set` offers `todo en-cours done bloqued`; `cwi` offers `md yaml`.
- fzf-tab previews the task's details when the candidate is a task ID.
- The fzf-tab configuration follows its README (table below). Tab's behaviour stays: accept, then continue
  completing (`continuous-trigger tab`).

## Non-goals

- Deleting `_devtodo`: it ships with zsh (`Cellar/zsh/<v>/share/zsh/functions`, and macOS's `/usr/share/zsh`);
  a delete returns on every `brew upgrade zsh`. Shadowing it is the durable fix.
- Completions for the blog list from other directories: `todo` reads only `./TODO.yaml` (or `./TODO.md`).
- Changing fzf's look (colours, height, pointer) or any key binding other than the no-op one below.

## Approaches

- **A. Generate, then patch (picked):** a mise task runs `todo completion zsh` and substitutes the generated
  `_default` placeholders with the completions below, then writes `_todo`. Stays in step with the CLI; fails loudly
  when a placeholder it expects is missing (after a `todo` upgrade).
- **B. Hand-written `_todo`:** readable, but drifts silently when the CLI changes.
- **C. Generated only:** fixes the bug and completes commands and flags; no tasks, tags or preview.

## Decided

- Task `zsh:completions:todo` (in `mise.toml`, next to `zsh:verify`) regenerates `_todo` from
  `todo completion zsh` with these substitutions, each required to match at least once:

  | Generated | Becomes |
  | --- | --- |
  | `:id -- …:_default` (update, delete, status) and `:TASK_ID:_default` | `_todo_task_ids` |
  | `:TAG:_default` | `_todo_tags` |
  | `:PRIORITY:_default` | `(low medium high)` |
  | `:SET:_default` | `(todo en-cours done bloqued)` |
  | `::format -- …:_default` (cwi) | `(md yaml)` |

- `_todo_task_ids` and `_todo_tags` are hand-written autoloaded functions, one file each in
  `config/zsh/opt/completions/` (no `#compdef` line); the generated `_todo` only references them. They read
  `todo list --tasks` and `todo tags` in the current directory and offer nothing (silently) when there is no TODO
  file. Task IDs complete with `_describe` (id + description), so fzf-tab shows both.
- fzf-tab preview for `todo`: when the word is a task ID, the task's block from `todo list --tasks`.
- fzf-tab and completion styles, per its README (installed version, fzf 0.75):

  | Where | Now | Change |
  | --- | --- | --- |
  | `config/zsh/opt/rc.d/zim.zsh:72` | `':completion:*' menu select=2` | `menu no` |
  | `config/zsh/opt/plugins/fzf-tab.zsh:95` | `':fzf-tab:complete:*' menu no` | delete (not a context fzf-tab reads) |
  | `:completion:*:descriptions` format | `'%F{yellow}-- %d --%f'` (zim module) | `'[%d]'`, set in `zim::overrides` (README: no escape sequences, or groups break) |
  | `config/zsh/opt/rc.d/env.zsh:99` | `list-colors "$LS_COLORS"` | `list-colors ${(s.:.)LS_COLORS}` |
  | `config/zsh/opt/plugins/fzf-tab.zsh:105` | `':fzf-tab:*' list-colors` | delete (not an fzf-tab style) |
  | `config/zsh/opt/plugins/fzf-tab.zsh` fzf-flags | `--bind=tab:accept` | delete (fzf-tab's `--expect=tab` already wins; no behaviour change) |

## My calls (correct if wrong)

- mise preview (`fzf-tab.zsh:158`) calls `mise_tool_preview`, which is defined nowhere: use `mise tool $word`.
- Task IDs only for `update`/`delete` IDs, though they also accept actor and comment IDs (rarely typed by hand).
- No `.zwc` or dump handling: zim rebuilds its dump when a file on `$fpath` is added or changes.

## Verification

- A Bun spec (`test/integration/bootstrap/`): in `zsh -f` with `fpath=(config/zsh/opt/completions $fpath)` and
  `compinit`, `$_comps[todo]` is `_todo`; the committed `_todo` equals a fresh `zsh:completions:todo` output
  (skipped without `todo`); `_todo_task_ids` and `_todo_tags` list a fixture's IDs, descriptions and tags.
- The spec also asserts the effective zstyles of an interactive zsh: `menu no`, descriptions format `[%d]`,
  `list-colors` more than one value, no `--bind=tab:accept` in fzf-flags, `continuous-trigger tab`.
- By hand in a new terminal: `todo <Tab>`, `todo status <Tab>`, `todo list --priority <Tab>`, `git checkout <Tab>`,
  `cd <Tab>`, `mise install <Tab>` show fzf-tab lists without errors, with groups and previews.
- Gates: `mise run test:specs`, `hk check --all`, `mise run zsh:verify`.

## Left to the builder

The patch tool (sed or a short script), the helpers' parsing, and the exact preview command.
