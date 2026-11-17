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

## Tab menus

`Tab` opens [fzf-tab](https://github.com/Aloxaf/fzf-tab)'s menu, framed by `--style=full` and coloured by the theme's
`FZF_THEME_OPTS`; its group headers take `DOTS_FZF_TAB_GROUP_COLORS`. The preview window shows:

- a directory through `$DOTS_LA_CMD` — the same command `la` expands to (`config/zsh/opt/aliases/ls.zsh`), so the
  preview and a typed `la` match;
- a text file in `bat`;
- anything else (an image, a binary) as `file -b` describes it;
- a command, flag or other candidate through `cmdhelp` when it is not a path.

`file-list all` is gone from `config/zsh/opt/rc.d/env.zsh`, so file candidates stay one row per name instead of
`ls -l` lines.

## Risky commands

While you type, `rm -rf`, `sudo rm`, `git push --force`, `git reset --hard`, `git clean -f`, `chmod -R 777`,
`dd of=/dev/…` and `mkfs` paint the whole line in the theme's `DOTS_WARN_STYLE` (red background, crust text, bold)
over zsh-patina's own colours. The cue leaves `rm x`, `rm -f x` and a name that merely mentions a command
(`cat rm-rf-notes.txt`) alone.

This is a `line-pre-redraw` hook (`config/zsh/opt/plugins/warn-highlight.zsh`) registered after zsh-patina. Option
(a) from the spec — zsh-syntax-highlighting's pattern highlighter — is not available here: zsh-patina is the
highlighter and zsh-syntax-highlighting is not loaded, so the pattern highlighter would have meant a second
highlighting engine. zsh-patina removes only its own `memo=zsh_patina` regions, so the warning entry layers on top.

## Safety net

`rm` in an interactive shell is [gomi](https://gomi.dev): files move to a trash you can restore from instead of
being unlinked. `config/zsh/opt/aliases/safety.zsh` and `config/bash/bashrc` alias it only when `gomi` is on
`PATH`; scripts, `zsh -c` and `bash -c` keep the real `rm`, and `\rm` or `command rm` deletes immediately.

```sh
rm notes.md              # moves notes.md to the trash
gomi --restore           # pick a trashed file and put it back
gomi --dry-run=table --prune=30d   # what --prune=30d would remove
```

On macOS and on Linux gomi uses the freedesktop trash: `$XDG_DATA_HOME/Trash` (`~/.local/share/Trash` by default),
the file under `files/` and its original path and deletion time under `info/`. On macOS it does not use `~/.Trash`.
Nothing empties the trash on a schedule; `gomi --prune=<duration>` does, and `--dry-run` shows the list first.

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
