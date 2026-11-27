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
- **Never commit unencrypted secrets:** `config/ssh/keys/*.key` and `config/age/keys.txt` must remain encrypted or excluded.
- **Do not push unasked:** only push branches and open pull requests when explicitly directed.

### Merging pull requests

- **Merge with a merge commit, or rebase:** squash merging is disabled on the repository.
- **Why:** `semantic-release` reads every commit's type and scope, but a squash merge keeps only the title and drops the commits inside: 67 of 68 `feat`/`fix` commits from October to November 2026 never reached a release.
- **Context:** [`docs/adr/0001-releases.md`](adr/0001-releases.md) records the decision and its consequences.

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

A task lives next to what it manages, so you know where to look without searching:

- **Repo tasks:** in `tasks.toml` inside the folder of what the task manages, one topic per file (zsh tasks in
  `config/zsh/tasks.toml`, the Docker image tasks in `distros/tasks.toml`). The root `mise.toml` includes them with
  `[task_config] includes = [".mise/tasks", "*/tasks.toml", "config/*/tasks.toml"]` and declares no task itself, so a
  new topic needs only its `tasks.toml`. They run from the repo root, whatever the current folder.
- **Top-level names in `tasks.toml`:** an included file names its tasks as top-level tables (`["zsh:verify"]`, not
  `[tasks."zsh:verify"]`). It is not called `mise.toml`, because mise would also load any `mise.toml` on its own from
  that folder (and through the `~/.config` links), where that form is invalid.
- **Subprojects:** a `mise.toml` in a subfolder is a separate project with its own tools, run with
  `mise run -C <folder> <task>`: `test/mise.toml` (the suite: `bdd`, `integration`, `test`; `mise run test:specs` runs
  it all), `config/nvim/mise.toml`, `config/bin/mise.toml`.
- **File tasks:** executable scripts in `.mise/tasks/<topic>/` (mise's default folder, linted like other scripts), named
  by their path (`.mise/tasks/blog/new.ts` is `blog:new`).
- **Bootstrap tasks:** global, in `config/mise/conf.d/tasks.toml` ([`docs/BOOTSTRAP.md`](BOOTSTRAP.md)).
- **Naming:** use concise, lowercase task names. Group related tasks with colons (e.g. `zsh:verify`, `test:specs`).
- **Describe every task:** a `description` (shown by `mise tasks ls` and on Tab after `mise run`) and a `usage` spec
  for its arguments:

  ```toml
  ["example:task"]
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
