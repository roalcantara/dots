# Testing guidelines

Verification gates, test suite architecture, BDD specifications, container checks, and the Definition of Done.

## 1. Quality gate

Every change must keep all relevant quality gates clean before merge:

- `mise run test:specs` — runs BDD scenarios and all integration test domains (`bin`, `backup`, `bootstrap`, `agents`, `hooks`).
- `hk check --all` — runs repository linters (`shellcheck`, `shfmt`, `taplo`, `tombi`, `hadolint`, `markdownlint`, `yamllint`, `zsh-syntax`).
- `mise doctor project` — runs project doctor checks (pins, mise diagnostics, git config, and container checks when in a container).
- `mise run zsh:verify` — verifies Zsh syntax and benchmarks startup time when editing `config/zsh/`.
- `mise run build --local --distro debian --tag <tag>` and `mise run test --image dots:debian-<tag>` — required for Dockerfile or bootstrap changes.

## 2. Test layout

All tests live under `test/`:

| Path | Purpose |
| --- | --- |
| `test/features/` | Living documentation in Gherkin (`.feature` files), verified by Cucumber |
| `test/features/support/` | Shared Screenplay actors, world context, and command runners |
| `test/features/step_definitions/<domain>/` | Domain-specific Cucumber step definitions |
| `test/integration/<domain>/` | Bun subprocess integration specs (`*.spec.ts`) |
| `test/integration/<domain>/fixtures/` | Test fixtures (e.g. pattern catalogs, launcher mocks) |
| `test/mise.toml` | Task runner for BDD and integration domains |

### Subprocess testing and stubs

Tests execute real scripts and commands through `Bun.spawn` or `Bun.spawnSync`:

- **No module mocking:** do not use `mock()` or monkey-patching for CLI integration tests.
- **Stubs on PATH:** when testing external dependencies (e.g. `brew`, `skills`, `osascript`, `gum`), create a temporary directory holding executable shell scripts and prepend it to `PATH`.
- **Isolated environments:** isolate tests using `mkdtempSync` for `HOME`, `XDG_STATE_HOME`, or `XDG_CONFIG_HOME`. Clean up temp directories in `afterEach` or `afterAll`.

## 3. Running tests

From repository root:

```sh
mise run test:specs                   # Run all BDD scenarios and integration domains
mise run test --image dots:debian-qc  # Run mise doctor project inside a built image
```

Under `test/` (or via `mise run -C test ...`):

```sh
mise run test all                     # Run every domain
mise run test bin                     # Run BDD + integration for bin domain
mise run integration <domain> all     # Run all integration specs for one domain
mise run integration <domain> <spec>  # Run a specific spec file
mise run bdd run --domain bin         # Run BDD feature scenarios
mise run bdd lint --domain bin        # Lint Gherkin feature files
```

To run an individual spec directly with Bun:

```sh
bun test test/integration/bin/xc-fabric.spec.ts
```

## 4. BDD and living documentation

`test/features/` provides executable living documentation using Cucumber and the Screenplay pattern.

### Feature files

Feature files declare user-observable behavior using Gherkin syntax:

```gherkin
Feature: Command discovery
  The interactive launcher discovers xc-* scripts in executable folders.

  Scenario: Launcher lists available tools
    Given the fixture bin directory contains executable xc tools
    And the xc launcher is available
    When Alice runs `xc list`
    Then Alice sees the command succeed
    And Alice sees "xc-sample" in the output
```

### Screenplay pattern

Steps remain thin and delegate command execution to Screenplay actors and activities:

- **Actors:** represent terminal users (e.g. `Alice`).
- **Interactions (`RunCommand`):** execute commands with controlled environment variables and PATH.
- **Questions (`LastCommand`):** query process state, exit codes, stdout, and stderr.

Step definitions translate Gherkin lines into Screenplay calls without inlining subprocess logic.

## 5. Container checks

Container setup is verified with `mise doctor project` rather than a separate test framework:

- **PR Preview (`.github/workflows/preview.yml`):** When a PR changes anything outside `docs/**` and `*.md`, the `bootstrap` job runs `distros/bootstrap.sh` strictly (`DOTS_STRICT=1`, `--save-env`) inside `mcr.microsoft.com/devcontainers/base:debian` as `vscode`, then runs `mise doctor project`.
- **Release (`.github/workflows/publish.yml`):** Builds the `linux/amd64` Debian image, runs `mise doctor project` inside it, checks the image size budget, and then builds and pushes the multi-platform Debian image.
- **Locally:** Build and run `mise doctor project` inside the image via:

  ```sh
  mise run build --local --distro debian --tag test
  mise run test --image dots:debian-test
  ```

## 6. Definition of Done checklist

Before declaring any task or feature complete, verify every applicable requirement:

- [ ] **Tests pass:** `mise run test:specs` passes with 0 failures.
- [ ] **Linters clean:** `hk check --all` reports 0 warnings and 0 errors.
- [ ] **Clean Git working tree:** only files relevant to the change are modified.
- [ ] **No committed secrets:** no unencrypted keys, tokens, or environment files.
- [ ] **Docs updated:** changes to commands, flags, or configuration reflected in canonical `docs/` and `README.md`.
- [ ] **Conventional commit:** commit message adheres to format specified in [`docs/CONTRIBUTING.md`](CONTRIBUTING.md).
