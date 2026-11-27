# Dots — agent instructions

## What this repo is

Dots is a cross-platform dotfiles repository configured via `install` and `mise bootstrap`.
It maintains a single Homebrew `Brewfile` across platforms, links `config/<app>` into `~/.config`,
and builds reproducible development Docker images under `distros/`.

## Layout

| Folder | Contents |
| --- | --- |
| `config/` | Application configurations linked into `~/.config`, Homebrew `Brewfile`, shell helpers (`config/bin`), and mise bootstrap fragments (`config/mise/conf.d/`) |
| `distros/` | Debian Dockerfile and shared container bootstrap script (`distros/bootstrap.sh`) |
| `docs/` | Canonical documentation and architecture decisions (`docs/adr/`), agent specs/plans (`docs/superpowers/`), and the blog (`docs/blog/`: posts, playbook, roadmap) |
| `*/tasks.toml` | Repo mise tasks, each next to what it manages (`config/zsh/tasks.toml`, `distros/tasks.toml`, …), included by the root `mise.toml` ([`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) §4) |
| `.mise/tasks/` | Bun file tasks run by mise (`.mise/tasks/blog/`: `blog:status`, `blog:new`, `blog:check`, `blog:publish`, …) |
| `.agents/` | Project agent commands (`.agents/commands/blog/`: `/blog:next`, `/blog:pick`, `/blog:draft`, …) and vendored skills (`.agents/skills/`, locked in `skills-lock.json`); `.claude/commands` and `.claude/skills` are symlinks to them |
| `script/` | Automation scripts (agent skills, restic backups, bootstrap logging, SOPS filter hooks) |
| `test/` | Verification suite: BDD features (`test/features/`) and Bun integration specs (`test/integration/`) |
| `.github/` | CI/CD GitHub Actions workflows (`preview.yml`, `publish.yml`, `release.yml`, `blog.yml`) |

## Workflow

1. **Brainstorm & Spec:** Explore requirements and create design specs under `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`.
2. **Plan:** Draft an implementation plan with step-by-step checkboxes under `docs/superpowers/plans/YYYY-MM-DD-<topic>.md`.
3. **Implement:** Work in an isolated worktree. Old specs and plans live in git history only.

The repo's next tasks live in the root [`TODO.yaml`](TODO.yaml), managed with `lida` (roalcantara/lida, Brewfile
dev profile) run from the repo root; the blog's are separate in [`docs/blog/TODO.yaml`](docs/blog/TODO.yaml)
(`mise run blog:todo`).

## Quality gate

Keep every gate green before declaring work complete:

- `mise run test:specs` — runs BDD scenarios and all Bun integration test domains (`bin`, `backup`, `bootstrap`, `agents`, `hooks`, `blog`).
- `hk check --all` — runs repository linters (shellcheck, shfmt, taplo, tombi, hadolint, markdownlint, yamllint, zsh-syntax).
- `mise doctor project` — runs project doctor checks (pins, mise diagnostics, git config, and container checks when in a container).
- `mise run zsh:verify` — runs syntax checks and benchmark verification for Zsh configuration changes.
- `mise run build --local --distro debian --tag <tag>` and `mise run test --image dots:debian-<tag>` — required for Dockerfile or bootstrap changes.

## Hard rules

- **SOPS Git Filter Wrapper:** Always invoke git with the SOPS filter wrapper:
  `g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }`
- **Never `git add -A` or `git add .`:** Stage named paths only.
- **Never print or commit secrets:** Files such as `config/ssh/keys/*.key`, `config/ssh/keys/*.pem`, and `config/age/keys.txt` must never be displayed or committed unencrypted.
- **No unrequested push or PR:** Do not push to remote or open a pull request unless explicitly instructed by the user.
- **Conventional Commits:** Write commit messages following Conventional Commits with a capitalized description; see [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md).
- **`.agents` over `.claude`:** Put agent files (commands, skills, agent-agnostic config) in `.agents/` for this project and `~/.agents/` for the user (here `config/agents/`), not in `.claude/` or `~/.claude/`. Add a `.claude/` entry only when Claude Code cannot read the `.agents/` path, and then as a symlink to it (for example `.claude/commands` → `../.agents/commands`, `~/.claude/commands` → `config/agents/commands`). Files only Claude Code reads (`settings.json`) stay in `.claude/`.

## Useful skills

- `systematic-debugging` — investigate failing tests, gate failures, regressions, or unexpected runtime errors.
- `mise-tasks` — orchestrate tasks, task dependencies, or usage specifications (repo tasks live in `<folder>/tasks.toml`; see `docs/CONTRIBUTING.md` §4).
- `mise-expert` — manage mise tool versions, plugins, or environment variables.
- `bash-scripting` — write or debug bash scripts with defensive error handling and ShellCheck compliance.
- `docker-expert` — optimize multi-stage Docker builds and container configs.
- `writing-plans` — sequence multi-step technical plans with checkpoints and verification steps.
- `brainstorming` — explore tradeoffs, architectural decisions, and alternatives before designing features.
- `verification-before-completion` — execute smoke tests and assert concrete results before completing tasks.
- `receiving-code-review` — systematically review and address critique and feedback.
- `documentation-and-adrs` — record a decision as an ADR (format in `docs/adr/README.md`).

## Docs

- [`README.md`](README.md) — overview, installation, day-to-day commands, and playbook references.
- [`docs/TESTING.md`](docs/TESTING.md) — test architecture, BDD/Gherkin patterns, and Definition of Done.
- [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) — commit conventions, code style standards, and mise task conventions.
- [`docs/adr/`](docs/adr/README.md) — architecture decisions (ADRs): why things are the way they are.
- [`docs/BOOTSTRAP.md`](docs/BOOTSTRAP.md) — what `mise bootstrap` runs, its phase and file tasks, recipes and gotchas.
- [`docs/DOCKER.md`](docs/DOCKER.md) — Debian container image, `mise doctor project` checks, and GitHub Actions CI pipelines.
- [`docs/REINSTALL.md`](docs/REINSTALL.md) — backup runbook and clean-machine reinstall procedure.
- [`docs/MACOS.md`](docs/MACOS.md) — macOS preferences (`config/mise/conf.d/macos.toml`), drift checks, and undo.
- [`docs/TILING.md`](docs/TILING.md) — yabai tiling, the fn layer (`config/karabiner`, `config/bin/yb`), and their setup.
- [`docs/THEME.md`](docs/THEME.md) — The switchable shell theme (`config/dots/config.toml`), tab menus, risky-command highlighting, and the gomi `rm`.
- [`docs/GLOSSARY.md`](docs/GLOSSARY.md) — repository-wide definitions and domain terminology.
- [`docs/blog/PLAYBOOK.md`](docs/blog/PLAYBOOK.md) — the blog series: goals, how a post moves, metadata in `TODO.yaml`, and [`STYLE.md`](docs/blog/STYLE.md).
