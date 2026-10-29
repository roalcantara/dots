<!-- markdownlint-disable -->
# Handoff: mise-bootstrap, from Task 7

You are taking over the implementation of a plan in the `dots` repository (`~/Work/dots`, branch
`feat/mise-bootstrap`). Tasks 1–6 are done, reviewed and committed. Start at **Task 7**.

## Read first, in this order

1. `assets/specs/mise-bootstrap/tasks.md` — the plan. Each task has exact files, code, commands and expected
   output; ticked boxes are done. Its **Findings** section (end of file) records what every task learned:
   read it before you start, it explains several non-obvious decisions.
2. `assets/specs/mise-bootstrap/design.md` — the spec (§4.4 `install`, §4.5 images, §8 testing).
3. `AGENTS.md` at the repo root — repo conventions.

## What this work is

`install` (repo root) was rewritten into a short, idempotent entry point: it creates the user if missing, sets
sudo/timezone, opens an encrypted secrets archive (`--secrets`), switches root → user, installs a pinned mise
(2026.10.21), links the repo, copies secrets, then runs `mise bootstrap`. Everything else is declarative in
`config/mise/conf.d/{bootstrap,dotfiles,packages}.toml`. Profiles: `desktop` = workstations (default on hosts),
`container` = Docker images (default in containers; `DOTS_CONTAINER=1` is set in the Dockerfiles).

## Remaining tasks

| Task | What | Who |
| --- | --- | --- |
| 7 | Build the Debian image (`mise run build --local --distro debian --tag local`), check no decrypted secrets in it, run `install` inside it as root with a **fixture** archive, then again (idempotent), run the structure tests; then Ubuntu | you |
| 8 | Ubuntu VM in Parallels, `curl` one-liner with the fixture archive | owner (manual) — prepare the commands, do not run |
| 9 | Docs (README, DOCKER_GUIDE, AGENTS, dots-context skill) | you |
| 10 | macOS VM rehearsal | owner (manual) |
| 11 | Reinstall the real Mac, then delete flox/Brewfile/old lists | owner (manual), then you for the deletions |

The success criteria (design.md §1): the Debian image and the Ubuntu VM run `install` with the fixture archive
successfully, and a second run changes nothing.

## Hard rules

- **This Mac is the owner's real machine.** Never run `install` without `--dry-run`, never run
  `mise bootstrap` (only `status`, `plan`, `--dry-run`), never `mise dot apply`, on the host. Everything real
  happens inside Docker.
- **Secrets:** use only fixture archives: `script/prepare-secrets --fixture --output <tmp>/fixture.zip.enc`
  (passphrase `dots-fixture`). Never commit a fixture. The owner's real archive is committed on purpose as
  `assets/dump.zip.enc` — never decrypt it, never pass it to anything.
- **Images build from the committed tree** (`git archive HEAD` with the SOPS smudge filter off), so commit a fix
  before rebuilding. Never push images. Ignore Docker Hub.
- **GitHub token for builds:** `.secrets/github_token.secret` is valid (checked); the build task passes it as a
  build secret. Never print a token.
- **Do not write to the external drive** `/Volumes/meex900`: its exFAT (FSKit) driver corrupts new writes.
- **Commits:** Conventional Commits, sentence-case subject ≤72 chars; `git add <paths>` then `git commit` (never
  `-a`, never `git commit <paths>`). Commits are SSH-signed through an already-loaded agent; if signing fails,
  stop and ask (do not disable signing). The `hk` pre-commit hook may reformat files (re-stage, commit again)
  and may make mise auto-install tools declared in the global config (expected).
- **Shell:** macOS, zsh. `install` and `script/prepare-secrets` must keep working under `/bin/bash` 3.2.
- **Tests:** `cd ~/Work/dots/assets && bun test integration/install/` (27 tests) must stay green; `shellcheck`
  `install` and `script/prepare-secrets` must stay clean. If you change `install`, add or adjust a spec case.
- **Plan upkeep:** tick each step as done; add one-line `- Task N:` findings; if code differs from a plan block,
  make the block byte-identical to the committed file.

## Known issues and expectations for Task 7

- The repo-wide `hk check --all` already fails on shfmt diffs in `config/nvim/tools/baseline.sh` and
  `config/raycast/scripts/*.sh` (not this branch's doing). Lint the files you touch directly instead.
- Likely first-build failures to debug from the log (keep logs in `/tmp/dots-build-*.log`, read them with
  `grep -nE 'ERROR|error:|failed' | tail -40`, not whole):
  - `--tz` rejected if the base image lacks tzdata → install `tzdata` in the Dockerfile `base` stage.
  - A formula failing, or building from source for a long time, on Linux arm64 → add `env = "desktop"` to its
    entry in `config/mise/conf.d/packages.toml` (keeps it on workstations, out of images).
  - Whether mise's native Homebrew bottles land in `/home/linuxbrew/.linuxbrew/bin` (on the image `PATH`); the
    structure test "core tools should be installed by mise bootstrap" will tell.
- The root → user switch (`sudo -u`) has never run for real; Task 7 is its first real test. The secrets copy and
  the regenerated script live in `/tmp/dots-*` and must be gone after the run.
- If a fix needs a design decision (dropping a feature, changing a default), stop and ask the owner.

## When you finish a task

Report what passed (with the key output lines), every fix (file, reason, commit SHA), and anything you could not
do. Stop before Task 8 and hand the owner the exact commands for the Ubuntu VM.
