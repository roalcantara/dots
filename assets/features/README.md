<!-- markdownlint-disable-file -->

# Dots BDD features

Living documentation written as Gherkin scenarios and verified by Cucumber.

## Layout

| Path | Purpose |
| --- | --- |
| `<domain>/` | Gherkin `.feature` files for a domain |
| `support/` | Shared Cucumber support (world, Screenplay helpers) |
| `step_definitions/<domain>/` | Domain-specific step definitions |
| `.gherkin-lintrc` | Gherkin lint configuration |

## Domains

- `bin/` — `config/bin` command discovery and Fabric listing
