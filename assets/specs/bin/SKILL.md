---
name: dots-bins-bdd
description: Use when creating or changing BDD, Gherkin, Cucumber, SDD, or living documentation artifacts for Dots config/bin scripts under assets/specs/bin.
---

# Dots bins BDD

Use this project-local skill for the bins BDD pilot only.

## Workflow

1. Read `assets/guides/GLOSSARY.md`.
2. Read `assets/guides/BDD_GHERKIN_GUIDE.md`.
3. Read `assets/guides/TESTING_GUIDE.md`.
4. Read `assets/guides/MISE_GUIDE.md`.
5. Read `assets/specs/bin/CONFIG_BIN_GUIDE.md`.
6. Read `assets/specs/bin/decisions.md`.
7. Put SDD artifacts in `assets/specs/bin`.
8. Put executable Gherkin in `assets/features/bin`.
9. Run only the gates listed in `assets/specs/bin/tasks.md`.

## Boundaries

- Do not work on `install`, `nvim`, `zsh`, or Lua specs during the bins pilot.
- Do not add Functional Core, Imperative Shell guidance.
- Do not add standalone helper scripts for docs, BDD, linting, Cucumber, or
  `xc` checks.
- Use mise tasks for repeatable commands.

## Useful skills

Use these skills for the bins pilot when the work matches the reason listed.
They are not forbidden; the boundary is to keep their output inside the paths
defined above.

| Skill | Use when |
| --- | --- |
| `bdd-gherkin-specification` | Creating or revising `.feature` files. |
| `bdd-scenarios` | Checking scenario quality, examples, and edge cases. |
| `bdd-patterns` | Applying BDD workflow and collaboration patterns. |
| `spec-driven-development` | Creating or changing `requirements.md`, `design.md`, or `tasks.md`. |
| `subagent-driven-development` | Handing the implementation to another agent or splitting execution. |
| `bun-runtime` | Managing Bun command behavior and dependency installation. |
| `bun-development` | Writing TypeScript support code run through Bun-managed dependencies. |
| `mise-tasks` | Adding or changing repeatable root `mise.toml` tasks. |
| `mise-expert` | Resolving mise tool versions, task syntax, or delegation behavior. |
| `bash-scripting` | Reviewing shell command patterns that apply to portable scripts. |
| `configuring-zsh` | Reviewing zsh-specific script behavior. |
| `verification-before-completion` | Checking gates before marking a task complete. |

BetterSpecs-style examples are welcome when they make behavior clearer. Use
them as readability guidance, not as permission to move specs away from
Gherkin, Cucumber, Screenplay, and mise.
