# Dots — agent instructions

## What this repo is

Dots is a cross-platform dotfiles repository configured via `install` and `mise bootstrap`.
It maintains a single Homebrew `Brewfile` across platforms, links `config/<app>` into `~/.config`,
and builds reproducible development Docker images under `distros/`.

## Layout

| Folder | Contents |
| --- | --- |
| `config/` | Application configurations linked into `~/.config`, Homebrew `Brewfile`, shell helpers (`config/bin`), and mise bootstrap fragments (`config/mise/conf.d/`) |
| `distros/` | Dockerfiles and Container Structure Test manifests for Debian and Ubuntu images |
| `docs/` | Canonical documentation, agent specs/plans (`docs/superpowers/`), and the blog (`docs/blog/`: posts, playbook, roadmap) |
| `.mise/tasks/` | Bun file tasks run by mise (`.mise/tasks/blog/`: `blog:check`, `blog:push`, `blog:stats`, `blog:report`, …) |
| `script/` | Automation scripts (agent skills, restic backups, bootstrap logging, SOPS filter hooks) |
| `test/` | Verification suite: BDD features (`test/features/`) and Bun integration specs (`test/integration/`) |
| `.github/` | CI/CD GitHub Actions workflows (`preview.yml`, `publish.yml`, `release.yml`, `blog.yml`) |

## Workflow

1. **Brainstorm & Spec:** Explore requirements and create design specs under `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`.
2. **Plan:** Draft an implementation plan with step-by-step checkboxes under `docs/superpowers/plans/YYYY-MM-DD-<topic>.md`.
3. **Implement:** Work in an isolated worktree. Old specs and plans live in git history only.

## Quality gate

Keep every gate green before declaring work complete:

- `mise run test:specs` — runs BDD scenarios and all Bun integration test domains (`bin`, `backup`, `bootstrap`, `agents`, `hooks`).
- `hk check --all` — runs repository linters (shellcheck, shfmt, taplo, tombi, hadolint, markdownlint, yamllint, zsh-syntax).
- `mise run zsh:verify` — runs syntax checks and benchmark verification for Zsh configuration changes.
- `mise run build --local --distro <d>` and `mise run test --image dots:<d>-<tag> --config distros/<d>/container-structure-test.yml` — required for Dockerfile, CST, or bootstrap changes.

## Hard rules

- **SOPS Git Filter Wrapper:** Always invoke git with the SOPS filter wrapper:
  `g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }`
- **Never `git add -A` or `git add .`:** Stage named paths only.
- **Never print or commit secrets:** Files such as `config/.env`, `config/ssh/keys/*.key`, `config/ssh/keys/*.pem`, and `config/age/keys.txt` must never be displayed or committed unencrypted.
- **No unrequested push or PR:** Do not push to remote or open a pull request unless explicitly instructed by the user.
- **Conventional Commits:** Write commit messages following Conventional Commits with a capitalized description; see [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md).
- **`.agents` over `.claude`:** Put agent files (commands, skills, agent-agnostic config) in `.agents/` for this project and `~/.agents/` for the user (here `config/agents/`), not in `.claude/` or `~/.claude/`. Add a `.claude/` entry only when Claude Code cannot read the `.agents/` path, and then as a symlink to it (for example `.claude/commands` → `../.agents/commands`, `~/.claude/commands` → `config/agents/commands`). Files only Claude Code reads (`settings.json`) stay in `.claude/`.

## Useful skills

- `systematic-debugging` — investigate failing tests, gate failures, regressions, or unexpected runtime errors.
- `mise-tasks` — orchestrate tasks, task dependencies, or usage specifications in `mise.toml`.
- `mise-expert` — manage mise tool versions, plugins, or environment variables.
- `bash-scripting` — write or debug bash scripts with defensive error handling and ShellCheck compliance.
- `docker-expert` — optimize multi-stage Docker builds, container configs, and CST assertions.
- `writing-plans` — sequence multi-step technical plans with checkpoints and verification steps.
- `brainstorming` — explore tradeoffs, architectural decisions, and alternatives before designing features.
- `verification-before-completion` — execute smoke tests and assert concrete results before completing tasks.
- `receiving-code-review` — systematically review and address critique and feedback.

## Docs

- [`README.md`](README.md) — overview, installation, day-to-day commands, and playbook references.
- [`docs/TESTING.md`](docs/TESTING.md) — test architecture, BDD/Gherkin patterns, and Definition of Done.
- [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) — commit conventions, code style standards, and mise task conventions.
- [`docs/DOCKER.md`](docs/DOCKER.md) — container images, CST testing, and GitHub Actions CI pipelines.
- [`docs/REINSTALL.md`](docs/REINSTALL.md) — backup runbook and clean-machine reinstall procedure.
- [`docs/MACOS.md`](docs/MACOS.md) — macOS preferences (`config/mise/conf.d/macos.toml`), drift checks, and undo.
- [`docs/TILING.md`](docs/TILING.md) — yabai tiling, the fn layer (`config/karabiner`, `config/bin/yb`), and their setup.
- [`docs/GLOSSARY.md`](docs/GLOSSARY.md) — repository-wide definitions and domain terminology.
- [`docs/blog/PLAYBOOK.md`](docs/blog/PLAYBOOK.md) — the blog series: goals, how a post moves, metadata in `TODO.yaml`, and [`STYLE.md`](docs/blog/STYLE.md).
