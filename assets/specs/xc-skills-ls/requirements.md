# Requirements: `xc-skills ls`

## 1. Executive Summary

`xc-skills` is a bash CLI tool for managing AI agent skill symlinks and regular files across multi-agent environments. This feature adds a interactive discovery and management command: `xc-skills ls`.

`xc-skills ls` provides an interactive terminal user interface (TUI) powered by `fzf` to list, search, preview, edit, copy, and update skills from the global or project-local skills directory.

---

## 2. Requirements & Acceptance Criteria (EARS)

### 2.1 CLI Interface & USAGE Specification

- **REQ-CLI-1:** The `xc-skills` binary SHALL declare `#USAGE cmd "ls"` with documentation for `-s/--source`, `-l/--local`, and `-r/--raw`.
- **REQ-CLI-2:** When invoked with `xc-skills ls -h` or `xc-skills ls --help`, the system SHALL output usage instructions, available flags, and examples.
- **REQ-CLI-3:** When invoked with `-r` or `--raw`, the system SHALL output list of discovered skill directory paths directly to stdout without launching `fzf`.
- **REQ-CLI-4:** When stdout is not a TTY (non-interactive, pipe, or subshell) and interactive mode cannot launch, the system SHALL default to raw output.

### 2.2 Interactive Discovery & Selection

- **REQ-FZF-1:** When `xc-skills ls` is invoked in an interactive terminal (TTY), the system SHALL launch `fzf` with multi-selection enabled (`-m`).
- **REQ-FZF-2:** The `fzf` header SHALL display instructions for all available keybindings:
  `↵ select  Tab multi  ^O edit  ^N copy-name  ^P copy-path  ^U update  Esc exit`
- **REQ-FZF-3:** The `Tab` key SHALL toggle item selection and move cursor down (`tab:toggle+down,btab:toggle+up`).
- **REQ-FZF-4:** Pressing `Enter` SHALL print the selected skill directory path(s) to stdout and exit `0`.

### 2.3 Side-Panel Markdown Preview

- **REQ-PREV-1:** The `fzf` interface SHALL display a right preview panel (`--preview-window="right:60%:wrap:border-rounded"`).
- **REQ-PREV-2:** When a skill directory is highlighted, the preview panel SHALL render `SKILL.md` (or the file itself if a standalone markdown file) using `glow -s dracula` if `glow` is available.
- **REQ-PREV-3:** If `glow` is absent, the preview panel SHALL fall back to `bat --color=always -l md --paging=never`, and then `cat`.

### 2.4 Interactive Keybindings

- **REQ-KEY-1 (Edit `ctrl-o`):** Pressing `ctrl-o` SHALL open the selected skill's `SKILL.md` file(s) in `${EDITOR:-nvim}`.
- **REQ-KEY-2 (Copy Name `ctrl-n`):** Pressing `ctrl-n` SHALL extract folder names (e.g., `my-skill`) for all selected skills and copy them to the system clipboard using the cross-platform clipboard helper (`pbcopy` / `wl-copy` / `xclip` / `xsel` / `OSC 52`).
- **REQ-KEY-3 (Copy Path `ctrl-p`):** Pressing `ctrl-p` SHALL extract folder paths with `$HOME` replaced by `~` (e.g., `~/.agents/skills/my-skill`) and copy them to the clipboard.
- **REQ-KEY-4 (Update `ctrl-u`):** Pressing `ctrl-u` SHALL invoke `skills update -g <skill-names>` (or `-p` if `--local` was active) for all selected skills.
- **REQ-KEY-5 (Exit `Esc`):** Pressing `Esc` SHALL exit `fzf` cleanly without executing actions.

### 2.5 Error Handling

- **REQ-ERR-1:** If the target skills directory does not exist, the system SHALL print `ERROR: Skills directory not found: <PATH>` to stderr and exit `1`.
- **REQ-ERR-2:** If the target skills directory contains zero skills, the system SHALL print `No skills found in <PATH>` and exit `0`.
- **REQ-ERR-3:** If `fzf` is missing when required for interactive mode, the system SHALL print an error suggesting `--raw` and exit `1`.
