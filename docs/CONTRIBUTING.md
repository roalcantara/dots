# Contributing guidelines

Code style, commit conventions, branch workflows, and mise task design for Dots.

## 1. Git workflow and worktrees

Work on features and fixes in isolated Git worktrees rather than the primary checkout:

```sh
# Create an isolated worktree for your branch
git worktree add ../dots-myfeature -b feat/myfeature
cd ../dots-myfeature
```

### SOPS filter wrapper

Git filters are configured to encrypt secrets upon commit. In automated environments or when inspecting diffs directly, use the SOPS filter bypass wrapper:

```sh
g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }
```

### Staging rules

- **Stage named files only:** never use `git add -A` or `git add .`.
- **Never commit unencrypted secrets:** `config/.env`, `config/ssh/keys/*.key`, and `config/age/keys.txt` must remain encrypted or excluded.
- **Do not push unasked:** only push branches and open pull requests when explicitly directed.

## 2. Commit message conventions

Commit messages follow the Conventional Commits specification. No hook enforces it: keep to the format below by hand.

### Format

```text
<type>[optional scope]: <Description>

[optional body wrapped at 72 chars]

[optional footer(s)]
```

### The 7 rules

1. Separate the subject from the body with a blank line.
2. Limit the subject line to a maximum of 50 characters.
3. Start the description with a capital letter (e.g. `feat(bin): Add search tool`).
4. Do not end the subject line with a period.
5. Use the imperative mood (e.g. "Add", "Fix", "Remove", not "Added" or "Fixes").
6. Wrap body lines at 72 characters maximum (URLs and `BREAKING CHANGE:` lines exempt).
7. Explain **what** and **why** in the body, not **how**.

### Allowed commit types

| Type | Purpose |
| --- | --- |
| `feat` | New feature or tool |
| `fix` | Bug fix |
| `docs` | Documentation changes |
| `style` | Formatting or markup adjustments (no logic change) |
| `ref` | Refactoring code without adding features (use `ref`, **not** `refactor`) |
| `perf` | Performance improvement |
| `test` | Adding or updating tests |
| `build` | Changes to build processes or external tools |
| `ci` | Changes to CI workflows or scripts |
| `chore` | Dependency upgrades, maintenance, or configuration tweaks |
| `revert` | Reverts a previous commit |

## 3. Code style

### Shell scripts (Bash and Zsh)

- **Linters:** ShellCheck (`shellcheck --rcfile .shellcheckrc`) and `shfmt -w` are enforced by `hk`.
- **Zsh syntax:** Zsh functions and scripts are validated using `zsh -n`.
- **Usage shebang:** CLI tools in `config/bin` that define flags should use `#!/usr/bin/env -S usage zsh` with `#USAGE` comment blocks.
- **Defensive scripting:** Always start non-interactive scripts with `set -euo pipefail`.

### TypeScript

- **Runtime:** Built for [Bun](https://bun.sh) (`bun:test`, `Bun.spawn`, `Bun.file`).
- **Strict typing:** Strict mode is enabled. Never use `any` or unchecked casts; narrow using type guards.
- **Testing:** Use `it()` blocks inside nested `describe()` suites. Prefer table-driven tests for pure functions.

### TOML configuration

- All TOML files (`mise.toml`, `config/**/*.toml`) must be formatted using `taplo fmt`.
- Backups and schema-checked files are validated using `taplo check`.
- `tombi lint --error-on-warnings` must pass on every TOML file: keep each parent's tables together (`tables-out-of-order`). Its rules live in `config/tombi/config.toml`.

## 4. Mise task conventions

Automation in dots is declared as tasks in `mise.toml` (root) or `test/mise.toml`:

- **Naming:** use concise, lowercase task names. Group related tasks with colons (e.g. `setup:git:filters`, `test:specs`).
- **Inline tasks:** define tasks using the inline table syntax with `description` and `usage` parameters:

  ```toml
  [tasks."example:task"]
  description = "Run example process"
  usage = '''
  arg "<target>" help="Target identifier"
  flag "-f --force" help="Force execution"
  '''
  run = '''
  #!/usr/bin/env bash
  set -euo pipefail
  echo "Target: $usage_target"
  '''
  ```

- **Root vs test split:**
  - `mise.toml` (repo root): dev environment bootstrap, Docker image builds, CST testing, and secret setups.
  - `test/mise.toml`: test suite runner (`bdd`, `integration`, `test`). Invoke from repo root with `mise run -C test <task>` or via root alias `mise run test:specs`.
