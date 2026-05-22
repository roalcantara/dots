<!-- markdownlint-disable-file -->

# REQUIREMENTS: project structure

## Overview

Reorganize Dots documentation and verification into a flat, tool-agnostic
layout under `assets/`. Remove the transitional `assets/docs/` tree, relocate
the Cucumber toolchain off the repository root, consolidate mise test tasks,
and document the agent workflow that replaces default superpowers paths.

## User roles

- **Maintainer:** navigates guides, specs, features, and integration checks
  without ambiguity.
- **Agentic worker:** follows SDD artifacts, task groups, handoff prompts, and
  mise gates.
- **Terminal user:** uses `config/bin` helpers on PATH and Zsh functions on
  `$fpath`; help via `xc-usage <name>` and `-h` on each entry point.

## Requirement 1: Canonical guides

**User story:** As a maintainer, I want one guide tree so every best practice
has a single source of truth.

**Acceptance criteria:**

1. WHEN reading project guides THEN they SHALL live only under
   `assets/guides/`.
2. WHEN comparing `assets/guides/` to the former `assets/guides/` THEN
   every Dots-relevant topic SHALL be merged with no duplicate filenames for
   the same topic.
3. WHEN listing `assets/guides/` THEN `FISHERY_GUIDE.md` and other guides
   unrelated to Dots SHALL NOT exist.
4. WHEN an agent starts work on Dots THEN `assets/guides/README.md` SHALL
   list the guide index and point to `assets/guides/GLOSSARY.md` first.

## Requirement 2: Canonical SDD specs

**User story:** As an agent, I want planning artifacts separated from
executable tests so I know where to write requirements and tasks.

**Acceptance criteria:**

1. WHEN creating SDD artifacts for a feature THEN they SHALL live under
   `assets/specs/<feature-slug>/` as `requirements.md`, `design.md`, and
   `tasks.md`.
2. WHEN searching for `assets/specs/` content THEN it SHALL have moved to
   `assets/specs/xc-git/`, `assets/specs/xc-usage/`, and sibling slugs.
3. WHEN the migration completes THEN `assets/specs/` SHALL NOT exist.
4. WHEN superpowers or brainstorming skills suggest `docs/superpowers/` THEN
   agents SHALL redirect output to `assets/specs/<feature-slug>/` per
   `assets/specs/project-structure/design.md`.

## Requirement 3: Centralized BDD features

**User story:** As a maintainer, I want one features tree for the whole
project so Cucumber discovers all living documentation from a single root.

**Acceptance criteria:**

1. WHEN listing Gherkin feature files THEN they SHALL live under
   `assets/features/<domain>/` (for example `assets/features/bin/`).
2. WHEN listing shared Cucumber support THEN `world.ts`, Screenplay helpers,
   and cross-domain glue SHALL live under `assets/features/support/`.
3. WHEN listing step definitions THEN domain glue SHALL live under
   `assets/features/step_definitions/<domain>/`.
4. WHEN the migration completes THEN `assets/docs/features/` SHALL NOT exist.
5. WHEN reading `.gherkin-lintrc` THEN it SHALL live at
   `assets/features/.gherkin-lintrc`.

## Requirement 4: Integration verification layer

**User story:** As a maintainer, I want subprocess script checks in a layer
named for behavior, not for Bun or another runner.

**Acceptance criteria:**

1. WHEN listing Bun integration specs for `config/bin` THEN they SHALL live
   under `assets/integration/bin/` including fixtures.
2. WHEN the migration completes THEN `config/bin/tests/` SHALL NOT exist.
3. WHEN reading guide docs THEN the integration layer SHALL be described as
   subprocess and script verification, not as unit tests.

## Requirement 5: Verification toolchain placement

**User story:** As a maintainer, I want the repository root to remain a
dotfiles project, not a Node application, with verification dependencies
declared in mise and/or package manifest as appropriate.

**Acceptance criteria:**

1. WHEN reading the repository root THEN `package.json` SHALL NOT exist.
2. WHEN verification needs npm registry packages THEN they SHALL be declared in
   `assets/package.json` under `devDependencies` without a `scripts` block.
3. WHEN verification needs CLI tools THEN they MAY be declared in
   `assets/mise.toml` under `[tools]` instead of or in addition to
   `assets/package.json`.
4. WHEN reading `assets/bun.lock` THEN it SHALL match `assets/package.json`
   when npm packages are used.
5. WHEN optional TypeScript lint config exists for verification THEN
   `assets/biome.json` MAY lint TypeScript under `assets/features/` and
   `assets/integration/`.

## Requirement 6: Mise task surfaces

**User story:** As a maintainer, I want repeatable commands through mise with
project-wide and verification-scoped tasks clearly separated.

**Acceptance criteria:**

1. WHEN reading root `mise.toml` THEN it SHALL contain Docker, setup, and CI
   tasks only, plus thin wrappers that delegate to `assets/mise.toml`.
2. WHEN reading `assets/mise.toml` THEN it SHALL define all BDD and integration
   tasks for the verification tree.
3. WHEN running `mise run test` from the repository root THEN all verification
   gates for the migrated bin domain SHALL execute successfully.
4. WHEN reading `assets/mise.toml` after migration THEN parameterized task inputs
   SHALL use `usage` args and flags, not per-task `env` blocks for values like
   `XC_GIT` or `XC_BIN_DIR`.
5. WHEN reading `config/bin/mise.toml` after migration THEN it SHALL NOT define
   `xc:*:specs` tasks (those tasks live in `assets/mise.toml`).
6. WHEN reading `assets/guides/MISE_GUIDE.md` after migration THEN task naming
   SHALL document merged action tasks per the Merging Similar Tasks section,
   not one mise task per integration spec file.
7. WHEN reading `assets/guides/MISE_GUIDE.md` THEN it SHALL discourage using
   task `env` or ad hoc exported variables for task parameters that belong in
   `usage` specs.

## Requirement 7: Implementation-only config trees

**User story:** As a maintainer, I want `config/bin/` to contain scripts only.

**Acceptance criteria:**

1. WHEN listing `config/bin/` after migration THEN it SHALL contain `xc-*`
   executables and maintainer docs such as `README.md` but SHALL NOT contain
   `tests/` or `specs/` directories.
2. WHEN listing Neovim tests THEN busted specs SHALL remain under
   `config/nvim/specs/` with tasks in `config/nvim/mise.toml`.

## Requirement 8: Agent workflow

**User story:** As an agent owner, I want contributor and agent directions in
the root README so onboarding does not depend on a nested workflow file.

**Acceptance criteria:**

1. WHEN reading root `README.md` THEN it SHALL document the `assets/` layout,
   verification commands, and the agent planning and implementation workflow.
2. WHEN an agent starts a new feature THEN it SHALL use the
   `spec-driven-development` skill to author `requirements.md`, `design.md`,
   and `tasks.md` under `assets/specs/<feature-slug>/`.
3. WHEN searching for a standalone agent workflow file THEN
   `assets/specs/project-structure/AGENT_WORKFLOW.md` SHALL NOT exist after
   migration.
4. WHEN a task group in `tasks.md` is marked complete THEN every acceptance
   criterion for that group SHALL pass with zero errors and zero warnings on
   listed gates, and Definition of Done items applicable to the change SHALL
   be green.
5. WHEN a task group completes THEN the agent SHALL create one conventional
   commit following `assets/guides/GIT_COMMITS_GUIDE.md`.
6. WHEN implementing tasks from `tasks.md` THEN the agent SHALL use
   `subagent-driven-development` unless the triggering prompt explicitly
   requests immediate inline implementation.
7. WHEN SDD artifacts are approved THEN the planning agent SHALL emit a
   handoff prompt for a separate implementation agent unless the triggering
   prompt explicitly requests inline implementation.

## Requirement 9: Guide separation

**User story:** As a maintainer, I want BDD concepts documented separately from
test execution so each guide stays focused.

**Acceptance criteria:**

1. WHEN onboarding to BDD THEN `assets/guides/BDD_GUIDE.md` SHALL explain Dots
   BDD concepts, verification layers, and folder roles.
2. WHEN writing Gherkin THEN `assets/guides/BDD_GHERKIN_GUIDE.md` SHALL cover
   syntax, checklist, templates, and step vocabulary only.
3. WHEN running gates THEN `assets/guides/TESTING_GUIDE.md` SHALL cover mise
   commands, verification gates, Bun integration-spec patterns, shellcheck, and
   syntax checks without duplicating BDD philosophy or Gherkin style rules.
4. WHEN merging guides THEN overlapping sections SHALL be moved or deleted — not
   copied across files with cross-links replacing the source section.
5. WHEN reading `assets/guides/README.md` THEN it SHALL list all guides with a
   one-line scope for each.

## Requirement 10: `config/bin` as Zsh helpers

**User story:** As a maintainer, I want a clear split between PATH helpers under
`config/bin/` and Zsh-only autoload functions so duplication and help drift
stop.

**Acceptance criteria:**

1. WHEN reading project architecture docs THEN they SHALL state that every
   `config/bin/xc-*` executable **except `xc-skills`** is a **helper for**
   Zsh autoload functions in `config/zsh/etc/functions/` — not a replacement
   for those functions unless explicitly migrated per a feature spec.
2. WHEN a function has been migrated to a `config/bin/xc-*` helper AND verified
   on PATH THEN its duplicate under `config/zsh/etc/functions/` SHALL be
   deleted.
3. WHEN a function is documented as Zsh-only (for example `gitx`, `psc`) THEN
   it SHALL remain under `config/zsh/etc/functions/` only and SHALL NOT gain a
   `config/bin/xc-*` copy.
4. WHEN reading architecture docs THEN `gen` SHALL be listed as a **Zsh-only**
   function (help via `##?` + `xc-usage`); there SHALL be **no** `xc-gen` or
   `gen` → `config/bin` migration.
5. WHEN a Zsh function implements `-h` / `--help` THEN it SHALL NOT duplicate
   help text with inline `echo` blocks when a `##?` header exists in the same
   file; it SHALL delegate to `xc-usage` per
   [design.md § config/bin and Zsh functions](design.md#configbin-and-zsh-functions).

## Requirement 11: Universal `xc-usage`

**User story:** As a terminal user, I want one command that prints docopt help
from any script or autoload function that declares `##?` headers — on PATH or
on `$fpath`.

**Acceptance criteria:**

1. WHEN `xc-usage <target>` is invoked and `<target>` is not a reserved flag
   THEN output SHALL be all `##?` lines from the resolved source (strip `##? `
   prefix), whether `<target>` is a file path, a PATH executable, or a Zsh
   function name on `$fpath`.
2. WHEN `<target>` resolves to `/opt/homebrew/bin/brew` (or any PATH binary)
   and that file contains `##?` headers THEN `xc-usage brew` SHALL print them;
   WHEN no `##?` header exists THEN `xc-usage` SHALL exit non-zero with a clear
   error (not “unknown command”).
3. WHEN `xc-usage gen` is invoked THEN output SHALL match the `##?` block in
   `config/zsh/etc/functions/gen` (Zsh-only; no `xc-gen`).
4. WHEN `xc-usage <target> --md` is invoked THEN help text SHALL be passed to
   `xc-md` (see Requirement 12); exit code SHALL match plain `xc-usage <target>`
   on success.
5. WHEN reading normative `xc-usage` docs after simplification THEN public
   subcommands `guard`, `print`, and `validate` SHALL NOT be documented as
   user-facing entry points; bin and Zsh callers SHALL use `xc-usage <target>`
   or flags documented in [design.md § xc-usage contract](design.md#xc-usage-contract).
6. WHEN `show_usage` is used from Zsh THEN it SHALL remain a thin wrapper that
   defaults the target to the calling function and delegates to
   `command xc-usage <resolved-target>` (not ad-hoc `grep '^##?'`).
7. WHEN integration specs cover `xc-usage` THEN they SHALL assert
   `xc-usage gen`, PATH resolution, and `--md` behavior per design — not only
   legacy subcommand forms.

## Requirement 12: `xc-md` renderer helper

**User story:** As a terminal user, I want markdown help rendered nicely when
optional tools exist, without failing when they do not.

**Acceptance criteria:**

1. WHEN `config/bin/xc-md` exists THEN it SHALL read markdown from **stdin** and
   write rendered output to stdout.
2. WHEN `glow` is on PATH THEN `xc-md` SHALL pipe stdin through `glow`.
3. WHEN `glow` is absent and `bat` is on PATH THEN `xc-md` SHALL pipe stdin
   through `bat` with markdown language and no pager (`--paging=never` or
   equivalent).
4. WHEN neither `glow` nor `bat` is on PATH THEN `xc-md` SHALL print stdin
   unchanged to stdout.
5. WHEN `xc-md` receives input THEN it SHALL exit **0** on success regardless
   of which renderer tier ran (no error merely because `glow` is missing).
6. WHEN `xc-usage <target> --md` is implemented THEN it SHALL delegate rendering
   to `command xc-md` (composition: extract then render — not inline `glow`).
7. WHEN listing PATH helpers THEN `xc-md` SHALL be documented alongside
   `xc-usage` as a single-purpose composable helper per
   [design.md § Purpose of `xc-*` helpers](design.md#purpose-of-xc-helpers).
