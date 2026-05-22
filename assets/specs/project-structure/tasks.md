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

## Task 9: Document bin ↔ Zsh architecture

Deliverable: READMEs and guides state the helper model; no `xc-gen` mention anywhere.

- [x] Update `config/bin/README.md` § xc-usage: target-first API; bin `-h` pattern;
  document `xc-md` (glow → bat → plain) and `--md` composition; note scoped flags
  for dispatchers only; remove guard/print/validate from the public subcommand table.
- [x] Update `config/zsh/README.md`: Zsh-only vs migrated; `gen` stays on fpath;
  `show_usage` → `xc-usage <target>`; example replacing inline `echo` help.
- [x] Add a short § to `assets/guides/BDD_GUIDE.md` or `assets/guides/GLOSSARY.md`
  (one paragraph + table) pointing to this design § `config/bin` and Zsh functions.
- [x] Run `! rg -n "xc-gen|xc-usage guard|xc-usage print" assets/specs/project-structure config/bin/README.md config/zsh/README.md`.
- [x] Run `git diff --check`.
- [x] Commit Task 9 with message `docs: Document bin helpers and xc-usage model`.

**Gate:** architecture docs match Requirements 10–12; no `xc-gen` references.

## Task 10: Simplify `xc-usage` and add `xc-md`

Deliverable: target-first `xc-usage`; new `config/bin/xc-md`; aligned
`assets/specs/xc-usage/` trio; green integration tests.

- [x] Add `config/bin/xc-md` per [design.md § xc-md contract](design.md#xc-md-contract):
  stdin markdown; **glow → bat → plain**; exit **0** on success.
- [x] Refactor `config/bin/xc-usage` per [design.md § xc-usage contract](design.md#xc-usage-contract):
  top-level `<target>` resolves PATH → fpath → file; `--md` pipes help to
  `command xc-md` (no inline glow/bat logic).
- [x] Remove or internalize public subcommands `guard`, `print`, `validate`; update
  all `config/bin/xc-*` callers to explicit `-h` + `xc-usage "${0:a}"` (scoped flags
  as `--scope`, not `print --scope`).
- [x] Update `assets/specs/xc-usage/requirements.md`, `design.md`, and `tasks.md` to
  match the simplified contract and document `xc-md`.
- [x] Update `assets/integration/bin/xc-usage.spec.ts`: assert `xc-usage gen` (with
  `FPATH`), PATH fixture, `--md` delegation to `xc-md`; add `xc-md` scenarios for
  glow/bat/plain tiers.
- [x] Run `mise run -C assets integration bin xc-usage` (27 pass, 0 fail).
- [x] Run `git diff --check`.
- [x] Commit Task 10 with message `ref(bin): Add xc-md and simplify xc-usage`.

**Gate:** `mise run -C assets integration bin xc-usage` exits **0**; `xc-usage gen`
and `echo x | xc-md` succeed; `--md` never errors solely because `glow` is absent.

## Task 11: Zsh function help delegation

Deliverable: fpath functions use `##?` + `xc-usage`; no duplicate inline help blocks.

- [x] Replace `gen` lines 27–35 with `command xc-usage gen` (or `funcstack` equivalent).
- [x] Update `config/zsh/etc/functions/show_usage` to call `command xc-usage "$target"`
  (drop `print` subcommand).
- [x] Migrate remaining inventory in `assets/specs/xc-usage/design.md` §10.3 that still
  use inline `echo` help — marked gen and show_usage as done.
- [x] Run `gen -h` and `xc-usage gen` smoke checks (output matches).
- [x] Run `git diff --check`.
- [x] Commit Task 11 with message `ref(zsh): Delegate function help to xc-usage`.

**Gate:** `gen -h` output matches `xc-usage gen`; no hand-written Usage echo in `gen`.

## Execution rule

Planning agents stop after Task 1 approval and emit handoff. Implementation
agents use `subagent-driven-development` unless the user prompt requests
inline execution.

## Handoff prompt (implementation agent — Tasks 9–11)

```markdown
You are taking over `assets/specs/project-structure/tasks.md` starting at **Task 9**.

Goal: Document and implement the bin ↔ Zsh helper model, target-first
`xc-usage`, and composable `xc-md` (glow → bat → plain) so `xc-usage gen`,
`xc-usage brew` (when ##? exists), and `xc-usage <target> --md` work.
Remove public guard/print/validate subcommands.
Do **not** create `xc-gen` — `gen` stays on $fpath.

Read first:
- assets/specs/project-structure/HANDOFF.md
- assets/specs/project-structure/requirements.md (Requirements 10–12)
- assets/specs/project-structure/design.md (§ Purpose of xc-* helpers, § xc-md contract, § xc-usage contract)
- assets/specs/project-structure/tasks.md (Tasks 9–11)
- assets/specs/xc-usage/ (update in Task 10 to match design)
- config/bin/xc-usage, config/zsh/etc/functions/gen, config/zsh/etc/functions/show_usage
- assets/guides/GIT_COMMITS_GUIDE.md, assets/guides/TESTING_GUIDE.md, assets/guides/DoD.md

Skills (load before coding):
- subagent-driven-development — execute task groups
- test-driven-development — integration spec changes in Task 10
- systematic-debugging — if xc-usage resolution fails for fpath/PATH cases

Workflow:
1. Complete Task 9 (docs only); run gate; one commit.
2. Complete Task 10 (`xc-md` + xc-usage refactor + xc-usage spec trio + integration tests); run gates; one commit.
3. Complete Task 11 (gen + show_usage + inventory); run gates; one commit.
4. Report: summary, commits, commands run (exit 0), follow-ups.

Stop and report when:
- A gate fails after one fix attempt
- xc-usage scoped flags break xc-git or xc launcher preview (document minimal fix)
- Requirements contradict xc-portable-tools or xc-launcher specs — ask user which wins
```
