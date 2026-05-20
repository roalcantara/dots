<!-- markdownlint-disable-file -->

# HANDOFF: bins BDD living documentation

You are implementing the Dots bins BDD pilot. Use `tasks.md` as the execution
checklist and `implementation-plan.md` as the expanded recipe.

## Copy-paste prompt

Use this prompt when handing the work to another implementation agent:

```text
You are working in /Users/roalcantara/Work/dots.

Implement the Dots bins BDD pilot from
assets/specs/bin/tasks.md. Tasks 1 and 2 are already complete. Start at
Task 3: Gherkin features.

Before editing, read these files:

- assets/specs/bin/tasks.md
- assets/specs/bin/requirements.md
- assets/specs/bin/design.md
- assets/specs/bin/decisions.md
- assets/specs/bin/implementation-plan.md
- assets/guides/GLOSSARY.md
- assets/guides/BDD_GHERKIN_GUIDE.md
- assets/guides/TESTING_GUIDE.md
- assets/guides/MISE_GUIDE.md
- assets/specs/bin/CONFIG_BIN_GUIDE.md
- assets/specs/bin/SKILL.md

Required boundaries:

- Put Gherkin files under assets/features/bin.
- Put Cucumber TypeScript steps under assets/features/bin/step_definitions.
- Use Screenplay actors, interactions or tasks, and questions.
- Use @cucumber/cucumber@^10, @cucumber/screenplay, tsx, and gherkin-lint.
- Use Bun for dependency management and command launching.
- Use Node 22 through mise for BDD tasks.
- Add repeatable commands only as root mise tasks.
- Do not add package scripts.
- Do not add standalone helper scripts for docs, Gherkin, Cucumber, linting, or
  xc checks.
- Do not work on root install, assets/specs/install, nvim, Lua, zsh
  configuration, or repo-wide docs cleanup.

Execution rule:

- Complete one task at a time.
- Run the gates listed in tasks.md before moving to the next task.
- Mark `tasks.md` items complete only after the corresponding gate is green.
- If a gate cannot run, document the blocker in the final response and leave
  the item incomplete.

Expected next work:

1. Create assets/features/bin/command-discovery.feature.
2. Create assets/features/bin/fabric-listing.feature.
3. Create .gherkin-lintrc.
4. Add the root mise task needed to run docs:gherkin:lint.
5. Run mise run docs:gherkin:lint.

Continue through Tasks 4, 5, and 6 only after Task 3 is green.
```

## Required skills

Use `subagent-driven-development` for task execution when delegating work. Use
these supporting skills when relevant: `bdd-gherkin-specification`,
`bdd-scenarios`, `bdd-patterns`, `spec-driven-development`, `bun-runtime`,
`bun-development`, `mise-tasks`, `mise-expert`, `bash-scripting`,
`configuring-zsh`, and `verification-before-completion`.

## Scope

- Read `assets/specs/bin/decisions.md` before changing scope, tooling, or
  feature layout.
- SDD artifacts live in `assets/specs/bin`.
- Gherkin files live in `assets/features/bin`.
- Step definitions live in `assets/features/bin/step_definitions`.
- Root `mise.toml` is the user-facing task entry point.
- Root `package.json` is dependency metadata only. Do not add package scripts.

## Non-goals

- Do not rewrite root `install`.
- Do not create `assets/specs/install`.
- Do not work on `nvim`, `zsh`, Lua, or repo-wide docs cleanup.
- Do not add Functional Core, Imperative Shell guidance.
- Do not create standalone helper scripts for docs, Gherkin, Cucumber, linting,
  or `xc` checks.
- Do not add package scripts.

## Execution rule

Finish each task in `tasks.md` with all listed gates green before starting the
next task.

Tasks 1 and 2 are complete. The next agent starts at Task 3.

## Final gates

Run:

```sh
mise run docs:gherkin:lint
mise run docs:bdd:dry-run
mise run docs:bdd
git diff --check
```

If zsh scripts change, also run:

```sh
mise exec -- shellcheck <changed-zsh-scripts>
zsh -n <changed-zsh-scripts>
```
