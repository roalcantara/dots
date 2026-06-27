---
title: Mise task guidelines
description: Task runner layout, usage args, and verification gates for Dots
---
<!-- markdownlint-disable-file -->

# Mise Guide

Cursor rule (summary): load **mise-tasks** / **mise-expert** skills before editing
tasks; see **Skills for task work** below.

## Quick start

```bash
# Docker build and container tests (root mise.toml)
mise run build
mise run test

# Shell verification (assets/mise.toml — use -C assets from repo root)
mise run -C assets test bin
mise run -C assets bdd lint --domain bin
mise run -C assets integration bin xc-git
mise run -C assets skill validate
```

List tasks: `mise tasks` or `mise run --help`. Inspect args: `mise run <task> --help`.

## Root vs assets split

Dots uses two mise configs:

| File | Scope | Examples |
| --- | --- | --- |
| [`mise.toml`](../../mise.toml) (repo root) | Toolchain pins, Docker, setup, CI | `build`, `start`, `test`, `setup:*`, `ci:*` |
| [`assets/mise.toml`](../mise.toml) | BDD, integration specs, skill registry | `bdd`, `integration`, `test`, `skill` |

**Important:** root `test` runs Container Structure Tests against Docker images.
Assets `test` runs BDD + integration for shell helpers. Always pass `-C assets` when
invoking verification tasks from the repo root.

Root `[tools]` pins lint and hook tooling (`shellcheck`, `hadolint`, `hk`, …).
Assets `[tools]` pins `bun` and `node` for Cucumber and integration specs.

## Why mise tasks?

1. **Consistency** — same execution across macOS and Linux
2. **Documentation** — `description` and `usage` blocks are self-describing
3. **Dependencies** — `depends` chains setup before dependent work
4. **Tool versions** — `[tools]` ensures the right Bun, ShellCheck, etc.
5. **No ad-hoc scripts** — automation belongs in `[tasks]`, not loose shell files

**Exception:** Cursor hook scripts under `.cursor/` are editor integration, not
project tasks.

## Dots tasks reference

### Root (`mise.toml`)

| Task | Purpose |
| --- | --- |
| `build` | Build a Docker image for dotfiles (`--distro`, `--platform`, `--local`, …) |
| `start` | Start a dev container |
| `test` | Container Structure Tests for built images |
| `setup:age` | Retrieve AGE keys (Bitwarden on macOS) |
| `setup:git:filters` | Configure SOPS git filters |
| `setup:hooks` | Install hk git hooks |

### Assets (`assets/mise.toml`)

| Task | Purpose |
| --- | --- |
| `bdd <action>` | Gherkin lint, dry-run, or run (`--domain`, default `bin`) |
| `integration <domain> [target]` | Bun subprocess specs (`--scenario`, `--bin-dir`) |
| `test <scope>` | Aggregate gate: `bin` → bdd + integration; `all` → full assets scope |
| `skill <cmd>` | Skill registry: `validate`, `sync`, `install`, `all`, `report` |

Examples:

```bash
mise run -C assets bdd lint --domain bin
mise run -C assets bdd run --domain bin
mise run -C assets integration bin all
mise run -C assets integration bin xc-git --scenario help
mise run -C assets test bin
mise run -C assets skill sync --dry-run
```

## Task inputs: `usage` and `${usage_*?}`

Parameterized tasks **must** declare CLI inputs in a `usage` field (KDL inside
TOML). Do not hide operator-facing flags in undocumented `env` blocks.

References:

- [Usage specification](https://usage.jdx.dev/)
- [Mise task arguments](https://mise.jdx.dev/tasks/task-arguments.html)

Inside bash task bodies, read values as `${usage_var?}` (required) or
`${usage_var:-default}` (optional). Boolean flags appear as `$usage_flag` (test with
`[[ "${usage_flag:-false}" = "true" ]]`).

```toml
[tasks]
"integration" = { description = "Integration specs for a domain target", usage = '''
arg "<domain>" help="Domain under integration/"
arg "<target>" help="Spec stem or all" default="all"
flag "--scenario <scenario>" help="Run one scenario when the spec supports filtering"
flag "--bin-dir <path>" help="Override config/bin root for subprocess tests"
''', run = '''
#!/usr/bin/env bash
set -euo pipefail
: "${usage_domain:?domain is required}"
: "${usage_target:?target is required}"
REPO_ROOT="$(cd .. && pwd)"
export CONFIG_BIN="${usage_bin_dir:-$REPO_ROOT/config/bin}"
export PATH="${CONFIG_BIN}:$PATH"
if [[ "${usage_target}" == "all" ]]; then
  bun test "integration/${usage_domain}/"
else
  bun test "integration/${usage_domain}/${usage_target}.spec.ts"
fi
''' }
```

In Bun shebang bodies, the same values appear as `process.env.usage_*`.

Use `${usage_var?}` so [ShellCheck](https://www.shellcheck.net/) understands usage
variables. See [bash variable expansion](https://mise.jdx.dev/tasks/task-arguments.html#bash-variable-expansion).

**Allowed `[env]` uses:** real environment policy (toolchain paths, CI flags) — not
per-invocation task arguments. Prefer `[tools]` for runtime versions.

## TOML layout

All tasks live under one `[tasks]` section as **inline objects**:

```toml
[tasks]
"build" = { description = "…", usage = '''…''', run = '''…''' }
"setup:hooks" = { description = "…", run = '''…''' }
```

Use quoted keys. Colon names (`setup:age`) are reserved for root infrastructure
tasks. Assets verification uses merged names (`bdd`, `integration`, `test`,
`skill`) with `usage` args — not `verify:bin` or `bdd:lint`.

### Task body style

| Shape | When | Example |
| --- | --- | --- |
| One-line `run` | Trivial delegation | `run = "bun run scripts/skill-registry.ts"` |
| Bash shebang | Shelling out, env exports, `usage_*` branching | `bdd`, `integration`, `build` |
| Bun shebang | Structured TS logic already in repo | Optional for complex orchestration |

**Required for multi-line bash bodies:**

1. Start with `#!/usr/bin/env bash` (not bare comments)
2. `set -euo pipefail` (or at least `set -e`)
3. Required args: `${usage_var?}` or `: "${usage_var:?message}"`
4. No placeholder stubs — bodies must be runnable as written

## File tasks vs TOML tasks

Mise supports two task shapes:

| Style | Definition | Dots usage |
| --- | --- | --- |
| **TOML tasks** | Inline `run = '''…'''` or one-line `run = "…"` in `mise.toml` | Primary — all Dots tasks today |
| **File tasks** | Executable scripts under `mise-tasks/` or paths referenced by `file =` | Not used in this repo |

Prefer TOML tasks for Dots so `usage`, `description`, and `depends` stay next to
the implementation. File tasks are appropriate when a script is long-lived and
shared outside mise; if you add one, document it here.

Docs: [TOML-based tasks](https://mise.jdx.dev/tasks/toml-tasks.html),
[file tasks](https://mise.jdx.dev/tasks/file-tasks.html).

## Completions (`_mise`)

Mise completions come from the [Usage](https://usage.jdx.dev/) spec embedded in
task definitions. Generated completion lives at
[`config/zsh/opt/completions/_mise`](../../config/zsh/opt/completions/_mise).

After changing `usage` blocks, regenerate completions if your workflow requires it
(`usage generate completion` for the mise CLI — see mise docs). Completions expose
task names, flags, and `choices` from `usage` without hand-maintaining `_arguments`
stanzas per task.

## Adding or changing tasks

1. **Before editing:** load **mise-tasks** (always). Load **mise-expert** when
   changing `[tools]`, `[env]`, or version pins.
2. Add the task under the correct `mise.toml` using inline `[tasks]` objects.
3. Include `description` and `usage` when the task takes args.
4. Use `depends` when a task requires setup first.
5. **After editing:**
   - `mise run <task> --help`
   - `mise tasks validate <task>` (when available)
   - Smoke-run the task (e.g. `mise run -C assets test bin`)

### When direct commands are acceptable

Use bare `bun test`, `docker build`, etc. only when:

1. No equivalent mise task exists yet
2. You need one-off debugging with custom parameters
3. You are exploring before promoting a workflow to a task

## Skills for task work

| Phase | Action |
| --- | --- |
| **Before** | Load **mise-tasks**. Load **mise-expert** for `[tools]` / `[env]`. |
| **During** | Inline `[tasks]` layout, `usage` args, bash shebang bodies. |
| **After** | `--help` → validate → smoke-run the gate affected by your change. |

## References

- [Mise documentation](https://mise.jdx.dev/)
- [Tasks overview](https://mise.jdx.dev/tasks/)
- [Task system architecture](https://mise.jdx.dev/tasks/architecture.html)
- [TOML-based tasks](https://mise.jdx.dev/tasks/toml-tasks.html)
- [Task arguments (`usage`)](https://mise.jdx.dev/tasks/task-arguments.html)
- [Usage specification](https://usage.jdx.dev/spec/)
- [Mise CLI](https://mise.jdx.dev/cli/)
- [Bun CLI](https://bun.com/docs)
