# Shell UX Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every shell-side tool takes its colours from one switchable dark theme. Tab menus are framed, and their
previews match `la`. `rm -rf` and similar commands show a warning colour while typed, and `rm` in interactive shells
moves files to a restorable trash (gomi).

**Architecture:**
- **Themes:** `config/theme/themes/<name>/` holds small per-tool files.
- **Selection:**
  - A `current` symlink in the state dir picks the active theme.
  - `theme.zsh` resolves it once into `DOTS_THEME_DIR` and sources the theme's `env.zsh`, and every tool reads
    from there.
  - `dots theme` (in `config/bin/dots`, declared with usage) switches it.
  - `mise run theme:build` regenerates the committed `ls_colors` with vivid.
- **Then:** fzf-tab's look, the warning highlight, and gomi.

**Tech Stack:**
- zsh (zim, fzf-tab, zsh-patina, powerlevel10k), bash;
- fzf 0.75, bat 0.26, eza 0.23, delta 0.20, vivid, gomi, Ghostty;
- usage (`#USAGE` and mise `usage = '''…'''`), mise tasks, Bun test.

**Spec:** [`docs/superpowers/specs/2026-11-17-shell-ux-theme-design.md`](../specs/2026-11-17-shell-ux-theme-design.md)
Read it first: Goals, Anti-goals, the per-theme file table, and "Future: full integration".

## Global Constraints

- **Branch and git:**
  - Branch `feat/shell-ux-theme` (checked out, stacked on `chore/add-todos`). No worktree, no push, no PR.
  - Run every git call through `g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }`.
  - Stage named paths only. One commit per task, Conventional Commits with a capitalised description, ending with
    `Co-Authored-By: DeepSeek V4.1 Flash <noreply@deepseek.com>`.
- **Themes:** exactly two, both dark: `catppuccin-mocha` (the default) and `catppuccin-macchiato`. No light theme;
  delta keeps `--dark` and `GLOW_STYLE=dark`.
- **Where new code goes:**
  - New code goes in `config/bin/dots` (a new `theme` subcommand) or in inline tasks in `mise.toml`. No new scripts
    in `script/` or `config/bin/`.
  - Each declares its inputs with usage: `choices`, `default`, `help` and `example`. Follow `config/bin/yb`
    (`arg … { choices … }`) and `[tasks."build"]` in `mise.toml` (`usage = '''…'''`).
  - The usage script docs are at <https://usage.jdx.dev/cli/scripts>.
- **Overrides for tests** (follow `yb`'s `DOTS_YABAI` pattern):
  - `DOTS_THEMES_DIR` sets where theme folders are read (default `${XDG_CONFIG_HOME:-$HOME/.config}/theme/themes`).
  - `DOTS_THEME_LINK` sets the active-theme link (default
    `${XDG_STATE_HOME:-$HOME/.local/state}/dots/theme/current`).
  - Never change `XDG_STATE_HOME` in a spec: zim's modules live there.
- **No new work at shell startup:** no `vivid`, `eza`, `bat` or subshell runs. The theme is a symlink read plus one
  `source`.
- **A missing theme never breaks a shell:**
  - If `DOTS_THEME_LINK` doesn't resolve, use `$DOTS_THEMES_DIR/catppuccin-mocha`.
  - If that folder is missing too, export nothing theme-related and leave each tool on its built-in colours.
- **Every changed behaviour updates its docs in the same task.**
  - Docs: `docs/THEME.md` (new), `README.md`, `AGENTS.md` (Docs list), `config/bin/README.md`, `docs/GLOSSARY.md`,
    and the research note `docs/superpowers/research/2026-11-17-shell-ux-options.md`.
  - Also comments in the changed files.
- **Prerequisite:** before Task 1, capture the zsh parity baseline from the unchanged config:
  `mise run zsh:baseline` (run it in a real terminal, or prefix with `script -q /dev/null` so fzf loads).
- **Running specs:** `mise run -C test integration <domain> <stem>`. The domains are `bin` and `bootstrap`.

## Review Focus

1. **A dangling or missing `current` link:** a new shell must still start, using Mocha, with no error on the prompt.
   Task 3 asserts it.
2. **`rm` in scripts, `sudo` and `zsh -c`:** it must stay `/bin/rm`. Only interactive zsh and bash get `gomi`.
   Task 6 asserts it.
3. **`rm x` (not forced) and `rm-rf-notes.txt`:** neither should get the warning colour; only the patterns in the
   spec's Goal 3 do. Task 5 asserts both.
4. **Switching theme while zsh-patina's daemon runs:** the daemon caches its theme, so `dots theme` must restart it,
   or the old colours linger. Task 2 asserts that `dots theme` calls `zsh-patina restart` when it exists.
5. **Container and Linux shells without vivid, gomi or the Nerd Font:** nothing may fail. Task 7's Docker build and
   CST cover it.

---

### Task 1: Theme folders, `theme:build` and the link

**Files:**

- Create, for each `<t>` in `catppuccin-mocha` and `catppuccin-macchiato`, in `config/theme/themes/<t>/`:
  - `theme.ghostty`;
  - `env.zsh`;
  - `env.bash`;
  - `ls_colors`;
  - `eza/theme.yml`, vendored from catppuccin/eza `themes/<mocha|macchiato>/` with its `LICENSE` beside it;
  - `zsh-patina.toml`.
- Create: `config/theme/README.md` (one paragraph pointing to `docs/THEME.md`).
- Create: `docs/THEME.md` (skeleton: the folder layout and `theme:build`; later tasks add their sections).
- Modify: `mise.toml` (task `theme:build`, after `zsh:completions:todo`).
- Modify: `config/mise/conf.d/dotfiles.toml` (link `~/.config/theme`, alphabetical, `relative = true`).
- Modify: `config/homebrew/Brewfile` (`brew "vivid"` in DEVTOOLS).
- Modify: `test/integration/bootstrap/brewfile-profiles.spec.ts`.
- Test: `test/integration/bin/theme.spec.ts` (new).

**Interfaces:**

- Produces:
  - **`env.zsh`, sourced, not run.** It assumes `DOTS_THEME_DIR` is set. It exports:
    - `BAT_THEME` (`Catppuccin Mocha` or `Catppuccin Macchiato`);
    - `FZF_THEME_OPTS`, one string of `--color=…` flags from catppuccin/fzf, plus `list-bg`, `input-bg`,
      `preview-bg`, `list-border`, `input-border`, `preview-border`, `list-label`, `preview-label` and `header`;
    - `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE` (`fg=<overlay0 hex>`);
    - `EZA_CONFIG_DIR=$DOTS_THEME_DIR/eza`;
    - `MISE_COLOR_THEME=catppuccin` and `GLOW_STYLE=dark`;
    - `DOTS_WARN_STYLE` (`fg=<crust hex>,bg=<red hex>,bold`);
    - `DOTS_P10K_GREY`, `DOTS_P10K_RED`, `DOTS_P10K_YELLOW`, `DOTS_P10K_BLUE`, `DOTS_P10K_MAGENTA`, `DOTS_P10K_CYAN`
      and `DOTS_P10K_WHITE` (hex).

    It also sets the global array `DOTS_FZF_TAB_GROUP_COLORS`: six `$'\e[38;2;R;G;Bm'` escapes for mauve, blue,
    green, peach, pink and yellow. Last, it sources `$DOTS_THEME_DIR/ls_colors`.
  - **`env.bash`:** the subset bash needs: `BAT_THEME`, `EZA_CONFIG_DIR`, `MISE_COLOR_THEME` and `GLOW_STYLE`, then
    it sources `ls_colors`.
  - **`ls_colors`:** a single line, `export LS_COLORS='…'`.
  - **`theme.ghostty`:** a single line, `theme = Catppuccin Mocha` (or `Catppuccin Macchiato`).
  - **`zsh-patina.toml`:** a theme file, `[metadata]` then `extends = "catppuccin-mocha"` (or `-macchiato`). Task 3
    points zsh-patina at it.
  - **The `theme:build` task:** usage is `arg "[name]" { choices "catppuccin-mocha" "catppuccin-macchiato" }`. No
    name means both. For each theme it writes `config/theme/themes/<name>/ls_colors` from `vivid generate <name>`.
    It fails with `theme:build: vivid not found (brew install vivid)` when vivid is missing.

- [ ] **Step 1: Write the failing spec** `test/integration/bin/theme.spec.ts`, `describe("theme folders")`:
  - `it("each theme has every file")`: for both names, the files listed above exist and are non-empty.
  - `it("ls_colors is one export line")`: it matches `/^export LS_COLORS='[^']+'\n$/`.
  - `it.skipIf(!Bun.which("vivid"))("theme:build reproduces the committed ls_colors")`: run
    `mise run theme:build` in place, then assert that `git diff --exit-code -- config/theme` exits 0.
  - `it("theme:build rejects an unknown name")`: `mise run theme:build nope` exits non-zero and stderr names both
    choices.
  - Add a case to `brewfile-profiles.spec.ts`: `vivid` appears on `desktop,dev` only.
- [ ] **Step 2: Run, expect FAIL:** `mise run -C test integration bin theme`.
- [ ] **Step 3: Create the folders and files:**
  - Colour values come from Catppuccin's palette (<https://catppuccin.com/palette>) and catppuccin/fzf.
  - Generate `ls_colors` with the new task once vivid is installed (`brew install vivid`).
  - Add the link, the Brewfile line, and `docs/THEME.md` (layout, `theme:build`, and how to add a theme: a folder,
    the files above, and a `choices` entry in both usage specs).
- [ ] **Step 4: Run, expect PASS:** the same command, plus `mise run -C test integration bootstrap brewfile-profiles`.
- [ ] **Step 5: Commit** `feat(theme): Add Catppuccin Mocha and Macchiato theme folders and theme:build`.

### Task 2: `dots theme` and Ghostty

**Files:**

- Modify: `config/bin/dots`: the USAGE block, the `gum choose` list, the `case` dispatch and an `example` line.
- Create: `config/ghostty/auto`, a committed relative symlink to
  `../../../../.local/state/dots/theme/current`, built the same way as `config/ghostty/themes`. Ghostty's existing
  `config-file = ?auto/theme.ghostty` then reads the active theme's file.
- Modify: `config/ghostty/config.ghostty`:
  - line 79 `theme = TokyoNight Storm` becomes `theme = Catppuccin Mocha` (the default when no link exists);
  - `font-family` becomes `Cascadia Code NF`;
  - the comment above `config-file = ?auto/theme.ghostty` names `dots theme`.
- Modify: `config/homebrew/Brewfile`: `cask "font-cascadia-code-nf"` in "Desktop: fonts".
- Modify: `config/bin/README.md` (the `dots` row) and `docs/THEME.md` (a "Switching" section).
- Test: `test/integration/bin/theme.spec.ts`.

**Interfaces:**

- Consumes: the theme folders, `DOTS_THEMES_DIR` and `DOTS_THEME_LINK` (Global Constraints).
- Produces: `dots theme [name]`.
  - USAGE:
    `cmd "theme" help="Show or switch the shell theme" { arg "[name]" help="Theme to activate" { choices "catppuccin-mocha" "catppuccin-macchiato" } }`.
  - With a name: `ln -sfn` the link (creating its parent directory), run `zsh-patina restart` when the command
    exists, then `_log_info "Theme: <name>. Open a new shell; reload Ghostty with cmd+shift+,"`.
  - With no name: print each folder name in `DOTS_THEMES_DIR`, with `* ` before the active one and two spaces before
    the others. Exit 0.

- [ ] **Step 1: Add failing cases** to `theme.spec.ts`, `describe("dots theme")`, running `config/bin/dots` with
  `DOTS_THEMES_DIR=<repo>/config/theme/themes` and `DOTS_THEME_LINK=<tmp>/current`:
  - `it("switches the link")`: `dots theme catppuccin-macchiato` exits 0, and `readlink(<tmp>/current)` ends with
    `/catppuccin-macchiato`.
  - `it("lists themes and marks the active one")`: after the switch, `dots theme` prints `* catppuccin-macchiato`
    and `  catppuccin-mocha`.
  - `it("rejects an unknown name")`: `dots theme nope` exits 1, stderr contains `catppuccin-mocha`, and no link is
    created.
  - `it("restarts zsh-patina")`: put a fake `zsh-patina` that appends its args to a log on `PATH`; the switch logs
    `restart`.
  - `it("choices match the theme folders")`: parse the `choices` line of `dots`'s `theme` block and the
    `theme:build` usage in `mise.toml`. Both sorted lists equal the sorted folder names.
- [ ] **Step 2: Run, expect FAIL:** `mise run -C test integration bin theme`.
- [ ] **Step 3: Implement** the subcommand, the symlink, the Ghostty and Brewfile edits, and the docs.
- [ ] **Step 4: Run, expect PASS.** Also check `mise run -C test integration bin dots` still passes.
- [ ] **Step 5: Commit** `feat(dots): Switch the shell theme with dots theme`.

### Task 3: The shell reads the theme

**Files:**

- Modify: `config/zsh/opt/rc.d/theme.zsh`:
  - `theme::palette` resolves `DOTS_THEME_DIR`, following Global Constraints' fallback, and exports it, then sources
    its `env.zsh`;
  - delete `LSCOLORS`, `LS_COLORS`, `EXA_COLORS` and the whole `FAST_HIGHLIGHT_STYLES` block;
  - update the header comment.
- Modify: `config/bash/bashrc`: after `.profile`, resolve the same `DOTS_THEME_DIR` and source `env.bash` when
  present.
- Modify: `config/zsh-patina/config.toml`: `theme = "file:$DOTS_THEME_DIR/zsh-patina.toml"`. If zsh-patina doesn't
  expand the variable for its daemon (check with `zsh-patina highlight`, or a new shell showing Catppuccin colours),
  fall back to `ZSH_PATINA_CONFIG_PATH` pointing at a full per-theme config. Say which in the commit body.
- Modify: `config/zsh/.p10k.zsh:41-47`: each `local <colour>` becomes `${DOTS_P10K_<COLOUR>:-<current value>}`.
- Modify: `config/zsh/opt/plugins/zsh-autosuggestions.zsh:27`: the hard-coded style becomes
  `${ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE:-fg=8}`.
- Drop the Dracula settings:
  - `config/bat/bat.conf`: delete `--theme=Dracula`; the comment points to `BAT_THEME`.
  - `config/git/config`: delete `syntax-theme = Dracula`.
  - `config/mise/config.toml`: delete `color_theme = "dracula"`; the comment says the theme sets
    `MISE_COLOR_THEME`. Check that mise honours it (`MISE_COLOR_THEME=catppuccin mise settings get color_theme`). If
    it doesn't, set `color_theme = "catppuccin"` and say so in the commit body.
  - `config/zsh/opt/rc.d/env.zsh:159`: delete `HOMEBREW_BAT_THEME`.
  - `config/bin/cmdhelp:27`, `config/zsh/opt/keybindings/fzf_alt_c_command.zsh:12` and every
    `config/television/cable/*.toml`: delete the `--theme=…` flag.
  - `config/bin/xc-fabric:173`: `${GLOW_STYLE:-dark}`.
- Test: `test/integration/bootstrap/theme-env.spec.ts` (new).

**Interfaces:**

- Consumes: Task 1's files.
- Produces: `DOTS_THEME_DIR` and the exports listed in Task 1, in every interactive zsh and bash.

- [ ] **Step 1: Write the failing spec.**
  - `envOf(themeLink, script)` runs `env -i HOME TERM=xterm-256color ZDOTDIR=$HOME/.config/zsh DOTS_THEME_LINK=<link> DOTS_THEMES_DIR=<repo>/config/theme/themes script -q /dev/null zsh -ic <script>`.
    Strip `\r` and the leading `^D` from the output. `script` is what makes fzf and zim load, as they would in a
    terminal.
  - `it("mocha exports its values")`: with the link at the Mocha folder, `BAT_THEME` is `Catppuccin Mocha`,
    `EZA_CONFIG_DIR` ends with `catppuccin-mocha/eza`, and `LS_COLORS` contains `di=`.
  - `it("macchiato exports its values")`: the same for Macchiato.
  - `it("a dangling link falls back to mocha, silently")`: with the link pointing at `<tmp>/missing`, `BAT_THEME`
    is `Catppuccin Mocha`, and the output has no `no such file`.
  - `it("bash reads the theme")`: `bash -ic 'echo $BAT_THEME'` with the same env prints the theme's value.
  - `it("no Dracula left")`: case-insensitive, no `dracula` under `config/zsh`, `config/bash`, `config/bin`,
    `config/bat`, `config/git`, `config/mise` or `config/television`, and no bat `--theme=` in those folders. Skip
    `*.zwc` files.
- [ ] **Step 2: Run, expect FAIL:** `mise run -C test integration bootstrap theme-env`.
- [ ] **Step 3: Implement.** Update `docs/THEME.md` ("What reads the theme": a table of tool → file → variable) and
  `docs/GLOSSARY.md` ("theme", "current theme").
- [ ] **Step 4: Run, expect PASS.** Also check `mise run zsh:verify`: syntax OK. Note the parity diff in the commit
  body; expected changes are the new theme env vars, plus `EXA_COLORS` and `LSCOLORS` gone.
- [ ] **Step 5: Commit** `feat(theme): Read every shell tool's colours from the active theme`.

### Task 4: Framed Tab menus and matching previews

**Files:**

- Modify: `config/zsh/opt/plugins/fzf-tab.zsh`:
  - **Colours:** the Dracula `--color` lines in `FZF_DEFAULT_OPTS`, `FZF_CTRL_T_OPTS` and `FZF_ALT_C_OPTS`, and in
    fzf-tab's `fzf-flags`, become `$FZF_THEME_OPTS`. In the zstyle, split it with `${(z)FZF_THEME_OPTS}`.
  - **Flags:** `fzf-flags` add `--style=full`, `--list-label=' {group} '`, and a preview label.
    - fzf-tab has no `{group}` field, so label the list from the zstyle context instead, or omit
      `--list-label` if it can't be done cleanly. `--preview-label` is set per preview with `$word`; the shared
      helper below does it.
    - Keep the other flags and `continuous-trigger tab`.
  - **Group colours:** `group-colors` uses `$DOTS_FZF_TAB_GROUP_COLORS` when set, otherwise fzf-tab's default. Fix
    the comment at line 97.
  - **One shared preview, `_dots_preview_path`,** replaces `fzf_dir_preview` and the generic file branch:
    - a directory runs `$DOTS_LA_CMD <path>`;
    - an image or anything else non-text prints `file -b`;
    - a text file runs `bat --style=numbers,changes --color=always --line-range :300`.

    Use it for `cd`, `z`, `__zoxide_z`, `eza` and the generic `:fzf-tab:complete:*` file branch. Previews run in a
    child zsh, so pass it as a string, as `fzf_dir_preview` is today.
- Modify: `config/zsh/opt/aliases/ls.zsh`: define `DOTS_LA_CMD` (the full eza command `la` expands to, with
  `--color=always --icons=always`) and make `la` use it, so the alias and the preview are one definition.
- Modify: `config/zsh/opt/rc.d/env.zsh:108`: delete `zstyle ':completion:*' file-list all`.
- Modify: `docs/THEME.md` ("Tab menus" section).
- Test: `test/integration/bootstrap/fzf-tab-styles.spec.ts`.

**Interfaces:**

- Consumes: `FZF_THEME_OPTS` and `DOTS_FZF_TAB_GROUP_COLORS` (Task 1, exported by Task 3).
- Produces: `DOTS_LA_CMD` (string) and the preview string `_dots_preview_path`.

- [ ] **Step 1: Add failing cases** to `fzf-tab-styles.spec.ts`:
  - `it("menus are framed and themed")`: `fzf-flags` include `--style=full` and the Mocha `bg` value from
    `FZF_THEME_OPTS`.
  - `it("no ls -l rows")`: `zstyle -s ':completion:*' file-list v` returns false or a value that isn't `all`.
  - `it("la and the directory preview share one command")`: `alias la` expands to a string containing
    `$DOTS_LA_CMD`'s value, and the `cd` preview contains `DOTS_LA_CMD`.
  - `it("group colours follow the theme")`: `group-colors` equals `DOTS_FZF_TAB_GROUP_COLORS`.
  - Update the existing generic-preview case to the new helper.
- [ ] **Step 2: Run, expect FAIL:** `mise run -C test integration bootstrap fzf-tab-styles`.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run, expect PASS.** In a real terminal, check that `rm <Tab>` shows names (no `ls -l` rows) in a
  framed Mocha menu.
- [ ] **Step 5: Commit** `feat(zsh): Frame fzf-tab menus in the theme and preview directories like la`.

### Task 5: Warning colour for risky commands

**Files:**

- Modify: `config/zsh/.zimrc` (option a) or create `config/zsh/opt/plugins/warn-highlight.zsh` (option b, loaded
  after zsh-patina).
- Modify: `config/zsh/opt/rc.d/theme.zsh` (option a's settings, before zim loads: `ZSH_HIGHLIGHT_HIGHLIGHTERS=(pattern)`).
- Modify: `docs/THEME.md` ("Risky commands" section: the patterns, and why each option was or wasn't used).
- Test: `test/integration/bootstrap/warn-highlight.spec.ts` (new).

**Interfaces:**

- Consumes: `DOTS_WARN_STYLE`.
- Produces: `region_highlight` entries of `DOTS_WARN_STYLE` over the whole command when the buffer matches one of
  these patterns:
  - `rm` with `-r`/`-R` and `-f` combined in any order or form (`-rf`, `-fr`, `-Rf`, `-r -f`, `--recursive --force`);
  - `sudo rm`;
  - `git push` with `--force`, `-f` or `--force-with-lease`;
  - `git reset --hard`;
  - `git clean` with `-f`;
  - `chmod -R 777`;
  - `dd` with an `of=/dev/` argument;
  - `mkfs`.

- [ ] **Step 1: Write the failing spec.** The harness is a temporary `ZDOTDIR` whose `.zshrc` sources the real one,
  then adds:

  ```zsh
  zle-line-init() { BUFFER=$CMD; CURSOR=$#BUFFER; zle -R; print -rl -- $region_highlight >> $OUT; exit }
  zle -N zle-line-init
  ```

  Run it with `script -q /dev/null zsh -i`, with `CMD` and `OUT` set. This is the same technique used to capture
  completions on this branch.
  - `it("rm -rf x is marked")`: some line of `OUT` contains `DOTS_WARN_STYLE`'s value, starting at `0`.
  - `it("git push --force is marked")`.
  - `it("rm x is not marked")`.
  - `it("rm-rf-notes.txt is not marked")`, for the buffer `cat rm-rf-notes.txt`.
  - If `zle -R` doesn't run the pre-redraw hooks, call `zle .redisplay`, or trigger the hooks directly.
- [ ] **Step 2: Run, expect FAIL:** `mise run -C test integration bootstrap warn-highlight`.
- [ ] **Step 3: Try option (a)**, zsh-syntax-highlighting's pattern highlighter only, loaded after zsh-patina.
  - If the spec passes and `mise run zsh:bench` stays within 10% of the baseline, keep it.
  - Otherwise remove it and write option (b): a `line-pre-redraw` hook via `add-zle-hook-widget`, registered after
    zsh-patina. It drops its own previous entries (tag them with `memo=dots-warn`) and appends new ones.
- [ ] **Step 4: Run, expect PASS.**
- [ ] **Step 5: Commit** `feat(zsh): Colour risky commands like rm -rf while typing`. The body says which option was
  kept, and the bench numbers.

### Task 6: gomi as `rm` in interactive shells

**Files:**

- Modify: `config/homebrew/Brewfile`: `brew "gomi"` in "Desktop: formulae".
- Create: `config/zsh/opt/aliases/safety.zsh`, sourced from `config/zsh/opt/aliases/init.zsh`. It sets
  `alias rm='gomi'` when `(( $+commands[gomi] ))`, with a comment: the real rm is `\rm` or `command rm`.
- Modify: `config/bash/bashrc`: the same alias, guarded by `command -v gomi`.
- Modify: `docs/THEME.md` ("Safety net": deleting, listing and restoring files with `gomi --restore`, where the trash
  lives on macOS and on Linux, and bypassing it).
- Modify: `README.md` (day-to-day commands: `dots theme`, `gomi --restore`, and the docs list entry for `THEME.md`),
  `AGENTS.md` (the Docs list entry for `docs/THEME.md`) and `docs/GLOSSARY.md` ("warning pattern", "safety net").
- Modify: `test/integration/bootstrap/brewfile-profiles.spec.ts` (gomi on desktop and dev, not container).
- Test: `test/integration/bootstrap/theme-env.spec.ts` (new cases).

- [ ] **Step 1: Add failing cases:**
  - `it("rm is gomi in an interactive shell")`: with a fake `gomi` on `PATH`, `zsh -ic 'whence -w rm'` prints
    `rm: alias`, and `alias rm` contains `gomi`.
  - `it("rm stays rm in zsh -c and bash -c")`: `zsh -c 'whence -p rm'` and `bash -c 'type -P rm'` print the real
    path (`/bin/rm` on macOS).
  - `it("no gomi, no alias")`: without gomi on `PATH`, `whence -w rm` prints `rm: command`.
  - The Brewfile case.
- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Implement.** Install gomi (`brew install gomi`) to confirm where it puts files on macOS; record that in
  `docs/THEME.md`.
- [ ] **Step 4: Run, expect PASS.**
- [ ] **Step 5: Commit** `feat(shell): Send rm to gomi's trash in interactive shells`.

### Task 7: Gates, docs check and the owner's look

- [ ] **Step 1: Gates.**
  - `mise run test:specs` exits 0.
  - `hk check --all` exits 0.
  - `script -q /dev/null mise run zsh:verify` passes syntax; the parity diff contains only the changes Tasks 3–6
    named. Paste it into the handoff.
  - `mise run zsh:bench` is within 10% of the pre-Task-1 numbers.
  - Then `mise run build --local --distro debian` and
    `mise run test --image dots:debian-<tag> --config distros/debian/container-structure-test.yml` both pass (the
    bashrc, Brewfile and link changes touch bootstrap).
- [ ] **Step 2: Docs check.**
  - `grep -rniE 'dracula|tokyonight storm' README.md AGENTS.md docs/*.md config/bin/README.md` finds nothing stale.
  - The research note's status line reads "Adopted: see `docs/superpowers/specs/2026-11-17-shell-ux-theme-design.md`".
  - `docs/THEME.md` has a "Future: full integration" section copied from the spec.
  - Commit `docs(theme): Finish the theme docs`.
- [ ] **Step 3: Owner checkpoint** (stop and ask; don't tick it for the owner). The owner opens a new Ghostty window
  and checks:
  - `la`, `rm <Tab>` and `cd <Tab>` look alike;
  - Tab menus are framed in Mocha;
  - `rm -rf foo` shows the warning colour while typed;
  - `touch /tmp/x && rm /tmp/x && gomi --restore` brings it back;
  - `dots theme catppuccin-macchiato`, then a new shell and cmd+shift+, re-themes everything;
  - `dots theme catppuccin-mocha` returns.
- [ ] **Step 4:** After the owner approves, run `mise run zsh:baseline`. Tick this plan's boxes, except Step 3, and
  commit (`docs(plans): Tick the shell UX theme plan`). Then run `/wip:handoff plan=docs/superpowers/plans/2026-11-17-shell-ux-theme.md`.
