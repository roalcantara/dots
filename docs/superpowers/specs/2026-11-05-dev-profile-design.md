# A `dev` profile on top of `desktop` — design

Status: approved by the owner (2026-11-05).

## 1. Goal

`install` sets up a fast **desktop** (shell, secrets, browsers, terminal, fonts, everyday apps). The heavy development
set (language servers, linters, toolchains, IDEs, Docker, coding-agent CLIs, agent skills) is added later, on
demand, with **`mise run setup dev`**.

Done when:

1. `curl -fsSL https://raw.githubusercontent.com/roalcantara/dots/main/install | bash` runs
   `mise bootstrap -E desktop` and installs nothing from the Brewfile's `# DEVTOOLS` section.
2. `mise run setup dev` (from any folder) records the profile and runs `mise bootstrap -E desktop,dev`, which adds
   the `# DEVTOOLS` entries, the agent skills restore and the Python 3.13 tools.
3. After `setup dev`, a plain `mise bootstrap` and new shells use `desktop,dev`; `mise run setup desktop` records
   `desktop` again.
4. `container` is unchanged.
5. Specs, `hk check`, the Brewfile parse job and the container build pass.

## 2. Profiles

| Profile | Brewfile | Bootstrap task |
| --- | --- | --- |
| `container` | the minimal group (before `return unless desktop`) | git filters only (unchanged) |
| `desktop` | minimal + everything above `# DEVTOOLS` | everything except the dev steps below |
| `dev` (with `desktop`) | + the `# DEVTOOLS` section | + agent skills restore, + Python 3.13 tools (graphifyy, code-review-graph) |

Desktop keeps: Neovim providers and `Lazy! restore`, `setup:hooks`, gopass store, gopass-keyring check, oMLX models.
The owner already split the Brewfile (`# DEVTOOLS` header, ~45 entries).

## 3. Design

### 3.1 Profile as a list

`MISE_ENV` / `-E` may hold several names (`desktop,dev`). Everything that reads the profile treats it as a
comma-separated list:

- **Brewfile:**
  ```ruby
  profiles = ENV.fetch("HOMEBREW_DOTS_PROFILE", "desktop").split(",").map(&:strip)
  dev = profiles.include?("dev")
  desktop = dev || profiles.include?("desktop")
  # minimal group
  return unless desktop
  # desktop
  # DEVTOOLS
  return unless dev
  # dev entries
  ```
- **post-packages hook** (`config/mise/conf.d/bootstrap.toml`): passes the whole list in `HOMEBREW_DOTS_PROFILE`;
  the `miserc.local.toml` fallback parses `env = ["desktop", "dev"]` into `desktop,dev`; the container exit tests
  membership (`,container,` in `,$profile,`), not equality.
- **bootstrap task:** `dev=false; case ",${MISE_ENV:-…}," in *,dev,*) dev=true ;; esac`, set where `desktop` is.
  The skills block and the `uv tool install --python 3.13` loop run only when `$dev`.

### 3.2 `mise run setup <desktop|dev>`

New `config/mise/conf.d/setup.toml` (global, so it runs from any folder, like the backup tasks):

```toml
[tasks.setup]
description = "Choose this machine's profile and apply it: desktop (default install) or dev (desktop + dev tools)"
usage = 'arg "<profile>" help="desktop or dev" { choices "desktop" "dev" }'
run = '''
#!/usr/bin/env bash
set -euo pipefail
dots="$HOME/.local/share/dots"
case "${usage_profile:?}" in
  desktop) envs='"desktop"'; list=desktop ;;
  dev) envs='"desktop", "dev"'; list=desktop,dev ;;
esac
printf 'env = [%s]\n' "$envs" > "$dots/config/mise/miserc.local.toml"
exec mise bootstrap -E "$list" --yes
'''
```

`install` keeps writing `env = ["desktop"]` (its `DOTS_PROFILE` default). Going back to `desktop` uninstalls nothing
(`brew bundle` never removes packages); the dev entries just stop being installed/updated.

### 3.3 Docs and CI

- README "Install" and `docs/REINSTALL.md`: `install` sets up desktop; `mise run setup dev` adds the dev tools;
  what each profile holds (the §2 table).
- `.github/workflows/preview.yml` "Brewfile parses": add `desktop,dev`.

## 4. Open points (plan Task 1 checks them)

| # | Question | If it fails |
| --- | --- | --- |
| P1 | On a plain `mise bootstrap` (profile from `miserc.local.toml`), does the `bootstrap` task see `MISE_ENV=desktop,dev`? | The task reads `miserc.local.toml` itself, like the hook's fallback |
| P2 | Does a global `setup` task coexist with the repo's `setup:age`/`setup:git:filters`/`setup:hooks` (`mise run setup dev` from inside `~/.local/share/dots`)? | Name it `profile` (`mise run profile dev`) |
| P3 | `usage_profile` is the variable name mise gives the `<profile>` arg | Use the name mise documents |

## 5. Tests

- `test/integration/bootstrap/brewfile-profiles.spec.ts`: `brew bundle list --all` with `HOMEBREW_DOTS_PROFILE`
  `container`, `desktop`, `desktop,dev` (skipped without `brew`): a `# DEVTOOLS` entry (`shellcheck`) only for
  `desktop,dev`; a desktop entry (`gopass`) for `desktop` and `desktop,dev`, not `container`.
- `post-packages.spec.ts`: the hook passes `desktop,dev` through; a `miserc.local.toml` with two envs is parsed.
- `skills-snippet.spec.ts` / a new task spec: with `MISE_ENV=desktop`, the skills restore and the Python tools do not
  run; with `desktop,dev` they do (stubbed `mise`/`uv`).
- `setup` task: run with a temp `HOME` and a stub `mise`: `dev` writes `env = ["desktop", "dev"]` and calls
  `mise bootstrap -E desktop,dev --yes`; an unknown profile is rejected.

## 6. Delivery

On `fix/brew-sudo` with the six macOS fixes already there; one push and one PR for everything (owner).
