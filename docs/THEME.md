---
title: Shell theme
description: One switchable dark theme for the shell-side tools, chosen in config/dots/config.toml
---

# Shell theme

> Last reviewed: 2026-11-17

Every shell-side tool takes its colours from one active theme. This page covers the folders, `mise run theme:build`
and how to add a theme. The design and its trade-offs are in the
[spec](superpowers/specs/2026-11-17-shell-ux-theme-design.md).

## Theme folders

[`config/theme/themes/`](../config/theme/themes/) holds one folder per theme:

- `catppuccin-mocha`, the default when no theme is chosen, and `catppuccin-macchiato`.
- `dracula`: [Dracula](https://draculatheme.com), the colours fzf and bat used before themes. zsh-patina ships no
  Dracula, so its `zsh-patina.toml` maps zsh-patina's scopes onto the Dracula palette.
- `tokyonight-storm`: Tokyo Night ([folke/tokyonight.nvim](https://github.com/folke/tokyonight.nvim)) around the
  hand-made palette the shell had before themes: its `ls_colors` and `EZA_COLORS` are that palette, unchanged, so
  `la` looks as it did. bat reads its theme from [`config/bat/themes/`](../config/bat/themes/) (Apache-2.0).

Each folder carries one small file per tool:

| File | Read by |
| --- | --- |
| `theme.ghostty` | Ghostty, through its `config-file = ?auto/theme.ghostty` include |
| `env.zsh` | zsh, at startup |
| `env.bash` | bash, at startup |
| `ls_colors` | zsh and bash (`LS_COLORS`), through `eza.sh` |
| `eza.sh` | zsh and bash: `EZA_CONFIG_DIR`, `LS_COLORS` (and `EZA_COLORS` where a theme sets one); the `eza` theme's, when the config file names one |
| `eza/theme.yml` | eza, through `EZA_CONFIG_DIR` (the vendored [catppuccin/eza](https://github.com/catppuccin/eza) theme, MIT) |
| `zsh-patina.toml` | zsh-patina, through its `file:` theme |
| `lig.toml` | Lig, as its whole config: `~/.config/lig/config.toml` links to the active theme's copy |

## Switching

The theme is two strings in [`config/dots/config.toml`](../config/dots/config.toml), linked to
`~/.config/dots/config.toml`. Edit them, then open a new shell (and reload Ghostty with `cmd+shift+,`):

```toml
[theme]
name = "tokyonight-storm"   # every tool
eza = "dracula"             # optional: eza's and ls's colours from another theme
```

The committed file is also what a new machine starts with. The theme names are the folders under
`config/theme/themes/`.

A new shell reads the file with builtins (`config/theme/config.zsh`; bash has the same loop in `config/bash/bashrc`),
sources `name`'s `env.zsh` and the `eza` theme's `eza.sh` (`name`'s own when `eza` is left out). Ghostty and Lig
cannot read the file, so they follow a link, `${XDG_STATE_HOME:-$HOME/.local/state}/dots/theme/current`: when the
file names another theme, the shell points the link at it with zsh's own `ln` and restarts zsh-patina's daemon, which
caches its theme. Nothing else runs at startup.

The `zsh-patina` command reads `$DOTS_THEME_DIR` from its config, and only an interactive zsh exports it, so run
`zsh-patina list-themes` or `zsh-patina check` from zsh (or set `DOTS_THEME_DIR` first), not from bash.

A name that is not a theme folder is reported once, at the first prompt, and its tools keep their built-in colours.
Without the file (a bare container, say), the shell uses the link a previous shell left, or no theme at all.

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
| Lig | `lig.toml` | [`config/lig/config.toml`](../config/lig/config.toml) links to `…/theme/current/lig.toml`; open tabs recolour live |

## Tab menus

Completions pop up under the cursor as you type, from [Lig](https://github.com/KevenGoncalves/lig): Fig's specs for
about 800 commands, and zsh's own completion for the rest (`completers = ["shell"]`, so `lida` comes from `_lida` and
the `config/bin` scripts from their usage completions). `Tab` and the arrows move through the popup, `Enter` accepts,
`Esc` closes it.

- `config/zsh/opt/rc.d/lig.zsh` sources Lig's integration from a cache (`mise run zsh:lig`, run by bootstrap): no
  `lig` process at startup. After `brew upgrade lig` the shell starts without the popup and says to rerun the task.
- Lig's history (`Ctrl-R`) and its online package search are off; `Ctrl-R` keeps the shell's own binding.
- `LIG_DISABLE=1 zsh` starts a shell without Lig; scripts, `zsh -c` and the Docker images never enter it.

With the popup closed or empty, `Tab` opens [fzf-tab](https://github.com/Aloxaf/fzf-tab)'s menu, coloured by the theme's `FZF_THEME_OPTS`; its group
headers take `DOTS_FZF_TAB_GROUP_COLORS`. The list is always bare: a prompt line and the candidates on the terminal's
own background, with no boxes. A preview pane, framed and on the theme's preview background, opens on the right only
when the menu has something to preview: a path, a flag or a subcommand with a description. A plain list of values
(`mise run theme:build <Tab>`, any usage `choices`) has none, so it shows no pane; `config/zsh/opt/plugins/fzf-tab.zsh` decides
per menu with `zstyle -e`, from the candidates fzf-tab holds while it looks its styles up.

The preview window shows:

- a directory through `$DOTS_LA_CMD` — the same command `la` expands to (`config/zsh/opt/aliases/ls.zsh`), so the
  preview and a typed `la` match;
- a text file in `bat`;
- anything else (an image, a binary) as `file -b` describes it;
- a subcommand or flag through `cmdhelp`, its `--help` coloured by `bat`.

`file-list all` is gone from `config/zsh/opt/rc.d/env.zsh`, so file candidates stay one row per name instead of
`ls -l` lines.

## Risky commands

While you type, `rm -rf`, `sudo rm`, `git push --force`, `git reset --hard`, `git clean -f`, `chmod -R 777`,
`dd of=/dev/…` and `mkfs` paint the command and its flags in the theme's `DOTS_WARN_STYLE` (red background,
crust text, bold) over zsh-patina's own colours — `rm -rf` is cued in `rm -rf build/`, the path is not, and for
`dd` the span ends at the `of=/dev/…` argument. For `sudo rm` the cue covers `rm` alone, so `sudo` keeps its usual
colour. The cue leaves `rm x`, `rm -f x` and a name that merely mentions a command (`cat rm-rf-notes.txt`) alone.

This is a `line-pre-redraw` hook (`config/zsh/opt/plugins/warn-highlight.zsh`) registered after zsh-patina. Option
(a) from the spec — zsh-syntax-highlighting's pattern highlighter — is not available here: zsh-patina is the
highlighter and zsh-syntax-highlighting is not loaded, so the pattern highlighter would have meant a second
highlighting engine. zsh-patina removes only its own `memo=zsh_patina` regions, so the warning entry layers on top.

The community recipe for this cue is zsh-syntax-highlighting's pattern highlighter,
`ZSH_HIGHLIGHT_PATTERNS+=('rm -rf *' 'fg=white,bold,bg=red')`; Prezto's example is `'rm*-rf*'` in the same style.
Both paint the whole match, operands included, so the narrower span here is a deliberate improvement rather than a
divergence: a pattern cannot tell `rm -rf build/` from `rm -rf` alone, and a literal glob cannot follow `-r -f`,
`sudo rm` or a command after `;`. zsh-patina offers no pattern API of its own
([README](https://github.com/michel-kraemer/zsh-patina)); issue
[#95](https://github.com/michel-kraemer/zsh-patina/issues/95) documents that a `line-pre-redraw` hook registered
after it wins on overlap, which is how this hook layers. Zsh 5.10 adds `layer=NN` to `region_highlight` for explicit
precedence; once the images and Homebrew carry it, the hook can stop relying on load order.

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
mise run theme:build                 # every theme
mise run theme:build catppuccin-mocha
```

A file whose first line starts with `# hand-made` (`tokyonight-storm`'s and `tokyonight-storm-custom`'s) is skipped: it is edited by hand.

The task writes `config/theme/themes/<name>/ls_colors`. Run it after editing a theme's palette, then commit the
file.

### Icon colours

`tokyonight-storm-custom` colours eza's icons per file, the VS Code way, from
[nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) (MIT). File names keep their `ls_colors`
colours:

```sh
mise run theme:icons                          # tokyonight-storm-custom
mise run theme:icons catppuccin-mocha
```

The task downloads the colours and rewrites the block between `# BEGIN devicons` and `# END devicons` in the
theme's `eza/theme.yml`. A rerun replaces hand edits inside the block. To give a name its icon's colour, add it to
`ls_colors` (`*.gitignore=0;38;2;245;77;39`).

## Add a theme

1. Copy a folder under `config/theme/themes/` and edit its files.
2. Add the folder name to the `choices` of `theme:build` (`config/theme/tasks.toml`); a spec keeps the list in step with the
   folders. Give it an `eza.sh` (eza's and ls's colours, so other themes can borrow them) like the others.
3. Run `mise run theme:build <name>`, then commit the folder and the `choices` entry. Set `name` (or `eza`) in
   `config/dots/config.toml` to try it.
4. A `BAT_THEME` bat does not ship goes in `config/bat/themes/` as a `.tmTheme`; bootstrap runs `bat cache --build`
   (run it once by hand on this machine).

## Future: full integration

This round themes the shell. A later round may follow Omarchy all the way, where one `name` in the config file re-themes
everything: Neovim, VS Code, btop, television's UI, kodexb, dinky, zentty, Ghostty's window chrome, and the macOS
wallpaper and accent.

The layout is built for that. A tool joins by adding its own file to each theme folder (`nvim.lua`, `vscode.json`,
`btop.theme`, …) plus a line in the shell's theme loader that links or reloads it, with no change to the folders that exist.
This page lists these candidates so the next round starts from it.
