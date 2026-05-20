<!-- markdownlint-disable-file -->

# Dots BDD guide

Dots uses Behaviour-Driven Development for living documentation of user-visible
command behaviour. The first suite covers `config/bin`; the pattern extends to
any domain with user-facing CLI contracts.

## Verification layers

| Layer | Location | Role |
| --- | --- | --- |
| SDD (specs) | `assets/specs/<slug>/` | Requirements, design, decisions, tasks — the written plan. |
| Gherkin (features) | `assets/features/<domain>/` | User-visible scenarios that Cucumber executes. |
| Integration | `assets/integration/<domain>/` | Subprocess specs that verify script exit codes, stdout, and stderr. |

Each layer answers a different question: specs answer *what and why*, features
answer *what the user sees*, integration specs answer *does the script behave*.

## Folder layout

- `assets/specs/<feature-slug>/` — SDD artifacts (`requirements.md`, `design.md`, `tasks.md`, `HANDOFF.md`)
- `assets/features/<domain>/` — Gherkin `.feature` files for a domain
- `assets/features/support/` — shared Cucumber support (world, Screenplay helpers)
- `assets/features/step_definitions/<domain>/` — domain-specific step definitions
- `assets/integration/<domain>/` — Bun subprocess specs and fixtures
- `assets/features/` — Gherkin lint configuration and `.feature` files

## Screenplay in Dots

Dots uses the Screenplay pattern to keep Cucumber step definitions thin and
reusable. Steps translate Gherkin into actor activities and questions.

- **Actors** represent named terminal users (for example `Alice`).
- **Tasks** express command-level intent, such as listing available commands.
- **Interactions** run shell commands with controlled environment variables.
- **Questions** inspect observable results, such as exit code and stdout.

Command execution and assertions live behind reusable Screenplay activities and
questions under `assets/features/support/`. Step definition files only translate
Gherkin phrases — they do not spawn processes or run assertions directly.

## When to add what

- New user-visible CLI behaviour → add a feature scenario under `assets/features/<domain>/`
- CLI contract, exit codes, or subprocess output → add an integration spec under `assets/integration/<domain>/`
- Normative API, protocol, or architectural contract → add SDD design under `assets/specs/<feature-slug>/`
- Shared terms or cross-domain behaviour → update `assets/guides/GLOSSARY.md`

## Related guides

- [BDD_GHERKIN_GUIDE.md](BDD_GHERKIN_GUIDE.md) — how to write feature files
- [TESTING_GUIDE.md](TESTING_GUIDE.md) — how to run verification gates
