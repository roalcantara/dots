<!-- markdownlint-disable-file -->

# HANDOFF (generic): mise task → usage-field migration

Reusable agent prompt for **any repository**. Copy this file (or paste its body)
into a new chat, fill in the **Project context** section, and execute.

For a concrete example applied to Dots, see
[HANDOFF.md](./HANDOFF.md).

---

## Project context (fill in before starting)

| Field                                 | Value                                              |
| ------------------------------------- | -------------------------------------------------- |
| **Repository root**                   | `<absolute-path>`                                  |
| **Primary mise config(s)**            | e.g. `mise.toml`, `assets/mise.toml`               |
| **Skills to load**                    | `mise-expert`, `mise-tasks`                        |
| **Project guide (optional)**          | e.g. `docs/MISE.md`, `CONTRIBUTING.md`             |
| **Full verification gate (optional)** | e.g. `mise run test`, `make check`                 |
| **Out of scope**                      | e.g. third-party vendored configs, generated files |

---

## Goal

Migrate every mise task in the repository to the **recommended usage-field
pattern**:

- [mise task arguments — usage field](https://mise.jdx.dev/tasks/task-arguments.html#usage-field)
- [usage spec reference](https://usage.jdx.dev/spec/)

### What “migration” means

Not every task needs a rewrite. Classify first:

| Class                       | Signal                                                        | Action                                       |
| --------------------------- | ------------------------------------------------------------- | -------------------------------------------- |
| **A — Already compliant**   | `usage = '''...'''` + `${usage_*}` in run                     | Format/lint/help smoke only                  |
| **B — Deprecated Tera**     | `{{arg()}}`, `{{flag()}}`, `{{option()}}` in run              | **Must migrate** (removed ~2026.11.0)        |
| **C — No arguments**        | Static run script, no CLI params                              | Leave as-is unless adding flags              |
| **D — Broken / incomplete** | `usage` without `run`, or `run` referencing missing `usage_*` | Fix or remove                                |
| **E — File tasks**          | `.mise/tasks/*` or `#MISE` headers                            | Migrate headers to `#USAGE` / `#MISE` syntax |

**Important nuance:** Tasks that already declare a `usage` field and read
`${usage_distro?}` etc. in bash **are already on the recommended path**. The main
work is eliminating deprecated Tera templates and fixing broken tasks.

---

## Phase 0 — Discovery (do not skip)

Run from repository root:

```bash
# All mise config files
fd -t f 'mise.toml' .

# All file-based tasks
fd -t f . .mise/tasks 2>/dev/null || true

# List every task (root)
mise tasks --all 2>/dev/null || mise tasks

# Deprecated Tera arg functions (must end at 0 after migration)
rg '\{\{(arg|flag|option)\(' --glob '**/mise.toml' --glob '**/.mise/**'

# Tasks with usage field
rg '^usage\s*=' --glob '**/mise.toml' -l

# Tasks with usage but possibly no run (broken)
rg -U 'usage\s*=.*?''' --glob '**/mise.toml' -l
```

For each directory that contains a `mise.toml`, also run:

```bash
mise tasks -C <dir>
```

Build an **inventory table** before editing:

| Config path            | Task name | Class (A–E) | Has `usage` | Has deprecated Tera | Notes                |
| ---------------------- | --------- | ----------- | ----------- | ------------------- | -------------------- |
| `mise.toml`            | `build`   | A           | yes         | no                  | optional format pass |
| `config/foo/mise.toml` | `deploy`  | B           | no          | yes                 | primary target       |
| …                      | …         | …           | …           | …                   | …                    |

---

## Target pattern (normative)

### TOML task with usage field

```toml
[tasks."deploy"]
description = "Deploy application"
usage = '''
arg "<environment>" {
  help "Target environment"
  choices "dev" "staging" "prod"
}
flag "-v --verbose" help="Enable verbose output"
flag "--region <region>" help="Cloud region" default="us-east-1"
flag "--dry-run" help="Preview without executing"
flag "--build-arg <arg>" {
  help "Extra docker --build-arg (repeat flag)"
  var #true
}
'''
run = '''
#!/usr/bin/env bash
set -euo pipefail

ENV="${usage_environment?}"
REGION="${usage_region?}"

[[ "${usage_verbose:-false}" == "true" ]] && set -x
[[ "${usage_dry_run:-false}" == "true" ]] && echo "DRY RUN"

# Variadic flags — shell-escaped string → bash array
if [[ -n "${usage_build_arg:-}" ]]; then
  eval "EXTRA_BUILD_ARGS=(${usage_build_arg})"
  for arg in "${EXTRA_BUILD_ARGS[@]}"; do
    echo "build-arg: $arg"
  done
fi

./deploy.sh "$ENV" --region "$REGION"
'''
```

### File task with usage headers

```bash
#!/usr/bin/env bash
#MISE description="Deploy application"
#USAGE arg "<environment>" {
#USAGE   choices "dev" "staging" "prod"
#USAGE }
#USAGE flag "--dry-run" help="Preview without executing"

set -euo pipefail
ENV="${usage_environment?}"
# ...
```

Use `#MISE` (recommended) or `#USAGE` for header lines.

### Bash variable access rules

| Usage spec               | Bash access                   | When                   |
| ------------------------ | ----------------------------- | ---------------------- |
| `default="debian"`       | `${usage_distro?}`            | Usage guarantees value |
| Boolean flag, no default | `${usage_nocache:-false}`     | Treat unset as false   |
| Required positional      | `${usage_target:?}`           | Must be non-empty      |
| Optional pass-through    | `${usage_verbose:+--verbose}` | Only add flag when set |
| Variadic (`var #true`)   | `eval "arr=(${usage_files})"` | Spaces in values       |

Reference:
[Bash variable expansion for usage vars](https://mise.jdx.dev/tasks/task-arguments.html#bash-variable-expansion-for-usage-variables)

### Format conventions

| Style                                         | Valid?           | When to use                 |
| --------------------------------------------- | ---------------- | --------------------------- |
| Inline `"task" = { description, usage, run }` | yes              | Existing; optional refactor |
| Section `[tasks."task"]`                      | yes              | Prefer when touching a task |
| Quoted keys                                   | required for `:` | `[tasks."ci:publish"]`      |

**Do not** mix deprecated Tera `{{arg()}}` / `{{flag()}}` / `{{option()}}` with
`usage` in the same task.

---

## Migration cookbook

### 1. Boolean flag (Tera → usage)

**Before (deprecated):**

```bash
if [ "{{flag(name="verbose")}}" = "true" ]; then
  set -x
fi
```

**After:**

```toml
usage = 'flag "-v --verbose" help="Enable verbose output"'
```

```bash
if [[ "${usage_verbose:-false}" == "true" ]]; then
  set -x
fi
```

### 2. Option with default (Tera → usage)

**Before:**

```bash
LOGDIR="{{option(name='logdir', default='./logs')}}"
```

**After:**

```toml
usage = 'flag "--logdir <path>" help="Log directory" default="./logs"'
```

```bash
LOGDIR="${usage_logdir?}"
```

### 3. Positional argument (Tera → usage)

**Before:**

```bash
cargo test {{arg(name="file", default="all")}}
```

**After:**

```toml
usage = 'arg "<file>" help="Test file" default="all"'
```

```bash
cargo test "${usage_file?}"
```

### 4. Choices / enum (Tera → usage)

**Before:**

```bash
deploy {{option(name="env", choices=["dev", "prod"])}}
```

**After:**

```toml
usage = '''
flag "--env <env>" {
  help "Environment"
  choices "dev" "prod"
}
'''
```

```bash
deploy --env "${usage_env?}"
```

### 5. Variadic arguments

**Before:**

```bash
eslint {{arg(name="files", var=true)}}
```

**After:**

```toml
usage = 'arg "<files>" var=#true help="Files to lint"'
```

```bash
eval "files=(${usage_files?})"
eslint "${files[@]}"
```

### 6. Already has `usage` — normalize only

If the task already uses `usage` + `${usage_*}`, limit changes to:

- `set -euo pipefail` if missing
- Consistent `${usage_var?}` vs `${usage_var:-false}` per guidelines
- Optional inline → section reformat (no behavior change)

### 7. Zero-arg tasks

Tasks like `setup`, `install-hooks` with no CLI parameters **do not need** a
`usage` block. Verify with `mise run <task>` only.

---

## Tera → usage name mapping

| Deprecated Tera                             | usage equivalent                           | Env var in bash |
| ------------------------------------------- | ------------------------------------------ | --------------- |
| `{{flag(name="dry-run")}}`                  | `flag "--dry-run"`                         | `usage_dry_run` |
| `{{flag(name="verbose")}}`                  | `flag "-v --verbose"`                      | `usage_verbose` |
| `{{option(name="profile", default="dev")}}` | `flag "--profile <profile>" default="dev"` | `usage_profile` |
| `{{arg(name="target")}}`                    | `arg "<target>"`                           | `usage_target`  |
| `{{arg(name="files", var=true)}}`           | `arg "<files>" var=#true`                  | `usage_files`   |

Hyphens in flag names become underscores in env vars: `--build-arg` →
`usage_build_arg`.

---

## Acceptance criteria (three layers — use all)

### Layer 1 — Static spec hygiene

For **every task with a `usage` field**:

1. **Extract** the usage block to a temp KDL file:

   ```bash
   # Example helper — adapt task name and path
   awk '/^usage = /,/^'\'''\''/ { print }' mise.toml > /tmp/task-deploy.usage.kdl
   ```

   Or copy the inner content between `usage = '''` and closing `'''`.

2. **Lint** with [usage lint](https://usage.jdx.dev/cli/reference/lint):

   ```bash
   usage lint /tmp/task-deploy.usage.kdl
   usage lint -W /tmp/task-deploy.usage.kdl   # stricter: warnings as errors
   ```

   Install: `mise use -g usage@latest` or `cargo install usage-cli`.

3. **Grep guard** — zero deprecated Tera across the repo:

   ```bash
   rg '\{\{(arg|flag|option)\(' --glob '**/mise.toml' --glob '**/.mise/**'
   ```

Lint catches invalid KDL and spec mistakes; it does **not** run bash.

### Layer 2 — Help smoke (mise integration)

For every task with `usage`:

```bash
mise run <task> --help
# subdirectory config:
mise run -C <dir> <task> --help
```

Verify: description, positional args, flags, defaults, and choices appear
correctly.

### Layer 3 — Execution smoke (behavioral)

**Lint + `--help` are necessary but not sufficient.** Each migrated task needs at
least one **safe** invocation that executes the script body.

Build a **smoke matrix** during Phase 0:

| Task     | Class | Safe smoke command               | Skip if                |
| -------- | ----- | -------------------------------- | ---------------------- |
| `<name>` | B→A   | `mise run <name> --help`         | —                      |
| `<name>` | B→A   | `mise run <name> [minimal args]` | needs Docker/GPU/creds |
| `<name>` | C     | `mise run <name>`                | destructive            |

Guidelines:

- Prefer **read-only / idempotent** commands (`lint`, `validate`, `--dry-run`).
- Use **`--help`** for interactive or heavy tasks (document why).
- Record in PR/commit: ran vs skipped (with reason).
- Run the project’s **full verification gate** once at the end if one exists.

---

## Execution order

1. Fill in **Project context** at the top.
2. **Phase 0 discovery** — inventory table, classify A–E.
3. **Migrate Class B first** (deprecated Tera) — highest priority.
4. **Fix Class D** (broken tasks).
5. **Class A** — format/lint/help only; avoid behavior churn.
6. **Skip Class C** unless adding real flags.
7. **Run Layers 1–3** acceptance gates.
8. **Update project docs** only if conventions changed (minimal diff).
9. **Commit** in logical groups (one area or one config file per commit).

Suggested commit message pattern:

```gitcommit
ref(mise): Migrate <area> tasks from Tera args to usage field

Replace deprecated {{flag()}}/{{option()}} templates with usage fields
and usage_* env vars. Smoke: <list commands run>.
```

---

## Do not

- Reintroduce `{{arg()}}`, `{{flag()}}`, or `{{option()}}` in run scripts.
- Change flag names, defaults, or behavior unless fixing an obvious bug (document
  in commit).
- Add empty `usage` blocks to zero-arg tasks.
- Mix Tera arg functions and `usage` in the same task.
- Refactor unrelated tasks in the same commit as a migration fix.

---

## Agent prompt (copy-paste)

Use this block to start a session:

```text
Execute the generic mise usage migration handoff.

Repository: <absolute-path>
Config(s): <list mise.toml paths or "discover all">

1. Read HANDOFF-GENERIC.md (or pasted content) in full.
2. Load mise-expert and mise-tasks skills.
3. Phase 0: discover all mise.toml and file tasks; build inventory table (classes A–E).
4. Migrate Class B (deprecated Tera) and fix Class D (broken tasks).
5. Run acceptance layers 1–3 (usage lint, --help, safe execution smoke).
6. Grep guard must be zero: rg '\{\{(arg|flag|option)\(' --glob '**/mise.toml'
7. Report inventory, changes per file, smoke matrix results, and suggested commits.

Do not change behavior or flag names unless fixing a bug. One logical commit per area.
```

---

## References

- [mise task arguments](https://mise.jdx.dev/tasks/task-arguments.html)
- [Usage field (preferred method)](https://mise.jdx.dev/tasks/task-arguments.html#usage-field)
- [File task headers](https://mise.jdx.dev/tasks/task-arguments.html#file-task-headers)
- [Deprecated Tera templates](https://mise.jdx.dev/tasks/task-arguments.html#deprecated-method)
- [Bash variable expansion](https://mise.jdx.dev/tasks/task-arguments.html#bash-variable-expansion-for-usage-variables)
- [usage lint](https://usage.jdx.dev/cli/reference/lint)
- [usage spec](https://usage.jdx.dev/spec/)

---

## Agent checklist before marking done

- [ ] Project context filled in
- [ ] Inventory table complete (all `mise.toml` + file tasks)
- [ ] `rg '\{\{(arg|flag|option)\(' --glob '**/mise.toml' --glob '**/.mise/**'` → 0 matches
- [ ] `usage lint` clean for every task `usage` block
- [ ] `mise run <task> --help` verified for every task with `usage`
- [ ] Smoke matrix executed or skips documented
- [ ] Full project verification gate run (if defined)
- [ ] Suggested commit messages provided
