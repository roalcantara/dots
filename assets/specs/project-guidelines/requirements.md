<!-- markdownlint-disable-file -->

# REQUIREMENTS: project guidelines

## Overview

Rewrite `assets/guides/` to reflect the Dots dotfiles repository (not kb/Electrobun),
establish a validated skill registry with Skills CLI automation, and add missing
guides (Docker). All planning artifacts live under `assets/specs/project-guidelines/`.

## User roles

- **Maintainer:** reads accurate guides, runs skill validation, updates registry.
- **Agentic worker:** loads `dots-context`, follows SKILLS.yml routing, uses SDD under `assets/specs/`.
- **Contributor:** follows CODESTYLE, BDD, mise, and CI guides scoped to Dots paths.

## Requirement 1: Skill registry for Dots

**User story:** As a maintainer, I want a Dots-specific skill registry with
automation so agents load the right skills and the lock file stays consistent.

**Acceptance criteria:**

1. WHEN reading `assets/guides/SKILLS.yml` THEN it SHALL describe Dots skills only
   with `schema_version: 3`.
2. WHEN a skill has `location: project` THEN it SHALL appear in `skills-lock.json`
   at the repository root.
3. WHEN running `mise run -C assets skill validate` THEN validation SHALL pass
   with zero errors on a clean checkout after `mise run -C assets skill install`.
4. WHEN running `mise run -C assets skill sync` THEN managed blocks in `AGENTS.md`,
   `.agents/skills/dots-context/SKILL.md`, and `.cursor/dots-skill-routing.md`
   SHALL update from `SKILLS.yml`.
5. WHEN searching guides for `kb`, `kodexb`, or `electrobun` THEN zero matches
   SHALL remain in `assets/guides/SKILLS.md` and `assets/guides/SKILLS.yml`.

## Requirement 2: Owned orientation skills

**User story:** As an agent, I want project-owned skills so Dots workflow is
always available without relying on global copies.

**Acceptance criteria:**

1. WHEN starting any Dots task THEN `.agents/skills/dots-context/SKILL.md` SHALL
   exist and define stack, paths, and guide routing.
2. WHEN writing or changing tests THEN `dots-testing` SHALL document verification
   layers and mise gates under `assets/`.
3. WHEN declaring work complete THEN `dots-quality-gate` SHALL document DoD and
   required mise commands.

## Requirement 3: CI guide accuracy

**User story:** As a maintainer, I want CI documentation that matches GitHub Actions.

**Acceptance criteria:**

1. WHEN reading `assets/guides/CI_GUIDE.md` THEN it SHALL describe
   `.github/workflows/preview.yml`, `release.yml`, and `publish.yml` only.
2. WHEN the guide mentions jobs THEN job names and purposes SHALL match the workflow files.
3. WHEN the guide mentions local parity THEN it SHALL reference root `mise run test`
   and link to `DOCKER_GUIDE.md`.

## Requirement 4: Glossary completeness

**User story:** As a reader, I want shared terminology for new guide topics.

**Acceptance criteria:**

1. WHEN reading `assets/guides/GLOSSARY.md` THEN it SHALL define Hadolint, CST,
   DevContainer, Flox, SOPS, `usage_*`, hk, and root vs assets mise scopes.
2. WHEN a term is defined in GLOSSARY THEN guides SHALL link to it instead of
   redefining inline.

## Requirement 5: Code style guide for Dots

**User story:** As a contributor, I want code style guidance scoped to this repo.

**Acceptance criteria:**

1. WHEN reading `assets/guides/CODESTYLE_GUIDE.md` THEN it SHALL cover shell
   (`config/bin`, `install`), Zsh functions, TypeScript under `assets/`, and
   optional Lua under `config/nvim`.
2. WHEN the guide references Bun skills THEN it SHALL name `bun-development` and
   `bun-runtime` and restrict TypeScript examples to `assets/integration/` and
   `assets/features/`.
3. WHEN searching CODESTYLE for `kodexb`, `TypeBox`, or `Elysia` THEN zero
   matches SHALL remain.

## Requirement 6: BDD guides with skill references

**User story:** As a BDD author, I want guides that point to the right skills.

**Acceptance criteria:**

1. WHEN reading `assets/guides/BDD_GUIDE.md` THEN a **Skills to load** section
   SHALL list BDD-related skills and when to load them.
2. WHEN reading `assets/guides/BDD_GHERKIN_GUIDE.md` THEN the same skill
   references SHALL appear and all paths SHALL be under `assets/`.
3. WHEN examples cite commands THEN they SHALL use `mise run -C assets bdd` and
   `mise run -C assets test bin`.

## Requirement 7: Docker guide

**User story:** As a maintainer, I want Docker usage documented for this project.

**Acceptance criteria:**

1. WHEN listing guides THEN `assets/guides/DOCKER_GUIDE.md` SHALL exist.
2. WHEN the guide describes build THEN it SHALL document root `mise run build`
   usage flags per root `mise.toml`.
3. WHEN the guide describes CI THEN it SHALL match Preview workflow matrix
   (debian, ubuntu) and CST config paths.
4. WHEN the guide lists improvements THEN it SHALL include at least three
   actionable suggestions for current Docker usage in this repo.

## Requirement 8: Mise guide rewrite

**User story:** As a maintainer, I want mise best practices documented for Dots.

**Acceptance criteria:**

1. WHEN reading `assets/guides/MISE_GUIDE.md` THEN it SHALL document root vs
   `assets/mise.toml` split and `usage` field patterns.
2. WHEN the guide shows task examples THEN they SHALL use Dots tasks only
   (`build`, `test`, `bdd`, `integration`, `skill`).
3. WHEN searching MISE_GUIDE for `kodexb` or `apps/kb` THEN zero matches SHALL remain.

## Requirement 9: Guide index

**User story:** As a reader, I want one index for all guides.

**Acceptance criteria:**

1. WHEN reading `assets/guides/README.md` THEN it SHALL list every guide file
   including `SKILLS.md`, `CI_GUIDE.md`, and `DOCKER_GUIDE.md`.
2. WHEN the index describes reading order THEN it SHALL recommend `GLOSSARY.md`
   first, then `SKILLS.md` for agents.

## Requirement 10: SDD artifacts

**User story:** As an agent, I want this rewrite planned under SDD.

**Acceptance criteria:**

1. WHEN listing `assets/specs/project-guidelines/` THEN `requirements.md`,
   `design.md`, `tasks.md`, `decisions.md`, and `HANDOFF.md` SHALL exist.
2. WHEN implementation completes THEN each task in `tasks.md` SHALL be marked
   `[x]` with gates recorded.
