# Quality checks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace CST and the per-PR image builds with a strict bootstrap plus `mise doctor project` in a Debian
base container, publish one Debian image at release, and delete every check that only echoes a declaration.

**Architecture:**
- One shared script, `distros/bootstrap.sh`, holds the install steps. The Dockerfile and the PR job both call it.
- Three new doctor checks run repo file tasks under `.mise/tasks/doctor/`. They reuse `_lib.sh`'s `has_profile`
  through the `bootstrap_step` template.
- PR CI runs the script in `mcr.microsoft.com/devcontainers/base:debian`, unless only docs changed. Release builds,
  checks and pushes the Debian image.

**Tech Stack:** mise 2026.11.14 (`[doctor.checks]`, task templates, `--save-env`), bash, Bun specs, GitHub Actions
(`container:` jobs), Docker buildx, hk.

**Spec:** [`docs/superpowers/specs/2026-11-27-quality-checks-design.md`](../specs/2026-11-27-quality-checks-design.md)
is the only source of architectural decisions. Read all of it, including Facts, Kinds and the CST map, before Task 1.
Where this plan and the spec disagree, the spec wins: stop and report.

## Global Constraints

- **Branch:** `feat/mise-bootstrap-tasks`, no worktree.
- **git:**
  - Always through the SOPS wrapper: `g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }`.
  - Stage named paths only.
  - Conventional Commits with a capitalized description, ending with the session's `Co-Authored-By` line.
  - **No push, no PR**, including a test PR. CI on GitHub is the owner's checkpoint (Task 8).
- **Distro:** Debian only. Docker Hub tags stay `debian-latest`, `debian-{{version}}`, `debian-{{major}}.{{minor}}`,
  `debian-{{major}}`, `debian-<sha>`. No plain `latest`. `ubuntu-*` is no longer pushed; existing tags are left alone.
- **Strict:** every bootstrap the script runs has `DOTS_STRICT=1` and `-E container --save-env --force-dotfiles
  --skip user --yes`.
- **Doctor checks** never echo a declaration. Each derives its list from a source of truth (the Brewfile,
  the steps' gates, `.gitattributes`), never from a hand-written list in the check.
- A check that does not apply prints `does not apply: <reason>` and exits 0.
- **Specs test behaviour,** never the owner's chosen config values (this is what Tasks 6 and 7 enforce).
- **Leave alone:** `docs/blog/posts/**`, and the untracked, git-ignored `config/mise/conf.d/.env.sh`.
- **Gates before each commit:** that task's specs, plus `hk check` on the touched files. Before the handoff: Task 8.

## Review Focus

1. **The Mac must stay green.** On the owner's Mac (`mise_env` = desktop,dev), `mise doctor project` passes. Each new
   check prints `does not apply` there. Test in Task 2 (`mise doctor project` run on the Mac).
2. **A fresh container with no saved profile.** If `--save-env` did not run, the checks default to `desktop`, say
   `does not apply` and pass silently. That's why Task 1 asserts that the image's `miserc.local.toml` holds
   `container`.
3. **The Brewfile's container group grows.** Adding a formula there must be checked without editing the check.
   Test in Task 2: the check stubs a failing `brew bundle check` and fails.
4. **A docs-only PR with a renamed `.md` under `config/`** still skips bootstrap. A PR touching `config/zsh/` or
   `.gitattributes` runs it. Test in Task 3 (filter cases).
5. **A spec case that mixes echo and behaviour** keeps its behaviour assertions (Tasks 6 and 7: each commit body
   lists the cases it trimmed, not only the deleted ones).

## Baseline (before Task 1)

Save to `B="$(g rev-parse --git-common-dir)/wip/quality-checks-baseline"`:

- [ ] `g rev-parse HEAD > $B/base.txt`
- [ ] For every `test/integration/**/*.spec.ts`: `grep -c 'it(' <file>` → `$B/spec-cases.txt` (file, count). The
  total is 844 at the time of writing.
- [ ] `mise doctor project > $B/doctor-mac.txt 2>&1` (3 passed).
- [ ] `gh run list --workflow preview.yml --limit 5 --json createdAt,updatedAt > $B/preview-times.json`

---

### Task 1: Shared bootstrap script, strict image build

**Files:**
- Create: `distros/bootstrap.sh`
- Modify: `distros/debian/Dockerfile` (`local` and `remote` stages call the script), `.mise/tasks/mise/version.sh`
  and `test/integration/bootstrap/mise-version.spec.ts` (the `MISE_VERSION` pin now lives in `distros/bootstrap.sh`
  instead of the Dockerfiles)
- Test: new `test/integration/bootstrap/distro-bootstrap.spec.ts`

**Interfaces (Produces):**
- `distros/bootstrap.sh`, run as the image user from any folder, with the checkout already at
  `$HOME/.local/share/dots`:
  - installs mise `MISE_VERSION=v2026.11.14` with `curl -fsSL https://mise.run`, unless `~/.local/bin/mise`
    already reports that version
  - links `~/.config/mise` → `../.local/share/dots/config/mise`
  - runs `DOTS_STRICT=1 ~/.local/bin/mise bootstrap -E container --save-env --force-dotfiles --skip user --yes`
  - uses `GITHUB_TOKEN` when the caller set it, and never prints it
- The Dockerfile's `RUN` keeps the `github_token` secret mount and only exports the token, then calls the script.

- [ ] **Step 1: Failing spec** `distro-bootstrap.spec.ts`. Run the script with a temp `HOME` and a stub `curl` and
  `mise` on PATH that record their argv:
  - `runs mise bootstrap strictly for the container profile and saves it`: the recorded `mise` argv equals
    `bootstrap -E container --save-env --force-dotfiles --skip user --yes`, with `DOTS_STRICT=1` in its env.
  - `links ~/.config/mise to the checkout's config/mise`: `readlink` equals `../.local/share/dots/config/mise`.
  - `skips the installer when the pinned mise is present`: with a stub `~/.local/bin/mise` answering
    `2026.11.14`, `curl` is not called.
  - `a failing bootstrap fails the script`: the stub `mise bootstrap` exits 3, so the script exits non-zero.
  - `the Dockerfile's local and remote stages call distros/bootstrap.sh and carry no MISE_VERSION`
- [ ] **Step 2:** It fails. **Step 3:** Implement, and update `mise:version` to read the pin from
  `distros/bootstrap.sh`. **Step 4:** The spec, `mise-version.spec.ts` and `mise run mise:version --check` pass.
- [ ] **Step 5: Strict build.** Set `DOCKER_HOST` from `docker context inspect`, then run
  `mise run build --local --distro debian --tag qc`.
  - Expected: the build succeeds and the image's `~/.config/mise/miserc.local.toml` contains `container`
    (`docker run --rm --entrypoint cat dots:debian-qc <path>`).
  - If a step fails only because strict mode is now on: fix it if the fix is local to that step and needs no design
    change (about 20 lines or fewer). Otherwise **stop and report** the step, its log, and the proposed fix.
- [ ] **Step 6: Commit:** `refactor(distros): Run the image bootstrap from one strict shared script`. List every step
  you fixed in Step 5 in the body.

### Task 2: Doctor checks from CST's non-echo entries

**Files:**
- Create: `.mise/tasks/doctor/container-tools.sh`, `.mise/tasks/doctor/profile-parts.sh`,
  `.mise/tasks/doctor/sops-encrypted.sh` (hidden file tasks, `#MISE extends="bootstrap_step"`, sourcing `_lib.sh`)
- Modify: `config/mise/conf.d/tasks.toml` (three `[doctor.checks.*]`); each step gated by
  `has_profile desktop || exit 0` or `has_profile dev || exit 0` gains one `#DOTS artifact=<path under $HOME>` line,
  or `#DOTS artifact=-` when it leaves nothing on disk
- Test: new `test/integration/bootstrap/doctor-checks.spec.ts`; `bootstrap-structure.spec.ts`

**Interfaces:**
- Consumes: `has_profile`, `DOTS_DIR` from `_lib.sh`, and `DOTS_ENV_PROFILES` from the `bootstrap_step` template.
- Produces:
  - Tasks `doctor:container-tools`, `doctor:profile-parts`, `doctor:sops-encrypted`.
  - Doctor checks with the same three names. Each runs `mise run -C {{ vars.dots }} doctor:<name>`, with a
    `description` and a `hint` that says how to fix it.
  - Every check starts with `has_profile container || { echo "does not apply: profile is not container"; exit 0; }`.
  - `container-tools`: `zsh -lic` finds `brew`, then
    `HOMEBREW_DOTS_PROFILE=container brew bundle check --file "$DOTS_DIR/config/homebrew/Brewfile"`.
  - `profile-parts`: for each step file whose gate excludes `container`, the path in its `#DOTS artifact=` line must
    not exist under `$HOME`. Ignore `-`. On a failure, name the path and the step.
  - `sops-encrypted`: list every file that `git -C "$DOTS_DIR" check-attr filter` tags as `filter: sops`
    (`ls-files` piped into `check-attr --stdin`). Each must contain `ENC[AES256_GCM,`. On a failure, name the file.

- [ ] **Step 1: Failing specs.** `doctor-checks.spec.ts` runs each task through the real `mise run`, with a temp
  `HOME` and the template copied, as `step-profile.spec.ts` does:
  - `each check does not apply outside the container profile` (`DOTS_ENV_PROFILES=desktop,dev`): exit 0, and stdout
    contains `does not apply`.
  - `container-tools fails when brew bundle check fails, and passes when it succeeds` (stub `brew`).
  - `profile-parts fails naming a present artifact, passes when none exists`. Create one artifact named in a real
    step's header.
  - `sops-encrypted fails naming a plain-text file, passes on an encrypted one`. Use a temp git repo with a
    `filter=sops` `.gitattributes` line and `DOTS_DIR` pointing at it.
  - Structure spec: `every step gated to desktop or dev declares exactly one #DOTS artifact line`.
- [ ] **Step 2:** They fail. **Step 3:** Implement. **Step 4:** They pass.
- [ ] **Step 5: Mac.** `mise doctor project` reports 6 passed, 0 failed. The three new checks say `does not apply`.
- [ ] **Step 6: Image.** Rebuild `dots:debian-qc`, then run
  `docker run --rm --entrypoint /usr/bin/zsh dots:debian-qc -lic 'mise doctor project'`.
  - Expected: 0 failed, and the three new checks really run. `mise-version` is skipped (macOS only).
  - If `mise-diagnostics` fails in the image only because Bun or `mise lsp` is missing there, give it
    `os = "macos"` and say so in the commit body. Fix any other failure.
  - Negative proof, once per check, on a container started from the image: remove `bat` from PATH, create one
    artifact path, and overwrite one SOPS file with plain text. Each makes its check fail. Record the three outputs
    in the commit body.
- [ ] **Step 7: Commit:** `feat(doctor): Check the container's tools, profile parts and encrypted files`.

### Task 3: PR pipeline: base-container bootstrap, no image

**Files:**
- Create: `.github/needs-bootstrap.sh`. It reads changed paths, one per line, on stdin. It exits 0 when any path
  is outside `docs/**` and is not `*.md`. It exits 1 when every path is docs or Markdown, or when there is none.
- Modify: `.github/workflows/preview.yml`
- Test: new `test/integration/bootstrap/needs-bootstrap.spec.ts`

**Interfaces:**
- Consumes: `distros/bootstrap.sh` (Task 1), `mise doctor project` (Task 2).
- Produces, in `preview.yml`:
  - `brewfile`: unchanged.
  - `lint`: no matrix, hadolint on `distros/debian/Dockerfile`.
  - `changes`: checkout with `fetch-depth: 0`. It runs
    `git diff --name-only "origin/$GITHUB_BASE_REF...HEAD" | .github/needs-bootstrap.sh` and outputs
    `bootstrap=true|false`.
  - `bootstrap`: `needs: [changes, lint, brewfile]`, `if: needs.changes.outputs.bootstrap == 'true'`,
    `container: mcr.microsoft.com/devcontainers/base:debian`, `timeout-minutes: 30`.
    - Check out as root, then copy the tree to `/home/vscode/.local/share/dots`, owned by `vscode`.
    - Run `sudo -u vscode -H env GITHUB_TOKEN=… bash /home/vscode/.local/share/dots/distros/bootstrap.sh` with
      `secrets.GH_TOKEN`.
    - Then run `sudo -u vscode -H /usr/bin/zsh -lic 'mise doctor project'`.
  - Removed: `validate` (and with it Docker Hub login, buildx, the registry cache, the size budget, CST and the
    JUnit report).

- [ ] **Step 1: Failing spec** `needs-bootstrap.spec.ts`:
  - `docs/BOOTSTRAP.md` → 1
  - `README.md` → 1
  - `config/zsh/README.md` → 1
  - `docs/blog/posts/x.md` → 1
  - empty input → 1
  - `config/zsh/.zshrc` → 0
  - `.gitattributes` → 0
  - `docs/x.md` plus `mise.toml` → 0
  - `distros/debian/Dockerfile` → 0
- [ ] **Step 2:** It fails. **Step 3:** Implement the script and the workflow. **Step 4:** The spec passes,
  `hk check` on the workflow passes, and `actionlint` passes if it is installed.
- [ ] **Step 5: Local run.** If `act` and Docker are available, run `act pull_request -j bootstrap` (`act-local-testing`
  skill). Expected: bootstrap and doctor pass. If `act` cannot run `container:` jobs here, say so; Task 8's owner
  checkpoint covers it.
- [ ] **Step 6: Commit:** `ci(preview): Bootstrap a clean Debian and run mise doctor instead of building images`.

### Task 4: Release pipeline: one Debian image, checked before push

**Files:** Modify `.github/workflows/publish.yml`.

**Interfaces:** no matrix (Debian), and the tags exactly as in Global Constraints. The steps, in order:
1. Build `linux/amd64` with `target: publish` and `load: true`.
2. `docker run --rm --entrypoint /usr/bin/zsh <image> -lic 'mise doctor project'`.
3. The size budget, copied from the old Preview step: `vars.IMAGE_BUDGET_BYTES || '2800000000'`, with the same
   summary line and error.
4. The existing multi-platform build and push.

- [ ] **Step 1:** Implement. **Step 2:** `hk check` on the file and `actionlint` (if installed) pass. Check with
  `docker/metadata-action`'s documented semantics that the generated tag list equals the Global Constraints list.
- [ ] **Step 3: Commit:** `ci(publish): Publish only the Debian image after mise doctor and the size budget`.

### Task 5: Remove Ubuntu and CST; docs and quality gate

**Files:**
- Delete: `distros/ubuntu/`, `distros/debian/container-structure-test.yml`.
- Modify:
  - `distros/tasks.toml`: drop `ubuntu` from every `choices`. The `test` task now runs Task 4's doctor command
    against the composed image name; keep its `--distro/--platform/--tag/--image` flags and drop `--config`.
  - `config/homebrew/Brewfile`: remove the `container-structure-test` line.
  - The references the spec lists: `AGENTS.md` (quality gate line, the `docker-expert` line, the docs list),
    `README.md`, `docs/TESTING.md` §5, `docs/DOCKER.md`, `config/kodexb/sources/dots.yml`.
  - The quality gate in `AGENTS.md` and `docs/TESTING.md` gains `mise doctor project`.
- Test: `bootstrap-docs.spec.ts` (new case).

- [ ] **Step 1: Failing doc case.** `no file outside docs/blog/posts and docs/superpowers mentions
  container-structure-test, distros/ubuntu or CST`. Use the spec's grep; whole words for `CST`.
- [ ] **Step 2:** It fails. **Step 3:** Implement. `docs/TESTING.md` §5 becomes "Container checks": the PR job,
  release, and `mise run test` running `mise doctor project` in a built image. **Step 4:** The case passes, and so
  do `brewfile-profiles.spec.ts`, `hk check --all` and `mise run test --distro debian --platform amd64 --tag qc`
  (or `--image dots:debian-qc`).
- [ ] **Step 5: Commit:** `refactor(distros): Drop the Ubuntu image and Container Structure Tests`.

### Task 6: Echo sweep, `test/integration/bootstrap/`

**Files:** every `test/integration/bootstrap/*.spec.ts`. Start with `macos-defaults`, `yabai`, `agent-shell`, `duti`,
`vscode-links`, `brewfile-profiles` and `theme-env`; then cover the rest.

**Rule** (from the spec's Kinds): delete a case, or the assertion inside a case, when it would still pass if the dots
logic around a declaration were deleted and mise applied the declaration alone. Keep behaviour assertions. A
machine-state assertion that fits Task 2's rules becomes a doctor check; otherwise keep it.

Examples:
- **Echo, delete:** "uses Omarchy's gaps: 10"; "sets a fast key repeat"; "links ~/.claude/agents to
  config/claude/agents".
- **Behaviour, keep:** "a failed entry warns, names it and records it, but exits 0"; "running it twice moves
  nothing the second time"; "yabairc and bordersrc are valid sh that shellcheck accepts".

- [ ] **Step 1:** Classify every case in the directory. Write the table in the commit body: file | before |
  deleted | trimmed | moved | kept, plus one line per deleted or trimmed case with its reason.
- [ ] **Step 2:** Apply it. Delete a spec file only when all of its cases are echoes.
- [ ] **Step 3:** `bun test test/integration/bootstrap/` passes. Every count drop is explained in the table.
- [ ] **Step 4: Commit:** `test(bootstrap): Drop cases that only restate the config`.

### Task 7: Echo sweep, the other domains

**Files:** every spec in `test/integration/{agents,backup,bin,blog,hooks}/`, and `test/features/` scenarios.

- [ ] **Steps 1–3:** As Task 6, same rule and table.
- [ ] **Step 4: Commit:** `test: Drop cases that only restate the config outside bootstrap`.

### Task 8: Whole-branch verification and handoff

- [ ] `mise run test:specs` passes. Its case total is the baseline's 844, minus the deleted cases from Tasks 6 and 7,
  plus the new cases. The arithmetic goes in the handoff.
- [ ] `hk check --all` passes. `mise run zsh:verify` syntax passes. `mise run mise:diagnostics` prints nothing.
- [ ] On the Mac, `mise doctor project` gives 6 passed, 0 failed (Review Focus 1).
- [ ] In a fresh `mise run build --local --distro debian --tag qc`, `mise run test --image dots:debian-qc` gives
  0 failed, and the three new checks run.
- [ ] `g grep -n -E 'container-structure-test|distros/ubuntu|\bCST\b' -- ':!docs/blog/posts' ':!docs/superpowers'`
  prints nothing.
- [ ] **Owner checkpoint.** List the commits, the spec-count table and the expected CI shape. Ask the owner to push
  and open a test PR when they choose, then to confirm three things:
  1. A PR touching `config/mise/` runs `bootstrap` and passes. Record its time against
     `$B/preview-times.json`.
  2. A docs-only PR skips `bootstrap` and can still be merged.
  3. No `validate` or CST check appears.

  Wait for the answer.
- [ ] `/wip:handoff`. No push, no PR.

**Definition of done:**
- Every task's checks pass.
- `mise doctor project` passes on the Mac and in the image, and each new check is proven to fail when its fact
  breaks.
- No CST, no Ubuntu image, and no echo spec case remains.
- The owner checkpoint is answered.
- The only uncommitted file is the owner's untracked `.env.sh`.
