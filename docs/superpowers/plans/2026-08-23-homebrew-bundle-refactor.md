# Homebrew Bundle Task Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor Homebrew task management in `mise.toml` to a namespaced `bundle:*` command hierarchy using `mise`, providing subcommands for installation, dumping, checking, listing, updating, cleaning, and adding/removing dependencies, while implementing a DRY flagset pattern.

**Architecture:** A single parent task `bundle` in `mise.toml` will act as a CLI router by defining a KDL `usage` spec with nested subcommands. The execution logic inside the `bundle` task will parse the subcommand environment variables and delegate to native `brew bundle` or run robust, text-based operations for adding/removing items in the `Brewfile`.

**Tech Stack:** `mise` task runner, Homebrew Bundle CLI, KDL `usage` spec, Bash scripting, Markdown documentation.

---

## File Structure Changes

* **Modify:**
  * `config/homebrew/mise.toml`
  * `config/homebrew/README.md`
* **Create:**
  * `assets/guides/homebrew-recipes.md`

---

## Tasks

### Task 1: Refactor `mise.toml` Task Structure

**Files:**
- Modify: `config/homebrew/mise.toml`

- [ ] **Step 1: Write the updated `mise.toml` content**

Overwrite `config/homebrew/mise.toml` with the new namespaced `bundle` structure. This includes keeping `brew:setup` and `brew:load` untouched, removing all other `brew:*` tasks, removing the long recipes header, and adding the new `bundle` task.

To handle compatibility with the current system's `mise` (2026.8.10 which uses `usage-lib` v5 and lacks top-level `flagset` node support), we provide the KDL specification in two forms. Write **Option B** to `mise.toml` so that it parses successfully on the current system, but document **Option A** as the target structure.

#### Option A: KDL Spec using `flagset` (Spec-Compliant)
```kdl
flagset "brewfile" {
  flag "-f --file <path>" help="Path to the Brewfile" default="${HOME}/.config/homebrew/Brewfile"
}

cmd "list" help="List all dependencies present in the Brewfile" {
  use "brewfile"
  flag "--all" help="List all dependencies"
  flag "--formula" help="List Homebrew formula dependencies"
  flag "--cask" help="List Homebrew cask dependencies"
  flag "--tap" help="List Homebrew tap dependencies"
  flag "--mas" help="List Mac App Store dependencies"
  flag "--vscode" help="List VSCode extensions"
  flag "--go" help="List Go packages"
  flag "--cargo" help="List Cargo packages"
  flag "--uv" help="List uv tools"
  flag "--krew" help="List Krew plugins"
  flag "--npm" help="List npm packages"
  flag "--flatpak" help="List Flatpak packages"
}

cmd "install" help="Install all dependencies from the active Brewfile" {
  use "brewfile"
}

cmd "dump" help="Generate a new Brewfile from currently installed packages" {
  use "brewfile"
}

cmd "check" help="Check local install state against the Brewfile" {
  use "brewfile"
}

cmd "update" help="Update Homebrew, upgrade packages, and reconcile bundle" {
  use "brewfile"
}

cmd "clean" help="Clean up Homebrew, prune old packages, and run doctor" {
}

cmd "add" help="Add a dependency to the Brewfile" {
  use "brewfile"
  arg "<type>" help="Type of dependency" {
    choices "formulae" "cask" "tap" "mas" "uv" "go" "cargo" "npm" "krew" "vscode" "flatpak"
  }
  arg "<name>" help="Name of the dependency"
  arg "[args...]" help="Additional arguments (e.g. mas ID or options)"
}

cmd "rm" help="Remove a dependency from the Brewfile" {
  use "brewfile"
  arg "<type>" help="Type of dependency" {
    choices "formulae" "cask" "tap" "mas" "uv" "go" "cargo" "npm" "krew" "vscode" "flatpak"
  }
  arg "<name>" help="Name of the dependency"
}
```

#### Option B: KDL Spec repeating flags (Runtime-Compatible for `usage-lib` v5)
Use this option in `mise.toml`.

```toml
[tasks."brew:setup"]
description = "Install Homebrew if it is not already available"
run = '''
#!/usr/bin/env bash
set -euo pipefail

HOMEBREW_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
if command -v brew >/dev/null 2>&1; then
  echo "Homebrew is already installed"
  exit 0
fi

NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "${HOMEBREW_URL}")"
if command -v brew >/dev/null 2>&1; then
  echo "Homebrew installed successfully"
else
  echo "Homebrew installation failed" >&2
  exit 1
fi
'''

[tasks."brew:load"]
description = "Load the Homebrew environment into the current shell session"
run = '''
#!/usr/bin/env bash
set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is not installed; run 'mise -C config/homebrew run brew:setup' first" >&2
  exit 1
fi

# shellcheck disable=SC1090
eval "$(brew shellenv)"
'''

[tasks.bundle]
description = "Homebrew bundle management (defaults to list)"
depends = ["brew:load"]
usage = '''
flag "-f --file <path>" help="Path to the Brewfile" default="${HOME}/.config/homebrew/Brewfile"

cmd "list" help="List all dependencies present in the Brewfile" {
  flag "-f --file <path>" help="Path to the Brewfile" default="${HOME}/.config/homebrew/Brewfile"
  flag "--all" help="List all dependencies"
  flag "--formula" help="List Homebrew formula dependencies"
  flag "--cask" help="List Homebrew cask dependencies"
  flag "--tap" help="List Homebrew tap dependencies"
  flag "--mas" help="List Mac App Store dependencies"
  flag "--vscode" help="List VSCode extensions"
  flag "--go" help="List Go packages"
  flag "--cargo" help="List Cargo packages"
  flag "--uv" help="List uv tools"
  flag "--krew" help="List Krew plugins"
  flag "--npm" help="List npm packages"
  flag "--flatpak" help="List Flatpak packages"
}

cmd "install" help="Install all dependencies from the active Brewfile" {
  flag "-f --file <path>" help="Path to the Brewfile" default="${HOME}/.config/homebrew/Brewfile"
}

cmd "dump" help="Generate a new Brewfile from currently installed packages" {
  flag "-f --file <path>" help="Path to the Brewfile" default="${HOME}/.config/homebrew/Brewfile"
}

cmd "check" help="Check local install state against the Brewfile" {
  flag "-f --file <path>" help="Path to the Brewfile" default="${HOME}/.config/homebrew/Brewfile"
}

cmd "update" help="Update Homebrew, upgrade packages, and reconcile bundle" {
  flag "-f --file <path>" help="Path to the Brewfile" default="${HOME}/.config/homebrew/Brewfile"
}

cmd "clean" help="Clean up Homebrew, prune old packages, and run doctor" {
}

cmd "add" help="Add a dependency to the Brewfile" {
  flag "-f --file <path>" help="Path to the Brewfile" default="${HOME}/.config/homebrew/Brewfile"
  arg "<type>" help="Type of dependency" {
    choices "formulae" "cask" "tap" "mas" "uv" "go" "cargo" "npm" "krew" "vscode" "flatpak"
  }
  arg "<name>" help="Name of the dependency"
  arg "[args...]" help="Additional arguments (e.g. mas ID or options)"
}

cmd "rm" help="Remove a dependency from the Brewfile" {
  flag "-f --file <path>" help="Path to the Brewfile" default="${HOME}/.config/homebrew/Brewfile"
  arg "<type>" help="Type of dependency" {
    choices "formulae" "cask" "tap" "mas" "uv" "go" "cargo" "npm" "krew" "vscode" "flatpak"
  }
  arg "<name>" help="Name of the dependency"
}
'''
run = '''
#!/usr/bin/env bash
set -euo pipefail

CMD="${usage_cmd:-list}"
BREW_FILE="${usage_file:-${HOME}/.config/homebrew/Brewfile}"

case "${CMD}" in
  list)
    opts=()
    [[ "${usage_all:-false}" == "true" ]] && opts+=(--all)
    [[ "${usage_formula:-false}" == "true" ]] && opts+=(--formula)
    [[ "${usage_cask:-false}" == "true" ]] && opts+=(--cask)
    [[ "${usage_tap:-false}" == "true" ]] && opts+=(--tap)
    [[ "${usage_mas:-false}" == "true" ]] && opts+=(--mas)
    [[ "${usage_vscode:-false}" == "true" ]] && opts+=(--vscode)
    [[ "${usage_go:-false}" == "true" ]] && opts+=(--go)
    [[ "${usage_cargo:-false}" == "true" ]] && opts+=(--cargo)
    [[ "${usage_uv:-false}" == "true" ]] && opts+=(--uv)
    [[ "${usage_krew:-false}" == "true" ]] && opts+=(--krew)
    [[ "${usage_npm:-false}" == "true" ]] && opts+=(--npm)
    [[ "${usage_flatpak:-false}" == "true" ]] && opts+=(--flatpak)

    brew bundle list --file="${BREW_FILE}" "${opts[@]}"
    ;;

  install)
    if [[ ! -f "${BREW_FILE}" ]]; then
      echo "Brewfile not found at ${BREW_FILE}" >&2
      exit 1
    fi
    brew bundle --file="${BREW_FILE}"
    ;;

  dump)
    brew bundle dump --file="${BREW_FILE}" --force
    ;;

  check)
    if [[ ! -f "${BREW_FILE}" ]]; then
      echo "Brewfile not found at ${BREW_FILE}" >&2
      exit 1
    fi
    brew bundle check --file="${BREW_FILE}"
    ;;

  update)
    brew update
    brew upgrade
    if [[ -f "${BREW_FILE}" ]]; then
      brew bundle --file="${BREW_FILE}"
    fi
    ;;

  clean)
    brew autoremove
    brew update
    brew upgrade
    brew upgrade --cask
    brew cleanup --prune=all
    brew doctor
    ;;

  "add formulae"|"add cask"|"add tap"|"add mas"|"add uv"|"add go"|"add cargo"|"add npm"|"add krew"|"add vscode"|"add flatpak")
    type="${CMD#add }"
    name="${usage_name}"

    case "${type}" in
      formulae) keyword="brew" ;;
      cask) keyword="cask" ;;
      tap) keyword="tap" ;;
      mas) keyword="mas" ;;
      *) keyword="${type}" ;;
    esac

    line="${keyword} \"${name}\""
    if [[ -n "${usage_args:-}" ]]; then
      if [[ "${type}" == "mas" && "${usage_args}" =~ ^[0-9]+$ ]]; then
        line="${line}, id: ${usage_args}"
      else
        line="${line}, ${usage_args}"
      fi
    fi

    pattern="^[[:space:]]*${keyword}[[:space:]]+['\"]${name}['\"]"
    if grep -qE "${pattern}" "${BREW_FILE}" 2>/dev/null; then
      echo "${type} '${name}' already exists in Brewfile."
    else
      mkdir -p "$(dirname "${BREW_FILE}")"
      echo "${line}" >> "${BREW_FILE}"
      echo "Added ${line} to Brewfile."
    fi
    ;;

  "rm formulae"|"rm cask"|"rm tap"|"rm mas"|"rm uv"|"rm go"|"rm cargo"|"rm npm"|"rm krew"|"rm vscode"|"rm flatpak")
    type="${CMD#rm }"
    name="${usage_name}"

    case "${type}" in
      formulae) keyword="brew" ;;
      cask) keyword="cask" ;;
      tap) keyword="tap" ;;
      mas) keyword="mas" ;;
      *) keyword="${type}" ;;
    esac

    pattern="^[[:space:]]*${keyword}[[:space:]]+['\"]${name}['\"]"
    if grep -qE "${pattern}" "${BREW_FILE}" 2>/dev/null; then
      grep -vE "${pattern}" "${BREW_FILE}" > "${BREW_FILE}.tmp"
      mv "${BREW_FILE}.tmp" "${BREW_FILE}"
      echo "Removed ${type} '${name}' from Brewfile."
    else
      echo "${type} '${name}' not found in Brewfile."
    fi
    ;;

  *)
    echo "Unknown subcommand: ${CMD}" >&2
    exit 1
    ;;
esac
'''
```

- [ ] **Step 2: Save and verify TOML structure**
  Save the file changes and check that `mise` parses the tasks.
  Run:
  ```bash
  mise tasks
  ```
  Expected: The output should list tasks `brew:setup`, `brew:load`, and `bundle` (with descriptions) and not complain about invalid configs.

---

### Task 2: Create `assets/guides/homebrew-recipes.md`

**Files:**
- Create: `assets/guides/homebrew-recipes.md`

- [ ] **Step 1: Write the recipe guide content**
  Write a comprehensive cookbook file containing the recipes migrated from `mise.toml`.
  Wrap lines at 80 characters, use sentence casing for all headings, and avoid a table of contents.

  Run:
  ```bash
  cat << 'EOF' > ../../assets/guides/homebrew-recipes.md
  # Homebrew Configuration Recipes

  Use this guide as a cookbook for declaring various dependency types inside your
  `Brewfile`. These examples demonstrate the correct syntax for taps, core
  formulae, casks, fonts, Mac App Store apps, npm packages, VSCode extensions, Go
  packages, Cargo packages, uv tools, Krew plugins, and Flatpak packages.

  ## Homebrew taps

  Use `tap` to register external formulas repositories.

  ```ruby
  tap "apple/apple"
  tap "user/tap-repository", "https://user@bitbucket.org/user/homebrew-tap-repository.git"
  ```

  ## Core formulae

  Use `brew` to register command-line tools and libraries.

  ```ruby
  brew "apple/apple/game-porting-toolkit"
  brew "postgresql@16", restart_service: true
  ```

  ## Homebrew casks

  Use `cask` to register graphical applications.

  ```ruby
  cask "firefox"
  ```

  ## Mac App Store apps

  Use `mas` to register Mac App Store applications (requires `mas` CLI installed).

  ```ruby
  mas "Refined GitHub", id: 1519867270
  ```

  ## npm packages

  Use `npm` to declare global JavaScript/TypeScript packages.

  ```ruby
  npm "create-react-app"
  ```

  ## VS Code extensions

  Use `vscode` to declare extensions.

  ```ruby
  vscode "editorconfig.editorconfig"
  ```

  ## Go packages

  Use `go` to declare Go command binaries.

  ```ruby
  go "github.com/charmbracelet/crush"
  ```

  ## Cargo packages

  Use `cargo` to declare Rust packages.

  ```ruby
  cargo "ripgrep"
  ```

  ## uv tools

  Use `uv` to declare Python packages.

  ```ruby
  uv "mkdocs"
  uv "ruff", source: "git+https://github.com/astral-sh/ruff.git"
  ```

  ## Krew plugins

  Use `krew` to declare Kubernetes CLI plugins.

  ```ruby
  krew "ctx"
  ```

  ## Flatpak packages

  Use `flatpak` to declare Linux Flatpak packages.

  ```ruby
  flatpak "com.visualstudio.code"
  flatpak "org.godotengine.Godot", remote: "flathub-beta", url: "https://dl.flathub.org/beta-repo/"
  flatpak "io.github.dvlv.boxbuddyrs", remote: "flathub-beta"
  ```
  EOF
  ```

  Expected: File created successfully.

---

### Task 3: Update `config/homebrew/README.md`

**Files:**
- Modify: `config/homebrew/README.md`

- [ ] **Step 1: Modify the README to reflect new commands**
  Update `config/homebrew/README.md` to reference the new namespaced `bundle` structure instead of `brew:*`, and add a "Homebrew configuration" section that links to `assets/guides/homebrew-recipes.md`. Keep lines wrapped at 80 characters.

  ```markdown
  [README.md#6E20]
  PUT 13.=37:
  +## Usage
  +
  +All Homebrew tasks are consolidated under the namespaced `bundle` task.
  +
  +```sh
  +# Setup Homebrew if it is missing:
  +mise run brew:setup
  +
  +# Run tasks under the bundle namespace:
  +mise run bundle                 # List all dependencies (Default)
  +mise run bundle install         # Install all dependencies
  +mise run bundle check           # Check installation state
  +mise run bundle update          # Update Homebrew, upgrade packages, and reconcile
  +mise run bundle clean           # Clean up Homebrew environment
  +mise run bundle dump            # Write currently installed packages to Brewfile
  +
  +# Add or remove dependencies:
  +mise run bundle add formulae git
  +mise run bundle add cask firefox
  +mise run bundle add mas Xcode 497799835
  +mise run bundle rm cask firefox
  +```
  +
  +## Homebrew configuration
  +
  +For a complete cookbook demonstrating how to declare various types of
  +dependencies inside your `Brewfile` (such as taps, casks, fonts, Mac App Store
  +apps, npm packages, VSCode extensions, Go packages, Cargo packages, uv tools,
  +Krew plugins, and Flatpak packages), see the [Homebrew Configuration Recipes
  +Guide](../../assets/guides/homebrew-recipes.md).
  ```

- [ ] **Step 2: Commit documentation changes**
  Run:
  ```bash
  git add config/homebrew/README.md assets/guides/homebrew-recipes.md
  git commit -m "docs: consolidate homebrew documentation and add recipes guide"
  ```

---

### Task 4: Smoke Testing and Verification

**Files:**
- None (Verification only)

- [ ] **Step 1: Verify the CLI structure help output**
  Run:
  ```bash
  mise run bundle --help
  ```
  Expected: It should output the list of subcommands (list, install, dump, check, update, clean, add, rm) along with descriptions and flags.

- [ ] **Step 2: Verify default subcommand**
  Run:
  ```bash
  mise run bundle
  ```
  Expected: It should execute the default `list` subcommand and print the core formula dependencies in the Brewfile.

- [ ] **Step 3: Verify list subcommand with options**
  Run:
  ```bash
  mise run bundle list --cask
  ```
  Expected: It should list only the cask dependencies declared in the Brewfile (e.g. `amethyst`, `antigravity`, etc.).

- [ ] **Step 4: Verify check subcommand**
  Run:
  ```bash
  mise run bundle check
  ```
  Expected: It should execute `brew bundle check` successfully.

- [ ] **Step 5: Verify add and remove subcommands**
  Create a temporary Brewfile copy to test modification subcommands without affecting the git index.
  Run:
  ```bash
  cp Brewfile /tmp/Brewfile.test
  mise run bundle --file /tmp/Brewfile.test add formulae jq
  mise run bundle --file /tmp/Brewfile.test add cask iterm2
  mise run bundle --file /tmp/Brewfile.test add mas Xcode 497799835
  grep -E '^(brew|cask|mas)' /tmp/Brewfile.test
  ```
  Expected: Outputs showing `Added brew "jq"`, `Added cask "iterm2"`, and `Added mas "Xcode", id: 497799835` inside `/tmp/Brewfile.test`.

  Now, verify removal:
  Run:
  ```bash
  mise run bundle --file /tmp/Brewfile.test rm cask iterm2
  grep -E 'cask "iterm2"' /tmp/Brewfile.test
  ```
  Expected: No output, indicating that `cask "iterm2"` was successfully removed. Clean up `/tmp/Brewfile.test` after verification.
