<!-- markdownlint-disable-file -->

# bins BDD living documentation design

This design defines the first BDD and Gherkin lab for Dots. It keeps the work
small on purpose: create only the guide artifacts needed for `config/bin`,
then use `assets/specs/bin` as the first living documentation area.

The goal is to learn a repeatable workflow before applying it to larger Dots
areas such as `install`, `nvim`, or `zsh`.

## Scope

This pass has two stages.

Stage 1 creates a minimal `assets/docs/guides` set that supports the bins
pilot. It must not become a full repository doctrine rewrite.

Stage 2 creates `assets/specs/bin` as the SDD specification for
`config/bin` and `assets/features/bin` as the executable Gherkin suite.
The spec area owns requirements, design, tasks, and the handoff prompt. The
features area owns Cucumber feature files and step definitions.

The first executable behavior slice must stay read-only. The preferred pilot is
command discovery, command listing, help output, and one concrete subcommand
path such as `xc-fabric ls`.

## Non-goals

This design does not include these tasks:

- Rewrite the root `install` script.
- Create `assets/specs/install`.
- Normalize all copied KB docs.
- Add Lua or Neovim guidance before a spec needs it.
- Replace the existing Bun specs under `config/bin/tests`.
- Adopt a reporting platform or test management service.
- Add package scripts. The bins pilot may add a minimal root `package.json`
  only for dev dependencies if Cucumber-JS requires project-local packages.
- Introduce Functional Core, Imperative Shell as a shell-script architecture for
  Dots. This repo does not follow that style, and the bins pilot must not try to
  force it.
- Add standalone helper scripts for docs, BDD, linting, or Cucumber execution.
  New automation must be expressed as mise tasks unless a later approved spec
  explicitly creates a script.

## Stage 1: guide artifacts

The guides stage creates only the files that the bins pilot needs.

| File                                          | Purpose                                                             |
| --------------------------------------------- | ------------------------------------------------------------------- |
| `assets/guides/GLOSSARY.md`          | Define Dots terms used by specs and scenarios.                      |
| `assets/guides/BDD_GHERKIN_GUIDE.md` | Define Dots Gherkin style with real bins examples.                  |
| `assets/guides/TESTING_GUIDE.md`     | Define Cucumber, Screenplay, Bun, shellcheck, and syntax gates.     |
| `assets/guides/MISE_GUIDE.md`        | Define task naming and execution through mise.                      |
| `assets/specs/bin/CONFIG_BIN_GUIDE.md`       | Define `config/bin` shell conventions without adding FCIS doctrine. |
| `assets/specs/bin/SKILL.md`             | Route future agents working on the bins BDD spec.                   |

The guide files must use Dots terminology and real `config/bin` examples.
They must not copy generic BDD content without adapting it to this repo.

`CONFIG_BIN_GUIDE.md` must describe the conventions that already fit Dots: `zsh`,
`xc-usage`, `##?` docopt-shaped help, graceful dependency checks where existing
scripts use them, and mise-driven verification. It must not prescribe
Functional Core, Imperative Shell, pure-function layering, or repo-wide shell
architecture cleanup.

## Guides skill

`assets/specs/bin/SKILL.md` is a project-local routing aid. It is not a
general BDD tutorial.

The skill frontmatter must be narrow:

```yaml
---
name: dots-bins-bdd
description: Use when creating or changing BDD, Gherkin, Cucumber, SDD, or living documentation artifacts for Dots config/bin scripts under assets/specs/bin.
---
```

The skill body must tell agents to:

- Read `assets/guides/GLOSSARY.md` first.
- Use `assets/guides/BDD_GHERKIN_GUIDE.md` for scenario style.
- Use `assets/guides/TESTING_GUIDE.md` for Cucumber and Screenplay
  runner expectations.
- Use `assets/guides/MISE_GUIDE.md` for task naming and command
  surfaces.
- Use `assets/specs/bin/CONFIG_BIN_GUIDE.md` for `config/bin` conventions.
- Read `assets/specs/bin/decisions.md` before changing scope, tooling, or
  feature layout.
- Put SDD artifacts for `config/bin` under `assets/specs/bin`.
- Put executable Gherkin for `config/bin` under `assets/features/bin`.
- Keep scenarios declarative, present tense, third person, and focused on one
  behavior.
- Avoid `install`, `nvim`, `zsh`, Lua, and repo-wide cleanup during this pilot.
- Run only the gates listed in `assets/specs/bin/tasks.md`.

The handoff can mention these installed local skills when they are relevant:

- `bdd-gherkin-specification`
- `bdd-scenarios`
- `bdd-patterns`
- `spec-driven-development`
- `subagent-driven-development`
- `bun-runtime`
- `bun-development`
- `mise-tasks`
- `mise-expert`
- `bash-scripting`
- `configuring-zsh`
- `verification-before-completion`

## Stage 2: bins spec structure

`assets/specs/bin` owns the SDD artifacts for `config/bin`. It references
the executable Gherkin suite, but it does not contain the `.feature` files.

The SDD directory uses this structure:

```text
assets/specs/bin/
  requirements.md
  design.md
  decisions.md
  tasks.md
  HANDOFF.md
```

The Cucumber suite uses a conventional `features` tree under `assets/docs`:

```text
assets/features/bin/
  command-discovery.feature
  fabric-listing.feature
  step_definitions/
    command-discovery.steps.ts
    support/
      paths.ts
      world.ts
      screenplay/
        run-command.ts
        last-command.ts
```

This keeps Gherkin close to the docs while avoiding a deeply nested
`specs/<slug>/features` path. It also makes later suites predictable:

```text
assets/docs/features/install/
assets/docs/features/nvim/
assets/docs/features/zsh/
```

The exact feature and step filenames can change during implementation, but the
directory shape must stay stable unless the selected runner requires a different
layout.

No standalone support scripts are allowed for this suite. TypeScript support
modules under `step_definitions/support` are allowed only as Cucumber step support
code.

## Decision record

`assets/specs/bin/decisions.md` is the source of truth for decisions that
future implementation agents must preserve. It records the two-stage scope,
feature-tree location, mise-only command surface, Cucumber-JS 10 and Node 22
choice, Screenplay model, advanced-tool boundaries, shell-guide boundaries, and
editor-support starting point.

When a later implementation changes one of those choices, update
`decisions.md` in the same task as the code or documentation change.

## Screenplay step model

The bins pilot must use the Screenplay pattern from the first step-definition
slice. This does not mean adopting Serenity/JS or a reporting platform.

Screenplay matters here because it keeps Gherkin steps as translation code,
while command execution and assertions live behind reusable actor activities
and questions. The initial model is:

- Actors represent named terminal users, such as `Alice`.
- Tasks describe user intent, such as `ListAvailableCommands` or
  `ListFabricPatterns`.
- Interactions perform low-level shell work, such as running `zsh` with a
  controlled `PATH` and fixture environment.
- Questions retrieve observable state, such as the last command's exit code,
  stdout, and stderr.

The first implementation should use `@cucumber/screenplay` rather than building
a custom actor abstraction. If the package's Cucumber peer range becomes a hard
blocker, the fallback is a tiny local Screenplay-inspired support layer under
`step_definitions/support/screenplay`, not direct `this.run(...)` helper methods in
every step.

## Gherkin style

Gherkin files must describe user-visible behavior, not implementation details.
The Dots guide must use the official Cucumber Gherkin reference as the syntax
authority and Automation Panda's "one scenario, one behavior" rule as the
primary style guardrail.

Feature files must follow these rules:

- Use one `Feature` per file.
- Prefer `Rule` when grouping scenarios around a single command behavior.
- Keep each scenario independent.
- Keep each scenario to one main `When`.
- Keep most scenarios near three to five steps.
- Use `Background` only for short, shared context that readers must know.
- Use third person instead of first person.
- Use real command names, real subcommands, and real output expectations.
- Avoid placeholder rows, fake command names, or fake descriptions.

The first features must focus on behavior such as:

- The user lists available `xc-*` commands.
- The user sees help for the `xc` launcher.
- The user sees `xc-fabric` subcommands.
- The user lists Fabric patterns with `xc-fabric ls`.

Interactive keyboard behavior, fzf scrolling, and terminal focus assumptions can
come after the first read-only slice is green.

## Cucumber and Bun integration

The first runner candidate is `@cucumber/cucumber`, because Cucumber-JS is the
official JavaScript implementation. Screenplay support comes from
`@cucumber/screenplay`.

The implementation plan must use project-local dependencies:

```sh
bun add --dev @cucumber/cucumber@^10 @cucumber/screenplay tsx gherkin-lint
bunx cucumber-js \
  assets/features/bin/**/*.feature \
  --require-module tsx/cjs \
  --require assets/features/bin/step_definitions/support/**/*.ts \
  --require assets/features/bin/step_definitions/**/*.steps.ts
```

This is intentionally a dependency manifest, not a script surface. Cucumber-JS
is stateful: the runner and step definitions must resolve the same
`@cucumber/cucumber` instance. A `bunx --package @cucumber/cucumber` command can
launch the binary, but step definitions may fail to import the package or may
load a different Cucumber instance. Root `mise.toml` remains the only
user-facing execution surface.

`@cucumber/screenplay` currently peers with Cucumber-JS through version 10. The
first implementation should therefore pin `@cucumber/cucumber@^10` and use
Node 22 through mise for the BDD tasks. Cucumber 12 can be reconsidered when
`@cucumber/screenplay` publishes a compatible peer range.

`bunx --bun cucumber-js` can remain an optional speed experiment after the Node
path is green. The required path must use Node-compatible step definitions:
`node:assert/strict`, `node:child_process`, and `node:fs` instead of Bun-only
globals.

Step definitions must be TypeScript and must execute real scripts through
controlled processes. They must use fixtures and environment variables to avoid
depending on the user's local shell state.

## Mise tasks

Mise is the task surface for this work.

All user-facing BDD, Gherkin, and `xc` verification tasks must be available from
the root `mise.toml`. This avoids scattering task entry points across hidden
scripts or nested task files.

The root `mise.toml` must expose high-level docs and BDD tasks such as:

```text
docs:gherkin:lint
docs:bdd
docs:bdd:dry-run
```

The root `mise.toml` must also expose the `xc` checks used by the bins pilot,
either by moving the existing `config/bin/mise.toml` task definitions into root
or by delegating root tasks to the existing task file with no behavior drift.
The final implementation must provide one user-facing task namespace instead of
two competing task entry points.

No new shell scripts, Node scripts, Bun scripts, package scripts, or ad hoc
executables may be created just to run Gherkin, Cucumber, linting, or `xc`
verification. If an operation needs a command, define it as a mise task.

The BDD tasks may run `bun install --frozen-lockfile` before invoking local
binaries. That keeps dependency setup explicit and repeatable without adding a
second task runner.

## Advanced BDD tools

Screenplay is part of the first bins implementation. The larger frameworks and
AI tooling stay out of the first slice:

- Serenity/JS can be reconsidered when Dots needs richer reports,
  cross-interface acceptance tests, or a larger Screenplay ecosystem.
- CodeceptJS can be reconsidered for browser-heavy end-to-end specs, not for
  shell CLI command discovery.
- Explorbot and AI testing tools can inform future exploratory browser work,
  but they are not acceptance-test infrastructure for `config/bin`.
- Bitloops is relevant as context-capture inspiration, not as a BDD runtime.

## Linting and editor support

The first Gherkin linter candidate is `gherkin-lint`. It supports rules that
match the Dots style goals, including one feature per file, one background per
file, indentation, scenario size, logical Given/When/Then order, only one
`When`, duplicate names, and trailing spaces.

The implementation must add a `.gherkin-lintrc` with conservative rules for the
bins pilot. The first rule set must favor useful feedback over strictness.

The recommended editor extension is the official Cucumber extension for VS Code
and Cursor:

```json
{
  "recommendations": ["CucumberOpen.cucumber-official"]
}
```

Workspace settings must point the extension to the project-local feature and
step paths:

```json
{
  "cucumber.features": ["assets/features/bin/**/*.feature"],
  "cucumber.glue": ["assets/features/bin/step_definitions/**/*.ts"]
}
```

Third-party Gherkin extensions can be researched later if the official extension
does not work for this layout.

## Verification gates

Each task in `assets/specs/bin/tasks.md` must define its own green gate.
An implementation agent can move to the next task only after the current task's
gate passes.

The final bins pilot must include these gates:

- `mise run docs:gherkin:lint`
- `mise run docs:bdd:dry-run`
- `mise run docs:bdd`
- Focused `config/bin` Bun specs for touched scripts.
- `mise exec -- shellcheck <changed-zsh-scripts>`
- `zsh -n <changed-zsh-scripts>`
- `git diff --check`

The final gate can expand if the implementation touches shared behavior.

## Handoff requirements

`assets/specs/bin/HANDOFF.md` must be written for another agent. It must
include:

- The current scope and non-goals.
- The decisions in `assets/specs/bin/decisions.md`.
- The required local skills.
- The `assets/features/bin` Gherkin location.
- The exact task order from `tasks.md`.
- The rule that every task must finish green before the next task starts.
- The command list for every acceptance gate.
- A warning not to create standalone helper scripts for Cucumber, Gherkin,
  docs, linting, or `xc` checks.
- A warning not to rewrite root `install`, `nvim`, `zsh`, or copied guide
  docs outside the bins pilot.

If subagents are used, the handoff must route them through
`subagent-driven-development` and give them disjoint ownership boundaries.

## References

This design uses these references as inputs for the later guides and bins
artifacts:

- [Cucumber Gherkin reference](https://cucumber.io/docs/gherkin/reference/)
- [Cucumber-JS installation](https://cucumber.io/docs/installation/javascript/)
- [Cucumber VS Code extension](https://marketplace.visualstudio.com/items?itemName=CucumberOpen.cucumber-official)
- [cucumber/vscode](https://github.com/cucumber/vscode)
- [Cucumber Language Server](https://github.com/cucumber/language-server)
- [gherkin-lint](https://github.com/gherkin-lint/gherkin-lint)
- [Automation Panda: Writing good Gherkin](https://automationpanda.com/2017/01/30/bdd-101-writing-good-gherkin/)
- [Gherkin best practices](https://github.com/andredesousa/gherkin-best-practices)
- [Awesome BDD](https://awesome-bdd.vercel.app/)
- [Testomat BDD tool survey](https://testomat.io/blog/top-bdd-automation-tools/)
- [Bun bunx documentation](https://bun.com/docs/cli/bunx)
- [Cucumber-JS installation notes](https://github.com/cucumber/cucumber-js/blob/main/docs/installation.md)
- [Cucumber-JS TypeScript transpiling](https://github.com/cucumber/cucumber-js/blob/main/docs/transpiling.md)
- [Cucumber Screenplay](https://github.com/cucumber/screenplay.js)
- [Understanding Screenplay](https://cucumber-school.github.io/screenplay-example/)
- [Serenity/JS Screenplay Pattern](https://serenity-js.org/handbook/design/screenplay-pattern/)
- [Serenity BDD Cucumber Screenplay tutorial](https://serenity-bdd.github.io/docs/tutorials/cucumber-screenplay)
- [CodeceptJS BDD](https://codecept.io/bdd/)
- [Explorbot](https://github.com/testomatio/explorbot)
- [Testomat AI in software testing](https://testomat.io/blog/ai-in-software-testing/)
- [Bitloops](https://github.com/bitloops/bitloops)
- [skills.sh](https://www.skills.sh/)

The optional catalogs and market surveys are research inputs only. They must not
introduce extra tools into the first bins pilot without an explicit follow-up
decision.

## Next steps

After this design is reviewed, create `requirements.md`, `tasks.md`, and
`HANDOFF.md` for `assets/specs/bin`. Then create the minimal guides
artifacts that those files reference. Implementation starts only after the SDD
artifacts are approved.
