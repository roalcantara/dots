# Portable CLI tools (`config/bin`)

Portable executable scripts and CLI helpers linked to `~/.local/bin/`.

## Overview

Scripts placed in `config/bin` are standalone executables available on `$PATH`. Unlike shell functions, they can be invoked across subshells, background runners, and tools like `fzf --preview` or `xargs`.

During `mise bootstrap`, all executable scripts in `config/bin/` are symlinked into `~/.local/bin/`.

## Tools

| Tool | Purpose | Example |
| --- | --- | --- |
| [`xc`](xc) | Interactive launcher and dispatcher for `xc-*` tools | `xc` |
| [`xc-fabric`](xc-fabric) | Fabric AI pattern runner with fzf picker and terminal UI | `xc-fabric ls --raw` |
| [`xc-git`](xc-git) | Git helpers (branch preview, fixup suggestions, fzf log) | `xc-git fixup-suggest --dry-run .` |
| [`xc-puts`](xc-puts) | Formatted, colored console output for scripts | `xc-puts --green "Done"` |
| [`xc-sec`](xc-sec) | Redact sensitive information in files with backups | `xc-sec --help` |
| [`xc-toast`](xc-toast) / [`toast`](toast) | Terminal toast overlay notifications | `toast "Build completed" 2` |
| [`xcg`](xcg) | Interactive Git branch manager using fzf | `xcg` |
| [`barrel`](barrel) | TypeScript/JavaScript barrel (`index.ts`) export generator | `barrel ./src -r` |
| [`recase`](recase) | File and string naming convention converter | `recase MyFile.ts --kebab` |
| [`gen`](gen) | Shell completion generator from command usage specs | `gen mycmd` |
| [`dots`](dots) | Dotfiles manager and runtime diagnostics | `dots doctor` |
| [`gitx`](gitx) | Interactive Git rebase and history dispatcher | `gitx fzl` |
| [`psc`](psc) / [`pss`](pss) | Gopass secret copier (`psc`) and revealer (`pss`) | `psc github/token` |
| [`zsys`](zsys) | Path, environment, and system diagnostics | `zsys --help` |
| [`yb`](yb) | macOS Yabai tiling manager helper | `yb --help` |

## Authoring conventions

Scripts in this directory use the [Usage CLI](https://usage.jdx.dev) specification with inline `#USAGE` annotations and native shebang:

```zsh
#!/usr/bin/env -S usage zsh
# shellcheck shell=bash disable=SC2154,SC2168

#USAGE version "0.1.0"
#USAGE about "One-line summary of tool"
#USAGE arg "<file>" help="Input file path"
#USAGE flag "-f --force" help="Force execution"
#USAGE example "xc-sample input.txt --force"

set -euo pipefail

FILE="${usage_file:-}"
FORCE="${usage_force:-false}"

# Command implementation
```

## Tasks

Tasks defined in `config/bin/mise.toml`:

```sh
mise run setup    # Ensure xc-fabric dependencies (fabric-ai, bat, fzf)
```
