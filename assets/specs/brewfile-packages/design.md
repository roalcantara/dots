<!-- markdownlint-disable -->
# One Brewfile for every package, minimal containers — design

## 1. Goal

Declare every user package in one `config/homebrew/Brewfile`, installed by real Homebrew from `mise bootstrap`,
on macOS, Linux desktops and containers. Containers get only a minimal shell set, so images stay small and CI
stops running out of disk. Agent skills, the gopass store and oMLX models are set up on desktops only.

**Done when:**

1. `config/homebrew/Brewfile` is the only list of user packages; `config/mise/conf.d/packages.toml` and the
   `[tools]` entries in `config/mise/config.toml` are gone.
2. `mise bootstrap -E desktop` on this Mac installs nothing new (everything already present) and
   `brew bundle check` passes.
3. The Debian and Ubuntu images build in Preview within budget (§6) and pass the updated CST.
4. The `devcontainer` profile no longer exists in config, `install` or docs.
5. README and guides describe only the Brewfile flow.

**Also:** remove `starship`, which is unused (the prompt is powerlevel10k): `config/starship/`, its link and
its CST checks.

**Out of scope:** Windows (`winget`), macOS settings, Homebrew services, Linux desktop rehearsal (its first run is
on real hardware), and pinning package versions.

## 2. Findings (2026-11-04)

| Finding | Evidence |
| --- | --- |
| Preview fails on disk | Run 41786878646, `validate (ubuntu)`: `no space left on device` exporting the image |
| Containers install the desktop set | The `container` profile installs all 83 formulae and runs `skills:restore` (≈60 clones, 318 skills) |
| `skills:restore` fails every image build | 3 dead sources make it exit 1 |
| Packages live in two places | `conf.d/packages.toml` (83 `brew:`, 34 `brew-cask:`, 10 `flatpak:`, 10 `apt:`) and `config.toml [tools]` (`uv`, 5 `pipx:`) |
| mise's brew backend cannot install `pipx`/`uv` tools | Hence the `[tools]` table |
| `brew bundle` (Homebrew 7.0) supports `uv`, `cargo`, `go`, `npm`, `vscode`, `flatpak`, `krew` | `brew bundle --help` |
| A Brewfile is Ruby | Conditionals (`OS.mac?`, `ENV`) select groups |
| `mise bootstrap` has a `post-packages` hook | mise docs, "How it runs": hooks `pre-packages`, `post-packages` |
| Real Homebrew is already installed on this Mac | `brew --version`: 7.0.12; mise's bottles are in `/opt/homebrew/Cellar` |

## 3. Decisions

| Decision | Choice | Why |
| --- | --- | --- |
| Package source | One `config/homebrew/Brewfile`, installed by real Homebrew | One file for formulae, casks, taps, `uv` tools and flatpaks on every OS |
| Who installs Homebrew | A `post-packages` hook in `mise bootstrap` | Same flow for `install` and the Dockerfiles; no second path |
| apt | Kept in mise as Homebrew's Linux prerequisites only, in `conf.d/system.toml` | `brew bundle` cannot manage apt |
| Profiles | `desktop` and `container`; `devcontainer` removed | The container profile itself becomes minimal |
| Containers | Homebrew plus a small always-installed group | Owner's choice: one source of truth over the smallest possible image |
| Neovim in containers | Binary and config only; no plugins or providers | Plugins, parsers and providers were most of the build time |
| CI | Both distros, minimal profile, plus a Brewfile parse job | A broken desktop entry still fails the PR without installing it |
| Rejected: `install` runs Homebrew | — | The images do not run `install`, so the Dockerfiles would repeat it |
| Rejected: keep mise's `brew:` backend, generate `packages.toml` | — | Needs a converter; `uv`/`flatpak` entries still not mise-native |

## 4. Components

### 4.1 `config/homebrew/Brewfile`

Ruby, read by `brew bundle`. The profile comes from `HOMEBREW_DOTS_PROFILE` (default `desktop`); Homebrew hides other variables from a
Brewfile:

```ruby
desktop = ENV.fetch("HOMEBREW_DOTS_PROFILE", "desktop") == "desktop"  # brew passes only HOMEBREW_* vars

# Taps (from [bootstrap.brew.taps])
tap "oven-sh/bun"
# ...

# Everywhere, containers included: the minimal shell set
brew "zoxide"
brew "fzf"
brew "eza"
brew "bat"
brew "ripgrep"
brew "fd"
brew "jq"
brew "neovim"
brew "git-delta"

return unless desktop

# Desktop: every other formula from packages.toml, with os gates as `if OS.mac?` / `if OS.linux?`
brew "gnu-sed" if OS.mac?
# ...
# The former [tools]: uv and the pipx tools
brew "uv"
uv "pynvim"
uv "debugpy"
uv "commit-check"
uv "graphifyy", python: "3.13"         # no wheels for the newest Python (Linux arm64)
uv "code-review-graph", python: "3.13"
# Casks (macOS)
cask "ghostty" if OS.mac?
# ...
# Flatpaks (Linux desktop)
flatpak "dev.zed.Zed" if OS.linux?
# ...
```

Every entry of `conf.d/packages.toml` maps over: `brew:<x>` → `brew "<x>"`, `brew-cask:<x>` → `cask "<x>"`,
`flatpak:<x>` → `flatpak "<x>"`, `{ os = "macos" }` → `if OS.mac?`, `{ os = "linux" }` → `if OS.linux?`,
`{ env = "desktop" }` → after `return unless desktop`, and each trailing comment is kept. If `brew bundle`'s `uv`
entry does not accept a Python version, those two tools pin it through `UV_PYTHON` in the hook instead (checked
in the plan's first task).

`HOMEBREW_BUNDLE_FILE` points at it (set in the shell config), so `brew bundle …` works from any directory.

### 4.2 `config/mise/conf.d/system.toml`

Replaces `conf.d/packages.toml`. Only apt, only Linux: the Homebrew prerequisites (`build-essential`, `procps`,
`curl`, `file`, `git`, `ca-certificates`) and `zsh`, plus `flatpak` and `docker.io` with `env = "desktop"`. The
Flathub remote files in `bootstrap.toml` stay.

### 4.3 The `post-packages` hook

In `conf.d/bootstrap.toml`, idempotent:

1. If `brew` is not found (on PATH, `/opt/homebrew/bin`, `/home/linuxbrew/.linuxbrew/bin`), install Homebrew
   with `NONINTERACTIVE=1` and the official script.
2. `eval "$(brew shellenv)"` for the rest of the run.
3. `HOMEBREW_DOTS_PROFILE="${MISE_ENV:-desktop}" brew bundle install --file <dots>/config/homebrew/Brewfile --no-upgrade`.

A failure stops the bootstrap (packages are the base for everything after).

### 4.4 The `bootstrap` task

Branches on `MISE_ENV`:

| Step | `desktop` | `container` |
| --- | --- | --- |
| `setup:git:filters` | ✓ | ✓ |
| `setup:hooks` | ✓ | — |
| gopass store clone | ✓ | — |
| oMLX models (macOS, app present) | ✓ | — |
| `skills:restore` | ✓ | — |
| Neovim providers and `Lazy! restore` | ✓ | — |

### 4.5 Profiles

- Delete `config/mise/config.devcontainer.toml` and the `devcontainer` case in `install`.
- `install` keeps writing `miserc.local.toml`.
- The XDG user folders (`~/Desktop`, `~/Documents`, `~/Downloads`, `~/Movies`, `~/Music`, `~/Pictures`) in
  `bootstrap.toml` get `env = "desktop"`.

### 4.6 Removed

`config/mise/conf.d/packages.toml`, the `[tools]` table and the `up`, `brew:search`, `brew:info`, `brew:add`,
`brew:rm` tasks in `config/mise/config.toml`, and the bashrc/zshenv lines that put the Homebrew prefix on PATH
"without brew" (replaced by `brew shellenv`).

### 4.7 Day-to-day commands

| Job | Command |
| --- | --- |
| State | `brew bundle check --verbose` |
| Install missing | `brew bundle install` (or `mise bootstrap -E <profile>`) |
| Add, remove | `brew bundle add <name> [--cask]`, `brew bundle remove <name>` |
| Find | `brew search <text>`, `brew info <name>` |
| Update | `brew update && brew upgrade` |
| Prune undeclared | `brew bundle cleanup` (lists), `brew bundle cleanup --force` (removes) |

## 5. Containers

- Before writing the Brewfile, check `config/zsh` and `config/git` for hard dependencies on desktop-only tools
  (sourced or aliased at startup, the git pager). Move each required one into the always-installed group; guard
  each optional one with `command -v`.
- CST (`distros/{debian,ubuntu}/container-structure-test.yml`):

  | Change | Test |
  | --- | --- |
  | Replace the core-tools loop | `brew --version`; `command -v` for exactly the always-installed group |
  | Remove | the `pynvim-python` test; `age`, `sops` from the tools list; the six XDG user-folder tests |
  | Add | `zsh -lic exit` with empty stderr |
  | Add | `~/.agents/skills`, `~/.local/share/gopass/password-store`, `~/.local/share/nvim/lazy` absent |
  | Keep | `mise --version`, config links and directories, SOPS files staying encrypted |

## 6. CI (`.github/workflows/preview.yml`)

| Change | Why |
| --- | --- |
| New `brewfile` job (`ubuntu-latest`): `ruby -c config/homebrew/Brewfile`, then `brew bundle list --all` with `HOMEBREW_DOTS_PROFILE=desktop` and `=container` | Parses both groups without installing |
| `validate`: free disk space first (remove `/usr/share/dotnet`, `/opt/ghc`, `/usr/local/lib/android`) | The run failed on a full disk |
| `validate`: `timeout-minutes: 30` | A hang fails fast |
| `validate`: after the build, fail if `docker image inspect --format '{{.Size}}'` exceeds the budget | The image cannot drift back to full size |

The budget starts at 2 GB and is set from the first green build (expected ≈1.5 GB: base ≈1 GB, Linuxbrew and nine
bottles). `publish.yml` is checked for anything tied to the removed profile.

## 7. Docs

- README: Install (two profiles); How it works (Brewfile, `system.toml`, no `[tools]`); Day to day (§4.7 and
  Brewfile entry examples: formula, cask, tap, `uv`, `flatpak`, a desktop-only line); Update; Gotchas (drop
  "brew packages not on PATH"; add "`brew bundle cleanup` without `--force` only lists").
- `assets/guides/DOCKER_GUIDE.md`: the container `install` playbook uses `DOTS_PROFILE=container`; document the
  size budget.
- `assets/specs/mise-bootstrap/design.md`: a "superseded" note on §4.1 pointing here.
- `AGENTS.md`, `.agents/skills/dots-context/SKILL.md`: update any mention of `packages.toml` or `devcontainer`.

## 8. Migration (this Mac)

1. `brew bundle check --verbose --file config/homebrew/Brewfile` and `brew bundle install --file … --no-upgrade
   --dry-run` (or `brew bundle list` diffed against `brew list`): expect only linking, no reinstalls.
2. Stop if more than a handful would be reinstalled; report.
3. Run `mise bootstrap -E desktop`; then `brew bundle check` passes and `mise bootstrap status --missing` exits 0.

## 9. Risks

| Risk | Mitigation |
| --- | --- |
| Homebrew on Linux needs `sudo` to create `/home/linuxbrew` | The devcontainer base images have passwordless sudo; on desktops `install` passes the terminal for the prompt |
| mise-installed bottles confuse real Homebrew | §8 checks before installing |
| A desktop-only tool is needed at zsh startup | §5 check and the `zsh -lic exit` CST test |
| `brew bundle`'s `uv` entry cannot pin Python | Fall back to `UV_PYTHON` (§4.1) |
| The image grows past the budget | CI size step fails the PR |
