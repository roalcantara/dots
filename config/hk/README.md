# hk Configuration

This directory contains the user-level configuration for [hk](https://hk.jdx.dev),
the Rust-native git hook manager.

## Files

- [hkrc.pkl](file:///Users/roalcantara/Work/dots/config/hk/hkrc.pkl) - The
  user-level configuration containing defaults for `hk`.

## Setup and Symlinks

During the dotfiles installation, the `hkrc.pkl` file is symlinked to the
standard `hk` user configuration path:

```sh
~/.config/hk/config.pkl -> ~/.local/share/dots/config/hk/hkrc.pkl
```

This distributes identical high-performance defaults (e.g., parallel
execution, auto-mise detection) across all machines running these dotfiles.

## Available hk Commands

Once installed, you can use `hk` directly or via `mise`:

- `hk check` (or `mise x hk -- hk check`): Standalone manual check or CI
  entry-point to lint staged files.
- `hk fix` (or `mise x hk -- hk fix`): Manually trigger auto-formatting on all
  staged files (which normally runs automatically on commit).
- `hk run <hook>`: Manually run all steps registered for a specific hook (e.g.
  `hk run pre-commit`).
