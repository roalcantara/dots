# Requirements

- Refactor Homebrew management from individual `brew:*` tasks to a namespaced `bundle:*` hierarchy using `mise`.
- Provide a clean, logical command/subcommand organization:
  - Default `mise run bundle` to `mise run bundle list`.
  - Use subcommands for actions: `install`, `dump`, `check`, `update`, `clean`.
  - Use nested subcommands for `add` and `rm` to handle mutually exclusive types (formulae, cask, tap, etc.).
- Implement DRY configuration using `mise`'s `usage` spec features (flagsets, nested commands).
- Automate Homebrew setup (`brew:setup`) and environment loading (`brew:load`) as dependencies.
- Consolidate documentation into a clear "Configuration Recipes" section in the README.

# Design

## Command Structure

The primary interface will be `mise run bundle`.

### Primary Subcommands
| Command | Description |
| :--- | :--- |
| `bundle list` | List all dependencies (Default) |
| `bundle install` | Install all dependencies |
| `bundle dump` | Generate Brewfile from installed packages |
| `bundle check` | Check installation state |
| `bundle update` | Update/Upgrade packages |
| `bundle clean` | Clean Homebrew |

### `add`/`rm` Subcommands
| Command | Usage |
| :--- | :--- |
| `bundle add <type> <name>` | Add a dependency |
| `bundle rm <type> <name>` | Remove a dependency |

Types: `formulae`, `cask`, `tap`, `mas`, `uv`, `go`, `cargo`, `npm`, `krew`, `vscode`, `flatpak`.

## Implementation Details

- Use a global `flagset` named `brewfile` for the optional `--file` flag: `default "${HOME}/.config/homebrew/Brewfile"`.
- Use KDL-based `usage` spec for all task arguments and subcommands.
- Task dependencies (`depends = ["brew:load"]`) will be maintained.

## Documentation
- Remove redundant header comments from `mise.toml`.
- Add "Homebrew Configuration" section to README.
- Add `assets/guides/homebrew-recipes.md` for specific configuration recipes.

# Tasks

1.  **Refactor `mise.toml`**: Implement the new `bundle` command hierarchy and `usage` specs.
2.  **Documentation Cleanup**: Update README and add `assets/guides/homebrew-recipes.md`.
3.  **Verification**: Test all `bundle` subcommands and verify help output.
