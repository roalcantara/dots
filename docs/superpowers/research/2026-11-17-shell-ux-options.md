# Shell UX options — research

Options for a modern, useful and beautiful terminal: autosuggestions, Tab completion, previews, and cues for risky
commands. They are measured against today's zsh + zim + fzf-tab + zsh-patina + p10k + Ghostty setup. Every option
must run on macOS and Linux, and options beyond zsh were in scope. The direction is fish, Catppuccin and Omarchy.
The illustrated version, with screenshots, is the artifact "Shell UX Field Guide"
(<https://claude.ai/code/artifact/c4a7a886-0af8-437e-bfa2-329395d81093>). Stars and last push are from the GitHub API
on 2026-11-17.

**Status:** Adopted: see
[`docs/superpowers/specs/2026-11-17-shell-ux-theme-design.md`](../specs/2026-11-17-shell-ux-theme-design.md).

## Today

- Three themes compete:
  - Ghostty uses `theme = TokyoNight Storm`.
  - fzf-tab flags and bat previews use Dracula.
  - zsh-patina uses its default.
- The `ls -l` rows in file completion come from `zstyle ':completion:*' file-list all` (`config/zsh/opt/rc.d/env.zsh:108`).
- zsh-patina has no pattern rules for dangerous commands. Its issue
  [#95](https://github.com/michel-kraemer/zsh-patina/issues/95) shows that a `line-pre-redraw` hook registered after it
  draws on top.
- powerlevel10k's README says "the project has very limited support".
- Already installed: eza, bat, delta, zoxide, fzf 0.75 (supports `--style full`, section borders and backgrounds) and
  macOS's `/usr/bin/trash`.
- television is in the Brewfile but not installed.

## Recommendation

1. **Adopt now: one theme, framed fzf, richer previews.**
   - Use Catppuccin Mocha everywhere:
     - Ghostty, bat and zsh-patina have it built in.
     - LS_COLORS via `vivid generate catppuccin-mocha`.
     - Ports exist for fzf, eza and delta.
   - In fzf-tab, use `fzf --style full` plus `list-bg`/`preview-bg` and labels.
   - Delete `file-list all`.
   - Directories preview with `eza --tree --level=2 --icons --git` (this needs a Nerd Font such as Cascadia Code NF).
   - Files preview with `bat --style=numbers` and a `--preview-label` naming the file.
2. **Adopt now: `rm -rf` cue and protection.**
   - Draw a white-on-red pattern on top of zsh-patina. Option (a) is zsh-syntax-highlighting with only its `pattern`
     highlighter, loaded after zsh-patina; a spike must confirm it layers on top. The fallback (b) is a roughly
     15-line `line-pre-redraw` hook.
   - Use [gomi](https://github.com/babarot/gomi) as `rm` in interactive shells only. It sends files to the XDG trash
     and has a restore TUI.
3. **Try in a spike.**
   - [Lig](https://github.com/KevenGoncalves/lig), an IDE-style popup that works on macOS, Linux and Windows, with
     Catppuccin, about 740 specs and a `--help` fallback.
   - [atuin](https://github.com/atuinsh/atuin) for Ctrl-R.
   - fish 4 as a second Ghostty profile, for comparison.

Rationale:
- What looks unpolished today is mostly configuration, which the tools already installed can fix on both platforms and
  under the repository's tests.
- The popup tools sit between Ghostty and the shell as a pseudo-terminal proxy and take over Tab, so they get a spike,
  not a migration.
- Moving to fish or nushell would mean rewriting a tested zsh setup for polish that zsh can mostly reach.

## Options

| Option | Area | Verdict | macOS / Linux | Stars | Last push | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Catppuccin Mocha everywhere | Look | Adopt | ✓ / ✓ | — | — | Settings only; ports for every tool here |
| [vivid](https://github.com/sharkdp/vivid) | Look | Adopt | ✓ / ✓ | 2.3k | 2026-11-14 | Generates LS_COLORS; cache the output |
| [fzf](https://junegunn.github.io/fzf/releases/0.58.0/) `--style full` + backgrounds | Tab list | Adopt | ✓ / ✓ | 84k | 2026-11-12 | Costs 2–4 lines of height; test with fzf-tab's flags |
| Remove `file-list all` | Tab list | Adopt | ✓ / ✓ | — | — | No icons in fzf-tab's list without patching |
| [eza](https://github.com/eza-community/eza) tree + bat previews | Preview | Adopt | ✓ / ✓ | 24k / 61k | 2026-08 / 11 | Icons need a Nerd Font |
| Danger pattern over zsh-patina | rm -rf | Adopt | ✓ / ✓ | 23k | 2026-10-09 | Layering to be confirmed in a spike |
| [gomi](https://github.com/babarot/gomi) | rm -rf | Adopt | ✓ / ✓ | 578 | 2026-11-17 | Alias only in interactive shells |
| [chafa](https://github.com/hpjansson/chafa) / `kitten icat` | Preview | Try | ✓ / ✓ | 5.4k | 2026-11-15 | icat is pixel-exact in Ghostty but flaky in tmux |
| [Lig](https://github.com/KevenGoncalves/lig) | Popup | Adopted ([design](../specs/2026-11-17-lig-popup-design.md)) | ✓ / ✓ | 288 | 2026-11-16 | PTY proxy; fzf-tab stays as its fallback |
| [atuin](https://github.com/atuinsh/atuin) | History | Try | ✓ / ✓ | 32.5k | 2026-11-17 | Replaces fzf Ctrl-R; sync optional |
| [television](https://github.com/alexpasmantier/television) | Picker | Try | ✓ / ✓ | 6.4k | 2026-11-15 | Ctrl-T channels; not a Tab engine |
| [fish 4](https://github.com/fish-shell/fish-shell) | Shell | Try alongside | ✓ / ✓ | 34k | 2026-11-16 | Polished out of the box; not POSIX |
| [inshellisense](https://github.com/microsoft/inshellisense) | Popup | Watch | ✓ / ✓ | 10.8k | 2026-11-10 | Node runtime; plainer look |
| [carapace-bin](https://github.com/carapace-sh/carapace-bin) | Completions | Watch | ✓ / ✓ | 2k | 2026-11-16 | Pays off mostly with nushell |
| [Yazi](https://github.com/sxyazi/yazi) | Files | Watch | ✓ / ✓ | 43k | 2026-11-13 | A file manager, complements fzf-tab |
| [Starship](https://github.com/starship/starship) | Prompt | Watch | ✓ / ✓ | 60.8k | 2026-11-16 | Switch if another shell takes hold |
| [zsh-autocomplete](https://github.com/marlonrichert/zsh-autocomplete) | Tab list | Skip | ✓ / ✓ | 6.8k | 2026-09-13 | Competes with fzf-tab |
| Ghost Complete, Figxit, Sill, Easy Complete | Popup | Skip | ✓ / ✗ | ≤347 | 2026-11 | macOS only |
| nushell, bash + ble.sh | Shell | Skip | ✓ / ✓ | 41k / 4.9k | 2026-11 / 10 | Too big a move for this goal |
| rip2, trash-cli, macOS `trash` | rm -rf | Skip | mixed | 683 / 4.6k | 2026-10 / 11 | Graveyard in /tmp; Linux only; macOS only |
