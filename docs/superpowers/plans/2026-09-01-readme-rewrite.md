# Dots README Rewrite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite and modernize the root `README.md` to be fully accurate, comprehensive, and compliant with Standard Readme and repository guidelines, accurately reflecting the current architecture (macOS/Darwin and Linux Debian/Ubuntu support, full `config/bin` CLI suite, `assets/` BDD & verification toolchain, Homebrew bundle management, `hk` git hooks, Flox & Mise package management, and agent workflows).

**Architecture:** The updated `README.md` provides a clean, well-structured guide to the dotfiles repository. It organizes information into standardized sections: Overview, Installation (one-liners and normal install on Darwin/Linux with all CLI flags), Tooling & Dependencies (Mise, Distro, Flox, Homebrew), Usage (Git hooks with `hk`, CLI suite in `config/bin`, Homebrew Bundle in `config/homebrew`, Zsh environment), Testing & Verification (`assets/` four-layer verification: guides, specs, features, integration), Docker & DevContainers, Benchmarks, and Contributing/Acknowledgements.

**Tech Stack:** Markdown, Standard Readme specification, Mise, Flox, Zsh, Bash, Bun, Cucumber/Gherkin, Docker, hk git hook manager.

---

## File Structure Changes

- **Create:**
  - `docs/superpowers/plans/2026-09-01-readme-rewrite.md`
- **Modify:**
  - `README.md`

---

## Tasks

### Task 1: Audit Current Repository Capabilities & Tooling

**Files:**

- Read: `README.md`
- Read: `config/bin/README.md`
- Read: `config/zsh/README.md`
- Read: `config/homebrew/README.md`
- Read: `assets/README.md`
- Read: `install`
- Read: `mise.toml`
- Read: `config/mise/config.toml`

- [ ] **Step 1: Verify installed CLI tools and binaries in `config/bin`**
      Verify the list of executable tools present in `config/bin/` (`barrel`, `dots`, `gen`, `gitx`, `keyring`, `osx`, `psc`, `pss`, `recase`, `toast`, `xc`, `xc-fabric`, `xc-git`, `xc-md`, `xc-puts`, `xc-skills`, `xc-toast`, `xc-usage`, `yw`, `zsys`).

- [ ] **Step 2: Verify package managers and dependencies**
      Verify tools managed via Mise (`bat`, `delta`, `eza`, `fd`, `fzf`, `gh`, `gum`, `hk`, `node`, `bun`, `npm`, `npx`, `nvim`, `python3`, `rg`, `starship`, `usage`, `watchexec`, `zoxide`, `dprint`, `fallow`, `ls-lint`, `mdschema`, `cocogitto`, `biome`, `commit-check`) and Flox (`config/flox/flox.toml`).

- [ ] **Step 3: Verify install flags and platform support**
      Verify `./install` supports macOS Darwin, Debian, Ubuntu, devcontainers, and flags: `-u`, `-g`, `-t`, `-p`, `-r`, `-b`, `-e`.

---

### Task 2: Rewrite `README.md`

**Files:**

- Modify: `README.md`

- [ ] **Step 1: Draft the updated `README.md`**
      Write a comprehensive, polished, and Standard-Readme compliant `README.md` containing:
  1. Title and status badges (Preview, Release, Publish, MIT License, Contributor Covenant, EditorConfig, Standard Readme, Conventional Commits).
  2. Clear Overview describing the repository purpose, architecture, and supported platforms.
  3. Installation section detailing one-liner scripts (curl/wget), normal git clone installation, all parameter flags (`-u`, `-g`, `-t`, `-p`, `-r`, `-b`, `-e`), and platform matrix (macOS Darwin, Debian/Ubuntu Linux, DevContainers).
  4. Tooling and Package Management table with categorized packages across Distro, Mise, Flox, and Homebrew.
  5. Git hooks management with `hk` (`setup:hooks`, `hk check`, `hk fix`, Conventional Commits, pre-commit linters).
  6. Terminal tools & executable scripts in `config/bin/` (Usage CLI docopt header conventions, table of tools, and examples).
  7. Homebrew Bundle workflow (`mise run bundle` tasks: `install`, `check`, `update`, `cleanup`, `dump`, `list`, `add`, `remove`).
  8. Documentation & Verification architecture under `assets/` (guides, specs, features, integration), with command references (`mise run -C assets test all`, `mise run -C assets test bin`, BDD, integration).
  9. Agent workflow guidelines for SDD planning and implementation.
  10. Docker container builds and devcontainer instructions (`mise run build`, `mise run start`, `mise run test`).
  11. Startup benchmarks table.
  12. Contributing guidelines, License, and Acknowledgements.

- [ ] **Step 2: Apply the changes to `README.md`**
      Write the newly formatted content to `README.md`.

---

### Task 3: Verification & Quality Gates

**Files:**

- Verify: `README.md`

- [ ] **Step 1: Check markdown link validity and anchor references**
      Ensure all relative links (`LICENSE`, `assets/guides/...`, `assets/specs/...`, `config/bin/...`, etc.) point to existing files.

- [ ] **Step 2: Run repository test suite**
      Run `mise run -C assets test all` to ensure all BDD features and integration tests remain 100% green.

- [ ] **Step 3: Check git hooks and formatting**
      Verify that `dprint` or markdown formatters/linters pass without errors.
