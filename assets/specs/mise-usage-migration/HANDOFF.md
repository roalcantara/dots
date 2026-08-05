<!-- markdownlint-disable-file -->

# HANDOFF: mise task usage migration (Dots)

> **Generic reusable version:** [HANDOFF-GENERIC.md](./HANDOFF-GENERIC.md) — use
> that file for any repository; this file is Dots-specific.

## Goal

Normalize all Dots `/Users/roalcantara/Work/dots/mise.toml` task definitions to the **recommended usage-field
pattern** documented in [mise task arguments](https://mise.jdx.dev/tasks/task-arguments.html#recommended-methods)
and [usage.jdx.dev](https://usage.jdx.dev/).

**Important nuance:** Root `mise.toml` tasks like `build` (lines 11–108) already
use a `usage` field and `${usage_*?}` in bash — that **is** the recommended
approach. The migration is **not** “add usage from scratch everywhere”; it is:

1. Replace **deprecated Tera** `{{arg()}}`, `{{flag()}}`, `{{option()}}` in run
   scripts (removal planned in mise 2026.11.0).
2. Optionally reformat inline `"task" = { ... }` objects into `[tasks."task"]`
   sections for readability (behavior must stay identical).
3. Fix incomplete tasks (e.g. `ci:publish:package` has `usage` but no `run`).
4. Align bash access patterns with [usage variable guidelines](https://mise.jdx.dev/tasks/task-arguments.html#bash-variable-expansion-for-usage-variables).

## Skills to load

- `mise-expert`, `mise-tasks` (before editing any `mise.toml`)
- `using-superpowers` + `spec-driven-development` if extending this spec
- Guide: [`assets/guides/MISE_GUIDE.md`](../../guides/MISE_GUIDE.md)

## Repository inventory

| File                                                                                      | Tasks                                                     | Current state                                                                 | Action                                                                                   |
| ----------------------------------------------------------------------------------------- | --------------------------------------------------------- | ----------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| [`mise.toml`](../../../mise.toml)                                                         | `build`, `start`, `test`, `setup:*`, `ci:publish:package` | `build`/`start`/`test` already usage + `${usage_*}`; setup tasks have no args | Normalize format; fix or remove `ci:publish:package`; keep setup tasks unless args added |
| [`assets/mise.toml`](../../../assets/mise.toml)                                           | `bdd`, `integration`, `test`, `skill`                     | Already usage + `${usage_*}`                                                  | Format pass + lint/help smoke only                                                       |
| [`config/nvim/mise.toml`](../../../config/nvim/mise.toml)                                 | `busted:build`, `tests`, `startuptime`, `setup`           | **`startuptime` and `setup` use deprecated Tera templates**                   | **Primary migration target**                                                             |
| [`config/bin/mise.toml`](../../../config/bin/mise.toml)                                   | `setup`                                                   | No arguments                                                                  | No usage needed; verify `mise run -C config/bin setup`                                   |
| [`config/raycast/scripts/node/mise.toml`](../../../config/raycast/scripts/node/mise.toml) | (none)                                                    | Tools only                                                                    | Skip                                                                                     |

## Target pattern (normative)

### Usage field (declarative args)

```toml
[tasks.build]
description = "Build a Docker image for dotfiles"
usage = '''
flag "--nocache" help="Disable build cache"
flag "--distro <distro>" {
  help "Distribution"
  choices "debian" "ubuntu"
  default "debian"
}
'''
run = '''
#!/usr/bin/env bash
set -euo pipefail
# Flags with defaults in usage spec:
TAG="dots:${usage_distro?}"
# Boolean flags without default in usage spec:
if [[ "${usage_nocache:-false}" == "true" ]]; then
  ...
fi
'''
```

Rules:

- Define **all** CLI args in `usage`, not in run via Tera `{{flag()}}` /
  `{{option()}}` / `{{arg()}}`.
- Read values as **`usage_<name>`** env vars (`--dry-run` → `usage_dry_run`).
- Use `${usage_var?}` when the usage spec sets `default=`; `${usage_var:-false}`
  for boolean flags without defaults; `${usage_var:?}` for required positional args.
- Prefer `set -euo pipefail` in new/edited bash bodies.
- Do **not** mix deprecated Tera arg functions and `usage` in the same task.

### Inline vs section format

Both are valid. Prefer **`[tasks.name]` sections** when touching a task (easier
diffs, matches mise docs). Quoted keys required for `:` names (`setup:hooks`).

## Migration examples

### A. `config/nvim/mise.toml` — `setup` (deprecated Tera → usage)

**Before (deprecated):**

```bash
if [ "{{flag(name="lazy")}}" = "true" ]; then
  CMD+=(+Lazy! sync)
fi
```

**After:**

```toml
usage = '''
flag "--lazy" help="Run Lazy sync"
flag "--treesitter" help="Run TSUpdateSync"
flag "--lsp" help="Install Mason LSP servers"
'''
run = '''
if [[ "${usage_lazy:-false}" == "true" ]]; then
  CMD+=(+Lazy! sync)
fi
'''
```

### B. `config/nvim/mise.toml` — `startuptime`

Migrate `{{option(name='logdir')}}` → `flag "--logdir <path>" default="./.tmp/logs"`
and `{{flag(name="log")}}` → `flag "--log"`.

### C. Root `mise.toml` — `ci:publish:package`

Currently broken: `usage` block with no `run`. Either:

- Implement `run` using `${usage_target?}` / `${usage_cmd?}` matching the `cmd`
  subcommand pattern used in `assets/mise.toml` `skill` task, or
- Delete the task and commented `# "xc"` block if obsolete.

Investigate git history / Makefile references before deleting.

## Acceptance criteria (layered — use all three)

### Layer 1: Static spec hygiene

For every task that has a `usage` field:

1. Extract the usage string to a temp file (e.g. `/tmp/task-build.usage.kdl`) or
   use mise’s built-in help generation.
2. Run [`usage lint`](https://usage.jdx.dev/cli/reference/lint) on the spec:

   ```bash
   usage lint /tmp/task-build.usage.kdl
   # optional stricter gate:
   usage lint -W /tmp/task-build.usage.kdl
   ```

   Install if missing: `mise use -g usage@latest` (or document in commit).

3. Grep guard — **zero** deprecated Tera arg functions in all `mise.toml`:

   ```bash
   rg '\{\{(arg|flag|option)\(' --glob '**/mise.toml'
   ```

**Why lint:** Catches invalid KDL, bad flag names, choices/default mismatches
*before* runtime. It does **not** execute bash.

### Layer 2: Help smoke (mise integration)

For every task with `usage`:

```bash
mise run <task> --help
# or from subproject:
mise run -C assets <task> --help
mise run -C config/nvim <task> --help
```

Help output must list expected flags/args with defaults and choices.

### Layer 3: Execution smoke (behavioral AC)

**Lint alone is not sufficient.** Each migrated task must run at least one
**safe** invocation proving the script still executes (exit 0 or expected
non-zero), not just `--help`.

Suggested matrix (adjust if environment lacks Docker/nvim):

| Task               | Safe smoke command                                                                                             | Notes                                             |
| ------------------ | -------------------------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| `build`            | `mise run build --help` then dry review; optional `mise run build --local --distro debian` if Docker available | Heavy; document if skipped                        |
| `start`            | `mise run start --help`                                                                                        | Do not require interactive `docker run -it` in CI |
| `test`             | `mise run test --help`; full CST only if image exists                                                          |                                                   |
| `setup:hooks`      | `mise run setup:hooks`                                                                                         | Idempotent                                        |
| `assets/bdd`       | `mise run -C assets bdd lint --domain bin`                                                                     | Fast                                              |
| `assets/skill`     | `mise run -C assets skill validate`                                                                            | Fast                                              |
| `assets/test bin`  | `mise run -C assets test bin`                                                                                  | Full verification gate                            |
| `nvim/setup`       | `mise run -C config/nvim setup --help`; `mise run -C config/nvim setup` only if nvim available headless        |                                                   |
| `nvim/startuptime` | `mise run -C config/nvim startuptime --help`                                                                   |                                                   |

Record in commit/PR which smokes ran vs were skipped (with reason).

## Execution order

1. **Inventory** — `mise tasks --all` from repo root and each config path.
2. **Migrate** `config/nvim/mise.toml` (only file with deprecated Tera today).
3. **Format pass** root + `assets/mise.toml` (optional, no behavior change).
4. **Fix** `ci:publish:package` or remove dead task.
5. **Run Layer 1–3** acceptance gates.
6. **Update** [`assets/guides/MISE_GUIDE.md`](../../guides/MISE_GUIDE.md) only if
   new conventions differ from current doc (minimal diff).
7. **One commit** per logical group (e.g. `ref(mise): Migrate nvim tasks to usage field`).

## Do not

- Reintroduce `{{arg()}}`, `{{flag()}}`, or `{{option()}}` in run scripts.
- Change task behavior, defaults, or flag names unless fixing an obvious bug
  (document in commit body).
- Move long scripts to file tasks unless a task exceeds ~120 lines and the move
  is agreed in commit message.
- Add `usage` to zero-arg tasks (`setup:hooks`, `config/bin/setup`) unless
  adding real flags.

## References

- [mise task arguments — usage field](https://mise.jdx.dev/tasks/task-arguments.html#usage-field)
- [Bash variable expansion for usage vars](https://mise.jdx.dev/tasks/task-arguments.html#bash-variable-expansion-for-usage-variables)
- [Deprecated Tera templates (migrate away)](https://mise.jdx.dev/tasks/task-arguments.html#deprecated-method)
- [usage lint CLI](https://usage.jdx.dev/cli/reference/lint)
- [assets/guides/MISE_GUIDE.md](../../guides/MISE_GUIDE.md)
- [assets/guides/DOCKER_GUIDE.md](../../guides/DOCKER_GUIDE.md) — documents root `build`/`test`

## Suggested commit messages

```gitcommit
ref(mise/nvim): Migrate tasks from Tera args to usage field

ref(mise): Normalize root and assets task table layout

fix(mise): Repair or remove ci:publish:package task
```

## Agent checklist before marking done

- [ ] `rg '\{\{(arg|flag|option)\(' --glob '**/mise.toml'` → 0 matches
- [ ] `usage lint` clean for every extracted usage spec (or `--help` equivalent)
- [ ] `mise run -C assets test bin` passes (if assets tasks touched)
- [ ] Documented smoke matrix results in PR or commit body
