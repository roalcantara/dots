# dots front door: one command, one place for values, one job per conf.d file

Status: approved (2026-11-26) · Branch: `feat/mise-bootstrap-tasks` · Follows:
[`2026-11-26-mise-bootstrap-tasks-design.md`](2026-11-26-mise-bootstrap-tasks-design.md)

## Intent

The bootstrap split made every step a file task, but the result is hard to use and still repeats itself:

- `mise tasks ls` lists 25+ `bootstrap:*` steps among every other task in every config; nothing groups them.
- Hooks hand over to `bootstrap:hook:<phase>`: names that say *when*, not *what*.
- The dots location (`~/.local/share/dots`) is written 57 times in `dotfiles.toml` and again in tasks and the
  hand-over; moving the checkout means editing many files.
- Steps learn the profile from an environment variable (`DOTS_PROFILE`), with no validation, help or completion.
- `conf.d` files mix jobs: `yabai.toml` holds macOS LaunchAgents and hooks; `backup.toml` and `setup.toml` each
  hold a few tasks.

The owner wants:

- **One front door:** `mise run dots …`, whose `--help` lists only what dots can do, with subcommands
  `setup`, `backup` and `profile`.
- **Names that say what:** `dots setup --brew --yabai`; a hook states what it sets up.
- **Flags over environment variables:** documented (`help`), validated (`choices`), completed in the shell.
- **One place for values:** hard-coded bootstrap values (above all the dots location) live in one file.
- **One job per `conf.d` file.**
- **Docs first:** every mechanism here is checked against the mise docs and tested on the installed mise before it
  is used (the owner's explicit rule after several avoidable detours).

## Goals

1. `mise run dots --help` lists `setup`, `backup`, `profile`; `mise run dots setup --help` lists one boolean flag per
   part, each with a one-line help, plus `--profile`.
2. `dots setup` with no part flags runs every part in the fixed order below; with flags, only those parts, still in
   that order.
3. Each part runs hidden step tasks, so per-step `skip_if`, `sources`, `raw`, `--force` and `--dry-run` keep working.
   `mise tasks ls` shows `dots` and no bootstrap step; `mise tasks ls --hidden` shows them all.
4. Hooks and the global `bootstrap` task call `dots setup` with the parts of their phase.
5. The profile reaches every step as a validated `--profile` flag, backed by `DOTS_PROFILE` (`env=`).
6. `dots backup <action>` replaces the six backup tasks, with documented `--include`, `--snapshot`, `--from-home`,
   `--target`, `--dry-run`, `--stdout`. `dots profile <desktop|dev>` replaces `mise run setup`.
7. The dots location lives in `conf.d/vars.yaml` (vars) and in `dotfiles.root` (the one setting that cannot read
   vars); a spec fails if they disagree. `dotfiles.toml` no longer spells the path per entry.
8. `conf.d` files: `bootstrap.toml` (machine setup: directories, files, packages, user, hooks, the `bootstrap` task,
   vars loading), `dotfiles.toml` (links), `macos.toml` (macOS preferences and LaunchAgents, yabai's included),
   `system.toml` (system packages), `tasks.toml` (the `dots` front door and nothing else). `yabai.toml`,
   `backup.toml`, `setup.toml` are gone.
9. Behaviour is unchanged: same steps, same order, same prompts, same links (`mise dot status` and
   `mise bootstrap plan` identical before and after), same warn-versus-fail semantics.

## Non-goals

- The `mise bootstrap` skill (still deferred).
- Changing what bootstrap installs, links or configures.
- Windows.
- A conf.d folder fragment (approach B, rejected below).

## Anti-goals

- A part that runs its steps inside one script (losing per-step `skip_if`, `raw`, failure names).
- A flag or choice list that drifts from the hidden tasks it names.
- Any `[env]` entry in global config that leaks dots values into every shell.
- A changed link target or a re-created link (`mise dot status` must not change).
- A step that silently reads a profile from somewhere other than its `--profile` flag.

## Facts this design rests on

Checked against the mise docs and tested on mise 2026.11.14 during brainstorming:

| Fact | Source |
|---|---|
| `usage` supports `cmd` blocks (subcommands), `global=#true` flags, boolean flags, `choices`, `var=#true`, `env="NAME"` backing, `help`/`long_help`; `--help` lists subcommands and flags; values fail validation before the script runs | tasks/task-arguments |
| `choices` carry no per-value help; one boolean flag per part does | tasks/task-arguments (completions) |
| Shared flags: a `.usage.kdl` `flagset`, loaded with `#USAGE include file=…` and `use "<name>"` | tasks/task-arguments (shared flags) |
| Task templates: `[task_templates.x]`, `extends`, vars per task, `usage` merged (template first); file tasks extend with `#MISE extends=` | tasks/templates |
| `hide = true` hides a task from `--help`, completions and `mise tasks ls`; `mise run` still runs it | tasks/task-configuration |
| `[vars] _.file = "<path>.yaml"` fills vars from a YAML file without exporting them; renders in hooks and tasks | configuration/vars; tested |
| A relative directive path in a single-file `conf.d` fragment resolves against `~` (the global root) and a miss is silent; `{{ mise_config_dir }}` gives the right folder | configuration, environments; tested |
| Settings render templates but cannot see `vars` (`env`, `xdg_*`, `mise_config_dir`, `system_brew_prefix` only) | tested (mise's own error) |
| `dotfiles.root = "{{ xdg_data_home }}/dots"` plus `[dotfile_groups.config]` (root `config`, target `~/.config`, `symlink-each`, `relative = true`, entries `{ mode = "symlink" }`) creates `~/.config/age -> ../.local/share/dots/config/age`, today's exact target | dotfiles/groups; tested |
| Dotfile `source` is not a template | tested |
| Hooks get neither `[env]` nor `MISE_ENV`; they render templates; `mise_env` holds the selected environments | tested; templates |
| Run steps take `{ task, args, env }` | tasks/task-configuration (`run`) |
| `config/.gitignore` ignores `*.env.*` | repo |

## Approaches

| | Approach | Trade-off | |
|---|---|---|---|
| A | `vars.yaml` (vars `_.file`) for hooks and tasks; `dotfiles.root` + one dotfile group for links | Location written twice (vars, setting), guarded by a spec; links unchanged | **Picked** |
| B | conf.d folder fragment `conf.d/dots -> ../..`; relative paths and `{{ config_root }}` | Location written once (the link); every link target changes form; `config/mise.toml` may also load as project config | Rejected |
| — | Front door shape: one task per part (`dots:brew`) vs one task with part flags dispatching to hidden tasks vs everything in one script | Per-part tasks clutter `tasks ls`; one script loses per-step mise features | Flags + hidden tasks **picked** |
| — | Part selection: positional `[parts]` vs repeatable `--part` vs one boolean flag per part | Only boolean flags give each part its own help line and described completion | Boolean flags **picked** |

## Design

### Values: `conf.d/vars.yaml`

```yaml
# Hard-coded values bootstrap needs, in one place. Read into {{ vars.* }} (not exported) by bootstrap.toml.
dots_dir: .local/share/dots        # the checkout, relative to $HOME
```

- `bootstrap.toml`: `[vars] _.file = "{{ mise_config_dir }}/conf.d/vars.yaml"`, then derived vars
  (`dots = "{{ env.HOME }}/{{ vars.dots_dir }}"`, the profile flags, the hand-over).
- Other values that are hard-coded today and read by more than one file move here too (the builder inventories them;
  a value used once stays where it is used).
- `config/mise/config.toml`: `dotfiles.root = "{{ xdg_data_home }}/dots"` and `dotfiles.relative_symlinks = true`.
  A spec asserts `{{ xdg_data_home }}/dots` equals `$HOME/` + `dots_dir` for the default XDG layout.
- `.env.sh` (untracked) is not used; the owner deletes it.

### Links: `dotfiles.toml` as a group

- `[dotfile_groups.config]`: `root = "config"`, `target = "~/.config"`, `mode = "symlink-each"`, `relative = true`,
  and one entry per linked top-level name, `"~/.config/<name>" = { mode = "symlink" }` (whole-folder links, as today).
- The walk must not link anything that is not linked today: everything else under `config/` is excluded (`exclude`),
  or the builder proves the group links only its entries.
- Entries whose target is not `~/.config/<same name>` (`~/.config/kb` from `kodexb`, `~/.local/bin` symlink-each,
  the two skill-lock files, `~/.agents/commands`, `~/.claude/commands`, `~/.ssh`, `~/.gnupg`, the VS Code and
  `claude-skills` variants) stay as plain `[dotfiles]` entries. If a group entry or `dotfiles.root` lets them drop
  the absolute path (verify in the docs, then test), use it; otherwise they keep it, and the spec in Goal 7 lists them.

### The front door: `conf.d/tasks.toml`

```toml
[tasks.dots]
description = "Set up this machine, back it up, choose its profile"
usage = '''
cmd "setup" help="Install and configure parts of this machine; no flags means all, in order" {
  flag "--brew"      help="Homebrew, its config link, and every Brewfile package for the profile"
  flag "--yabai"     help="yabai's scripting addition (sudoers rule, boot argument)"
  …                  # one flag per part, in run order
  flag "--profile <profile>" var=#true env="DOTS_PROFILE" help="…" { arg "<profile>" { choices "desktop" "dev" "container" } }
}
cmd "backup" help="Back up and restore this machine with restic" { … actions and their flags … }
cmd "profile" help="Choose this machine's profile and apply it" { arg "<profile>" { choices "desktop" "dev" } }
'''
```

- `setup` runs, for each selected part in the fixed order, `mise run -C {{ vars.dots }} dots:setup:<part>` with the
  profile flags. `backup` runs `script/backup.ts <action>` with the parsed flags (no `--`). `profile` runs
  `mise bootstrap -E <list> --save-env --yes` (desktop → `desktop`, dev → `desktop,dev`).
- Parts and order (each part = today's steps of that area, unchanged inside):

| Part flag | Hook | Steps (today's `bootstrap:<area>:<step>`) |
|---|---|---|
| `--brew` | post-packages | brew install, config-link, bundle |
| `--yabai` | post-packages | yabai scripting-addition |
| `--app-files` | pre-dotfiles | dotfiles move-aside |
| `--vscode` | post-dotfiles | vscode settings-sync |
| `--bat` | post-dotfiles | bat cache |
| `--lig` | post-dotfiles | lig zsh |
| `--macos` | post-defaults | macos activate |
| `--swiftbar` | post-defaults | macos swiftbar |
| `--git` | final | git filters, home-config, hooks |
| `--shell` | final | zsh warm-caches |
| `--dev` | final | dev python-tools |
| `--secrets` | final | gopass store, keyring, pass-link; ssh keychain |
| `--tiling` | final | tiling checks, borders build |
| `--ai` | final | omlx models |
| `--skills` | final | skills restore |
| `--nvim` | final | nvim providers, plugins |
| (always last) | final | brew remind |

  This order matches today's except one move: `zsh:warm-caches` now runs after `git:hooks` instead of between
  `git:home-config` and `git:hooks`. Neither reads the other's output (author's call). The order spec uses this table.
- Hooks: `run = "{{ vars.mise }} dots setup --brew --yabai"` (post-packages), `--app-files` (pre-dotfiles),
  `--vscode --bat --lig` (post-dotfiles), `--macos --swiftbar` (post-defaults); `[tasks.bootstrap]` runs the final
  parts. `vars.mise` renders the profile flags from `mise_env`, passing only names in `desktop`, `dev`, `container`.

### Hidden tasks and the profile flag (repo)

- `.mise/tasks/bootstrap/phases.toml` becomes the part tasks `dots:setup:<part>` (ordered run steps), all
  `hide = true`; the `bootstrap:hook:*` tasks go.
- `--profile` is repeatable (`--profile desktop --profile dev`) so `choices` can validate each name. The builder first
  tests that `env="DOTS_PROFILE"` with `var=#true` accepts `DOTS_PROFILE=desktop,dev`; if it does not, the flag becomes
  one `--profile <list>` value (comma list) and `has_profile` rejects names outside `desktop`, `dev`, `container`.
- Every step file task is `hide = true` and takes `--profile` from one shared definition (a `.usage.kdl` flagset or a
  task template; the builder picks one and uses it everywhere). `has_profile` reads `usage_profile`; `_lib.sh` stops
  reading `DOTS_PROFILE`, `MISE_ENV` and `miserc.local.toml` itself (the flag's `env="DOTS_PROFILE"` covers manual
  runs).

### File merges

- `yabai.toml` → `macos.toml` (its two LaunchAgents; its hooks are already gone).
- `backup.toml` + `setup.toml` → `tasks.toml` (as the `backup` and `profile` subcommands).
- Specs that read those files by name follow (`yabai.spec.ts`, `setup-task.spec.ts`), and every doc reference
  (AGENTS.md, README, BOOTSTRAP, MACOS, TILING, REINSTALL, GLOSSARY, `script/backup.ts` messages) moves to
  `mise run dots backup …` / `mise run dots profile …`.

## Verification

- `mise run dots --help`, `dots setup --help`, `dots backup --help` show the commands and per-flag help; a bad
  `--profile` or unknown flag fails before anything runs.
- `mise tasks ls` lists `dots` and no bootstrap step.
- `mise dot status` and `mise bootstrap plan` identical before and after (saved baselines, diffed).
- A spec: every part flag has a hidden `dots:setup:<part>` task and vice versa; every step belongs to one part.
- A spec: the run order equals the baseline order (captured from `mise run --dry-run bootstrap:hook:*` before).
- The hand-over spec runs the real `mise bootstrap` on a temp config for `-E container`, `-E desktop,dev`, miserc and
  no environment, asserting the `dots setup` call and its profile flags.
- `mise run test:specs`, `hk check --all`, `mise doctor project`, the distro builds and CST; owner runs
  `mise bootstrap` twice.

## Calls made by the author (owner to check)

- Part names and flags as in the table; `--app-files` for move-aside, `--ai` for oMLX models.
- `brew remind` always runs last and has no flag.
- `zsh:warm-caches` moves after `git:hooks` so parts stay whole.
- `vars.yaml` holds only values used in more than one place.
- Plain `[dotfiles]` entries outside `~/.config` may keep absolute paths if mise offers no root-relative form.

## Left to the builder

Flagset file vs task template for `--profile`; exact help texts; the dispatcher's loop; which values beyond
`dots_dir` join `vars.yaml` (per the rule above); whether the group needs an `exclude` list or only its entries.
