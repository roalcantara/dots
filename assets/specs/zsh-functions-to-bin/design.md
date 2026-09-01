# DESIGN: Port Zsh Autoload Functions to `config/bin/` with Usage CLI & Gum

## 1. Overview & Goals

This specification defines the architecture, design, and migration strategy for porting all 12 functions currently in `config/zsh/etc/functions/` to standalone, executable scripts in `config/bin/`.

The ported scripts replace legacy docopt `##?` headers, `zparseopts`, and manual parsing with the **Usage CLI shebang pattern** (`#!/usr/bin/env -S usage zsh` / `usage bash`), and replace bespoke terminal formatting, spinners, prompts, and loggers with **Charm Gum** primitives ("BUY over BUILD").

### Key Objectives

1. **Subshell & Process Portability**: Convert shell functions from `$fpath` into standalone executables in `config/bin/` accessible from any subshell, script, `fzf --preview`, or process.
2. **Usage CLI Integration**: Use `#USAGE` headers on a `usage` shebang to provide automatic `--help` generation, flag/argument parsing via `$usage_*` environment variables, and shell tab-completion via `usage generate completion-init zsh`.
3. **Charm Gum User Experience**: Integrate Charm Gum (`gum log`, `gum style`, `gum choose`, `gum filter`, `gum spin`, `gum confirm`, `gum input`) with automatic non-TTY fallbacks for interactive workflows.
4. **Comprehensive Bun Test Coverage**: Create and run integration tests using `bun:test` under `assets/integration/bin/<tool>.spec.ts` covering `--help`, invalid inputs, and all documented `#USAGE example` lines.
5. **Clean Deprecation & Cutover**: Remove migrated functions from `config/zsh/etc/functions/`, update `.zimrc` autoloading, and synchronize documentation.

---

## 2. Inventory & Migration Tiers

| Tier | Script | Shell | Purpose & Key Features | Gum Components Used | Integration Test File |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | `barrel` | bash/zsh | TypeScript/JavaScript barrel (`index.ts/js`) exporter | `gum log`, `gum confirm` | `assets/integration/bin/barrel.spec.ts` |
| **1** | `recase` | zsh | File and folder casing transformer (`--snake`, `--kebab`, etc.) | `gum log`, `gum style` | `assets/integration/bin/recase.spec.ts` |
| **1** | `toast` | zsh | Terminal toast notification overlay (unify with `xc-toast`) | ANSI / `tput` / `gum log` | `assets/integration/bin/toast.spec.ts` |
| **1** | `yw` | zsh | Yarn workspace package and script interactive selector | `gum choose`, `gum filter`, `gum log` | `assets/integration/bin/yw.spec.ts` |
| **2** | `keyring` | bash | Agnostic keychain access (macOS `security` / Linux `secret-tool`) | `gum input --password`, `gum filter`, `gum confirm` | `assets/integration/bin/keyring.spec.ts` |
| **2** | `psc` | zsh/bash | Gopass secret copy to clipboard | `gum filter`, `gum log` | `assets/integration/bin/psc.spec.ts` |
| **2** | `pss` | zsh/bash | Gopass secret reveal and bulk export | `gum filter`, `gum spin`, `gum log` | `assets/integration/bin/pss.spec.ts` |
| **3** | `gen` | zsh | Completion script generator from command `--help` | `gum spin`, `gum log` | `assets/integration/bin/gen.spec.ts` |
| **3** | `zsys` | zsh | PATH, command, file, and setup inspection/diagnostic utilities | `gum style`, `gum log` | `assets/integration/bin/zsys.spec.ts` |
| **4** | `dots` | zsh | Dotfiles manager (env, xdg perms, palette, benchmarks, settings) | `gum choose`, `gum spin`, `gum log`, `gum style` | `assets/integration/bin/dots.spec.ts` |
| **4** | `osx` | zsh | macOS maintenance (services, defaults, cache, sleep, users, dock) | `gum spin`, `gum filter`, `gum confirm`, `gum log` | `assets/integration/bin/osx.spec.ts` |
| **4** | `gitx` | zsh | Git workflow dispatcher (`cnb`, `nb`, `branches`, `fzb`, `lol`) | `gum choose`, `gum filter`, `gum confirm`, `gum log` | `assets/integration/bin/gitx.spec.ts` |

---

## 3. Architecture & Shared Implementation Standards

### 3.1 Script Skeleton

Every script adheres to the standard Usage CLI structure:

```zsh
#!/usr/bin/env -S usage zsh
# shellcheck shell=bash disable=SC2154

#? <tool> 0.1.0
#? License RIT (Robot Institute of Technology)

#USAGE version "0.1.0"
#USAGE about "Clear, concise one-line summary"
#USAGE arg "<req_arg>" help="Description of required argument"
#USAGE flag "-f --flag <val>" help="Description of flag" default="val"
#USAGE example "<tool> --flag val my_target"

# Strict execution modes
emulate -L zsh
setopt no_unset pipe_fail extended_glob

# Logic using $usage_req_arg, $usage_flag, etc.
```

### 3.2 Charm Gum Integration Rules ("BUY over BUILD")

1. **Interactive Detection**: Check for interactive TTY before invoking Gum prompts:

   ```zsh
   _has_gum() {
     [[ -t 1 && "${TERM:-}" != dumb ]] && command -v gum >/dev/null 2>&1
   }
   ```

2. **Log Messages**: Use `gum log` for all level-based status output:

   ```zsh
   _log_info() { _has_gum && gum log --time DateTime --level info "$@" || print -P -- "%F{green}✔%f $*"; }
   _log_warn() { _has_gum && gum log --time DateTime --level warn "$@" || print -P -- "%F{yellow}▲%f $*" >&2; }
   _log_error() { _has_gum && gum log --time DateTime --level error "$@" || print -P -- "%F{red}✘%f $*" >&2; }
   ```

3. **Interactive Pickers**: Use `gum choose` or `gum filter` when arguments are omitted in interactive sessions.
4. **Spinners**: Wrap long-running batch operations in `gum spin --spinner dot --title "..." -- <cmd>`.
5. **Confirmation**: Guard destructive operations with `gum confirm "Proceed with <action>?"`.

---

## 4. Component Details per Tier

### 4.1 Tier 1: Flat Utilities & Interactive Pickers

#### `config/bin/barrel`

- **Specification:**
  - `arg "<folder>"`: Target directory for barrel generation.
  - `flag "-r --recursive"`: Include subdirectories recursively.
  - `flag "-ts --ts"`: Use `.ts` exports (default).
  - `flag "-js --js"`: Use `.js` exports.
- **Behavior:** Discovers files using `fd`, extracts module exports, updates `index.ts`/`index.js`, and logs changes with `gum log`.

#### `config/bin/recase`

- **Specification:**
  - `arg "<path>"`: Target file or directory path.
  - `flag "-f --files"`: Transform filenames only.
  - `flag "-d --dirs"`: Transform directory names only.
  - `flag "-r --recursive"`: Recurse into subdirectories.
  - `flag "--camel"`, `flag "--pascal"`, `flag "--snake"`, `flag "--kebab"`, `flag "--dot"`, `flag "--upper"`, `flag "--lower"`, `flag "--title"`.
- **Behavior:** Safely performs case transformation (handling case-insensitive filesystems via intermediate temporary renames) and logs renames with `gum log` and `gum style`.

#### `config/bin/toast`

- **Specification:**
  - `arg "<message>"`: Notification message text.
  - `flag "-d --duration <seconds>"` / `arg "[duration_pos]"`: Toast duration in seconds (default: 3).
  - `flag "-t --type <type>"` / `arg "[type_pos]"`: Toast type (`info`, `success`, `error`, `warning`).
- **Behavior:** Overlays background terminal toast at top right using `tput`. Unifies `xc-toast` and `ztoast`.

#### `config/bin/yw`

- **Specification:**
  - `arg "[package]"`: Specific Yarn workspace package.
  - `arg "[script]"`: Script name inside `package.json`.
  - `flag "--run"`: Execute immediately (default: true in interactive mode).
  - `flag "--dry-run"`: Print generated command without running.
- **Behavior:** Lists packages via `yarn workspaces list --json` and scripts via `jq`, presents interactive `gum choose` / `gum filter` selectors when omitted, and runs `yarn workspace <pkg> <script>`.

---

### 4.2 Tier 2: Credentials & Secrets Management

#### `config/bin/keyring`

- **Specification:**
  - `#USAGE cmd "get <key>"`
  - `#USAGE cmd "set <key> [value]"` (prompts via `gum input --password` if value omitted)
  - `#USAGE cmd "rm <key>"` (confirms via `gum confirm`)
  - `#USAGE cmd "list"`
- **Behavior:** Provides platform-agnostic secret management wrapping macOS `security` and Linux `secret-tool`.

#### `config/bin/psc`

- **Specification:**
  - `arg "[key]"`: Gopass secret path.
- **Behavior:** If `key` is provided, copies secret to clipboard with `gopass show --clip "$key"`. If omitted, opens `gum filter` over `gopass ls --flat` to select the key.

#### `config/bin/pss`

- **Specification:**
  - `arg "[key]"`: Gopass secret path.
  - `flag "-c --cp"`: Copy password value to clipboard instead of revealing.
  - `flag "-e --export <path>"`: Export secrets to target directory.
- **Behavior:** Reveals secret to stdout, copies with `--cp`, or runs bulk export with `gum spin`.

---

### 4.3 Tier 3: Generators & Shell Inspection Utilities

#### `config/bin/gen`

- **Specification:**
  - `arg "<toolname>"`: CLI command name to generate completions for.
  - `flag "-d --dir <path>"`: Output directory (default: `~/.config/zsh/opt/completions`).
- **Behavior:** Executes `<toolname> --help`, parses arguments/options, generates a valid `#compdef` Zsh completion script into target directory, and reports status via `gum log`.

#### `config/bin/zsys`

- **Specification:**
  - `#USAGE cmd "path"` with flags `--list`, `--remove <path>`, `--append <path>`, `--prepend <path>`, `--clean`
  - `#USAGE cmd "cmd"` with flags `--exists <command>`, `--path <command>`
  - `#USAGE cmd "file"` with flags `--source <file>`, `--mtime <file>`
  - `#USAGE cmd "setup"` with flags `--profiling`, `--debugging`, `--xdg <path>`
- **Behavior:** Inspects environment paths, checks command availability, benchmarks files, and outputs shell configuration snippets.

---

### 4.4 Tier 4: Complex Multi-Command Dispatchers

#### `config/bin/dots`

- **Specification:**
  - `#USAGE cmd "env"`: Print formatted environment variables.
  - `#USAGE cmd "path"` / `fpath` / `cdpath`: Print clean, deduplicated path listings.
  - `#USAGE cmd "palette"`: Print 256-color ANSI terminal palette with hex values.
  - `#USAGE cmd "xdg <action>"` (`check_runtime_perms`, `ensure_runtime_perms`).
  - `#USAGE cmd "setup <action>"` (`local_settings` for VSCode/Insiders symlink sync).
  - `#USAGE cmd "zsh <action>"` (`benchmark`, `prof`).
  - `#USAGE cmd "git [args...]"`: Forward to `xc-git`.
  - Default invocation (no args): Interactive `gum choose` menu for all subcommands.

#### `config/bin/osx`

- **Specification:**
  - `#USAGE cmd "wifi"`, `services`, `systemctl`, `launchctl`, `notify`, `plist`, `cache`, `exclusions`, `sleep`, `groups`, `users`, `system_profiler`, `dock`, `finder`, `export-defaults`, `enable-locate`.
- **Behavior:** Centralizes macOS system operations with `gum spin` on export/profiler and `gum confirm` on service/cache/user modifications.

#### `config/bin/gitx`

- **Specification:**
  - `#USAGE cmd "cnb <branch>"`: Smart create branch with commit cherry-picking picker.
  - `#USAGE cmd "nb <branch>"`: Create branch from origin/main.
  - `#USAGE cmd "branches"`: List local branch names.
  - `#USAGE cmd "clear-merged"`, `clear-gone`, `remote-branches`.
  - `#USAGE cmd "rebase-from"`, `edit`, `drop`, `reword`, `fix`, `fix-root`, `squash`, `fix-all`, `squash-all`.
  - `#USAGE cmd "lol"`, `fzlog`, `fzl`, `fzdiff`, `fza`, `fzu`, `fzus`, `fzc`, `fzb`, `fzr`, `fzf`, `fzw`, `fze`, `fzd`, `fzhs`, `fzhh`, `fzunstage`.
  - `#USAGE cmd "grep-commit"`, `tail`, `grep-branch`, `head-branch`, `strip`, `preview`.
- **Behavior:** Complete git productivity toolkit with interactive `gum` / `fzf` pickers, delegating core primitives to `xc-git`.

---

## 5. Testing & Quality Assurance Plan

### 5.1 Static Checks

1. `usage lint config/bin/<script>`: Validates KDL/Usage header syntax and variable mapping.
2. `shellcheck config/bin/<script>`: Validates shell syntax and variables across all scripts.

### 5.2 Bun Integration Tests (`assets/integration/bin/<script>.spec.ts`)

Each script has a companion Bun test file asserting:

- `<script> -h` and `<script> --help` exit with status `0` and print Usage text.
- Missing required arguments exit with status `1` and print help to stderr.
- Direct subprocess execution of every documented `#USAGE example` passes with expected exit codes.

### 5.3 Quality Gate Commands

```bash
# Run lint on all scripts
for s in barrel recase toast yw keyring psc pss gen zsys dots osx gitx; do
  usage lint "config/bin/$s"
done

# Run integration tests
bun test assets/integration/bin/
```

---

## 6. Deprecation & Cleanup

1. Remove all 12 files from `config/zsh/etc/functions/`.
2. Update `config/zsh/.zimrc` to autoload any remaining functions or remove the function autoload line if empty.
3. Update `config/bin/README.md` and `config/zsh/README.md` to document the new tools.
4. Ensure `~/.local/bin/` symlinks reflect the new tools.
