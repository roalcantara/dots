# Docker and CI guide

Operational manual for Dots container images under `distros/` and GitHub Actions workflows.

## Overview

Dots builds a reproducible multi-stage Docker development image based on Debian:

| File | Role |
| --- | --- |
| `distros/bootstrap.sh` | Shared strict container bootstrap script called by both the Dockerfile and PR CI |
| `distros/debian/Dockerfile` | Multi-stage image definition (`base`, `local`, `remote`, `publish`) |
| `distros/debian/.dockerignore` | Build-context exclusions |
| `.hadolint.yaml` | Lint rules for the Dockerfile |
| `distros/tasks.toml` | Task wrappers: `build`, `test`, `start` |
| `.github/workflows/` | CI/CD pipelines: `preview.yml`, `publish.yml`, `release.yml` |

The build context is always the repository root (`.`). The Dockerfile does not run `install`: each stage calls `distros/bootstrap.sh`, which installs the pinned `mise` and executes `DOTS_STRICT=1 mise bootstrap -E container --save-env --force-dotfiles --skip user --yes`. The pipeline it runs is documented in [BOOTSTRAP.md](BOOTSTRAP.md).

## Distro layout

```text
distros/
├── bootstrap.sh
├── tasks.toml
└── debian/
    ├── Dockerfile
    └── .dockerignore
```

### Multi-stage targets

The Debian Dockerfile defines four build targets:

| Target | Purpose | Install source | Typical tag |
| --- | --- | --- | --- |
| `base` | Microsoft base image (`mcr.microsoft.com/devcontainers/base:debian`) | Upstream registry | — |
| `local` | Dev iteration with committed changes (excludes uncommitted edits) | `git archive HEAD` + `distros/bootstrap.sh` | `dots:debian-local` |
| `remote` | Branch testing | `git clone` of branch + `distros/bootstrap.sh` | `dots:debian` |
| `publish` | Docker Hub release build | `git archive HEAD` + `distros/bootstrap.sh` | `dots:debian-<version>` |

Local and publish builds run `git archive HEAD` with the SOPS smudge filter disabled (`-c filter.sops.smudge=cat`), ensuring encrypted secrets remain encrypted inside the build context. Stages execute as the non-root `vscode` user.

## CLI commands

[`distros/tasks.toml`](../distros/tasks.toml) defines task wrappers for container lifecycle operations:

### `mise run build`

Builds a Docker image using BuildKit:

```sh
# Default: remote install, debian, linux/arm64
mise run build

# Local dev iteration with committed tree
mise run build --local --distro debian --tag local

# Specific platform or branch
mise run build --distro debian --platform amd64 --branch main
```

Key flags:

- `--distro`: `debian` (default).
- `--platform`: `arm64` (default), `amd64`, etc.
- `--local`: build target `local` from git archive.
- `--publish`: build target `publish`.
- `--tag`: suffix appended to image name (`dots:debian-<tag>`).
- `--nocache`: pass `--no-cache` to docker build.

### `mise run test`

Runs `mise doctor project` in a login Zsh shell inside a built image:

```sh
# Default: tests dots:debian-arm64
mise run test

# Test a specific image
mise run test --image dots:debian-local
```

### `mise run start`

Runs an interactive container:

```sh
mise run start --tag local --user vscode --workdir /home/vscode
```

### Hadolint Dockerfile linting

Hadolint rules are configured in `.hadolint.yaml`. Run locally via:

```sh
hadolint --config .hadolint.yaml distros/debian/Dockerfile
```

## Continuous Integration (CI)

Dots maintains three GitHub Actions workflows in `.github/workflows/`:

### 1. PR Preview (`.github/workflows/preview.yml`)

Runs automatically on non-draft pull requests targeting `main`:

1. **`brewfile` job:** Verifies that `config/homebrew/Brewfile` parses without errors under `container`, `desktop`, and `desktop,dev` profiles (`HOMEBREW_DOTS_PROFILE=<p> brew bundle list`).
2. **`lint` job:** Runs Hadolint against `distros/debian/Dockerfile`.
3. **`changes` job:** Pipes changed paths into `.github/needs-bootstrap.sh`; skips bootstrap when every changed file is under `docs/**` or `*.md`.
4. **`bootstrap` job:** When `changes` requires it, runs `distros/bootstrap.sh` strictly inside `mcr.microsoft.com/devcontainers/base:debian` as `vscode`, followed by `mise doctor project` in a login Zsh shell — no Docker image build on PRs.

### 2. Publish (`.github/workflows/publish.yml`)

Runs upon publishing a new GitHub release:

1. Triggers on `release` published events.
2. Authenticates to Docker Hub via `DOCKERHUB_TOKEN`.
3. Builds the `linux/amd64` `publish` target, runs `mise doctor project` inside it, and checks its size against `IMAGE_BUDGET_BYTES` (default 2.8 GB).
4. Builds and pushes the multi-platform Debian image (`linux/amd64`, `linux/arm64`) with tags `debian-latest`, `debian-<version>`, `debian-<major>.<minor>`, `debian-<major>`, and `debian-<sha>`.

### 3. Automated Release (`.github/workflows/release.yml`)

Automates SemVer versioning and GitHub Releases:

1. Triggers on push to `main` branch or manual `repository_dispatch`; a release in progress is never cancelled (a newer run waits).
2. Installs the locked tooling from `.github/release/` with `npm ci`, then fails if any tag lacks a GitHub Release (a run that failed between the tag and the release; ADR 0001 has the fix).
3. Runs `semantic-release` using Conventional Commits and the `conventionalcommits` preset.
4. Publishes the release notes as a GitHub Release and pushes the tag; commits nothing back to `main`, so the Releases page is the changelog.

See [`docs/adr/0001-releases.md`](adr/0001-releases.md) for why.

## Testing `install` in a container

To test the full `install` script and encrypted secrets recovery in a temporary container without affecting the host:

1. Copy the age secret key and a GitHub personal access token to a temporary folder:

   ```sh
   t="$(mktemp -d)"
   (umask 077; grep '^AGE-SECRET-KEY' ~/.config/age/keys.txt > "$t/age"; gh auth token > "$t/gh")
   ```

2. Copy the `install` script to test:

   ```sh
   cp install "$t/install"
   ```

3. Run the container:

   ```sh
   docker run --rm -it -v "$t:/run/s:ro" -u vscode -w /home/vscode \
     mcr.microsoft.com/devcontainers/base:ubuntu bash -c '
       export DOTS_AGE_KEY="$(cat /run/s/age)" GH_TOKEN="$(cat /run/s/gh)" DOTS_PROFILE=container
       bash /run/s/install
       zsh -lic "gopass ls --flat && echo ssh-ok"
     '
   ```

4. Clean up temporary credentials:

   ```sh
   rm -rf "$t"
   ```

## See also

- [`README.md`](../README.md) — dots repository overview and day-to-day guide
- [`docs/TESTING.md`](TESTING.md) — test gates and BDD/integration suite architecture
- [`docs/CONTRIBUTING.md`](CONTRIBUTING.md) — commit conventions and code style
- [`docs/GLOSSARY.md`](GLOSSARY.md) — terminology definitions
