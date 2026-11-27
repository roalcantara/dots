# Quality checks: one place, no echoes, a faster PR

## Intent

dots grew one part at a time, and its checks grew with it: Container Structure Tests (CST) on two images per PR,
three `mise doctor project` checks, 844 Bun spec cases, hk linters. Many now restate what a declaration already
guarantees. The owner wants:

- a clear map of which checks are necessary, which move to `mise doctor`, and which are redundant;
- as many of the non-redundant checks as possible under `mise doctor project`, so they live in one place and run at
  will, on the Mac and in a container;
- a faster PR pipeline that still catches a Linux bootstrap break **before** merge.

The image still serves two purposes: a dev container, and proof that the setup works on Linux. One distro is enough.

## Facts (checked 2026-11-27)

| Fact | Evidence |
| --- | --- |
| A Preview run takes about 8 min; almost all of it is two parallel image builds (about 7 min each). | `gh run view 45553340666` |
| PR CI runs no Bun specs and no `hk check`, only: Brewfile parse (3 profiles), hadolint ×2, image build ×2, size budget, CST. | `.github/workflows/preview.yml` |
| Debian and Ubuntu images differ only in the base image and the HOME mode (`drwx------` vs `drwxr-x---`). | `diff distros/{debian,ubuntu}/…` |
| Bootstrap inside `docker build` is not strict: `warn` fails a step only under `CI` or `DOTS_STRICT`, and neither is set, so a broken step can still yield an image. | `.mise/tasks/bootstrap/_lib.sh` `warn`, Dockerfiles |
| `mise bootstrap -E container` is not saved (`--save-env` is not passed), so nothing in the image knows its profile afterwards. | Dockerfiles |
| Doctor checks take `description`, `run`, `hint`, `os`, `timeout`; they filter by OS only. | `config/mise/conf.d/tasks.toml`, `mise doctor project --help` |
| Homebrew on Linux requires glibc; Alpine (musl) is unsupported, and bootstrap installs nearly everything through Homebrew. | Homebrew's Linux requirements |

## Goals

1. **Every check has one kind and one home** (see Kinds). The map of today's checks, with each verdict, is part of
   this design (CST, doctor, CI below) or produced by Part 2 (Bun specs).
2. **`mise doctor project` holds every machine-state check** and passes on the Mac and in the container.
3. **A PR that touches bootstrap runs the real bootstrap on a clean Debian, strictly, then `mise doctor project`,**
   without building an image.
4. **Release builds, checks and publishes one image** (Debian).
5. **No Bun spec restates a declaration** ("echo" below).

## Non-goals

- Adding `mise run test:specs` or `hk check --all` to PR CI. Worth revisiting; not here, since the aim is a faster PR.
- Caching Homebrew downloads in CI (optional follow-up if the job is still slow).
- Rewriting behaviour specs that are fine, or raising coverage.
- Published blog posts (`docs/blog/posts/**`): their old commands are history.

## Anti-goals (a failure even if it works)

- A doctor check that echoes a declaration (a folder mode, a link target, a defaults value).
- A PR check that passes on a setup different from the one the image ships (for example Alpine, or the bare GitHub
  runner whose preinstalled tools would hide a missing package).
- Losing a check that is not an echo: every dropped CST entry and spec case is either an echo or moved.
- Any doctor check that fails on the owner's Mac or in the container for reasons outside its job.

## Kinds

| Kind | Meaning | Home |
| --- | --- | --- |
| **Behaviour** | Logic dots wrote: scripts, fallbacks, ordering, idempotency, error paths. | Bun spec (keep) |
| **Echo** | Restates a declaration that mise applies (directory, mode, link, defaults value, Brewfile entry, config value). If the declaration is applied, the fact holds. | Delete |
| **Machine state** | Can drift or be wrong on a real machine after setup and is cheap to inspect. | `mise doctor project` |
| **Integration** | Does a clean bootstrap finish? Only running it answers. | PR job (bootstrap + doctor), release |

Test for an echo: *would the check still pass if the dots logic around the declaration were deleted and mise applied
the declaration alone?* Yes means echo.

## Approaches

| | What | Trade-off |
| --- | --- | --- |
| A | Keep one image per PR; replace CST with `docker run <image> mise doctor project`. | One place for checks, but every bootstrap PR still pays for a full image build. |
| B | Slim CST (4 unique checks) plus doctor for the rest. | Checks stay split across two tools, against the goal. |
| **C (chosen)** | No image on PRs: a job **inside `mcr.microsoft.com/devcontainers/base:debian`** runs the Dockerfile's steps (install mise, strict `mise bootstrap -E container`), then `mise doctor project`; path-filtered. Release builds, doctors and pushes the Debian image. | Fastest PR that still proves Linux before merge. Gap: a broken Dockerfile line shows only at release (the file is ~30 lines, rarely changes, and hadolint still runs on every PR). |

The owner first proposed C with an Alpine container. Rejected: Homebrew does not support musl, so Alpine would test
a different setup from the shipped image. The Debian base container is the same starting point as the Dockerfile.

## Part 1: CI and doctor

### PR pipeline (`.github/workflows/preview.yml`)

- **Every non-draft PR:** `brewfile` (unchanged) and `lint` (hadolint on `distros/debian/Dockerfile` only).
- **`bootstrap` job**, on every PR except one that touches only `docs/**` or `**/*.md` (an inverted filter: bootstrap
  links every `config/<app>`, warms zsh, reads `.gitattributes` and the root `mise.toml`, so a narrow list would miss
  real breaks; *my call*):
  - `container: mcr.microsoft.com/devcontainers/base:debian`, as user `vscode` with `HOME=/home/vscode` (the image's
    user), so modes and paths match the shipped image.
  - Puts the checkout at `~/.local/share/dots`, installs mise at the version the Dockerfile pins, links
    `~/.config/mise` as the Dockerfile does, then runs `DOTS_STRICT=1 mise bootstrap -E container --save-env
    --force-dotfiles --skip user --yes`, then `mise doctor project`.
  - The commands are shared with the Dockerfile (one script both call), so the two cannot drift.
- **Removed:** the `validate` matrix (image build, Docker Hub login, registry cache, size budget, CST, JUnit upload).
- `main` has no required status checks (its ruleset only blocks non-fast-forward pushes; checked 2026-11-27), so a
  skipped or renamed job blocks nothing and no settings change is needed.
- GitHub's `container:` jobs start as root; `actions/checkout` needs that, so the job checks out as root and runs the
  bootstrap as `vscode`.

### Strict mode may surface failures hidden today

The first plan task runs a strict bootstrap in the Debian base container before anything else changes. Failing steps
that need a small, local fix are fixed in this work; anything larger stops the plan and goes back to the owner
(*my call*).

### Release pipeline (`.github/workflows/publish.yml`)

- Debian only, with the `debian-*` tags unchanged (`debian-latest`, `debian-X.Y.Z`, `debian-X.Y`, `debian-X`,
  `debian-<sha>`; owner's decision). `ubuntu-*` tags stop being pushed; the existing ones on Docker Hub are left as
  they are. No plain `latest`. Before the multi-platform push: build `linux/amd64`, load it, run `mise doctor project` in it, check
  the image size budget (moved from Preview, same `IMAGE_BUDGET_BYTES` var), then push.
- `DOTS_STRICT=1` and `--save-env` apply to the image build too (via the shared script).

### Doctor checks after this work

Existing, kept: `mise-version` (macOS only), `mise-diagnostics`, `home-gitconfig`.

New, from CST's non-echo entries:

| Check | Inspects | Applies when |
| --- | --- | --- |
| `container-tools` | The container Brewfile group (read from the Brewfile, not a pinned list) resolves on PATH in a login zsh. | profile `container` |
| `profile-parts` | Parts gated to other profiles are absent (agent skills, gopass store, nvim plugins in `container`). Derive the list from what the steps gate, not a hand list. | profile `container` |
| `sops-encrypted` | SOPS-filtered files in the checkout are still encrypted. | profile `container` (on the Mac the smudge filter decrypts them by design) |

A check that does not apply prints why and exits 0. It learns the profile from the saved `mise_env` (Tera
`{{ mise_env }}` in `run`, the same filtered list `dots setup` uses), which `--save-env` makes available.

### CST map

| CST entry | Kind | Verdict |
| --- | --- | --- |
| `globalEnvVars` (13) | Inputs to CST, not assertions | Gone with CST |
| `which curl/jq/zsh/git` | Echo (base image, Brewfile) | Covered by `container-tools` |
| `mise --version` | Integration | Implied by bootstrap running |
| Homebrew `--version` | Integration | Implied by the Brewfile step running strictly |
| Container Brewfile group on PATH in login shell | Machine state | `container-tools` |
| Desktop-only parts absent | Machine state | `profile-parts` |
| SOPS files stay encrypted | Machine state | `sops-encrypted` |
| 10 directory existence + mode entries | Echo (`[bootstrap.directories]`) | Delete |
| 10 link / file entries (`.zshenv`, `.config/nvim`, …) | Echo (`[dotfiles]`, dotfile group) | Delete |
| Image size budget (CI step, not CST) | Integration | Moves to release |

### Removals and edits

- Delete `distros/ubuntu/`, both `container-structure-test.yml`, the `test` task in `distros/tasks.toml` (or make it
  run `mise doctor project` in a built image), and CST from the Brewfile if it is listed.
- Update every reference found by `grep -rn "container-structure-test\|distros/ubuntu\|CST"` outside
  `docs/blog/posts` and `docs/superpowers`: `AGENTS.md` (quality gate line, `docker-expert` line, docs list),
  `README.md`, `docs/TESTING.md` §5, `docs/DOCKER.md`, `config/kodexb/sources/dots.yml`.
- The Quality gate in `AGENTS.md` and `docs/TESTING.md` gains `mise doctor project`.

## Part 2: Bun spec sweep

- For every `test/integration/**/*.spec.ts` case, apply the echo test above. Starting points (sampled, not exhaustive):
  `macos-defaults`, `yabai`, `agent-shell`, `duti`, `vscode-links`, `brewfile-profiles`, `theme-env`.
- Echo cases are deleted. A case that is partly echo, partly behaviour keeps only the behaviour.
- A case that checks machine state (true only on a set-up machine) moves to a doctor check if it fits Part 1's rules.
- Output: a table in the plan or its commit bodies, per file: cases before, deleted, moved, kept; and
  `mise run test:specs` still green. The total is expected to drop; that is the point.

## Left to the builder

- The shared bootstrap script's name and place (for example `distros/bootstrap.sh`).
- The path-filter mechanism.
- How each new doctor check derives its list (Brewfile group, gated parts, SOPS-filtered paths from
  `.gitattributes`).
- Whether `mise-diagnostics` (needs Bun) runs in the container, or gets `os = "macos"`. It must not fail there.

## Verification

- Owner's Mac: `mise doctor project` passes (all new checks print "does not apply" and exit 0).
- Locally: `mise run build --local --distro debian`, then `mise doctor project` inside it passes; break one thing
  each new check guards (remove `bat` from PATH, add a desktop-only folder, decrypt one SOPS file) and see it fail.
- A test PR touching `config/mise/` runs the `bootstrap` job and passes; a docs-only PR skips it and is still
  mergeable. Record both run times.
- `mise run test:specs` and `hk check --all` pass.
