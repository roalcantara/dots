<!-- markdownlint-disable-file -->

# REQUIREMENTS: bins BDD living documentation

## Overview

Create the first Dots living documentation suite for `config/bin`. The suite
starts with read-only `xc` and `xc-fabric ls` behavior, then grows only after
the first gates are green.

## User roles

- Terminal user: runs `xc` and `xc-*` commands.
- Maintainer: changes `config/bin` scripts and needs fast verification.
- Agentic worker: follows specs, tasks, and handoff prompts.

## Requirement 1: Minimal guides

**User story:** As a maintainer, I want shared Dots BDD guide docs so
future specs use shared language without copying generic guidance.

**Acceptance criteria:**

1. WHEN reading `assets/guides/GLOSSARY.md` THEN it SHALL define Dots,
   Guides, Spec, Living documentation, Feature file, Scenario, Step
   definition, Screenplay, `config/bin`, `xc-*` tool, `xc` launcher,
   `xc-usage`, Mise task, and Acceptance gate.
2. WHEN reading `assets/specs/bin/CONFIG_BIN_GUIDE.md` THEN it SHALL state
   that Functional Core, Imperative Shell is not the `config/bin`
   architecture.
3. WHEN reading `assets/specs/bin/SKILL.md` THEN it SHALL route bins SDD
   artifacts to `assets/specs/bin` and executable Gherkin to
   `assets/features/bin`.

## Requirement 2: Gherkin suite location

**User story:** As a maintainer, I want feature files under a conventional
features tree so Cucumber tooling can discover them easily.

**Acceptance criteria:**

1. WHEN the bins Cucumber suite is created THEN `.feature` files SHALL live
   under `assets/features/bin`.
2. WHEN step definitions are created THEN TypeScript steps SHALL live under
   `assets/features/bin/step_definitions`.
3. WHEN command execution support is created THEN it SHALL use Screenplay
   actors, activities, and questions instead of direct world helper methods.
4. WHEN `assets/specs/bin` is updated THEN it SHALL contain SDD artifacts,
   not `.feature` files.

## Requirement 3: Command discovery living docs

**User story:** As a terminal user, I want to list available `xc-*` tools so I
can discover commands without memorizing them.

**Acceptance criteria:**

1. WHEN the fixture bin directory contains executable `xc-*` tools AND the user
   runs `xc list` THEN the command SHALL exit 0.
2. WHEN `xc list` succeeds THEN stdout SHALL include `xc-sample`.
3. WHEN `xc list` succeeds THEN stdout SHALL include `Fixture tool`.
4. WHEN `xc -h` runs THEN stdout SHALL include `xc`, `list`, and `launcher`.

## Requirement 4: Fabric listing living docs

**User story:** As a Fabric user, I want to list available Fabric patterns so I
can choose a pattern before running it.

**Acceptance criteria:**

1. WHEN fixture Fabric patterns exist AND the user runs `xc-fabric ls --raw`
   THEN the command SHALL exit 0.
2. WHEN `xc-fabric ls --raw` succeeds THEN stdout SHALL include `summarize`.
3. WHEN `xc-fabric ls --raw` succeeds THEN stdout SHALL include
   `youtube_summary`.

## Requirement 5: Mise-only execution

**User story:** As a maintainer, I want all BDD and bins checks available as
mise tasks so there are no hidden runner scripts.

**Acceptance criteria:**

1. WHEN reading root `mise.toml` THEN it SHALL expose `docs:gherkin:lint`,
   `docs:bdd:dry-run`, and `docs:bdd`.
2. WHEN reading root `mise.toml` THEN it SHALL expose the `xc` checks used by
   the bins pilot or delegate to the existing `config/bin` tasks.
3. WHEN searching the repo for new BDD runner scripts THEN none SHALL exist
   outside Cucumber TypeScript step definitions.
4. WHEN reading root `package.json` THEN it SHALL contain dev dependencies only
   and no `scripts` block.
