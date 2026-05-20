---
title: Mise task guidelines
description: When to use mise tasks vs bun run; no ad-hoc project scripts
---
<!-- markdownlint-disable-file -->

# Mise Task Preference Guidelines

Cursor rule (summary): load `mise-tasks` / `mise-expert` skills before editing
tasks; see **Skills for Task Work** below.

## Overview

This project uses Mise as the primary task runner for all complex workflows.
Always prefer `mise run <task>` over direct shell commands for complex tasks.

## Why Mise Tasks?

1. **Consistency** - same execution across all environments
2. **Documentation** - tasks are self-documenting
3. **Dependencies** - tasks can define complex workflows
4. **Environment Management** - Mise handles tool versions via `mise.toml` at the repo root
5. **Cross-platform** - works consistently across macOS and Linux

## Guidelines

### ❌ Avoid: Direct Shell Commands

```bash
# Avoid
bun build apps/kb/src/index.ts --compile --outfile dist/kb
bun test
biome check --write .
bun tsc --noEmit
```

### ✅ Prefer: Mise tasks

```bash
# Prefer
mise run -C assets test bin
mise run bdd lint
mise run integration bin xc-git --scenario help
```

### When Direct Commands Are Acceptable

Only use direct commands when:

1. No equivalent mise task exists
2. You need custom parameters not supported by existing tasks
3. You are debugging or exploring new functionality

### No Standalone Scripts

Do not add ad-hoc shell scripts to the repository. If automation is needed,
add a Mise task to `mise.toml` (tasks can run bash, Bun, etc. *But not ad-hoc scripts*!).

**Exception:** Scripts used exclusively by Cursor and living under `.cursor/` (e.g. hook scripts like `.cursor/hooks/dod-check.ts`) are allowed. The “no scripts” rule applies to **project** automation and tasks (e.g. build, test, release); Cursor-specific hooks are editor integration, not project tasks.

### Adding New Mise Tasks

If you need functionality not covered by existing tasks:

1. **Before editing:** load the `mise-tasks` skill (always) and `mise-expert`
   (when changing `[tools]`, `[env]`, or tool versions). Read
   [MISE_GUIDE.md](MISE_GUIDE.md) and the links in **REFERENCES** below.
2. Add the task under the existing `[tasks]` section using **inline task
   objects** (`"name" = { description = …, usage = …, run = … }`), matching
   root `mise.toml` — not separate `[tasks.name]` sections.
3. Include a `description` field and a `usage` field when the task takes args.
4. Follow naming conventions (`verb` or `noun:verb` style).
5. Define task dependencies with `depends` when needed.
6. **After editing:** run `mise run <task> --help`, `mise tasks validate
   <task>`, then a smoke run (e.g. `mise run -C assets test bin` from repo
   root).

### TOML layout (normative)

All tasks live under one `[tasks]` section as inline objects, like root
`mise.toml` and [kodexb `mise.toml`][kodexb-mise]:

```toml
[tasks]
"prepare" = { description = "Install dependencies and hooks", usage = '''
  flag "--ci" help="Install dependencies for CI"
''', run = '''
#!/usr/bin/env bash
set -euo pipefail
bun install $($usage_ci && echo '--frozen-lockfile')
$usage_ci || pre-commit install --hook-type commit-msg
''' }
```

Use quoted keys for names with `:` only when an existing root task already
uses that shape (e.g. Docker `setup:*`, `ci:*`). New verification tasks in
`assets/mise.toml` use merged names (`bdd`, `integration`, `test`) with
`usage` args — not `verify:bin` or `bdd:lint`.

### Task inputs: `usage` args and flags (required)

Parameterized tasks **must** declare inputs in a `usage` field. Do not use
per-task `env = { … }` blocks or undocumented shell exports for values that
operators pass on the command line (scenario filters, target selection, paths,
dry-run toggles, and similar).

The [mise task arguments](https://mise.jdx.dev/tasks/task-arguments.html)
guide is the reference. Inside task bodies, read `usage_*` variables (for
example `${usage_scenario?}`, `${usage_target?}`) or the Tera `usage` map in
templates.

```toml
[tasks]
"integration" = { description = "Run integration specs for a domain target", dir = "{{ config_root }}", usage = '''
  arg "<domain>" {
    help "Domain under integration/"
    choices "bin"
  }
  arg "<target>" {
    help "Spec stem or all"
    choices "all" "xc" "xc-git"
    default "all"
  }
  flag "--scenario <scenario>" {
    help "Run one scenario when the spec supports filtering"
  }
  flag "--bin-dir <path>" {
    help "Override config/bin root for subprocess tests"
  }
''', run = '''
#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd .. && pwd)"
export CONFIG_BIN="${usage_bin_dir:-$REPO_ROOT/config/bin}"
bun test "integration/${usage_domain?}/${usage_target?}.spec.ts"
''' }
```

**Discouraged — task parameters disguised as env:**

```toml
# Do not use env blocks to fake CLI parameters
"xc-git:specs" = { env = { XC_GIT = "{{ config_root }}/xc-git" }, usage = '''…''', run = "…" }
```

Prefer one merged task (`integration`) with `target` and `scenario` args. Let
specs resolve script paths from a shared helper; reserve `XC_*` names for
optional subprocess overrides inside tests, not mise configuration.

**Allowed `[env]` uses:** real environment policy (toolchain paths, `NODE_ENV`,
non-interactive CI flags) that is not a per-invocation task argument. Prefer
`[tools]` for runtime versions.

In bash task bodies, use `${usage_var?}` or `${usage_var:-default}` so
[shellcheck](https://www.shellcheck.net/) understands usage variables. See
[mise bash variable expansion](https://mise.jdx.dev/tasks/task-arguments.html#bash-variable-expansion).
Bun bodies read the same values from `process.env.usage_*` (see **Task body
style** below).

### Merging Similar Tasks

Near-duplicate tasks that share the same domain and implementation surface
should merge into one task with an `arg` for the action when merging improves
clarity without hiding meaningful safety distinctions. Prefer a single
`mise run <noun> <action>` over `mise run <noun>:<action1>`, `mise run
<noun>:<action2>` when the actions are low-risk administrative or query
operations.

Keep separate tasks when:

- the actions have significantly different safety profiles,
- one action is destructive and the other is read-only,
- the actions target different execution environments (local vs CI),
- separate tasks improve CI step readability and debugging.

### Task body style (normative)

Follow the same pattern as [kodexb `mise.toml`][kodexb-mise]: declare inputs in
`usage`, then implement the task.

| Shape          | When                                                              | Example                                               |
| -------------- | ----------------------------------------------------------------- | ----------------------------------------------------- |
| One-line `run` | Trivial delegation to another command or task                     | `run = "bun run lint"` or `run = "mise run test bin"` |
| Bash shebang   | Shelling out, `find`, env exports, branching on `usage_*`         | BDD Cucumber tasks, CI glue, packaging                |
| Bun shebang    | Shared TS helpers, structured spawn logic, or logic already in TS | Optional for integration orchestration                |

**Required for multi-line bodies:**

1. Start with `#!/usr/bin/env bash` or `#!/usr/bin/env bun` (not bare comments).
2. Bash: `set -euo pipefail` (or at least `set -e`).
3. Required args: `${usage_var?}` or `: "${usage_var:?message}"`.
4. Optional flags: `${usage_flag:-default}`; boolean flags: `$usage_ci && echo …`.
5. No placeholder stubs — task bodies must be runnable as written.

**Bash example** (inline `[tasks]` entry, same style as kodexb `prepare`):

```toml
[tasks]
"prepare" = { description = "Install dependencies and hooks", usage = '''
  flag "--ci" help="Install dependencies for CI"
''', run = '''
#!/usr/bin/env bash
set -euo pipefail
bun install $($usage_ci && echo '--frozen-lockfile')
$usage_ci || pre-commit install --hook-type commit-msg
''' }
```

**Bun example** (when TS is clearer than bash):

```toml
run = '''
#!/usr/bin/env bun
const action = process.env.usage_action
if (!action) throw new Error("usage_action is required")
// …
'''
```

Prefer **bash** for Dots verification tasks (Cucumber, `bun test`, path setup).
Use **Bun** only when the body reuses TS modules or needs non-trivial structured
logic. From repo root, invoke assets tasks with `mise run -C assets …` (root
`test` is reserved for Docker container structure tests).

[kodexb-mise]: https://github.com/roalcantara/kodexb/blob/feat-add-sync-ui/mise.toml

### Skills for Task Work (required workflow)

Whenever you **write or update** a mise task:

| Phase      | Action                                                                                                     |
| ---------- | ---------------------------------------------------------------------------------------------------------- |
| **Before** | Load the `mise-tasks` skill (always). Load `mise-expert` when editing `[tools]`, `[env]`, or version pins. |
| **During** | Follow this guide: inline `[tasks]` layout, `usage` args, bash/bun shebang bodies.                         |
| **After**  | `mise run <task> --help` → `mise tasks validate <task>` → smoke-run the task or its gate.                  |

If something fails, use the mise docs in **REFERENCES** (tasks, TOML tasks,
task arguments, architecture, CLI).

## Implementation Notes

- Project-wide tasks live in root `mise.toml` (Docker, setup, CI).
- Verification tasks live in `assets/mise.toml` (BDD, integration, aggregates).
- From repo root: `mise run -C assets test bin|all` (root `test` is Docker CST).
- Run `mise tasks` or `mise run --list` to see available tasks.
- Run `mise run <task> --help` to inspect `usage` args for merged tasks.
- Tasks handle environment setup and proper error output.

## REFERENCES

- [Mise documentation][0]
- [Tasks overview][5]
- [Task system architecture][6]
- [TOML-based tasks][7]
- [Task arguments (`usage`)][3]
- [Glossary][8]
- [Tips & tricks][9]
- [Mise architecture][10]
- [Mise CLI][11]
- [Usage specification][4]
- [Bun CLI][1]

[0]: https://mise.jdx.dev/ 'Mise — dependency management and task runner'
[1]: https://bun.com/docs 'Bun — runtime, package manager, bundler, test runner'
[3]: https://mise.jdx.dev/tasks/task-arguments.html 'Task arguments'
[4]: https://usage.jdx.dev/spec/ 'Usage specification reference'
[5]: https://mise.jdx.dev/tasks/ 'Tasks'
[6]: https://mise.jdx.dev/tasks/architecture.html 'Task system architecture'
[7]: https://mise.jdx.dev/tasks/toml-tasks.html 'TOML-based tasks'
[8]: https://mise.jdx.dev/glossary.html 'Glossary'
[9]: https://mise.jdx.dev/tips-and-tricks.html 'Tips & tricks'
[10]: https://mise.jdx.dev/architecture.html 'Mise architecture'
[11]: https://mise.jdx.dev/cli/ 'Mise CLI'
