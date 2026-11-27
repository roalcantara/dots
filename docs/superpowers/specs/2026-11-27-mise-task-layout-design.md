# Mise task layout: tasks next to what they manage

Approved by the owner on 2026-11-27. A small change.

## Intent

Today the repo's 18 TOML tasks share the root `mise.toml` (about 440 lines, seven topics) and there is no convention,
so the owner finds a task with grep. A rule that says where a task lives, one topic per file, makes it findable
without searching and keeps each file focused. Behaviour must not change.

## The rule

- A repo task lives in `tasks.toml` inside the folder of what it manages, one topic per file, with top-level task
  names (`["zsh:verify"]`). The root `mise.toml` includes them by glob and holds no tasks.
- A `mise.toml` in a subfolder is a separate project with its own tools, run with `mise run -C <folder>`
  (`config/nvim`, `config/bin`, `test`).
- File-task scripts stay in `.mise/tasks/<topic>/` (mise's default folder, linted like other scripts).

## Mapping

| File | Tasks |
| --- | --- |
| `distros/tasks.toml` | `build`, `start`, `test` |
| `test/tasks.toml` | `test:specs` |
| `config/zsh/tasks.toml` | `zsh:baseline`, `zsh:verify`, `zsh:bench`, `zsh:completions:lida`, `zsh:completions:usage`, `zsh:lig` |
| `config/age/tasks.toml` | `setup:age` |
| `config/sops/tasks.toml` | `setup:git:filters` |
| `config/hk/tasks.toml` | `setup:hooks` |
| `config/theme/tasks.toml` | `theme:build` |
| `config/karabiner/tasks.toml` | `karabiner:build` |
| `config/raycast/tasks.toml` | `tuis:build` |
| `config/agents/tasks.toml` | `skills:audit`, `skills:restore` |

The root `mise.toml` keeps `[task_config] includes = [".mise/tasks", "*/tasks.toml", "config/*/tasks.toml"]`,
`[settings]`, `[tools]` and `[env]`.

## Facts (tested on mise 2026.11.14)

| Fact | Consequence |
| --- | --- |
| `task_config.includes` accepts globs (`config/*/tasks.toml`) | a new topic needs no edit to `mise.toml` |
| An included task runs from the including config's root (the repo), whatever the cwd | `./script/…` paths keep working |
| An included file must use top-level task names; `[tasks."x"]` there fails ("unknown field") | the files are not `mise.toml` |
| Any `mise.toml` is also auto-loaded as its own config from that folder (and through the `~/.config` links), where the top-level form is invalid | the files are named `tasks.toml`, which mise never auto-loads |

## Approaches

- **A. `<topic>/tasks.toml` included by glob** (chosen): names and behaviour unchanged, self-maintaining.
- B. Each topic as its own `mise.toml` project (monorepo mode): every name changes (`//config/zsh:verify`), tasks run
  from their folder, experimental. Breaks "keep the current behaviour".
- C. `.mise/tasks/<topic>.toml`: one folder, but nothing sits next to what it manages.

## Goals and non-goals

- Goals: every task where the rule says; `mise tasks ls --hidden` identical before and after; the gate green; a spec
  that fails if a task returns to the root `mise.toml`; the rule documented in `docs/CONTRIBUTING.md` and `AGENTS.md`.
- Non-goals: renaming tasks (the `setup:*` names no longer match their folders; a rename is a later, separate choice),
  moving file tasks, changing the subproject `mise.toml` files.
- Side effect: `zsh`, `theme`, `karabiner`, `age`, `sops` and `agents` are linked into `~/.config`, so each gains a
  `tasks.toml` there; none of those tools reads it.
