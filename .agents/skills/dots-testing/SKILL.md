---
name: dots-testing
description: Canonical testing workflow for Dots — SDD specs, Gherkin features, Bun integration specs under assets/, and mise verification gates. Load when adding or changing tests, fixtures, or Cucumber support.
---

# Dots — testing

## Verification layers

| Layer       | Path                           | Question                |
| ----------- | ------------------------------ | ----------------------- |
| SDD         | `assets/specs/<slug>/`         | What and why?           |
| Gherkin     | `assets/features/<domain>/`    | What does the user see? |
| Integration | `assets/integration/<domain>/` | Does the script behave? |

## Mise gates

From repository root:

```bash
mise run -C assets test bin      # BDD + integration for config/bin
mise run test                    # Docker CST + root CI parity (when applicable)
```

From `assets/` directory context:

```bash
mise run bdd lint --domain bin
mise run bdd run --domain bin
mise run integration bin all
mise run integration bin xc-usage --scenario help
```

## Bun integration specs

- Location: `assets/integration/<domain>/*.spec.ts`
- Runner: `bun test` via mise `integration` task
- Use `it()` not `test()` for new specs
- Table-driven cases preferred
- Set `CONFIG_BIN` / PATH via mise task (do not hardcode repo paths in specs)
- No mocking for subprocess CLI tests — run real scripts

## Gherkin

- Features: `assets/features/<domain>/`
- Support: `assets/features/support/`
- Steps: `assets/features/step_definitions/<domain>/`
- Screenplay: keep steps thin; logic in support layer

See [`assets/guides/BDD_GUIDE.md`](../../assets/guides/BDD_GUIDE.md) and
[`assets/guides/TESTING_GUIDE.md`](../../assets/guides/TESTING_GUIDE.md).

## Skills to load

| Situation          | Skill                                           |
| ------------------ | ----------------------------------------------- |
| Gherkin authoring  | `bdd-gherkin-specification`, `cucumber-gherkin` |
| Scenario design    | `bdd-scenarios`, `bdd-patterns`                 |
| Bun test API       | `bun-development`, `bun-runtime`                |
| Debugging failures | `systematic-debugging`                          |

## Shell checks

- `shellcheck` on `config/bin/*` and shell scripts
- `zsh -n` on Zsh function files when touched

Do not add Jest, Vitest, or SQLite patterns — they are not part of Dots.
