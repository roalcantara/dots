<!-- markdownlint-disable-file -->

# TASKS: bins BDD living documentation

`tasks.md` is the canonical implementation checklist. `implementation-plan.md`
is the expanded handoff recipe with examples, but agents execute from this
file and mark each item only after its gate is green.

## Task 1: Guide docs

- [x] Create `assets/guides/GLOSSARY.md`.
- [x] Create `assets/guides/BDD_GHERKIN_GUIDE.md`.
- [x] Create `assets/guides/TESTING_GUIDE.md`.
- [x] Create `assets/guides/MISE_GUIDE.md`.
- [x] Create `assets/specs/bin/CONFIG_BIN_GUIDE.md`.
- [x] Create `assets/specs/bin/SKILL.md`.
- [x] Run `! rg -n "TO[D]O|TB[D]|\\.\\.all|lorem[ ]ipsum" assets/docs/guides`.
- [x] Run `git diff --check`.
- [x] Commit Task 1 with `git commit --no-verify -m "docs(bins): add foundation and task docs"`.

## Task 2: SDD artifacts

- [x] Create `assets/specs/bin/requirements.md`.
- [x] Create `assets/specs/bin/design.md`.
- [x] Create `assets/specs/bin/decisions.md`.
- [x] Create `assets/specs/bin/tasks.md`.
- [x] Create `assets/specs/bin/HANDOFF.md`.
- [x] Update `assets/specs/README.md` for Dots and `bins`.
- [x] Run `! rg -n "kb|Entry Action Panel|Raycast|CLAUDE.md" assets/specs/README.md assets/specs/bin/requirements.md assets/specs/bin/HANDOFF.md`.
- [x] Run `git diff --check`.
- [x] Commit Task 2 with `git commit --no-verify -m "docs(bins): record BDD decisions"`.

## Task 3: Gherkin features

- [x] Create `assets/features/bin/command-discovery.feature`.
- [x] Create `assets/features/bin/fabric-listing.feature`.
- [x] Create `.gherkin-lintrc`.
- [x] Create minimal private `package.json` with `gherkin-lint` and no scripts.
- [x] Run `mise run docs:gherkin:lint`.
- [x] Commit Task 3 with `git commit --no-verify -m "test(bins): add Gherkin features"`.

## Task 4: Cucumber step definitions

- [x] Create `assets/features/bin/step_definitions/support/paths.ts`.
- [x] Create `assets/features/bin/step_definitions/support/world.ts`.
- [x] Create Screenplay command activities and questions.
- [x] Create command discovery steps.
- [x] Create Fabric listing steps.
- [x] Run `mise run docs:bdd:dry-run`.
- [x] Run `mise run docs:bdd`.
- [x] Commit Task 4 with `git commit --no-verify -m "test(bins): add Cucumber step definitions"`.

## Task 5: Tooling and editor support

- [ ] Create `.vscode/extensions.json`.
- [ ] Update minimal private `package.json` with Cucumber BDD dev dependencies and no
  scripts.
- [ ] Update `assets/.vscode/settings.json`.
- [ ] Update root `mise.toml`.
- [ ] Run `mise run docs:gherkin:lint`.
- [ ] Run `mise run docs:bdd:dry-run`.
- [ ] Run `mise run docs:bdd`.
- [ ] Commit Task 5 with `git commit --no-verify -m "chore(bdd): add Cucumber tooling tasks"`.

## Task 6: Final verification

- [ ] Run focused `config/bin` Bun specs for touched scripts.
- [ ] Run `mise exec -- shellcheck <changed-zsh-scripts>` when zsh changes.
- [ ] Run `zsh -n <changed-zsh-scripts>` when zsh changes.
- [ ] Run `git diff --check`.
- [ ] Confirm no standalone BDD runner scripts were added.
- [ ] Commit Task 6 with `git commit --no-verify -m "fix(bins): finish BDD pilot gates"` if cleanup changes are needed.

## Execution rule

An agent can move to the next task only after every acceptance gate for the
current task is green. If a gate cannot run, document the blocker before
continuing.
