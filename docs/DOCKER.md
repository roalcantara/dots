# Docker and CI guide

Operational manual for Dots container images under `distros/` and GitHub Actions workflows.

## Overview

Dots builds reproducible multi-stage Docker development images based on Debian and Ubuntu:

| File | Role |
| --- | --- |
| `distros/<distro>/Dockerfile` | Multi-stage image definitions (`base`, `local`, `remote`, `publish`) |
| `distros/<distro>/container-structure-test.yml` | Container Structure Test (CST) assertions |
| `distros/<distro>/.dockerignore` | Build-context exclusions per distribution |
| `.hadolint.yaml` | Lint rules for Dockerfiles |
| `mise.toml` | Task wrappers: `build`, `test`, `start` |
| `.github/workflows/` | CI/CD pipelines: `preview.yml`, `publish.yml`, `release.yml` |

The build context is always the repository root (`.`). Dockerfiles do not run `install`: each stage installs `mise` and executes `mise bootstrap -E container` directly.

## Distro layout

```text
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

### Multi-stage targets

Both Debian and Ubuntu Dockerfiles share four distinct build targets:

| Target | Purpose | Install source | Typical tag |
| --- | --- | --- | --- |
| `base` | Microsoft base image (`mcr.microsoft.com/devcontainers/base:<distro>`) | Upstream registry | — |
| `local` | Dev iteration with committed changes (excludes uncommitted edits) | `git archive HEAD` + `mise bootstrap` | `dots:<distro>-local` |
| `remote` | CI, PR preview, branch testing | `git clone` of branch + `mise bootstrap` | `dots:<distro>` |
| `publish` | Docker Hub release build | `git archive HEAD` + `mise bootstrap` | `dots:<distro>-<version>` |

Local and publish builds run `git archive HEAD` with the SOPS smudge filter disabled (`-c filter.sops.smudge=cat`), ensuring encrypted secrets remain encrypted inside the build context. Stages execute as the non-root `vscode` user.

## CLI commands

The root [`mise.toml`](../mise.toml) defines task wrappers for container lifecycle operations:

### `mise run build`

Builds a Docker image using BuildKit:

```sh
# Default: remote install, debian, linux/arm64
mise run build

# Local dev iteration with committed tree
mise run build --local --distro ubuntu --tag local

# Specific platform or branch
mise run build --distro ubuntu --platform amd64 --branch main
```

Key flags:

- `--distro`: `debian` (default) or `ubuntu`.
- `--platform`: `arm64` (default), `amd64`, etc.
- `--local`: build target `local` from git archive.
- `--publish`: build target `publish`.
- `--tag`: suffix appended to image name (`dots:<distro>-<tag>`).
- `--nocache`: pass `--no-cache` to docker build.

### `mise run test`

Runs Google Container Structure Tests against a built image:

```sh
# Default: tests dots:debian-arm64
mise run test

# Test specific image with explicit config
mise run test --image dots:ubuntu-local --config distros/ubuntu/container-structure-test.yml
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
hadolint --config .hadolint.yaml distros/ubuntu/Dockerfile
```

## Continuous Integration (CI)

Dots maintains three GitHub Actions workflows in `.github/workflows/`:

### 1. PR Preview (`.github/workflows/preview.yml`)

Runs automatically on pull requests targeting `main`:

1. **`brewfile` job:** Verifies that `config/homebrew/Brewfile` parses without errors under both `container` and `desktop` profiles (`HOMEBREW_DOTS_PROFILE=<p> brew bundle list`).
2. **`lint` job:** Runs Hadolint against `distros/debian/Dockerfile` and `distros/ubuntu/Dockerfile`.
3. **`validate` job:** Builds `remote` target Docker images on `linux/amd64` using GitHub Actions layer cache, runs Container Structure Tests with JUnit reporting, and asserts image size against the repository `IMAGE_BUDGET_BYTES` limit (2 GB).

### 2. Publish (`.github/workflows/publish.yml`)

Runs upon publishing a new GitHub release:

1. Triggers on `release` published events.
2. Authenticates to Docker Hub via `DOCKERHUB_TOKEN`.
3. Builds the `publish` target for Debian and Ubuntu across configured platforms (`linux/amd64`, `linux/arm64`).
4. Tags and pushes release images: `<repo>:<distro>-<version>`.

### 3. Automated Release (`.github/workflows/release.yml`)

Automates SemVer versioning and changelogs:

1. Triggers on push to `main` branch or manual `repository_dispatch`.
2. Runs `semantic-release` using Conventional Commits.
3. Automatically increments versions, generates release notes from commit history, and creates GitHub tags and releases.

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
