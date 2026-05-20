<!-- markdownlint-disable-file -->

# TASKS: project structure

Execute task groups in order. Mark a group complete only when every gate is
green with zero errors and zero warnings. Create one conventional commit per
completed group.

Reference: [requirements.md](requirements.md), [design.md](design.md).

## Task 1: Spec and assets index

Deliverable: this SDD trio plus top-level indexes exist before file moves.

- [x] Create `assets/specs/project-structure/requirements.md`.
- [x] Create `assets/specs/project-structure/design.md`.
- [x] Create `assets/specs/project-structure/tasks.md`.
- [x] Create `assets/specs/README.md`.
- [x] Create `assets/README.md` describing `guides`, `specs`, `features`,
  `integration`.
- [x] Run `! rg -n "TO[D]O|TB[D]|pick one|either . or ." assets/specs/project-structure`.
- [x] Run `git diff --check`.
- [x] Commit Task 1 with message `docs(specs): Add project-structure SDD`.

**Gate:** Task 1 files exist and placeholder scan is clean.

## Task 2: Guides merge

Deliverable: single canonical guide tree at `assets/guides/`; per-file content
contracts in [design.md](design.md) § Per-file content contracts.

- [x] Create `assets/guides/README.md` (filename | scope table).
- [x] Create `assets/guides/BDD_GUIDE.md` per design contract (move Screenplay
  from pilot TESTING; no Gherkin or mise commands).
- [x] Create `assets/guides/BDD_GHERKIN_GUIDE.md` (path rewrites from pilot only).
- [x] Update `assets/guides/TESTING_GUIDE.md` (keep legacy Bun sections; add
  verification gates with `mise run test bin`; remove BDD/Gherkin/Screenplay).
- [x] Merge `assets/guides/GLOSSARY.md` into `assets/guides/GLOSSARY.md`.
- [x] Finalize `assets/guides/MISE_GUIDE.md` (pilot merge + inline `[tasks]`).
- [x] Update `assets/guides/GIT_GUIDE.md` → `GIT_COMMITS_GUIDE.md` reference.
- [x] Delete `assets/guides/FISHERY_GUIDE.md`.
- [x] Update `assets/guides/DoD.md` links to `assets/guides/`.
- [x] Delete `assets/guides/`.
- [x] Run design contract gates (`rg` checks per file in design.md).
- [x] Run `! rg -n "assets/docs/guides" assets/guides`.
- [x] Run `git diff --check`.
- [x] Commit Task 2 with message `docs(guides): Merge guides and add BDD_GUIDE`.

**Gate:** contract `rg` gates pass; `rg "assets/docs/guides" assets/guides`
returns no matches.

## Task 3: Specs relocation

Deliverable: all SDD artifacts under `assets/specs/`.

- [x] Move `assets/docs/specs/bins/` to `assets/specs/bin/`.
- [x] Move each `config/bin/specs/xc-*` directory to `assets/specs/xc-*`.
- [x] Update internal cross-links and paths in moved specs (features,
  guides, integration paths).
- [x] Update `assets/specs/bin/SKILL.md` for new paths and agent workflow.
- [x] Delete `config/bin/specs/` when empty.
- [x] Delete `assets/docs/specs/` when empty.
- [x] Run `! rg -n "assets/docs/specs|config/bin/specs" assets/specs`.
- [x] Run `git diff --check`.
- [x] Commit Task 3 with message `docs(specs): Consolidate SDD under assets/specs`.

**Gate:** no references to `assets/docs/specs` or `config/bin/specs` under
`assets/specs/`.

## Task 4: Features relocation

Deliverable: centralized BDD tree at `assets/features/`.

- [x] Create `assets/features/README.md`.
- [x] Move `assets/docs/features/bins/*.feature` to `assets/features/bin/`.
- [x] Move support files to `assets/features/support/`.
- [x] Move step files to `assets/features/step_definitions/bin/`.
- [x] Move `.gherkin-lintrc` to `assets/features/.gherkin-lintrc`.
- [x] Update imports in step definitions and support files.
- [x] Delete `assets/docs/features/` when empty.
- [x] Run `! rg -n "assets/docs/features|spec_steps" assets/features`.
- [x] Run `git diff --check`.
- [x] Commit Task 4 with message `test(features): Centralize BDD under assets/features`.

**Gate:** no `step_definitions` or `assets/docs/features` references under
`assets/features/`.

## Task 5: Integration relocation

Deliverable: subprocess specs at `assets/integration/bin/`.

- [x] Move `config/bin/tests/*.spec.ts` to `assets/integration/bin/`.
- [x] Move `config/bin/tests/fixtures/` to `assets/integration/bin/fixtures/`.
- [x] Add shared path helper under `assets/integration/bin/support/paths.ts`.
- [x] Update specs to default paths via helper; read `usage_scenario` from mise
  when filtering; keep `XC_*` only as optional subprocess overrides.
- [x] Delete `config/bin/tests/` when empty.
- [x] Run `! rg -n "config/bin/tests" assets/integration`.
- [x] Run `git diff --check`.
- [x] Commit Task 5 with message `test(integration): Move bin specs to assets/integration`.

**Gate:** `rg "config/bin/tests" assets/integration` returns no matches.

## Task 6: Toolchain and mise

Deliverable: verification toolchain scoped to `assets/`; mise tasks consolidated.

- [x] Move root `package.json` to `assets/package.json`.
- [x] Move root `bun.lock` to `assets/bun.lock`.
- [x] Run `cd assets && bun install` to refresh lockfile if needed.
- [x] Create `assets/mise.toml` with merged `bdd`, `integration`, and `test`
  tasks per design.md and `assets/guides/MISE_GUIDE.md` (inline `[tasks]`
  layout, bash shebang bodies, `usage` args, no placeholder comments).
- [x] Remove BDD and `xc:*:specs` tasks from root `mise.toml`.
- [x] Do not add root `verify*` wrappers (root `test` is Docker CST; use
  `mise run -C assets test bin` from repo root).
- [x] Remove or reduce `config/bin/mise.toml` to non-test tools only.
- [x] Update VS Code cucumber settings paths.
- [x] Run `mise run -C assets test bin` from repository root.
- [x] Run `git diff --check`.
- [x] Commit Task 6 with message `chore(assets): Scope verification toolchain to assets/`.

**Gate:** `mise run -C assets test bin` exits `0`; root has no `package.json`.

## Task 7: Repository sweep

Deliverable: no stale paths; `assets/docs/` removed; agent workflow in root README.

- [x] Update root `README.md` with `assets/` layout, verification commands, and
  agent workflow (extend the Task 1 draft if present).
- [x] Delete `assets/specs/project-structure/AGENT_WORKFLOW.md` if present.
- [x] Update `assets/README.md` to link root README agent section instead of
  AGENT_WORKFLOW.
- [x] Update `config/bin/README.md` test instructions.
- [x] Update `.cursor/rules` and project skills referencing old paths.
- [x] Run `! rg -n "assets/docs/|docs:bdd|docs:gherkin" . --glob '!*.lock'`.
- [x] Delete `assets/docs/` if empty.
- [x] Run `mise run -C assets test all`.
- [x] Run `git diff --check`.
- [x] Commit Task 7 with message `docs: Remove assets/docs transitional tree`.

**Gate:** `mise run -C assets test all` exits `0`; no `assets/docs/` directory.

## Task 8: Handoff for follow-up work

Deliverable: bins pilot Task 5+ can resume under new layout.

- [x] Update `assets/specs/bin/tasks.md` paths and gate commands.
- [x] Update `assets/specs/bin/HANDOFF.md` with `mise run -C assets test bin` gates.
- [x] Mark Task 8 items complete in this file.
- [x] Commit Task 8 with message `docs(bin): Align pilot tasks with new layout`.

**Gate:** `assets/specs/bin/tasks.md` lists only new paths and mise tasks.

## Execution rule

Planning agents stop after Task 1 approval and emit handoff. Implementation
agents use `subagent-driven-development` unless the user prompt requests
inline execution.

## Handoff prompt (implementation agent)

```markdown
Implement `assets/specs/project-structure/tasks.md` starting at Task 2.

Read first:
- assets/specs/project-structure/design.md
- assets/guides/GLOSSARY.md
- assets/guides/MISE_GUIDE.md

Rules:
- Complete one task group at a time; run all gates; one commit per group.
- Use subagent-driven-development for individual checklist items.
- Do not recreate root package.json.
- Stop and report if a gate fails after a fix attempt.
```
