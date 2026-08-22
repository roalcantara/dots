# Project Skill Guide

This guide explains how Dots classifies agent skills and how the project keeps
that classification consistent. The structured source of truth is
[`SKILLS.yml`](SKILLS.yml); this Markdown file is the human-facing explanation
of the same policy.

Run `mise run -C assets skill validate` after editing `SKILLS.yml`. Run
`mise run -C assets skill sync` to refresh generated snippets in `AGENTS.md`,
`.agents/skills/dots-context/SKILL.md`, and `.cursor/dots-skill-routing.md`.
Run `mise run -C assets skill install` to restore project-managed external
skills from `skills-lock.json` through the Skills CLI.

## Schema

`SKILLS.yml` keeps one `skills:` entry per relevant skill. Each entry has a
single `location`, a `rationale`, and one discriminated `policy.type`.

| Field               | Meaning                                                                                                                  |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `location: owned`   | Project-authored skill committed under `.agents/skills/<skill-id>`. These skills are not managed by `skills-lock.json`.  |
| `location: project` | External skill managed by the Skills CLI, recorded in `skills-lock.json`, and restored into `.agents/skills/<skill-id>`. |
| `location: global`  | Global-only companion used from `$HOME/.agents/skills/<skill-id>` when available.                                        |

| Policy type | Meaning                                                                                                          |
| ----------- | ---------------------------------------------------------------------------------------------------------------- |
| `required`  | Standing project skill for its domain.                                                                           |
| `optional`  | Companion skill loaded for specific situations when it does not conflict with Dots guidance.                     |
| `reference` | Upstream reference only; useful for reading, not project routing.                                                |
| `blocked`   | Skill looks relevant at first glance but is **not** recommended for Dots; see [Blocked skills](#blocked-skills). |

Dots does **not** use a `routed` policy type. Domain selection uses
`policy.routing.domain` entries synced to `.cursor/dots-skill-routing.md`.

Usable policies define `policy.usage.summary`,
`policy.usage.when.load`, and `policy.usage.when.avoid`. Blocked policies do
not define `usage`; they define `policy.reason`, `rationale` (why the skill
*seems* applicable), and `policy.redirect_to` (what to use instead).

The schema intentionally has no skill-level `source`, `install`, `link`,
`decision`, or `load` fields. `location` prevents source/install
contradictions, and `policy.type` prevents blocked/optional state
contradictions.

**Registry scope:** `SKILLS.yml` lists skills Dots actively routes to—or skills
that are **misleading near-misses**. It is not a catalog of every global skill
you will never use. Stacks unrelated to dotfiles (Electrobun, Firebase, AWS,
and similar) are simply omitted; `dots-context` and project guides remain
authoritative when an agent might otherwise reach for them.

## Consistency

The registry and lock file must agree:

- Every `location: project` entry must appear in `skills-lock.json`.
- Every `skills-lock.json` entry must appear in `SKILLS.yml` as
  `location: project`.
- `location: owned` and `location: global` entries must not appear in
  `skills-lock.json`.
- The Skills CLI owns how project skills are materialized under
  `.agents/skills/`; Dots does not model copy versus symlink in `SKILLS.yml`.

## Decision Rules

Apply these rules before adopting or invoking a skill:

1. Dots-specific instructions win over generic skill advice.
2. `AGENTS.md` and `.agents/skills/dots-context/SKILL.md` define the standing
   workflow.
3. `assets/guides/` define the project style, testing, runtime, and quality
   expectations.
4. Domain work must use `.cursor/dots-skill-routing.md` before choosing a
   narrower companion skill.
5. Generic skills may be used as optional companions only when they do not
   weaken the quality gate or project guide conventions.
6. For SDD under `assets/specs/`, load **`using-superpowers`** and
   **`spec-driven-development`** together; redirect any OpenSpec (`openspec-*`)
   workflow to Dots SDD paths per `dots-context`.

Do not add a skill to the project only because it sounds useful. Add domain
routing only when the skill changes agent behavior in a repeatable
project-specific situation.

## Current Project Skills

| Skill               | Location  | Policy     | Rationale                                                                   |
| ------------------- | --------- | ---------- | --------------------------------------------------------------------------- |
| `dots-context`      | `owned`   | `required` | Mandatory project orientation, paths, SDD location, and guide routing.      |
| `dots-testing`      | `owned`   | `required` | Canonical verification workflow for specs, features, and integration tests. |
| `dots-quality-gate` | `owned`   | `required` | Executable completion and commit-readiness gate.                            |
| `bun-development`   | `project` | `optional` | Bun TypeScript under `assets/integration/` and `assets/features/`.          |
| `bun-runtime`       | `project` | `optional` | Bun runtime, package manager, and test-runner behavior under `assets/`.     |

## Optional Companion Matrix

| Situation                                    | Optional companion skills                                                                          |
| -------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| Starting any Dots task, skill selection      | `using-superpowers`                                                                                |
| Failing tests, regressions, unclear behavior | `systematic-debugging`                                                                             |
| Structural search or repository rules        | `ast-grep`                                                                                         |
| `config/bin`, install scripts, shell hooks   | `bash-scripting`, `bash-linux`                                                                     |
| `config/zsh`, plugins, completions           | `configuring-zsh`                                                                                  |
| Docker, Dockerfile, distros, CST, Hadolint   | `docker-expert`, `docker-patterns`                                                                 |
| Flox manifests under `config/flox/`          | `flox-environments`                                                                                |
| `mise.toml`, task wiring, tool versions      | `mise-tasks`, `mise-expert`                                                                        |
| GitHub Actions, workflows, CI                | `github-actions-docs`                                                                              |
| Gherkin, Cucumber, `assets/features/`        | `bdd-gherkin-specification`, `cucumber-gherkin`, `bdd-scenarios`, `bdd-patterns`, `bdd-principles` |
| SDD under `assets/specs/`                    | `using-superpowers`, `spec-driven-development`, `writing-plans`                                    |
| Bun TypeScript under `assets/`               | `bun-development`, `bun-runtime`                                                                   |
| Neovim Lua under `config/nvim/`              | `neovim-best-practices`, `lua`                                                                     |
| Writing or reviewing guides and specs        | `docs-writer`                                                                                      |
| Review preparation or review feedback        | `requesting-code-review`, `receiving-code-review`                                                  |
| Final verification reminder                  | `verification-before-completion`; `dots-quality-gate` remains executable authority                 |

## Reference-Only Skills

Reference-only skills are useful for reading when the situation explicitly
calls for them, but they are not project routing defaults:

- `find-skills`
- `using-git-worktrees`
- `quality-assurance`

## Blocked skills

`blocked` is **not** a deny list of every skill Dots will never touch. Omit
skills that are obviously unrelated (desktop app frameworks, cloud PaaS stacks,
and similar)—agents should rely on `dots-context` and project guides instead.

Use `blocked` only for **misleading near-misses**: skills that share vocabulary
or tooling with Dots and might be chosen by mistake. Each entry in
`SKILLS.yml` explains **why it looks relevant** and **why it is not
recommended**, then points to the correct guide or companion skill.

| Skill                                                                                   | Why it looks relevant              | Why it is blocked                                                | Use instead                                                    |
| --------------------------------------------------------------------------------------- | ---------------------------------- | ---------------------------------------------------------------- | -------------------------------------------------------------- |
| `functional-core-imperative-shell`                                                      | Shell work and testable boundaries | Dots does not use FCIS or mandatory purity comments              | `TESTING_GUIDE.md`, `dots-testing`                             |
| `elysia`, `elysiajs`                                                                    | Dots uses Bun under `assets/`      | No Elysia apps, ORMs, or web-server scaffolding                  | `CODESTYLE_GUIDE.md`, `bun-development`                        |
| `webapp-testing`                                                                        | Task mentions testing              | Browser/Playwright QA, not subprocess + Cucumber                 | `dots-testing`, `TESTING_GUIDE.md`, `BDD_GUIDE.md`             |
| `stitch-loop`                                                                           | Iterative design or UI work        | Autonomous loop bypasses SDD, tasks, and DoD                     | `using-superpowers`, `spec-driven-development`, `DoD.md`       |
| `deploy-to-vercel`                                                                      | Task mentions publish or deploy    | Dots ships Docker images, not Vercel web apps                    | `DOCKER_GUIDE.md`, `CI_GUIDE.md`                               |
| `tdd-workflow`                                                                          | Test-first development             | Assumes application layers and coverage unlike Dots verification | `dots-testing`, `TESTING_GUIDE.md`                             |
| `openspec-propose`, `openspec-new-change`, `openspec-ff-change` (OpenSpec `openspec-*`) | Spec or change planning            | OpenSpec change workflow, not Dots SDD under `assets/specs/`     | `using-superpowers`, `spec-driven-development`, `dots-context` |

When adding a new `blocked` entry, ask: *Would a reasonable agent pick this
skill without knowing Dots?* If no, leave it out of the registry.

## Domain Routing

These optional skills have `policy.routing.domain` entries synced to
`.cursor/dots-skill-routing.md`:

| When the task involves…                        | Read this skill first       | Note    |
| ---------------------------------------------- | --------------------------- | ------- |
| Docker, Dockerfile, CST, distros               | `docker-expert`             | global  |
| mise.toml, usage field, task args              | `mise-expert`               | global  |
| GitHub Actions, workflows, CI                  | `github-actions-docs`       | global  |
| Gherkin, Cucumber, assets/features             | `bdd-gherkin-specification` | global  |
| config/bin, install, shell scripts             | `bash-scripting`            | global  |
| assets/integration, assets/features TypeScript | `bun-development`           | project |

## Updating Skills

Use this workflow when changing the registry:

1. Edit `assets/guides/SKILLS.yml`.
2. Run `mise run -C assets skill validate`.
3. Run `mise run -C assets skill sync` when generated snippets must change.
4. Run `mise run -C assets skill install` when project-managed external skills
   must be restored from `skills-lock.json`.
5. Review `assets/guides/SKILLS.md`, `AGENTS.md`,
   `.agents/skills/dots-context/SKILL.md`, and `.cursor/dots-skill-routing.md`
   together when the change affects routing or optional companion guidance.

To add a new project-managed skill, install it with the Skills CLI at the
repository root (without `-g`), then add matching entries to both
`skills-lock.json` and `SKILLS.yml` before running validate.
