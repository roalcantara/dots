<!-- markdownlint-disable-file -->

# DECISIONS: bins BDD living documentation

This file records the current decisions for the bins BDD pilot. Keep it short:
new entries should explain what changed, why it changed, and what future agents
must respect.

## Decision 1: Keep the first pass to two stages

**Decision:** The pilot has exactly two stages: `assets/docs/guides` for shared
guidance and `assets/specs/bin` plus `assets/features/bin` for the
first `config/bin` living documentation.

**Rationale:** Dots covers many languages and folders. A repository-wide cleanup
would delay the BDD lab and mix unrelated concerns into the first Cucumber
slice.

**Consequences:**

- Do not start `assets/specs/install` in this pilot.
- Do not rewrite root `install`.
- Do not expand into `nvim`, Lua, zsh configuration, or copied KB docs unless a
  bins task directly needs one reference.

## Decision 2: Store executable Gherkin under `assets/docs/features`

**Decision:** Bins SDD artifacts live under `assets/specs/bin`, while
feature files and Cucumber glue live under `assets/features/bin`.

**Rationale:** Cucumber tools expect a conventional feature tree. Keeping
`.feature` files outside the spec folder also avoids burying executable living
documentation under a deep planning path.

**Consequences:**

- `assets/specs/bin` contains requirements, design, tasks, decisions, and
  handoff material.
- `assets/features/bin` contains `.feature` files and `step_definitions`.
- Future suites can follow `assets/docs/features/install`,
  `assets/docs/features/nvim`, and `assets/docs/features/zsh` when they exist.

## Decision 3: Use mise as the only user-facing command surface

**Decision:** All repeatable BDD, Gherkin, Cucumber, and `xc` checks must be
available through root `mise.toml`.

**Rationale:** Dots already has many moving parts. Adding hidden runner scripts
or package scripts would create another command surface to remember and debug.

**Consequences:**

- Do not add package scripts.
- Do not add standalone helper scripts for docs, BDD, Gherkin, Cucumber,
  linting, or `xc` checks.
- TypeScript files under `assets/features/bin/step_definitions` are allowed
  because they are Cucumber support code, not general runner scripts.

## Decision 4: Use Cucumber-JS 10 with Node 22 first

**Decision:** The first executable implementation uses
`@cucumber/cucumber@^10`, `@cucumber/screenplay`, `tsx`, and Node 22 through
mise. Bun remains the package manager and command launcher.

**Rationale:** `@cucumber/screenplay` currently peers with Cucumber-JS through
version 10. A local spike confirmed that Cucumber-JS works with Bun-managed
dependencies when the runner and steps resolve the same local package.

**Consequences:**

- A minimal private root `package.json` may exist for dev dependencies only.
- The root package manifest must not contain a `scripts` block.
- Cucumber 12 can be revisited when `@cucumber/screenplay` publishes a
  compatible peer range.

## Decision 5: Use Screenplay from the first step-definition slice

**Decision:** Step definitions should translate Gherkin into Screenplay actors,
tasks or interactions, and questions instead of directly calling world helper
methods.

**Rationale:** Screenplay keeps step definitions thin and gives later CLI,
browser, and cross-interface specs a reusable vocabulary.

**Consequences:**

- Actors represent named terminal users, such as `Alice`.
- Interactions run commands with controlled environment variables.
- Questions inspect observable state such as exit code, stdout, and stderr.
- If `@cucumber/screenplay` becomes a hard blocker, the fallback is a tiny local
  Screenplay-inspired support layer, not ad hoc command helpers in every step.

## Decision 6: Keep advanced BDD tools as research inputs

**Decision:** Serenity/JS, CodeceptJS, Explorbot, Testomat AI tooling, and
Bitloops are not first-slice infrastructure for bins.

**Rationale:** Those tools are valuable, but command discovery and Fabric
listing are shell CLI behaviors. The first slice needs reliable Cucumber and
Screenplay basics before adopting larger reporting or browser-oriented
frameworks.

**Consequences:**

- Mention advanced tools in guidance as references.
- Do not add their dependencies in the bins pilot.
- Reconsider them when a later spec needs reporting, browser automation,
  exploratory testing, or richer Screenplay ecosystem support.

## Decision 7: Document current shell conventions without FCIS

**Decision:** `assets/specs/bin/CONFIG_BIN_GUIDE.md` documents practical
`config/bin` conventions, but it must not prescribe Functional Core,
Imperative Shell, pure-function layering, or a repo-wide shell architecture.

**Rationale:** Dots does not follow FCIS and should not pretend to. The guide is
an exercise in shared language for bins, not a shell architecture migration.

**Consequences:**

- `CONFIG_BIN_GUIDE.md` should cover zsh, `xc-usage`, `##?` help comments,
  non-interactive execution, controlled test environments, graceful dependency
  errors, and mise-driven verification.
- Avoid broad shell refactors while implementing BDD infrastructure.

## Decision 8: Start with official editor support

**Decision:** Recommend the official Cucumber VS Code extension first:
`CucumberOpen.cucumber-official`.

**Rationale:** It aligns with Cucumber-JS and the Cucumber language server
ecosystem. Third-party extensions can be evaluated after the project-local
feature and glue paths are stable.

**Consequences:**

- `.vscode/extensions.json` should recommend the official extension.
- Workspace settings should point to `assets/features/bin/**/*.feature`
  and `assets/features/bin/step_definitions/**/*.ts`.
