# Shell theme

`config/theme` holds the shell-side theme folders. The canonical guide, including how to switch themes and which
tool reads which file, is [`docs/THEME.md`](../../docs/THEME.md).

Each folder under `themes/` is one selectable theme; `catppuccin-mocha`, `catppuccin-macchiato`, `dracula` and `tokyonight-storm` ship today.

The theme in use is chosen in [`config/dots/config.toml`](../dots/config.toml): `name` for every tool, `eza` for
eza's and ls's colours. [`config.zsh`](config.zsh) reads it.
