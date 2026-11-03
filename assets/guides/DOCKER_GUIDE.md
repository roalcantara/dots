<!-- markdownlint-disable-file -->

# Docker guide

Operational manual for Dots dev container images under `distros/`. Pairs with
root [`mise.toml`](../../mise.toml) Docker tasks and the Preview CI workflow.

For deeper Dockerfile design or security hardening, load the **docker-expert**
and **docker-patterns** companion skills (see
[`.cursor/dots-skill-routing.md`](../../.cursor/dots-skill-routing.md)).

## Overview

| Piece | Role |
| --- | --- |
| `distros/<distro>/Dockerfile` | Multi-stage image definitions |
| `distros/<distro>/container-structure-test.yml` | Post-build image assertions (CST) |
| `distros/<distro>/.dockerignore` | Build-context exclusions per distro |
| `.hadolint.yaml` | Hadolint rules for Dockerfile lint |
| `mise run build` | Local build wrapper with usage flags |
| `mise run test` | Run CST against a built image |
| `mise run start` | Run a container (built image or upstream DevContainer base) |
| `.github/workflows/preview.yml` | PR pipeline: Hadolint → build → CST |

Build context is always the **repository root** (`.`). Dockerfiles live under
`distros/<distro>/`. Images do not run `install`: each stage installs mise and runs `mise bootstrap` directly.

## Distro layout

```
distros/
├── debian/
│   ├── Dockerfile
│   ├── container-structure-test.yml
│   └── .dockerignore
└── ubuntu/
    ├── Dockerfile
    ├── container-structure-test.yml
    └── .dockerignore
```

### Debian and Ubuntu

Both distros share the same multi-stage pattern:

| Stage | Purpose |
| --- | --- |
| `base` | Microsoft DevContainer base (`mcr.microsoft.com/devcontainers/base:debian` or `:ubuntu`) |
| `local` | `git archive HEAD` (SOPS files kept encrypted) copied to `~/.local/share/dots`, then `mise bootstrap` |
| `remote` | `git clone` of `BRANCH` into `~/.local/share/dots`, then `mise bootstrap`; default for CI and production-like builds |
| `publish` | Same as `local`, tagged for Docker Hub |

Shared build args: `TZ`, `TERM`, `BRANCH`, `USERNAME`, `GITHUB_REPO`.

## Build targets: local vs remote vs publish

| Target | When to use | Install source | Typical tag |
| --- | --- | --- | --- |
| `remote` | CI, PR preview, “branch” smoke tests | `git clone` + `mise bootstrap` | `dots:<distro>` or `dots:<distro>-<tag>` |
| `local` | Dev loop with committed changes | `git archive HEAD` + `mise bootstrap` | `dots:<distro>-local` (convention) |
| `publish` | Docker Hub / embedded publish | `git archive HEAD` + `mise bootstrap` | `dots:<distro>-publish` |

**Remote** builds the given `BRANCH` from GitHub. Preview CI builds `remote` with `BRANCH=${{ github.head_ref }}`.

**Local** and **publish** build from `git archive HEAD` with the SOPS smudge filter
disabled, so encrypted files stay encrypted in the image; uncommitted changes are not included. Every stage runs as the base image's `vscode` user: it installs mise,
links `~/.config/mise` and runs `mise bootstrap -E container --force-dotfiles --skip user --yes`. Images never get
the age key or the `dots-history` secrets; only `GITHUB_TOKEN`, from the `github_token` build secret.

Pass `--publish` to `mise run build` to select the `publish` target.

## `mise run build`

Declared in root [`mise.toml`](../../mise.toml). Wraps `DOCKER_BUILDKIT=1 docker build`
with platform mapping and target selection.

### Flags

| Flag | Default | Description |
| --- | --- | --- |
| `--distro` | `debian` | `debian` or `ubuntu` |
| `--platform` | `arm64` | `amd64`, `arm64`, `amd64v2`, `riscv64`, `ppc64le`, `s390x`, `386` |
| `--local` | off | Build `--target=local` (COPY working tree) |
| `--publish` | off | Build `--target=publish` |
| _(neither)_ | — | Build `--target=remote` |
| `--nocache` | off | Pass `--no-cache` to Docker |
| `--tag` | — | Suffix appended: `dots:<distro>-<tag>` |
| `--user` | — | `USERNAME` build-arg |
| `--branch` | — | `BRANCH` build-arg (remote/publish install URL) |
| `--repo` | — | `GITHUB_REPO` build-arg (`owner/name`) |
| `--secret` | `./.secrets/github_token.secret` | GitHub token for BuildKit secret mount |
| `--build-arg` | — | Repeatable extra `--build-arg` pairs |

Image tag pattern: `dots:<distro>` plus optional `-<tag>` suffix.

### Examples

```bash
# Default: remote install, debian, linux/arm64
mise run build

# CI-like amd64 remote build for ubuntu
mise run build --distro ubuntu --platform amd64 --branch main

# Local dev iteration
mise run build --local --nocache --user vscode --tag latest

# Publish target (registry-oriented image)
mise run build --publish --distro debian --platform amd64 --tag publish
```

GitHub token: if `GITHUB_TOKEN` is unset, the task mounts
`--secret=id=github_token,src=<--secret path>` when that file exists.

## `mise run test` (Container Structure Test)

Runs [Container Structure Test](https://github.com/GoogleContainerTools/container-structure-test)
(CST) against a built image.

```bash
# Default: dots:debian-arm64 + distros/debian/container-structure-test.yml
mise run test

# Match Preview CI naming
mise run test --image roalcantara/dots:debian-pr-42-abc1234-amd64 \
  --config distros/debian/container-structure-test.yml
```

| Flag | Default | Description |
| --- | --- | --- |
| `--distro` | `debian` | Used when composing image name |
| `--platform` | `arm64` | Platform segment in composed name |
| `--tag` | — | Tag segment in composed name |
| `--image` | — | Full reference (overrides composed name) |
| `--config` | `distros/<distro>/container-structure-test.yml` | CST config path |

Composed image name: `dots:<distro>[-<platform>][-<tag>]`.

## `mise run start`

Starts an interactive container:

- With `--tag`: runs `dots:<distro>-<tag>`
- Without `--tag`: runs upstream `mcr.microsoft.com/devcontainers/base:<distro>` with `zsh` entrypoint (no Dots install)

```bash
mise run start --tag local --user vscode --workdir /workspaces/dots
```

## Hadolint (`.hadolint.yaml`)

Root [`.hadolint.yaml`](../../.hadolint.yaml) configures
[Hadolint](https://github.com/hadolint/hadolint) for Dockerfile lint:

| Setting | Value | Effect |
| --- | --- | --- |
| `failure-threshold` | `warning` | Warnings fail the lint step |
| `ignored` | `SC2155`, `DL3007`, `DL3008`, `DL3018` | ShellCheck export noise; pin-version rules relaxed for base images and apt |
| `strict-labels` | `false` | Do not require OCI label schema |
| `trustedRegistries` | `docker.io`, `gcr.io`, `mcr.microsoft.com` | Allow pulls from DevContainer and test images |

Run locally (mise installs `hadolint` via root `[tools]`):

```bash
hadolint --config .hadolint.yaml distros/debian/Dockerfile
hadolint --config .hadolint.yaml distros/ubuntu/Dockerfile
```

## Container Structure Test configs

Per-distro YAML under `distros/<distro>/container-structure-test.yml`
(schema 2.0.0). Each file defines:

1. **`globalEnvVars`** — XDG paths, `ZDOTDIR`, `MISE_*`, npm/starship config
2. **`commandTests`** — `which` for core tools
3. **`fileExistenceTests`** — Home layout, config symlinks, nvim venv, absence of `.oh-my-zsh`

CI runs CST in debug mode with JUnit output for GitHub Checks (see below).

## Preview CI workflow

[`.github/workflows/preview.yml`](../../.github/workflows/preview.yml) runs on
non-draft PRs to `main`.

```mermaid
flowchart LR
  PR[Pull request] --> Lint[lint: Hadolint]
  Lint --> Validate[validate: build remote]
  Validate --> CST[CST + JUnit report]
```

| Job | Matrix | Steps |
| --- | --- | --- |
| `lint` | `debian`, `ubuntu` | Checkout → Hadolint action on `distros/<distro>/Dockerfile` with `.hadolint.yaml` |
| `validate` | `debian`, `ubuntu` | Checkout → Docker Hub login → Buildx → **build `remote`** (`linux/amd64`, `load: true`) → CST → JUnit upload |

Notable CI settings:

- **Target:** `remote` (not `local` or `publish`)
- **Platform:** `linux/amd64` (`PLATFORMS` env)
- **Branch arg:** `BRANCH=${{ github.head_ref || github.ref_name }}`
- **Tags:** `<repo>:<distro>-pr-<number>-<short_sha>-amd64`
- **Cache:** GitHub Actions cache + registry cache refs
- **Secrets:** `GH_TOKEN` / `github_token` for install; `DOCKERHUB_TOKEN` for login

## Related skills

| Skill | Load when |
| --- | --- |
| **docker-expert** | Editing Dockerfiles, build args, multi-stage design, BuildKit mounts |
| **docker-patterns** | Compose, networking, volume strategy, container security |
| **github-actions-docs** | Changing `.github/workflows/preview.yml` |
| **mise-tasks** | Extending `build` / `test` / `start` task usage blocks |

## Suggested improvements

1. **Pin base image digests** — Dockerfiles use floating tags
   (`mcr.microsoft.com/devcontainers/base:debian`). Pin by digest in `FROM` and
   document update cadence in this guide to improve reproducibility and supply-chain
   hygiene (Hadolint `DL3007` is currently ignored for flexibility).

2. **Document and promote `--local` in contributor flow** — Remote builds hide
   uncommitted changes; new contributors often expect `mise run build` to test
   their branch. Add a short “local vs remote” callout to PR templates or
   [`TESTING_GUIDE.md`](TESTING_GUIDE.md) cross-link, and consider a
   `mise run build --local` smoke job on PRs (optional, cache-friendly).


## See also

- [`GLOSSARY.md`](GLOSSARY.md) — Hadolint, CST, DevContainer
- [`MISE_GUIDE.md`](MISE_GUIDE.md) — `usage` flags and `usage_*` variables
- [`TESTING_GUIDE.md`](TESTING_GUIDE.md) — verification gates
