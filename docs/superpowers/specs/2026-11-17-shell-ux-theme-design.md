# Shell UX, adopt tier — design

Project-sized. Branch: `feat/shell-ux-theme`, stacked on `chore/add-todos` (PR #114); rebase onto `main` once that merges.
Research: [`docs/superpowers/research/2026-11-17-shell-ux-options.md`](../research/2026-11-17-shell-ux-options.md).
Implemented by another agent (DeepSeek V4.1 Flash via `/wip:run`), reviewed via `/wip:review`.

## Intent

The terminal should feel like one designed product: modern, useful and beautiful, in the spirit of fish, Catppuccin
and Omarchy. Today it looks like several tools that happen to share a window:

- Ghostty is TokyoNight Storm.
- fzf, bat and delta are Dracula.
- zsh-patina is `tokyonight`.
- `LS_COLORS` is a hand-written string.

`la` (eza, with icons) and `rm <Tab>` (zsh's `ls -l` rows) look like two different programs. A risky `rm -rf` looks like
any other command, and deleted files are gone for good.

This round adopts the research's "Adopt" tier. Once it's in use, the owner re-evaluates the "Try" tier (Lig, atuin,
fish 4); see `TODO.yaml` (tag `shell-ux`).

## Goals

1. **One switchable theme.**
   - Every shell-side tool takes its colours from one active theme, so all of them change together.
   - `dots theme <name>` switches it; `dots theme` alone prints the active theme and the available ones.
   - Ships two dark themes: `catppuccin-mocha` (the default) and `catppuccin-macchiato`. Two themes prove that
     switching works.
2. **A framed, aligned Tab menu.**
   - fzf-tab uses fzf's framed style: section borders, labels and per-section backgrounds from the theme.
   - File candidates are plain coloured names, without `ls -l` rows.
   - A directory preview is the same eza view `la` prints. A file preview is bat with line numbers, and the preview
     label shows the candidate's name.
3. **A warning colour for risky commands while typing.** The cue is the theme's red background with bold text, drawn
   over zsh-patina's highlighting for: `rm -rf` and `rm -fr` (any order or combination of `-r`/`-R` and `-f`),
   `sudo rm`, `git push --force` and `-f`, `git reset --hard`, `git clean -f…`, `chmod -R 777`, `dd … of=/dev/…` and
   `mkfs`.
4. **A safety net for `rm`.** In interactive zsh and bash shells, `rm` runs [gomi](https://github.com/babarot/gomi),
   which moves files to a trash they can be restored from. Scripts and non-interactive shells keep the real `rm`.

## Non-goals

- The "Try" tier: Lig, atuin, television, fish, chafa and image previews, and Starship.
- Light themes, and following the OS light or dark appearance. Only dark themes ship. A light theme (Latte) is a later
  folder, added only if one is ever needed, and the dark-only values (delta `--dark`, `GLOW_STYLE=dark`) would then
  move into the theme.
- Themes beyond the two dark Catppuccin flavours. The layout must make adding one a folder, not code.
- Re-theming tools outside the shell: Neovim, VS Code, kodexb, dinky, zentty, television's UI, btop and others. This
  round leaves them alone, apart from dropping the hard-coded `--theme=dracula` bat flags in television's cable
  channels so they follow `BAT_THEME`. See "Future: full integration".
- Changing key bindings, completion behaviour or zsh-patina's own highlighting rules.

## Anti-goals

- Shell startup must not slow down noticeably: no `vivid`, `eza` or theme-generation process at startup. Generated
  values are committed or cached.
- A missing or broken theme must never break a shell. A missing `current` link means `catppuccin-mocha`. If even that
  folder is missing (a bare container, say), the theme env vars are left unset and each tool uses its own built-in
  colours. No copy of today's TokyoNight and Dracula values is kept.
- `rm` in scripts, `sudo` subshells, CI and the Docker images must stay the real `rm`.

## Constraints

- macOS and Linux (the `distros/` images too). Tools come from `config/homebrew/Brewfile`:
  - `vivid` and `gomi` are new;
  - a Nerd Font for icons (`font-cascadia-code-nf`, a desktop cask; the font family becomes `Cascadia Code NF`).
- Versions installed today: fzf 0.75.0, bat 0.26.1, eza 0.23.5, delta 0.20.1, zsh-patina 1.12.0, Ghostty. Mocha and
  Macchiato are built into Ghostty (`Catppuccin Mocha`, `Catppuccin Macchiato`), bat (same names) and zsh-patina
  (`catppuccin-mocha`, `catppuccin-macchiato`). vivid ships both, and catppuccin/eza ships `themes/mocha` and
  `themes/macchiato`.
- New code goes in `config/bin/dots` (already on PATH) or in inline mise tasks, never in a new script. Every command
  and task declares its inputs with [usage](https://usage.jdx.dev/cli/scripts): `choices`, defaults, flags and help
  text, so usage validates them. `config/bin/yb` (`choices`) and the `build` task in `mise.toml` (`usage = '''…'''`)
  are the models.
- Repo rules (AGENTS.md):
  - the SOPS git wrapper;
  - named-path staging;
  - Conventional Commits;
  - the gates `mise run test:specs`, `hk check --all` and `mise run zsh:verify`;
  - the Docker build and CST for anything touching bootstrap.
- `zsh:verify` parity will change (new env vars and functions). The expected diff is listed in the plan, and the
  baseline is retaken at the end.

## Approaches

- **A. Fixed Catppuccin Mocha:** edit every tool's colours in place. It's the least code, but every later change (a
  second palette, a new tool) repeats the edit across about 12 files.
- **B. Switchable theme folders behind a `current` link (picked; the owner agreed).**
  - Each theme is a folder of small per-tool files.
  - A `current` symlink in the state dir points at the active one, and each tool reads its file through `current`.
  - `dots theme <name>` repoints the link.
  - This is Omarchy's model (`~/.config/omarchy/current/theme`); adding a theme means adding a folder.
- **C. One palette file plus templates rendered into each tool's config:** a single source of hex values, but it needs
  a template engine and a render step after every edit. Too much machinery for two themes.

## Decided

### Theme folders

- `config/theme/themes/<name>/` holds the theme files. `config/theme` is linked to `~/.config/theme`, the way other
  `config/<app>` folders are linked.
- The active theme is `${XDG_STATE_HOME:-$HOME/.local/state}/dots/theme/current`, a symlink to a theme folder. When
  it's missing, everything resolves to `catppuccin-mocha`.
- Per-theme files, each owned by one tool:

  | File | Read by | How |
  | --- | --- | --- |
  | `ghostty` | Ghostty | `theme = Catppuccin Mocha`, included via Ghostty's existing `config-file = ?auto/theme.ghostty` (or a renamed include); the hard-coded `theme = TokyoNight Storm` goes |
  | `env.zsh` | zsh, at startup | exports `BAT_THEME`, `FZF_THEME_OPTS` (fzf `--color` flags), the fzf-tab group colours (replacing the Dracula escapes in `fzf-tab.zsh`'s `group-colors`), `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE`, `EZA_CONFIG_DIR`, `MISE_COLOR_THEME` (`catppuccin`), `GLOW_STYLE` (`dark` or `light`) and the warning style; sources `ls_colors` |
  | `env.bash` | bash, at startup | the subset bash uses: `BAT_THEME`, `LS_COLORS`, `EZA_CONFIG_DIR` |
  | `ls_colors` | zsh, bash | `export LS_COLORS=…`, generated by `vivid generate <flavour>` and committed |
  | `eza/theme.yml` | eza | the [catppuccin/eza](https://github.com/catppuccin/eza) theme, vendored with its MIT notice |
  | `zsh-patina.toml` | zsh-patina | its config with that flavour's built-in theme (`catppuccin-mocha`), via `ZSH_PATINA_CONFIG_PATH` |
  | `p10k.zsh` | powerlevel10k | the 8 `*_FOREGROUND` colours `.p10k.zsh` sets today, loaded after `.p10k.zsh` so they win |

- Tools that drop their own theme flag and follow the env:
  - **bat:** `config/bat/bat.conf`, and every `--theme=Dracula` in `config/zsh/opt/plugins/fzf-tab.zsh`,
    `config/zsh/opt/keybindings/fzf_alt_c_command.zsh`, `config/bin/cmdhelp`, `config/zsh/opt/rc.d/env.zsh`
    (`HOMEBREW_BAT_THEME`) and `config/television/cable/*.toml`.
  - **mise:** `color_theme = "dracula"` goes from `config/mise/config.toml`; `MISE_COLOR_THEME` sets it. Check that mise
    reads that env var, and if it doesn't, use the closest supported mechanism and note it in the commit.
  - **glow:** `config/bin/xc-fabric` keeps its `${GLOW_STYLE:-…}` default but falls back to `dark`, not `dracula`.
    Both themes set `GLOW_STYLE=dark`.
  - **delta:** in `config/git/config`, `syntax-theme` goes, so delta uses `BAT_THEME`. `--dark` stays, since only
    dark themes ship.
- `LS_COLORS`, `EXA_COLORS` and `LSCOLORS` in `config/zsh/opt/rc.d/theme.zsh` are replaced by the theme's `ls_colors`.
  The dead `FAST_HIGHLIGHT_STYLES` block goes too: fast-syntax-highlighting is disabled in `.zimrc`.
- **`dots theme [name]`**, a new subcommand in `config/bin/dots`:
  - USAGE: `cmd "theme" help=…`, with `arg "[name]"` and `choices "catppuccin-mocha" "catppuccin-macchiato"`, plus
    `example` lines. usage rejects an unknown name and lists the valid ones (exit 1).
  - A spec keeps the `choices` in step with the folders under `config/theme/themes/`.
  - With a name, it repoints `current` and writes `~/.config/ghostty/auto/theme.ghostty` (or links it). It then logs
    `Theme: <name>. Open a new shell; reload Ghostty with cmd+shift+,` through the script's `_log_info`.
  - With no name, it lists the themes and marks the active one.
  - It's added to the `gum choose` menu, the `#USAGE example` lines, and the `case` dispatch.
- **`mise run theme:build`**, an inline task in `mise.toml` next to `zsh:completions:todo`:
  - usage: `arg "[name]"` with the same `choices`; with no name it builds every theme.
  - It regenerates a theme's `ls_colors` with vivid. Contributors run it, and the output is committed; it never runs
    at shell start.
  - `vivid` is a dev-profile Brewfile entry, since only contributors need it.

### Tab menu (fzf-tab)

- `fzf-flags` take `--style=full`, the theme's `FZF_THEME_OPTS` colours (including `list-bg`, `preview-bg`, `input-bg`
  and the border colours), a `--list-label` showing the group, and a `--preview-label` showing the candidate.
- The existing key flags stay: `continuous-trigger tab`, right and enter accept, `--cycle`, and the rest.
- The Dracula `--color` lines in `fzf-tab.zsh` and in `FZF_DEFAULT_OPTS`, `FZF_CTRL_T_OPTS` and `FZF_ALT_C_OPTS` are
  replaced by `FZF_THEME_OPTS`, so `Ctrl-T`, `Alt-C` and `Ctrl-R` match the Tab menu.
- `zstyle ':completion:*' file-list all` (`config/zsh/opt/rc.d/env.zsh:108`) goes.
- One preview helper is used by `cd`, `z`, `__zoxide_z`, `eza` and the generic file branch:
  - a directory runs the same eza command and flags as the `la` alias, defined once and used by both;
  - a file runs `bat --style=numbers,changes --color=always --line-range :300`.
- The `cmdhelp` previews and the per-command previews (git, brew, todo, man) stay as they are, apart from following
  `BAT_THEME`.

### Warning colour

- Option (a), tried first: [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) with
  `ZSH_HIGHLIGHT_HIGHLIGHTERS=(pattern)` only, loaded after zsh-patina in `.zimrc`, with the patterns from Goal 3.
- Option (b), the fallback if (a) is hidden by zsh-patina or doubles the cost per keystroke: a small `line-pre-redraw`
  hook registered after zsh-patina that appends `region_highlight` entries for the same patterns. zsh-patina's
  maintainer confirms that later hooks layer on top
  ([#95](https://github.com/michel-kraemer/zsh-patina/issues/95)).
- The plan's first task proves which option works with a test. The task's commit message records which was picked
  and why.

### gomi

- `brew "gomi"` in the Brewfile on the desktop profile and dev.
- In interactive zsh (an alias file in `config/zsh/opt/aliases/`) and in `config/bash/bashrc` (already
  interactive-only), `rm` is aliased to `gomi`, guarded by `command -v gomi`.
- `\rm` and `command rm` still reach the real `rm`.
- The plan records where gomi puts files on macOS, so restoring them is documented in `docs/` (MACOS.md or the README
  day-to-day commands).

## My calls (correct if wrong)

- Macchiato ships as the second theme: it's Catppuccin's other dark flavour, every tool here has it, and it proves
  switching. Frappé is left out (it's the lightest of the dark three).
- The Nerd Font change is in scope, since the icons in previews and `la` need it. Ghostty's `font-family` becomes
  `Cascadia Code NF`.
- The warning style is `bg=<theme red>,fg=<theme crust>,bold`: the theme's own colours, not terminal white.
- `la` keeps its current columns; only its colours change (via the eza theme).
- With no theme folder at all, tools use their own built-in colours. Keeping a copy of today's look would mean
  carrying dead TokyoNight and Dracula values, and would conflict with the no-Dracula check.
- mise and glow join the theme. "Every tool" covers them, and both have Catppuccin or light/dark styles.

## Docs

Every doc and reference that the changes make stale is updated in the same task as the change:

- A new `docs/THEME.md`, in the style of `docs/TILING.md`, covering:
  - the theme folders and the `current` link;
  - `dots theme` and `mise run theme:build`;
  - adding a theme (a folder plus a `choices` entry);
  - the warning patterns;
  - gomi, and restoring files with it;
  - the future-integration list below.
- `README.md`: day-to-day commands (`dots theme`, `gomi --restore`) and the docs list.
- `AGENTS.md`: the Docs list (`docs/THEME.md`).
- `config/bin/README.md`: the `dots` row mentions `theme`.
- `docs/GLOSSARY.md`: "theme", "current theme" and "warning pattern".
- The research note's status: adopted, with this spec's path.
- Comments in the changed files: `theme.zsh`'s header, `fzf-tab.zsh`'s group-colours comment, and `bat.conf`.

## Future: full integration

This round themes the shell. A later round may follow Omarchy all the way, where one `dots theme` re-themes
everything: Neovim, VS Code, btop, television's UI, kodexb, dinky, zentty, Ghostty's window chrome, and the macOS
wallpaper and accent.

The layout is built for that. A tool joins by adding its own file to each theme folder (`nvim.lua`, `vscode.json`,
`btop.theme`, …) plus a line in `dots theme` that links or reloads it, with no change to the folders that exist.
`docs/THEME.md` lists these candidates so the next round starts from it.

## Verification

- **Specs** (`test/integration/`):
  - `dots theme` switches `current` and the Ghostty include, lists themes, and rejects unknown names (usage's exit 1).
  - Its `choices` match the folders in `config/theme/themes/`.
  - `mise run theme:build` regenerates a theme's `ls_colors` byte-for-byte (skipped without vivid).
  - A shell started with a missing `current` gets `catppuccin-mocha`.
  - With each theme active, an interactive zsh exports the expected `BAT_THEME`, `LS_COLORS` (non-empty) and
    `EZA_CONFIG_DIR`.
  - No `dracula` (any case) remains in `config/zsh`, `config/bash`, `config/bin`, `config/bat`, `config/git` or
    `config/mise`.
  - No bat `--theme=` flag remains in those folders.
  - fzf-tab's `fzf-flags` contain `--style=full`.
  - `file-list` is not `all`.
  - The warning highlighter marks `rm -rf x` and leaves `rm x` unmarked.
  - `rm` is an alias for `gomi` in an interactive shell and the real binary in `zsh -c`.
- **Gates:** `mise run test:specs`, `hk check --all`, and `mise run zsh:verify` (re-baseline after reviewing the diff).
  Startup benchmark within 10% of the baseline.
- **Owner checkpoint (by hand, in a new Ghostty window):**
  - `la`, `rm <Tab>` and `cd <Tab>` look alike;
  - Tab menus are framed;
  - `rm -rf foo` shows the warning colour;
  - `rm` of a test file then `gomi --restore` recovers it;
  - `dots theme catppuccin-macchiato` re-themes everything after a new shell and a Ghostty reload, and
    `dots theme catppuccin-mocha` goes back.

## Left to the builder

- The exact fzf colour values (from catppuccin/fzf) and label wording.
- How `theme` links the Ghostty include.
- The preview helper's name and file.
- The pattern list's exact zsh patterns.
- How the `la` command is shared between the alias and the preview.
