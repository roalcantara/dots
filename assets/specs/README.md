<!-- markdownlint-disable-file -->

# Dots feature specs

Planning artifacts (SDD) live under **`assets/specs/<feature-slug>/`**.

Executable verification lives elsewhere:

| Kind                      | Path                  |
| ------------------------- | --------------------- |
| BDD living docs (Gherkin) | `assets/features/`    |
| Integration checks        | `assets/integration/` |
| Project guides            | `assets/guides/`      |

Each spec folder SHOULD contain `requirements.md`, `design.md`, and `tasks.md`.

## Specs

| Slug                                             | Purpose                                                               |
| ------------------------------------------------ | --------------------------------------------------------------------- |
| [project-structure](project-structure/design.md) | Canonical `assets/` layout, mise tasks, agent workflow                |
| `bin/`                                           | BDD pilot umbrella — migrated from `assets/specs/bin` in Task 3 |
| [macos-tiling-wm-experiment](macos-tiling-wm-experiment/design.md) | Omarchy-style yabai + SIP-on WM comparison                 |
| [mise-bootstrap](mise-bootstrap/design.md)       | Replace `install` with `mise bootstrap` (macOS, Debian/Ubuntu, images) |

## Do not use

- `docs/superpowers/` — redirect agent output to `assets/specs/<feature-slug>/`
- `assets/docs/` — removed after project-structure migration
