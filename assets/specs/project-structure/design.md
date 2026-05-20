<!-- markdownlint-disable-file -->

# project structure design

Normative contract for the Dots `assets/` layout, verification toolchain, mise
tasks, and agent workflow. Implements
[requirements.md](requirements.md).

## Scope

This spec covers repository layout polish after the BDD pilot commit. It does
not change `config/bin` script behavior. It relocates documentation,
verification, and task entry points.

## Non-goals

- Rewriting `install`, Neovim Lua, or zsh beyond path reference updates.
- Replacing Bun or Cucumber with another runner in this pass.
- Merging unrelated legacy guides without Dots adaptation.
- Running implementation in the same agent session that authors this spec
  unless the user explicitly requests inline execution.

## Target directory tree

```text
assets/
├── README.md
├── package.json
├── bun.lock
├── biome.json
├── mise.toml
├── guides/
│   ├── README.md
│   ├── GLOSSARY.md
│   ├── BDD_GHERKIN_GUIDE.md
│   ├── MISE_GUIDE.md
│   ├── TESTING_GUIDE.md
│   ├── GIT_COMMITS_GUIDE.md
│   └── …
├── specs/
│   ├── README.md
│   ├── project-structure/
│   ├── bin/
│   └── xc-git/ …
├── features/
│   ├── README.md
│   ├── .gherkin-lintrc
│   ├── support/
│   ├── step_definitions/
│   │   └── bin/
│   └── bin/
│       └── *.feature
└── integration/
    └── bin/
        ├── *.spec.ts
        └── fixtures/

config/bin/                   # xc-* scripts only
config/nvim/specs/            # busted exception
mise.toml                     # project-wide + wrappers
```

### `assets/README.md`

The file SHALL explain the four sibling folders:

| Folder         | Role                                        |
| -------------- | ------------------------------------------- |
| `guides/`      | How we work — canonical best practices      |
| `specs/`       | What and why — SDD planning artifacts       |
| `features/`    | User-visible behavior — Gherkin living docs |
| `integration/` | Script verification — subprocess checks     |

The file SHALL state that verification dependencies live in `assets/mise.toml`
and/or `assets/package.json`, and that neither makes the dotfiles repo a Node
application.

## Migration map

| Source                                            | Destination                             |
| ------------------------------------------------- | --------------------------------------- |
| `assets/guides/*`                            | Merge into `assets/guides/`             |
| `assets/guides/*` (legacy)                        | Merge; dedupe; drop unrelated           |
| `assets/specs/bin/`                         | `assets/specs/bin/`                     |
| `assets/specs/xc-*`                           | `assets/specs/xc-*`                     |
| `assets/features/bin/*.feature`             | `assets/features/bin/`                  |
| `assets/features/bin/step_definitions/support/*`  | `assets/features/support/`              |
| `assets/features/bin/step_definitions/*.steps.ts` | `assets/features/step_definitions/bin/` |
| `config/bin/tests/*`                              | `assets/integration/bin/`               |
| `/package.json`                                   | `assets/package.json`                   |
| `/bun.lock`                                       | `assets/bun.lock`                       |
| Root `mise.toml` `docs:*` tasks                   | `assets/mise.toml` merged `bdd` task    |
| `config/bin/mise.toml` `xc:*:specs`               | `assets/mise.toml` `integration:bin:*`  |
| `.gherkin-lintrc` (root)                          | `assets/features/.gherkin-lintrc`       |

After migration, delete `assets/docs/` and remove empty legacy directories.

### Domain slug

The bounded context for `config/bin` scripts uses the slug **`bin`** (singular)
in `assets/features/bin/`, `assets/integration/bin/`, and `assets/specs/bin/`.
Tool-specific slugs such as `xc-git` remain under `assets/specs/` for focused
SDD workstreams.

## Verification dependencies

Dependencies MAY be declared in `assets/mise.toml`, `assets/package.json`, or
both. Choose the channel that fits each dependency:

| Channel                                 | Use for                                   | Examples                    |
| --------------------------------------- | ----------------------------------------- | --------------------------- |
| `assets/mise.toml` `[tools]`            | CLI runtimes and tools mise installs      | `bun`, `node`, `shellcheck` |
| `assets/package.json` `devDependencies` | npm registry packages for Cucumber and TS | `@cucumber/cucumber`, `tsx` |

Rules:

- Root `package.json` SHALL NOT exist.
- `assets/package.json` SHALL NOT contain a `scripts` property.
- Prefer mise for tools that mise already manages elsewhere in the repo.
- Prefer `devDependencies` for npm-only packages (Cucumber, Screenplay, tsx).
- BDD mise tasks SHALL run `bun install --frozen-lockfile` in `assets/` when
  npm packages are required.

Initial `assets/package.json`:

```json
{
  "name": "dots-verification",
  "private": true,
  "devDependencies": {
    "@cucumber/cucumber": "^10",
    "@cucumber/screenplay": "^5.3.0",
    "gherkin-lint": "^4.2.4",
    "tsx": "^4.22.3"
  }
}
```

Initial `assets/mise.toml` `[tools]`:

```toml
[tools]
bun = "latest"
node = "22"
shellcheck = "latest"
```

## Cucumber configuration

### Feature discovery

| Item                | Path                                       |
| ------------------- | ------------------------------------------ |
| Feature files       | `assets/features/bin/**/*.feature`         |
| Support             | `assets/features/support/**/*.ts`          |
| Step definitions    | `assets/features/step_definitions/**/*.ts` |
| Gherkin lint config | `assets/features/.gherkin-lintrc`          |

### Required command shape

All BDD mise tasks SHALL run from `assets/` (`dir = "{{ config_root }}"` in
`assets/mise.toml`) and use:

```bash
bun install --frozen-lockfile
bunx gherkin-lint $(find features/bin -name '*.feature' -type f | sort)
bunx cucumber-js $(find features/bin -name '*.feature' -type f | sort) \
  --require-module tsx/cjs \
  --require <support files> \
  --require <step definition files>
```

Dry-run tasks append `--dry-run` to the `cucumber-js` invocation.

### VS Code

`assets/.vscode/settings.json` or `config/vscode/settings.json` SHALL set:

```json
{
  "cucumber.features": ["assets/features/**/*.feature"],
  "cucumber.glue": ["assets/features/**/*.ts"]
}
```

## Integration tests

| Item         | Path                                                                    |
| ------------ | ----------------------------------------------------------------------- |
| Spec files   | `assets/integration/bin/*.spec.ts`                                      |
| Fixtures     | `assets/integration/bin/fixtures/**`                                    |
| Path helpers | `assets/integration/bin/support/paths.ts` (or equivalent shared module) |

### Path resolution

Integration specs SHALL default script and fixture paths through a shared helper
that resolves the repository root from the spec file location and points at
`config/bin/`. Do not require one mise task env block per script
(`XC_GIT`, `XC_FABRIC`, …).

Optional `XC_*` variables MAY remain **inside spec subprocess env** when a
scenario needs a non-default bin directory (for example fixture launcher bins).
They are test-harness overrides, not mise task configuration.

### Mise task parameters vs subprocess env

Task inputs (`domain`, `target`, `scenario`, optional fixture overrides) SHALL
use mise [`usage` args and flags](https://mise.jdx.dev/tasks/task-arguments.html)
and appear as `usage_*` variables in the task body. Specs MAY read
`Bun.env.usage_scenario` (and siblings) when filtering suites, as the current
`xc-git.spec.ts` pilot already does.

Do **not** recreate the legacy `config/bin/mise.toml` pattern:

```toml
# discouraged — parameters belong in usage, not per-task env
env = { XC_GIT = "{{ config_root }}/xc-git" }
```

Prefer computing `config/bin` paths in the shared helper or exporting a single
`DOTS_ROOT` / `CONFIG_BIN` from the task body when specs need an override flag
(for example `flag "--bin-dir <path>"` → `export CONFIG_BIN="${usage_bin_dir?}"`).

Normative `integration` task body shape:

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd .. && pwd)"
export CONFIG_BIN="${usage_bin_dir:-$REPO_ROOT/config/bin}"
export usage_scenario="${usage_scenario:-}"
# bun test integration/${usage_domain?}/${usage_target?}.spec.ts
```

Run command shape from repository root:

```bash
mise run integration bin xc-git --scenario help
```

## Mise tasks

`assets/mise.toml` tasks SHALL follow
[assets/guides/MISE_GUIDE.md](../../guides/MISE_GUIDE.md): parameterized
`usage` specs, merged similar tasks, and `description` on every user-facing
task. Prefer `mise run <noun> <action>` over many `noun:action1`, `noun:action2`
tasks when actions share the same safety profile and runner.

### Root `mise.toml`

Root tasks SHALL retain existing project-wide tasks (`build`, `start`, `test`
for container structure tests, `setup:*`, `ci:*`).

Root SHALL **not** add `verify`, `verify:bin`, or other colon-separated
verification aliases. Root `test` is already reserved for Docker container
structure tests.

From the repository root, run verification through `assets/mise.toml`:

```bash
mise run -C assets test bin   # bin gate: bdd run + integration all
mise run -C assets test all   # full verification scope
```

Inside `assets/`, the same commands omit `-C assets`:

```bash
cd assets && mise run test bin
```

Root SHALL NOT contain BDD, integration, or per-script spec tasks after
migration.

### `assets/mise.toml`

`[tools]` SHALL pin tools required by verification:

```toml
[tools]
bun = "latest"
node = "22"
shellcheck = "latest"
```

#### Task `bdd` (merged BDD actions)

One task replaces separate `bdd:lint`, `bdd:dry-run`, and `bdd:run` tasks.

| Invocation             | Purpose                              |
| ---------------------- | ------------------------------------ |
| `mise run bdd lint`    | gherkin-lint on `features/<domain>/` |
| `mise run bdd dry-run` | Cucumber binding check               |
| `mise run bdd run`     | Execute living documentation         |

`usage` SHALL define:

- `arg "<action>"` with choices `lint`, `dry-run`, `run`
- `flag "--domain <domain>"` default `bin`

Task bodies SHALL follow the [kodexb `mise.toml`][kodexb-mise] pattern: a
`usage` field, then either a one-line `run = "…"` for trivial delegation or a
multi-line body with `#!/usr/bin/env bash` (preferred for shelling out to
`bunx`, `find`, and Cucumber) or `#!/usr/bin/env bun` when TypeScript logic is
clearer. Use `set -euo pipefail` in bash bodies; validate required args with
`${usage_var?}` or `: "${usage_var:?message}"`. Do not leave placeholder
comments such as `# branch on ${usage_action?}` — bodies MUST be copy-paste
ready for Task 6.

[kodexb-mise]: https://github.com/roalcantara/kodexb/blob/feat-add-sync-ui/mise.toml

#### Task `integration` (merged integration targets)

One task replaces separate `integration:bin:xc`, `integration:bin:xc-git`, and
similar per-file tasks.

| Invocation                                        | Purpose                          |
| ------------------------------------------------- | -------------------------------- |
| `mise run integration bin all`                    | All specs in `integration/bin/`  |
| `mise run integration bin xc-git`                 | One spec file                    |
| `mise run integration bin xc-git --scenario help` | Filtered scenario when supported |

`usage` SHALL define:

- `arg "<domain>"` with choices starting with `bin`
- `arg "<target>"` with choices `all`, `xc`, `xc-git`, `xc-fabric`,
  `xc-skills`, `xc-usage`, `xc-puts`, `xc-toast`
- `flag "--scenario <scenario>"` optional

The task body SHALL map `<target>` to `integration/<domain>/<target>.spec.ts`
or all `*.spec.ts` when `target` is `all`. Pass `usage_domain`, `usage_target`,
and optional `usage_scenario` through to Bun; resolve `config/bin` paths in a
shared spec helper instead of per-task `env` blocks.

Normative task definitions use the **inline `[tasks]` layout** (same as root
`mise.toml` and [kodexb `mise.toml`][kodexb-mise]): one `[tasks]` section,
each task an inline object (`"name" = { description = …, usage = …, run = … }`).
Do **not** use separate `[tasks.name]` sections for new or migrated tasks.
Paths assume `dir = "{{ config_root }}"` in `assets/mise.toml`.

```toml
[tasks]
"bdd" = { description = "BDD living documentation: lint, dry-run, or run for a domain", dir = "{{ config_root }}", usage = '''
  arg "<action>" {
    help "BDD workflow step"
    choices "lint" "dry-run" "run"
  }
  flag "--domain <domain>" {
    help "Domain folder under features/"
    default "bin"
  }
''', run = '''
#!/usr/bin/env bash
set -euo pipefail
: "${usage_action:?action is required (lint | dry-run | run)}"
DOMAIN="${usage_domain:-bin}"
FEATURE_DIR="features/${DOMAIN}"
bun install --frozen-lockfile
mapfile -t FEATURES < <(find "$FEATURE_DIR" -name '*.feature' -type f | sort)
[[ ${#FEATURES[@]} -gt 0 ]] || { echo "ERROR: no .feature under $FEATURE_DIR" >&2; exit 1; }
case "$usage_action" in
  lint)
    bunx gherkin-lint "${FEATURES[@]}"
    ;;
  dry-run|run)
    REQUIRE_ARGS=()
    while IFS= read -r f; do REQUIRE_ARGS+=(--require "$f"); done \
      < <(find features/support -name '*.ts' -type f | sort)
    while IFS= read -r f; do REQUIRE_ARGS+=(--require "$f"); done \
      < <(find features/step_definitions -maxdepth 1 -name '*.steps.ts' -type f | sort)
    EXTRA=()
    [[ "$usage_action" == "dry-run" ]] && EXTRA+=(--dry-run)
    bunx cucumber-js "${FEATURES[@]}" \
      --require-module tsx/cjs \
      "${REQUIRE_ARGS[@]}" \
      "${EXTRA[@]}"
    ;;
  *)
    echo "ERROR: unknown action $usage_action" >&2; exit 1
    ;;
esac
''' }

"integration" = { description = "Integration specs for a domain target", dir = "{{ config_root }}", usage = '''
  arg "<domain>" {
    help "Domain under integration/"
    choices "bin"
  }
  arg "<target>" {
    help "Spec stem or all"
    choices "all" "xc" "xc-git" "xc-fabric" "xc-skills" "xc-usage" "xc-puts" "xc-toast"
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
: "${usage_domain:?domain is required}"
: "${usage_target:?target is required}"
REPO_ROOT="$(cd .. && pwd)"
export CONFIG_BIN="${usage_bin_dir:-$REPO_ROOT/config/bin}"
if [[ "${usage_target}" == "all" ]]; then
  bun test "integration/${usage_domain}/"
else
  bun test "integration/${usage_domain}/${usage_target}.spec.ts"
fi
''' }

"test" = { description = "Run BDD + integration for a scope", dir = "{{ config_root }}", usage = '''
  arg "<scope>" {
    help "Verification scope"
    choices "bin" "all"
  }
''', run = '''
#!/usr/bin/env bash
set -euo pipefail
case "${usage_scope?}" in
  bin)
    mise run bdd run --domain bin
    mise run integration bin all
    ;;
  all)
    mise run test bin
    ;;
  *)
    echo "ERROR: unknown scope ${usage_scope?}" >&2; exit 1
    ;;
esac
''' }
```

Agents editing tasks MUST follow [MISE_GUIDE.md](../../guides/MISE_GUIDE.md)
**Skills for Task Work** (load skills before editing; validate and run after).

#### Task `test` (merged aggregates)

| Invocation          | Purpose                                                 |
| ------------------- | ------------------------------------------------------- |
| `mise run test bin` | `bdd run --domain bin` then `integration bin all`       |
| `mise run test all` | Every domain aggregate (today equivalent to `test bin`) |

Implement with a `usage` arg `scope` (`bin`, `all`) or explicit `test:bin`
alias task that runs the two commands in sequence. Do not add separate public
tasks per integration spec file.

Hidden deprecated aliases (`xc:specs`, `xc-git:specs`, …) MAY point to
`integration bin <target>` for one release cycle, then be removed.

### `config/nvim/mise.toml`

No changes required. Busted tasks remain local to Neovim.

## Guides merge rules

### Guide roles and deduplication

Each guide owns **one concern**. Overlap is resolved by **moving or deleting**
duplicate sections during merge — not by cross-linking the same prose in
multiple files.

| File                   | Owns                                                                                                       | Does **not** own                                   |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| `BDD_GUIDE.md`         | Why/when BDD in Dots, three layers, folder roles, Screenplay overview                                      | Gherkin syntax, templates, mise commands           |
| `BDD_GHERKIN_GUIDE.md` | Gherkin checklist, templates, Rules, step vocabulary, feature paths                                        | BDD philosophy, Screenplay theory, gates           |
| `TESTING_GUIDE.md`     | Verification gates, mise commands, Bun integration-spec patterns, shellcheck, `zsh -n`, `git diff --check` | BDD philosophy, Gherkin style, Screenplay overview |

**Keep all three BDD-related guides.** They are not duplicates: `BDD_GUIDE` is
conceptual onboarding, `BDD_GHERKIN_GUIDE` is authoring reference,
`TESTING_GUIDE` is execution. Where pilot `assets/guides/TESTING_GUIDE.md`
copies Screenplay or layer content, **move** it into `BDD_GUIDE.md` and
**delete** it from `TESTING_GUIDE.md` — do not leave “see also” stubs for
content that belongs elsewhere.

**Delete outright:** `FISHERY_GUIDE.md` (unrelated to Dots). **`assets/guides/`**
after merge (superseded tree).

### Per-file content contracts (Task 2)

Agents SHALL produce each file from the outline below. Copy only from listed
sources; do not invent parallel sections.

#### `assets/guides/BDD_GUIDE.md` (new)

| Section                  | Content                                                                                                                                      |
| ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `# Dots BDD guide`       | One paragraph: living documentation for user-visible behavior.                                                                               |
| `## Verification layers` | Table: `assets/specs/` (SDD), `assets/features/` (Gherkin), `assets/integration/` (subprocess specs). One sentence per layer.                |
| `## Folder layout`       | Bullet list of canonical paths under `assets/` (from this design).                                                                           |
| `## Screenplay in Dots`  | Actors, tasks, interactions, questions — **moved from** pilot `assets/guides/TESTING_GUIDE.md` § Screenplay; no step examples.          |
| `## When to add what`    | Short decision list: new user-visible behavior → feature scenario; CLI contract / exit codes → integration spec; normative API → SDD design. |
| `## Related guides`      | One line each pointing to `BDD_GHERKIN_GUIDE.md` (writing features) and `TESTING_GUIDE.md` (running gates). No duplicated checklists.        |

**Sources:** pilot `TESTING_GUIDE.md` (Screenplay + layers only), `assets/specs/bin/design.md` scope paragraphs.

**Gate:** `rg -n "gherkin-lint|mise run|Given Alice" assets/guides/BDD_GUIDE.md` returns no matches.

#### `assets/guides/BDD_GHERKIN_GUIDE.md`

| Section       | Content                                                                                                                                                                                   |
| ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Full document | Copy from `assets/guides/BDD_GHERKIN_GUIDE.md` with path rewrites only: `assets/docs/features/` → `assets/features/`, `step_definitions` → `support` + `step_definitions` per this design. |
| Do not add    | Layer tables, Screenplay theory, mise command tables.                                                                                                                                     |

**Gate:** paths in examples use `assets/features/` only.

#### `assets/guides/TESTING_GUIDE.md`

| Section                 | Content                                                                                                                                                                                                                                                                             |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Keep                    | Legacy `assets/guides/TESTING_GUIDE.md` Bun/`describe`/`it`/table-driven/FCIS sections (update examples if paths change).                                                                                                                                                           |
| `## Verification gates` | Table from pilot `assets/guides/TESTING_GUIDE.md` § Gates with **updated** commands: `mise run bdd …`, `mise run integration …`, `mise run test bin`, `mise run test all` (from `assets/` or `mise run -C assets …` at repo root), `zsh -n`, `shellcheck`, `git diff --check`. |
| Remove                  | Pilot § Cucumber/Screenplay/BDD philosophy; pilot dependency install prose (keep a single line: “devDeps in `assets/package.json`; run via mise — see `MISE_GUIDE.md`”).                                                                                                            |
| Do not add              | Gherkin checklist or templates.                                                                                                                                                                                                                                                     |

**Gate:** `rg -n "Screenplay model|Writing checklist|Feature template" assets/guides/TESTING_GUIDE.md` returns no matches.

#### `assets/guides/MISE_GUIDE.md`

Merge pilot stub into canonical file (already updated in Task 1 draft). Ensure:
inline `[tasks]` examples, `bdd` / `integration` / `test` commands, skills
workflow, mise doc links. Remove KB/Biome/package-script preference.

#### `assets/guides/GLOSSARY.md`

Merge unique terms from `assets/guides/GLOSSARY.md` into legacy file; dedupe entries.

#### `assets/guides/GIT_GUIDE.md`

Add one reference to `GIT_COMMITS_GUIDE.md` for commit message rules (no duplicate commit tables).

#### `assets/guides/README.md` (new)

Markdown table: filename | one-line scope (from **Guide roles** table above).

### Task 2 execution order

1. `README.md` index (scopes from contracts above).
2. `BDD_GUIDE.md` (new — move Screenplay/layers from pilot TESTING).
3. `BDD_GHERKIN_GUIDE.md` (path rewrite only).
4. `TESTING_GUIDE.md` (keep legacy Bun body; replace gates; strip BDD/Gherkin).
5. `GLOSSARY.md`, `MISE_GUIDE.md`, `GIT_GUIDE.md` merges.
6. Delete `FISHERY_GUIDE.md` and `assets/guides/`.
7. Run gates listed in each contract plus `rg "assets/docs/guides" assets/guides`.

## Agent workflow

Document in root [`README.md`](../../../README.md) under **Documentation and
verification** and **Agent workflow**. Do not maintain a separate
`AGENT_WORKFLOW.md`; `assets/README.md` and `assets/specs/bin/SKILL.md` link
to the README section.

### Artifact placement

| Artifact     | Path                                          |
| ------------ | --------------------------------------------- |
| Requirements | `assets/specs/<feature-slug>/requirements.md` |
| Design       | `assets/specs/<feature-slug>/design.md`       |
| Tasks        | `assets/specs/<feature-slug>/tasks.md`        |
| Handoff      | `assets/specs/<feature-slug>/HANDOFF.md`      |

Forbidden paths: `.superpowers/`, `docs/superpowers/`. (add them to .gitignore)

### Planning phase

1. Load `using-superpowers` and `spec-driven-development` skills.
2. Read `assets/guides/` for conventions.
3. Place SDD files under `assets/specs/<feature-slug>/`.
4. Stop after artifact approval unless the user explicitly requests inline
   implementation.
5. Otherwise emit a handoff prompt for a separate implementation agent. The
   prompt MUST reference `assets/specs/<feature-slug>/HANDOFF.md` and follow
   the template below (adapt placeholders; do not omit the workflow or stop
   conditions).

#### Handoff prompt template

```markdown
You are taking over `assets/specs/<feature-slug>/tasks.md`.

Goal: <one paragraph — work to do and expected outcomes>

Read first:
- `assets/specs/<feature-slug>/HANDOFF.md`
- `assets/specs/<feature-slug>/requirements.md`
- `assets/specs/<feature-slug>/design.md`
- `assets/specs/<feature-slug>/tasks.md`
- `assets/guides/GLOSSARY.md`
- `assets/guides/CODESTYLE_GUIDE.md`
- `assets/guides/TESTING_GUIDE.md`
- `assets/guides/GIT_GUIDE.md`
- `assets/guides/GIT_COMMITS_GUIDE.md`
- `assets/guides/MISE_GUIDE.md`
- `assets/guides/DoD.md`
- `assets/guides/<relevant_guide>.md` (only if listed in HANDOFF.md)

Skills (load before coding):
- `subagent-driven-development` — execute task groups
- `test-driven-development` — focused tests per task item
- `<relevant_skill>` — <when to use>

Workflow:
1. Load `subagent-driven-development`.
2. For each pending `## Task N:` in `tasks.md`:
   1. Implement per `design.md` and applicable guides.
   2. Run focused tests until green for that task’s acceptance criteria.
   3. Run the task group gate from `tasks.md` and applicable `DoD.md` checks.
   4. Mark the task group complete in `tasks.md`.
   5. Create one conventional commit (`GIT_COMMITS_GUIDE.md`).
3. Repeat until all task groups are complete.
4. Report to the user:
   - One-line summary of work done
   - Commit subject(s) created
   - Task groups completed vs skipped (with reasons)
   - New tests added (count)
   - Verification commands run and expected exit code `0`
   - Issues encountered and fixes applied
   - Code smells or follow-ups worth noting

Stop and report (do not guess) when:
- A gate fails for reasons outside the current task group
- Requirements, design, or tasks are ambiguous
- A bulk change breaks imports, templates, or semantics
- A step takes unexpectedly long — include command, elapsed time, suspected cause, smallest next step
```

### Implementation phase

1. Read the given handoff prompt and follow its instructions.

### Task group definition

1. A task group is a `## Task N:` section in `tasks.md`.
2. Each group SHALL deliver a testable increment, for example:
   1. “guides merged and referenced”
   2. “features tree migrated and bdd gates green”
3. Each group SHALL provide a git commit suggestion.

## Error handling

| Failure                             | Response                                        |
| ----------------------------------- | ----------------------------------------------- |
| Gate fails during migration         | Fix before marking task group complete          |
| Broken cross-link after move        | Update in the same task group                   |
| Duplicate guide topic               | Merge into one file in `assets/guides/`         |
| Missing env var in integration spec | Update path helper in `assets/integration/bin/` |

## Verification gates (final)

From repository root after all task groups complete:

```bash
mise run -C assets test bin   # bin verification gate (bdd + integration)
mise run -C assets test all   # full verification gate
git diff --check              # trailing whitespace / conflict markers
```

Expected exit code for each command: `0`.

## References

- [Mise configuration hierarchy](https://mise.jdx.dev/configuration.html)
- [assets/guides/BDD_GUIDE.md](../../guides/BDD_GUIDE.md) (path after Task 2)
- [assets/guides/BDD_GHERKIN_GUIDE.md](../../guides/BDD_GHERKIN_GUIDE.md) (path after Task 2)
- [assets/specs/bin/design.md](../bin/design.md) (migrated bins pilot)
