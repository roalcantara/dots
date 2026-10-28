<!-- markdownlint-disable -->
# Setting up machines with `mise bootstrap` — design

Evaluation and effort estimate: [report.md](./report.md).

## 1. Goal

Replace `install` with `mise bootstrap` so that one declarative config sets up a fresh Mac (the planned
reinstall), a Debian/Ubuntu desktop and the `distros/` Docker images, using the fewest tools possible:
mise alone, plus `apt` and `flatpak` on Linux where Homebrew cannot help.

**Done when:**

1. A fresh macOS guest in Parallels, set up with the runbook (§6), ends with
   `mise bootstrap status` showing nothing pending, and a second `mise bootstrap` changes nothing.
2. The Debian and Ubuntu images build with `mise bootstrap -E container` and no `install`.
3. This Mac shows nothing unexpected in `mise bootstrap status` before it is wiped.
4. After the real Mac is set up, `install`, `config/flox`, `config/bin/purge_flox`, the Brewfile and the
   snap list are deleted, and the docs describe the new flow.

**Out of scope:** macOS settings (`[bootstrap.macos.defaults]`), Arch/Omarchy, restoring backups from inside
bootstrap, and rehearsing the Linux desktop profile (its first run is on real hardware).

## 2. Decisions

| Decision | Choice | Why |
| --- | --- | --- |
| Package source | Convert the Brewfile; diff with `mise bootstrap packages import --dry-run` | Keeps its comments and its commented-out entries out |
| Homebrew | Not installed; mise installs bottles and casks itself | Fewest tools; mise never runs `brew` |
| Repo location | `~/Work/dots`, linked from `~/.local/share/dots` | Every existing link target keeps working |
| Secrets and backups | Restored by hand before bootstrap | Bootstrap stays generic; the age key exists before `setup:age` runs |
| Config layout | `config/mise/conf.d/{bootstrap,packages,dotfiles}.toml` | Small files by concern; `config.toml` untouched; live on this Mac through the existing `~/.config/mise` link |
| Linux target | Debian/Ubuntu (`apt`, `flatpak`) | What `install` supports; the images already exist |
| Users and timezone in images | Dockerfile steps, not bootstrap | Standard place; bootstrap stays user-level |

## 3. Layout

All files live in `config/mise/`, which `~/.config/mise` links to. mise loads `conf.d/*.toml`
alphabetically, before `config.toml`.

| File | Holds |
| --- | --- |
| `conf.d/bootstrap.toml` | `[bootstrap.repos]`, `[bootstrap.directories]`, `[bootstrap.files]` (Linux), `[bootstrap.user]` (zsh login shell), `[tasks.bootstrap]` |
| `conf.d/packages.toml` | `[bootstrap.brew.taps]`, `[bootstrap.apt.sources]`, `[bootstrap.packages]` |
| `conf.d/dotfiles.toml` | `[dotfiles]` |
| `config.toml` | Existing settings and tasks; `[tools]` gains the Brewfile's 9 `go` and 3 `uv` entries as `go:` and `pipx:` tools |

### Profiles

| Profile | Selected by | Used by | Effect |
| --- | --- | --- | --- |
| default | — | the new Mac | Every entry for the current OS |
| `desktop` | `-E desktop` | a Linux desktop | Also applies entries marked `env = "desktop"` |
| `container` | `-E container` | the Debian and Ubuntu images | Applies no `env = "desktop"` entries; the Dockerfile also passes `--skip user` (the login shell) |

Entries carry `os = "macos"` or `os = "linux"` only where needed: mise skips entries whose manager is
missing (no casks on Linux, no flatpak in containers).

## 4. Components

### 4.1 Packages (`conf.d/packages.toml`)

| Group | Entries | Condition |
| --- | --- | --- |
| Formulae | 84 from the Brewfile, keeping its comments; commented-out lines stay comments | `os = "macos"` on formulae with no Linux support in Homebrew's data |
| Taps | The Brewfile's taps under `[bootstrap.brew.taps]` | — |
| Casks | 38 as `brew-cask:` | `os = "macos"`; Nerd Font casks `os = ["linux", "macos"]` |
| Mac App Store | `mas:` entries for any Brewfile `mas` lines, with `mas` in `[tools]` | `os = "macos"` |
| apt basics | `zsh`, `git`, `ca-certificates`, `gnupg`, `unzip`, `wget` | `os = "linux"` |
| flatpak | The 10 entries of `config/flatpak/requirements.txt` as `flatpak-user:` | none needed |
| Docker Desktop | apt source and key under `[bootstrap.apt.sources]`, `apt:docker-desktop` | `env = "desktop"` |
| Ollama | `brew:ollama` (replaces `curl \| sh`) | — |
| Desktop-only CLI tools | Formulae only useful on a desktop | `env = "desktop"`, added when a container build shows they are slow or useless there |

The snap list (2 entries) is dropped, with flatpak or Homebrew replacements where they exist; the 1-entry
apt list folds into the basics. Formulae that ran under `brew services` get a
`[bootstrap.macos.launchd.agents]` entry or start from their own command; each is flagged during conversion.

### 4.2 Links and directories (`conf.d/dotfiles.toml`, `conf.d/bootstrap.toml`)

Shared by both systems, mirroring this Mac:

| Link | Target | Count |
| --- | --- | --- |
| `~/.local/share/dots` | `~/Work/dots` | 1, applied first |
| `~/.config/<name>` | `~/.local/share/dots/config/<name>` | 35 today, plus `hk` (from `setup:hooks`); `bunfig.toml` and `cog` normalised to go through `~/.local/share/dots`; `kb` and `kodexb` both kept |
| `~/.zshenv`, `~/.bashrc`, `~/.profile` | their files under `~/.config` | 3 |
| `~/.ssh`, `~/.gnupg` | `~/.config/ssh`, `~/.config/gnupg` (restored from backup) | 2 |
| `~/.local/bin/*` | each executable in `config/bin` (`symlink-each`) | 24 today; non-executables excluded or moved out of `config/bin` |

Folders for macOS-only tools (yabai, skhd, amethyst, rift, glide, ranma) are linked on Linux too.

`[bootstrap.directories]` creates the folders `install` created: `~/.local/{bin,share,state}`,
`~/.local/state/zim`, `~/.local/share/{zsh,npm,gems}`, `~/.cache/{zsh,npm,mise}`, and `~/Work`. The
environment variables `install` exported are already set by the zsh config.

`[bootstrap.files]` (`os = "linux"`) adds the `USER_ZDOTDIR` line to `/etc/zsh/zshenv`; mise uses `sudo`.

### 4.3 Bootstrap task (`[tasks.bootstrap]`)

Runs last on every `mise bootstrap`; every step is idempotent and warns instead of failing:

1. `mise run -C ~/Work/dots setup:git:filters` (depends on `setup:age`, which skips when
   `~/.config/age/keys.txt` exists).
2. `mise run -C ~/Work/dots setup:hooks`.
3. Neovim providers and plugins, as `install` does: `npm` `neovim`, the `pynvim` venv, `gem` `neovim`, and a
   headless `Lazy! sync`.

### 4.4 Docker images (`distros/{debian,ubuntu}/Dockerfile`)

Replace the `./install … -e` steps with:

1. Create the user and group, grant passwordless sudo, set `TZ` (standard Dockerfile steps).
2. Install mise (pinned version); copy the repo to `/home/<user>/Work/dots`; link `~/.config/mise` to
   `~/Work/dots/config/mise` (the copy has no remote to clone from, so `--from` is not used).
3. As the user: `mise bootstrap -E container --skip user`.

A failing bootstrap step fails the build.

## 5. Entry point

```sh
curl https://mise.run | sh
~/.local/bin/mise bootstrap --from https://github.com/roalcantara/dots \
  --from-dir ~/Work/dots --config-dir config/mise
```

A Linux desktop adds `-E desktop`. Later runs: `mise bootstrap`, or `mise bootstrap --update` to pull first.

## 6. New-Mac runbook

1. Finish macOS setup; sign in to the Apple Account and the App Store; run `xcode-select --install`; connect
   the backup drive.
2. Restore `config-<date>.zip` into `~`, then `omp-<date>.zip`.
3. Run the two commands in §5.
4. Restore `Work-<date>.zip` without the repo: `unzip Work-<date>.zip -x 'Work/dots/*'`.
5. Open a new shell; `mise bootstrap status` shows nothing pending.

## 7. Failures

- Bootstrap is not transactional. A failed part is fixed and the command rerun; parts already applied are
  skipped.
- `mise dot undo` reverts dotfile changes.
- Image builds stop at the first failing part.
- The Brewfile and `install` stay in the repo until the real Mac is set up (§1, criterion 4).

## 8. Testing

Each stage gates the next:

| # | Where | Checks |
| --- | --- | --- |
| 1 | This Mac, read-only | `mise bootstrap status` and `--dry-run` load the `conf.d` bootstrap tables and show almost nothing pending; `mise bootstrap packages status` matches the converted list against what is installed |
| 2 | Debian and Ubuntu images | Build succeeds; a second `mise bootstrap` in the image leaves nothing pending; links resolve; slow source builds are moved behind `env = "desktop"` |
| 3 | macOS guest in Parallels | The §6 runbook end to end; casks, links, task, login shell. `mas:` entries may be untestable in a VM |
| 4 | This Mac, reinstalled | The §6 runbook; then the deletions in §1 criterion 4 |

## 9. Risks

| Risk | Mitigation |
| --- | --- |
| `[bootstrap]` tables in `conf.d` files are not loaded | Test stage 1 checks it first; fall back to `config.toml` |
| A formula needs `brew services` or a skipped post-install step | Flag during conversion; launchd agent or a task step |
| Linux arm64 formulae without bottles build from source and slow image builds | `env = "desktop"` for those |
| `symlink-each` cannot skip non-executables in `config/bin` | Move non-executables out of `config/bin` |
| `mise bootstrap` is new and its keys may change | Pin the mise version in the Dockerfiles; rerun `mise bootstrap status` after mise upgrades |
