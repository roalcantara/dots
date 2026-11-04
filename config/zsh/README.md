# Zsh configuration

Modular Zsh configuration powered by [Zimfw](https://github.com/zimfw/zimfw) and [Powerlevel10k](https://github.com/romkatv/powerlevel10k).

## Overview

The configuration is organized under `config/zsh/`:

```text
config/zsh/
├── .zshrc               # Entrypoint sourcing modules and aliases
├── .zshenv              # Environment variables sourced for all shells
├── .zprofile            # Login shell setup
├── .zlogin              # Post-login execution
├── .zimrc               # Zim module declarations
├── .p10k.zsh            # Powerlevel10k prompt configuration
└── opt/
    ├── rc.d/            # Modular lifecycle scripts (functions only)
    ├── plugins/         # Plugin setup and configurations
    ├── keybindings/     # Custom ZLE keymaps and fuzzy-finder widgets
    ├── completions/     # Autoloadable shell completion functions
    └── aliases/         # Command shortcuts grouped by domain
```

## Lifecycle modules (`opt/rc.d/`)

Each file under `opt/rc.d/` defines isolated functions that `.zshrc` invokes in a controlled sequence:

| Script | Purpose | Declares |
| --- | --- | --- |
| `env.zsh` | Shell options, PATH search order, Homebrew shell environment, and editor configuration | `env::core`, `env::options`, `env::paths`, `env::homebrew`, `env::editor`, `_has_command` |
| `term.zsh` | Terminal detection (Ghostty, Warp, etc.), minimal terminal mode gates, and shell integration | `term::profile`, `term::prompt` |
| `theme.zsh` | Color palettes (`LS_COLORS`, `EXA_COLORS`) and fast-syntax-highlighting themes | `theme::palette` |
| `zim.zsh` | Zim completion dump location and atomic caching for `zim-mise` | `zim::dumpfile`, `zim::mise_cache`, `zim::load`, `zim::overrides` |
| `sys.zsh` | Secrets loading (`~/.config/.env`), private runtime directory permissions, one-time error alerts, and startup benchmarks | `sys::dotenv`, `sys::fix_xdg_runtime_dir`, `sys::bench` |

## Adding aliases and functions

- **Aliases:** Add short commands to domain files under `opt/aliases/` (e.g. `git.zsh`, `docker.zsh`, `util.zsh`).
- **Autoloaded completions:** Place completion scripts prefixed with an underscore in `opt/completions/` (e.g. `_mytool`).
- **Complex scripts:** Executable helpers and CLI tools belong in `config/bin/`, not inline shell functions, so subshells and non-interactive scripts can invoke them.

## Benchmarking startup

Run the built-in startup benchmark:

```sh
sys::bench --startup
```
