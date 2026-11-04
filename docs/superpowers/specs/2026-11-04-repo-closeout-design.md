# Repo close-out — design

**Date:** 2026-11-04

**Status:** Approved approach A (consolidate); this document awaits the owner's review.

**Scope:** the whole repository: removals, the `assets/` split into `docs/` and `test/`, one canonical doc set,
a green test gate, and a non-blocking, parallel `skills:restore`.

## 1. Goal

The repository holds only what dots uses. Every topic is documented once. `mise run test:specs` and
`hk check --all` pass. Agent plans and specs live under `docs/superpowers/`. Old specs exist only in git history.
`mise bootstrap` no longer waits for agent skills.

**Done when:**

1. None of the removals in §3 exist, and nothing in the tree references them: the stale-term search in §8 is
   empty outside `CHANGELOG.md`.
2. `assets/` is gone. Docs are in `docs/`, tests in `test/`.
3. The canonical doc set in §4 is the only place each topic is covered. Every relative Markdown link resolves.
4. `mise run test:specs` runs every test domain and passes. `hk check --all` is clean. The Ubuntu image builds
   and passes its CST.
5. On a desktop, `mise bootstrap` finishes without waiting for `skills:restore`, which runs in parallel in the
   background and raises an OS notification when done (§6).

## 2. Findings (2026-11-04)

From a read-only audit of the tree and a web survey of dotfiles conventions.

| Finding | Evidence |
| --- | --- |
| The skills registry is dead | `assets/scripts/skill-registry.ts`, `assets/guides/SKILLS.{md,yml}` back `mise run -C assets skill …`, a task that never existed; `skills-lock.json` (bun-development, bun-runtime) is read only by that script |
| `test all` is red on `main` | Six specs under `assets/integration/bin` test bins removed on 2026-10-20 (`xc-md`, `xc-skills`, `xc-usage`, `keyring`, `osx`, `yw`); two BDD scenarios fail (below) |
| BDD `bin` failures | "launcher help" runs `zsh config/bin/xc -h`, bypassing the `usage` shebang, so `-h` hits `_xc_main`'s unknown-command branch (`config/bin/xc:288-309`); "lists tools" uses a fixture with legacy `##?` headers and a PATH without `usage` |
| Tests not run | `test all` skips `integration/agents` and `integration/hooks`; CI runs no `assets/` test |
| Lockfile | `assets/bun.lock` is ignored by `*.lock`, yet the `bdd` task runs `bun install --frozen-lockfile` |
| Foreign docs | `CI_GUIDE.md` describes an electrobun/kodexb pipeline; `CODESTYLE_GUIDE.md` says "for kodexb" |
| Stale references | About 45 lines cite missing `.mdc` rules, gitlint, `ci:*`/`skill` tasks, a root `[tools]` table, removed `xc-*` tools; `config/zsh/README.md` is stale throughout |
| Duplication | Testing in 7 places, git and commits in 5, BDD in 3, the agent entry in 4 (`AGENTS.md`, `dots-context`, `SKILLS.md`, `.cursor/dots-skill-routing.md`) |
| Broken links | The 3 owned `.agents/skills/dots-*` have 20 relative links one level short |
| Junk | `script/skills.txt` (pasted error), `script/skills.json` (empty), `assets/all/skill.md` (broken symlink), `assets/integration/fixtures/` (unused duplicate of `bin/fixtures`) |
| `skills:restore` is slow and blocking | `script/agent-skills.ts:291-293` installs ≈60 sources one after another; `bootstrap.toml:94` waits for it |
| `xc-toast` is not an OS notification | It draws a terminal overlay with `tput` (`config/bin/xc-toast:45-55`) |
| Conventions | mise prescribes no repo tree; `config/<app>` + `conf.d/dotfiles.toml` already fit it ([mise dotfiles](https://mise.jdx.dev/dotfiles.html)). `docs/superpowers/{plans,specs}/` is Superpowers' default ([writing-plans](https://github.com/obra/superpowers/blob/main/skills/writing-plans/SKILL.md)). `AGENTS.md` at the root is the agent entry ([agents.md](https://agents.md/)). Shell repos keep tests under one `test/` root ([bats](https://bats-core.readthedocs.io/en/stable/tutorial.html)). Diátaxis advises against empty four-folder trees ([Diátaxis](https://diataxis.fr/how-to-use-diataxis/)) |

## 3. Decisions

| Decision | Choice | Why |
| --- | --- | --- |
| Approach | A, consolidate | The problem is duplicated and stale docs; B (Diátaxis + ADRs) adds structure a one-owner repo won't fill; C (move as is) keeps the duplication |
| Agent artifacts | `docs/superpowers/plans/YYYY-MM-DD-<topic>.md`, `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` | Superpowers' defaults; no override needed |
| Old specs | All removed, `assets/specs/` **and** the 10 existing files in `docs/superpowers/` (Aug–Sep 2026); git history keeps them | The owner asked for every old spec to live only in git history; this document is the first under the new convention |
| Agent entry | `AGENTS.md` only; `.agents/` removed after merging its 3 owned skills | Every agent reads `AGENTS.md`; the skills duplicated it |
| Cursor | Removed: `.cursor/`, `.cursorignore`, `config/cursor` and its link | Not used |
| graphify | Keep the tool (bootstrap `uv` install, Brewfile); remove `graphify-out/` and its repo references | Used elsewhere; the committed graph is stale (2026-05-08) |
| Unused app configs | Reviewed one by one (§3.2) | Owner's choice |
| CI test job | Not now | Owner's choice |
| Rejected: `home/` mirror (chezmoi style), moving `config/mise` to `.config/mise` | — | A restructure, not a clean-up; `~/.config/mise` already links to `config/mise` |

### 3.1 Removed

- `.agent/`, `.claude/` (tracked kfc agents and settings), `.cursor/`, `.cursorignore`, `.specify/`, `graphify-out/`
- `assets/specs/`, `assets/.vscode/`, `assets/all/`, `assets/README.md`, `assets/integration/fixtures/`,
  `assets/scripts/skill-registry.ts`, `assets/guides/SKILLS.md`, `assets/guides/SKILLS.yml`
- `skills-lock.json`, `.agents/` (after §4 merges its owned skills)
- `docs/superpowers/plans/*` and `docs/superpowers/specs/*` dated before 2026-11-04
- `config/cursor/` and its `dotfiles.toml` link
- `script/skills.txt`, `script/skills.json`, `script/catalog_global_skills.py`, `script/fix_skill_commands.rb`
- `config/bin/HANDOFF-USAGE-MIGRATION.md`
- The specs and fixtures for the removed bins: `xc-md`, `xc-skills`, `xc-usage` (and `bin/fixtures/xc-usage`),
  `keyring`, `osx`, `yw`
- The legacy commented `"brew:…"` lines in `config/homebrew/Brewfile` (about lines 105–135)
- Every reference to the above: `hk.pkl`, `.gitignore`, `.markdownlintignore`, `.gitattributes`, `mise.toml`,
  `AGENTS.md`, `README.md`, code comments citing `assets/specs/…` (≈40; drop the citation, restate the reason in
  one line where it matters)

### 3.2 Reviewed one by one

The plan lists each with its `dotfiles.toml` link, Brewfile state and last change. Execution stops at that table
until the owner marks each **keep** or **delete**: `config/opencode`, `config/glow`, `config/amethyst`,
`config/skhd`, `config/rift`, `config/ranma`, `config/glide`, `config/dinky`, `config/claude/commands/opsx`.

## 4. Docs

| Canonical | Holds | Merged from |
| --- | --- | --- |
| `README.md` | What dots is, install, how it works, day to day, playbooks, gotchas, layout, a **Docs** index | itself; `assets/README.md`; the `assets/guides/README.md` index; the `MISE_GUIDE` task table |
| `AGENTS.md` | The agent entry: layout, where plans and specs go, the quality gate, hard rules (SOPS filter, never `git add -A`, no pushes unasked), the companion skills that are actually useful | `.agents/skills/dots-context`, `dots-quality-gate`, `dots-testing`; the policy parts of `SKILLS.md`; `.cursor/dots-skill-routing.md` |
| `docs/TESTING.md` | The gate (`test:specs`, `hk check`, `zsh:verify`, CST), Bun integration-spec patterns, BDD and Gherkin rules, the definition of done | The dots parts of `TESTING_GUIDE`; `BDD_GUIDE`; `BDD_GHERKIN_GUIDE`; `features/README.md`; `DoD.md` |
| `docs/CONTRIBUTING.md` | Commits, code style, mise task conventions | `GIT_GUIDE`; `GIT_COMMITS_GUIDE`; the dots parts of `CODESTYLE_GUIDE`; `MISE_GUIDE` conventions |
| `docs/DOCKER.md` | Images, CST, and one section on the real workflows (`preview`, `publish`, `release`) | `DOCKER_GUIDE`; `CI_GUIDE` is dropped |
| `docs/REINSTALL.md` | Backup and reinstall | `REINSTALL_GUIDE`; the runbook `README.md:164` links into `assets/specs/mise-bootstrap` (§6 of that design), moved here before the spec is removed; row 29 fixed to `config/agents/skill-lock.json` |
| `docs/GLOSSARY.md` | Terms | `GLOSSARY` minus removed terms (`xc-usage`, `xc-md`, `show_usage`, spec/skill-registry terms) |
| `config/*/README.md` | Per-app notes | `config/zsh/README.md` rewritten to the current functions; `config/bin/README.md` pruned to existing tools and tasks |

Rules: keep only what is true of dots today; no generic tutorials (BetterSpecs, Fishery), nothing from kodexb or
electrobun, no references to `.mdc` rules or gitlint. External guidance is linked, not copied.

References that move with the guides: `script/backup.ts` (header and the GitHub URL in the drive README),
`config/restic/backup.toml`, `config/restic/backup.schema.json`, `config/mise/conf.d/backup.toml`, `cog.toml`.

## 5. Tests

- `git mv` the test parts of `assets/` to `test/`: `mise.toml`, `package.json`, `tsconfig.json`, `features/`,
  `integration/`. Update the hard-coded paths in `features/support/paths.ts`, `integration/bin/support/paths.ts`
  and the bootstrap spec, and every `mise run -C assets`.
- Track `test/bun.lock` (`!test/bun.lock` after `*.lock` in `.gitignore`).
- A root task `test:specs` runs `mise run -C test test all`. The root `test` task stays the CST.
- `test all` runs `bin`, `backup`, `bootstrap`, `agents` and `hooks`.
- Fix the BDD `bin` scenarios: the `xc-launcher` fixture uses `#USAGE` headers; the steps put the `usage`
  binary's folder on PATH; `xc` answers `-h`/`--help` (and `help`) in `_xc_main` with its usage text.
- The root `.dockerignore` already excludes `test/`, so the image build context shrinks.

## 6. `skills:restore`: parallel and in the background

### 6.1 Parallel

`restore()` in `script/agent-skills.ts` runs a pool of `SKILLS_JOBS` (default 6) `skills add` processes with
`Bun.spawn`, one per source:

- Each worker gets its own throwaway `XDG_STATE_HOME`, so concurrent runs never share the CLI's lock file.
- Each source writes to its own log under the run's state folder; the terminal shows one line per finished
  source (`✓ owner/repo (12)` or `✗ owner/repo, log: …`), never interleaved output.
- The final check stays: what is still missing after all workers finish decides the exit code and summary.
- Before relying on it, a spike runs two `skills add` for different sources at once against a temp `HOME` and
  checks the agent links (`~/.claude/skills`, …) and `~/.agents/skills`. If they race, the default becomes
  `SKILLS_JOBS=1` (the background part of §6.2 still removes the wait), and a serial retry pass reinstalls any
  source whose skills are still missing after the pool.

### 6.2 In the background

The `bootstrap` task (desktop only) starts `skills:restore` detached and moves on:

```bash
state="${XDG_STATE_HOME:-$HOME/.local/state}/dots"
if [ -n "${DOTS_SKILLS_FOREGROUND:-}" ]; then
  mise run -C "$dots" skills:restore || warn "skills:restore"
else
  nohup bun "$dots/script/agent-skills.ts" restore --background >"$state/skills-restore.log" 2>&1 &
  echo "bootstrap: restoring agent skills in the background (log: $state/skills-restore.log)"
fi
```

`restore --background`:

- Takes a lock (`$state/skills-restore.pid`, holding its PID); if a live process already holds it, it exits 0
  with "already running".
- On finish, writes `$state/skills-restore.result` (`542 installed, 3 failed: a, b, c`) and sends an OS
  notification:
  - macOS: `osascript -e 'display notification "<result>" with title "dots: agent skills"'`
  - Linux: `notify-send "dots: agent skills" "<result>"` when `notify-send` exists and `DISPLAY`,
    `WAYLAND_DISPLAY` or `DBUS_SESSION_BUS_ADDRESS` is set
  - Otherwise nothing extra: the result file and the log hold it.
- A failure also writes `$state/skills-restore.failed`; the next interactive zsh prints it once and deletes it
  (one line in `config/zsh`), so a headless VM still learns about it.
- Releases the lock on exit, including on error.

`mise run skills:restore` stays the foreground command (retries, watching progress). `DOTS_SKILLS_FOREGROUND=1`
restores the old blocking behavior in the bootstrap.

### 6.3 Tests

In `test/integration/agents/` with a stub `skills` on PATH: the pool runs at most `SKILLS_JOBS` at once (the stub
records start and end times); each worker gets a distinct `XDG_STATE_HOME`; a failing source is reported and
the exit code is non-zero; `--background` writes the result file, the failed marker on failure, and honours
the lock; the notifier is called with the result (stub `osascript`/`notify-send`). The bootstrap snippet is
checked like the post-packages hook spec: extracted from `bootstrap.toml`, run with a stub `bun`, it returns
at once and `DOTS_SKILLS_FOREGROUND=1` runs in the foreground.

## 7. Delivery

One worktree (`~/Work/dots-closeout`), branch `chore/repo-closeout`, one PR. Commits grouped by area so each is
reviewable on its own: removals; `assets/` → `test/` and the test fixes; docs; app-config review; skills restore.

## 8. Verification

- `mise run test:specs` green; `hk check --all` clean.
- `mise run build --local --distro ubuntu --tag closeout`, then `mise run test --image dots:ubuntu-closeout
  --config distros/ubuntu/container-structure-test.yml`: passes, size not larger than `main`'s.
- Every relative Markdown link resolves (a small check over `git ls-files '*.md'`).
- This search prints nothing outside `CHANGELOG.md` and this document:
  `git grep -nE 'assets/|\.cursor|skills-lock|SKILLS\.yml|skill-registry|devcontainer|starship|xc-usage|xc-md|kodexb|electrobun|gitlint|\.mdc\b|graphify-out'`
- On this Mac: `mise bootstrap -E desktop` returns before the skills finish, prints the log path, and a
  notification appears when they are done.

## 9. Risks

| Risk | Mitigation |
| --- | --- |
| A removed file was used after all | Each removal's references are listed in the audit; the stale-term search and the full gate run before the PR |
| Merging guides drops something true | Each canonical doc's plan step lists the source sections kept; anything dropped is generic or stale by the rules in §4 |
| Concurrent `skills add` races | The §6.1 spike decides; fallback is a serial pass for failures |
| A background restore outlives a failed bootstrap and confuses the next run | The PID lock makes the next run report "already running"; the result file says what happened |
| Notifications need permission on macOS | The first `osascript` notification may ask; the result file and the zsh one-liner cover a denied permission |
