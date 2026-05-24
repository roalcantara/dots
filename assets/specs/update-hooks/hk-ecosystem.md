<!-- markdownlint-disable-file -->
# HK Ecosystem Exploration

**Date:** 2026-05-23
**Purpose:** Comprehensive map of hk features, builtins, and ecosystem opportunities for the `dots` project

---

## What is hk?

[hk](https://hk.jdx.dev) (v1.45.0 current) is a Rust-native git hook manager by [@jdx](https://github.com/jdx) (the same author as `mise`). Unlike Python-based managers, hk is:

- **Fast:** Rust startup, no interpreter overhead
- **Parallel-safe:** Uses R/W file locks to safely parallelize staged-file checks
- **Auto-stashing:** Stashes unstaged changes before fix hooks, unstashes after
- **mise-native:** Invokes tools through `mise x` automatically when `HK_MISE=1`
- **Pkl-configured:** Uses Apple's [Pkl](https://pkl-lang.org/) language for type-safe, modular config

---

## hk Feature Map

### Core Hooks Supported

| Hook                 | Trigger               | Typical Use                     |
| -------------------- | --------------------- | ------------------------------- |
| `pre-commit`         | Before every commit   | Lint/format staged files        |
| `commit-msg`         | After message written | Validate commit message format  |
| `prepare-commit-msg` | Before editor opens   | Render default commit templates |
| `post-checkout`      | After branch switch   | Update tooling/env              |
| `post-merge`         | After merge           | Sync dependencies               |
| `post-rewrite`       | After rebase/amend    | Notify/sync                     |
| `pre-rebase`         | Before rebase         | Safety checks                   |
| `post-commit`        | After commit          | Notifications                   |
| `pre-push`           | Before push           | Heavier CI-style checks         |

**For dots:** `pre-commit` + `commit-msg` are the immediate targets. `pre-push` could run heavier Docker linting later.

---

### Built-in Linter Library (90+ presets)

hk ships a `Builtins.pkl` module with 90+ pre-configured linters/formatters.

#### Relevant to dots project:

| Builtin                         | Glob                       | Use in dots                                              |
| ------------------------------- | -------------------------- | -------------------------------------------------------- |
| `Builtins.shellcheck`           | `*.sh`                     | Shell scripts in `config/`, `script/`, `install`         |
| `Builtins.shfmt`                | `*.sh`, `*.bash`           | Shell formatting                                         |
| `Builtins.markdownlint`         | `*.md`                     | README, changelogs, all docs                             |
| `Builtins.hadolint`             | `Dockerfile*`              | `distros/debian/Dockerfile`, `distros/ubuntu/Dockerfile` |
| `Builtins.yamllint`             | `*.yml`, `*.yaml`          | GitHub Actions, `.pre-commit-config.yaml` etc            |
| `Builtins.taplo`                | `*.toml`                   | `mise.toml`                                              |
| `Builtins.prettier`             | `*.md`, `*.yaml`, `*.json` | Alternative to above (opinionated)                       |
| `Builtins.actionlint`           | `.github/workflows/*.yml`  | GitHub Actions workflow validation                       |
| `Builtins.editorconfig-checker` | `*`                        | Enforce `.editorconfig` rules                            |

#### Not directly relevant (no files of this type in dots):
`eslint`, `pyright`, `rubocop`, `rustfmt`, `gofmt`, `biome`, `black`, etc.

---

### Configuration Layering

hk builds config from lowest to highest precedence:

```
Built-in defaults
    ↓
~/.config/hk/config.pkl  (hkrc — user-level)
    ↓
hk.pkl / .config/hk.pkl  (project-level)
    ↓
Git config (global → local)
    ↓
HK_* env vars
    ↓
CLI flags  ← highest precedence
```

**For dots:** This means the distributed `config/hk/hkrc.pkl` sets sensible user defaults (jobs, mise integration) while `hk.pkl` defines project-specific rules. Any user can override per-repo with `hk.local.pkl` (not committed).

---

### mise Integration

The killer feature for this project: hk understands mise natively.

```sh
# Option 1: env var
HK_MISE=1

# Option 2: hkrc.pkl setting
settings { mise = true }

# Option 3: install with mise awareness
hk install --mise
```

When `mise = true`, hk invokes every tool via `mise x -- <tool>`, guaranteeing the correct version is used even if mise's shims aren't on PATH at the time the hook fires.

**This means:** All the tools listed in `mise.toml [tools]` are automatically available to hk steps without any PATH manipulation.

---

### Parallelism Model

```
pre-commit
├── shellcheck  ──────────┐
├── markdownlint ─────────┤  (read locks — all parallel)
├── hadolint  ────────────┤
└── yamllint  ────────────┘
    ↓ (after read steps)
├── shfmt --write  ───────┐  (write lock on *.sh — exclusive)
└── taplo fmt  ───────────┘  (write lock on *.toml — exclusive)
```

**Key insight:** shfmt and taplo each hold write locks on their respective file sets. shellcheck, markdownlint, yamllint, hadolint all run in parallel because they're read-only.

---

### `hk check` and `hk fix`

These are special hooks that can be defined for manual/CI invocation:

```sh
hk check   # Run all check steps (no file modification)
hk fix     # Run all fix steps (with file modification)
```

**For dots:** This enables:
- Developers to run `hk fix` to auto-format before committing
- CI to run `hk check` as a standalone lint step (without triggering git hooks)

---

### Global Install (`hk install --global`)

On Git 2.54+, `hk install --global` writes to `~/.gitconfig`:

```ini
[hook "hk-pre-commit"]
    command = hk run pre-commit

[hook "hk-commit-msg"]
    command = hk run commit-msg
```

**Benefit:** Once installed globally, every repo with an `hk.pkl` file automatically has hk hooks — no per-clone setup needed. Repos without `hk.pkl` are completely unaffected (silent no-op).

---

### Pkl Language Features

hk's Pkl config supports:

| Feature              | What it enables                     |
| -------------------- | ----------------------------------- |
| `amends`             | Extend/override parent configs      |
| `import`             | Import other .pkl files or packages |
| Type-safe schemas    | Catch config errors before runtime  |
| Conditionals & loops | Dynamic step generation             |
| Local variables      | Reuse step definitions              |
| Comments             | Self-documenting configs            |
| HTTP package imports | Share configs across repos via URL  |

**For dots:** The `local stagingLinters = new Mapping<String, Step> { ... }` pattern avoids repeating the step list across `pre-commit`, `fix`, and `check` hooks.

---

### `hk.local.pkl` (Developer Override)

Any developer can create a local `hk.local.pkl` (`.gitignored`) to override project settings:

```pkl
amends "./hk.pkl"
import "./hk.pkl" as repo_config

hooks = (repo_config.hooks) {
    ["pre-commit"] {
        // Disable taplo locally if not installed
        (steps) {
            ["taplo"] { enabled = false }
        }
    }
}
```

---

### Environment Variables

Key `HK_*` env vars for tuning:

| Variable         | Default   | Purpose                                       |
| ---------------- | --------- | --------------------------------------------- |
| `HK_MISE`        | `false`   | Invoke tools via `mise x`                     |
| `HK_JOBS`        | CPU count | Parallel steps                                |
| `HK_STASH`       | `"git"`   | Stash strategy (`git`, `none`)                |
| `HK_PKL_BACKEND` | `"pkl"`   | `"pkl"` or `"pklr"` (built-in Rust evaluator) |
| `HK_FILE`        | auto      | Override config file path                     |
| `HK_LOG`         | `"info"`  | Log level                                     |

---

## Opportunities Summary for dots

### High Value (implement now)

| Opportunity                               | Why                                           |
| ----------------------------------------- | --------------------------------------------- |
| Replace gitlint with `commit-msg` step    | Remove Python dep; encode same rules in shell |
| Replace pre-commit with `pre-commit` hook | Single tool, Rust-fast, parallel              |
| Add shellcheck to pre-commit              | No current staged-file shell linting          |
| Add markdownlint to pre-commit            | Catch docs issues before commit               |
| Add hadolint to pre-commit                | Dockerfile linting currently only in CI       |
| Distribute `hkrc.pkl` as dotfile          | User-level defaults for all repos             |
| `hk install --global` in install script   | Zero per-repo setup                           |

### Medium Value (consider later)

| Opportunity                | Why                                                      |
| -------------------------- | -------------------------------------------------------- |
| Add `yamllint` step        | Catch YAML errors in GitHub Actions files early          |
| Add `taplo` for TOML       | Consistent `mise.toml` formatting                        |
| Add `actionlint` step      | GitHub Actions workflow validation locally               |
| Add `editorconfig-checker` | Enforce `.editorconfig` rules on all staged files        |
| Add `pre-push` hook        | Run heavier Docker builds pre-push instead of only in CI |

### Low Value / Out of Scope

| Opportunity                   | Why Not Now                                            |
| ----------------------------- | ------------------------------------------------------ |
| `prepare-commit-msg` template | No issue tracker integration currently needed          |
| `post-merge` hook             | Deps sync already handled by mise auto-install         |
| Prettier for markdown         | markdownlint is more targeted; prettier is opinionated |
| Python/Ruby/Go linters        | No files of those types in dots                        |

---

## Tool Availability via mise

The following tools need to be in `mise.toml [tools]` for hk to resolve them:

| Tool                | Already in mise.toml? | Action         |
| ------------------- | --------------------- | -------------- |
| `hk`                | ✅ `hk = "latest"`     | None           |
| `shellcheck`        | ❓ Check               | Add if missing |
| `shfmt`             | ❓ Check               | Add if missing |
| `markdownlint-cli2` | ❓ Check               | Add if missing |
| `hadolint`          | ❓ Check               | Add if missing |
| `yamllint`          | ❓ Check               | Add if missing |
| `taplo`             | ❓ Check               | Add if missing |

> **Note:** With `HK_MISE=1`, mise will auto-install any declared tool before running it. But if the tool is not in `mise.toml`, it won't be found.
