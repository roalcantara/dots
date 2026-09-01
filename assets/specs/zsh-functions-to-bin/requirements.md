# REQUIREMENTS: Port Zsh Autoload Functions to `config/bin/` with Usage CLI & Gum

## 1. Purpose & Scope

Port all 12 shell functions in `config/zsh/etc/functions/` (`barrel`, `dots`, `gen`, `gitx`, `keyring`, `osx`, `psc`, `pss`, `recase`, `yw`, `zsys`, `ztoast`) to standalone executable scripts in `config/bin/`.

Every migrated script must adopt the **Usage CLI shebang pattern** (`usage zsh` / `usage bash`), use `#USAGE` specification headers, integrate **Charm Gum** for UI/logging/spinners/prompts, be covered by **Bun integration tests** (`bun-test`), and pass quality gates (`usage lint`, `shellcheck`).

---

## 2. Functional Requirements (EARS)

### 2.1 Usage CLI & Argument Handling

- **REQ-ARG-01 (Shebang):** When a script is executed, the script SHALL execute using `#!/usr/bin/env -S usage zsh` (or `usage bash` where bash-specific).
- **REQ-ARG-02 (Help Output):** When invoked with `-h` or `--help`, the script SHALL output formatted usage information and exit with status code `0`.
- **REQ-ARG-03 (Invalid / Missing Arguments):** When required positional arguments or flags are missing or invalid, the script SHALL output usage error information to stderr and exit with status code `1`.
- **REQ-ARG-04 (Environment Variables):** The script SHALL consume arguments parsed by Usage via `$usage_<arg>` and `$usage_<flag>` environment variables without relying on `zparseopts`.

### 2.2 Charm Gum Integration ("BUY over BUILD")

- **REQ-GUM-01 (Logging):** When emitting informational, warning, or error messages, the script SHALL use `gum log` with timestamps and log levels in interactive TTY sessions, falling back to clean formatted text in non-TTY environments.
- **REQ-GUM-02 (Interactive Selection):** When arguments are omitted in interactive mode for `yw`, `psc`, `pss`, `gitx`, and `dots`, the script SHALL present interactive selections via `gum choose` or `gum filter`.
- **REQ-GUM-03 (Long Tasks & Spinners):** When running lengthy operations (such as defaults export, system profiler reports, or completion generation), the script SHALL display visual progress using `gum spin`.
- **REQ-GUM-04 (Destructive Confirmation):** When performing destructive actions (such as removing keychain entries, branches, or system users), the script SHALL require confirmation via `gum confirm`.

### 2.3 Individual Tool Capabilities

- **REQ-TOOL-01 (barrel):** `barrel` SHALL discover TypeScript/JavaScript modules using `fd` and update/create `index.ts`/`index.js` barrel export files.
- **REQ-TOOL-02 (recase):** `recase` SHALL transform file/folder names across casing conventions (`--snake`, `--kebab`, `--camel`, `--pascal`, etc.) preserving dotfiles and handling case-insensitive filesystem renames safely.
- **REQ-TOOL-03 (toast):** `toast` SHALL display temporary terminal overlay notifications with configurable type and duration.
- **REQ-TOOL-04 (yw):** `yw` SHALL discover Yarn workspace packages and package scripts and execute `yarn workspace <pkg> <script>`.
- **REQ-TOOL-05 (keyring):** `keyring` SHALL support `get`, `set`, `rm`, and `list` operations wrapping macOS `security` and Linux `secret-tool`.
- **REQ-TOOL-06 (psc / pss):** `psc` and `pss` SHALL interface with `gopass` to reveal, copy, or export secrets with interactive filtering.
- **REQ-TOOL-07 (gen):** `gen` SHALL parse CLI `--help` output and generate valid `#compdef` Zsh completion scripts into `~/.config/zsh/opt/completions/`.
- **REQ-TOOL-08 (zsys):** `zsys` SHALL provide diagnostics for PATH entries, command existence, and file modification timestamps.
- **REQ-TOOL-09 (dots):** `dots` SHALL provide environment diagnostics, XDG runtime permission checks/fixes, ANSI color palette preview, and benchmark workflows.
- **REQ-TOOL-10 (osx):** `osx` SHALL manage macOS services, system defaults export, cache maintenance, and user/group inspection.
- **REQ-TOOL-11 (gitx):** `gitx` SHALL centralize git workflow commands (`cnb`, `nb`, `branches`, `clear-merged`, `fzb`, `lol`, etc.) and delegate core git operations to `xc-git`.

---

## 3. Non-Functional & Verification Requirements

- **REQ-TEST-01 (Bun Tests):** Each migrated tool SHALL have an automated integration test file under `assets/integration/bin/<tool>.spec.ts`.
- **REQ-TEST-02 (Example Validation):** Every `#USAGE example "..."` line defined in a script header SHALL have an automated test assertion verifying its behavior and exit code.
- **REQ-TEST-03 (Linter):** All scripts SHALL pass `usage lint config/bin/<tool>` without errors or warnings.
- **REQ-TEST-04 (ShellCheck):** All scripts SHALL pass `shellcheck` static analysis cleanly.
