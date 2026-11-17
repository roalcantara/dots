---
title: Shell theme
description: One switchable dark theme for the shell-side tools, from the theme folders to dots theme
---

# Shell theme

> Last reviewed: 2026-11-17

Every shell-side tool takes its colours from one active theme. This page covers the folders, `mise run theme:build`
and how to add a theme. The design and its trade-offs are in the
[spec](superpowers/specs/2026-11-17-shell-ux-theme-design.md).

## Theme folders

[`config/theme/themes/`](../config/theme/themes/) holds one folder per theme; `catppuccin-mocha` is the default and
`catppuccin-macchiato` proves switching works. Each folder carries one small file per tool:

| File | Read by |
| --- | --- |
| `theme.ghostty` | Ghostty, through its `config-file = ?auto/theme.ghostty` include |
| `env.zsh` | zsh, at startup |
| `env.bash` | bash, at startup |
| `ls_colors` | zsh and bash (`LS_COLORS`) |
| `eza/theme.yml` | eza, through `EZA_CONFIG_DIR` (the vendored [catppuccin/eza](https://github.com/catppuccin/eza) theme, MIT) |
| `zsh-patina.toml` | zsh-patina, through its `file:` theme |

## Switching

`dots theme` lists the themes and marks the active one with `*`; `dots theme <name>` makes one active:

```sh
dots theme                          # list, with * on the active theme
dots theme catppuccin-macchiato     # switch
```

The active theme is the `current` link,
`${XDG_STATE_HOME:-$HOME/.local/state}/dots/theme/current`. A new shell picks up its `env.zsh`; Ghostty reads
`theme.ghostty` through the `auto` link in this folder and reloads with `cmd+shift+,` (a new window also works).
Switching also restarts zsh-patina's daemon, which caches its theme.

When the link is missing or dangling, everything falls back to `catppuccin-mocha`. If that folder is missing too
(a bare container, say), the theme variables are left unset and each tool keeps its built-in colours.

## What reads the theme

| Tool | File | How |
| --- | --- | --- |
| bat | `env.zsh`, `env.bash` | `BAT_THEME` |
| delta | `env.zsh` | `BAT_THEME` (its own `syntax-theme` is gone) |
| fzf, fzf-tab | `env.zsh` | `FZF_THEME_OPTS`, `DOTS_FZF_TAB_GROUP_COLORS` |
| zsh-autosuggestions | `env.zsh` | `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE` |
| eza (and `la`) | `env.zsh`, `env.bash` | `EZA_CONFIG_DIR` → `eza/theme.yml` |
| zsh and bash listings | `ls_colors` | `LS_COLORS` |
| mise | `env.zsh`, `env.bash` | `MISE_COLOR_THEME` |
| glow | `env.zsh`, `env.bash` | `GLOW_STYLE` |
| zsh-patina | `zsh-patina.toml` | `theme = "file:$DOTS_THEME_DIR/zsh-patina.toml"` |
| powerlevel10k | `env.zsh` | `DOTS_P10K_*` |
| Ghostty | `theme.ghostty` | its `config-file = ?auto/theme.ghostty` include |

## Regenerate the colours

`ls_colors` comes from [vivid](https://github.com/sharkdp/vivid) and is committed, so no shell start runs vivid:

```sh
mise run theme:build                 # both themes
mise run theme:build catppuccin-mocha
```

The task writes `config/theme/themes/<name>/ls_colors`. Run it after editing a theme's palette, then commit the
file.

## Add a theme

1. Copy a folder under `config/theme/themes/` and edit its files.
2. Add the folder name to the `choices` of `dots theme` (`config/bin/dots`) and `theme:build` (`mise.toml`); a spec
   keeps the two lists in step with the folders.
3. Run `mise run theme:build <name>` and commit the folder with the two `choices` entries.
