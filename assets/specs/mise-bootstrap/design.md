<!-- markdownlint-disable -->
# Setting up machines with `mise bootstrap` — design

Evaluation and effort estimate: [report.md](./report.md).

## 1. Goal

Rewrite `install` as a short entry point that prepares a machine and hands over to `mise bootstrap`, so that
one declarative config sets up a fresh Mac (the planned reinstall), a Debian/Ubuntu desktop and the
`distros/` Docker images, using the fewest tools possible: mise alone, plus `apt` and `flatpak` on Linux
where Homebrew cannot help.

**Done when:**

1. **Debian image:** the image builds with the new `install`; inside it, `install --secrets` with the fixture
   archive (§4.6) succeeds, and a second run changes nothing.
2. **Ubuntu VM** (Parallels, arm64): `install -E desktop --secrets` with the fixture archive succeeds from the
   `curl` one-liner, and a second run changes nothing.
3. **macOS guest** in Parallels, set up with the runbook (§6), ends with `mise bootstrap status` showing nothing
   pending, and a second `install` run changes nothing.
4. This Mac shows nothing unexpected in `mise bootstrap status` before it is wiped.
5. After the real Mac is set up, `config/flox`, `config/bin/purge_flox`, the Brewfile and the old package lists
   are deleted, and the docs describe the new flow.

**Out of scope:** macOS settings (`[bootstrap.macos.defaults]`), Arch/Omarchy, restoring backups other than
secrets, and rehearsing the Linux desktop profile (its first run is on real hardware).

## 2. Decisions

| Decision | Choice | Why |
| --- | --- | --- |
| Entry point | A rewritten `install` (about 120 lines) that ends in `mise bootstrap` | mise cannot create macOS users, switch from root to the user, or place secrets before they are needed |
| Package source | Convert the Brewfile; diff with `mise bootstrap packages import --dry-run` | Keeps its comments and its commented-out entries out |
| Homebrew | Not installed; mise installs bottles and casks itself | Fewest tools; mise never runs `brew` |
| Repo location | `~/Work/dots` when cloned; `~/.local/share/dots` links to the checkout in use | Every existing link target keeps working |
| Secrets | `mise run prepare` packs them into an AES-256 encrypted archive; `install --secrets <archive>` opens it | One file to carry; private keys never sit unencrypted on a drive; the age key exists before `setup:age` runs |
| Test secrets | A fixture archive of throwaway keys, generated (`prepare --fixture`), never committed | The repo is public; secret scanners would flag committed keys, even fake ones |
| Image contents | `--local` and `--publish` images build from the committed tree (`git archive`), with the SOPS smudge filter off | The working tree holds decrypted SOPS files; images must only contain them encrypted |
| Passwordless sudo | Automatic in containers; opt-in with `--nopasswd` elsewhere | Unattended builds without weakening hosts by default |
| User name | `roalcantara` by default; `--user` targets another (such as `vscode`) | Devcontainers ship their own user |
| Config layout | `config/mise/conf.d/{bootstrap,packages,dotfiles}.toml` | Small files by concern; `config.toml` untouched; live on this Mac through the existing `~/.config/mise` link |
| Linux target | Debian/Ubuntu (`apt`, `flatpak`) | What `install` supports; the images already exist |

## 3. Layout

| Path | Holds |
| --- | --- |
| `install` | The entry point (§4.4) |
| `script/prepare-secrets`, `[tasks.prepare]` in `mise.toml` | The secrets archive (§4.6) |
| `config/mise/conf.d/bootstrap.toml` | `[bootstrap.directories]`, `[bootstrap.user]` (`login_shell = "zsh"`), `[tasks.bootstrap]` |
| `config/mise/conf.d/packages.toml` | `[bootstrap.brew.taps]`, `[bootstrap.packages]` |
| `config/mise/conf.d/dotfiles.toml` | `[dotfiles]` |
| `config/mise/config.toml` | Existing settings and tasks; `[tools]` gains the Brewfile's 7 `go` modules and 3 `uv` packages as `go:` and `pipx:` tools (`cmd/go` and `cmd/gofmt` come with Go itself) |

`~/.config/mise` links to `config/mise`. mise loads `conf.d/*.toml` alphabetically, before `config.toml`.

### Profiles

| Profile | Selected by | Used by | Effect |
| --- | --- | --- | --- |
| default | — | the new Mac | Every entry for the current OS |
| `desktop` | `-E desktop` (`install` passes it through) | a Linux desktop | Also applies entries marked `env = "desktop"` |
| `container` | `install` detects a container | the Debian and Ubuntu images, devcontainers | Applies no `env = "desktop"` entries; `install` also passes `--skip user` (the login shell) |

Entries carry `os = "macos"` or `os = "linux"` only where needed: mise skips entries whose manager is
missing (no casks on Linux, no flatpak in containers).

## 4. Components

### 4.1 Packages (`conf.d/packages.toml`)

| Group | Entries | Condition |
| --- | --- | --- |
| Formulae | 84 from the Brewfile, keeping its comments; commented-out lines stay comments | `os = "macos"` on formulae with no Linux support in Homebrew's data |
| Taps | The Brewfile's taps under `[bootstrap.brew.taps]` | — |
| Casks | 38 as `brew-cask:` | `os = "macos"`; Nerd Font casks `os = ["linux", "macos"]` |
| apt basics | `zsh`, `git`, `ca-certificates`, `gnupg`, `unzip`, `wget`, `fontconfig` | `os = "linux"` |
| flatpak | The 10 entries of `config/flatpak/requirements.txt` as `flatpak-user:` | none needed; skipped where flatpak is missing. `install -E desktop` installs flatpak and adds the Flathub remote, which mise never does |
| Docker Engine | `apt:docker.io` (replaces the old Docker Desktop repo step, which pointed at a repository Docker does not publish Desktop through) | `env = "desktop"` |
| Ollama | `brew:ollama` (replaces `curl \| sh`) | — |
| Desktop-only CLI tools | Formulae only useful on a desktop | `env = "desktop"`, added when a container build shows they are slow or useless there |

The Brewfile has no `mas` lines, so there are no App Store entries. The snap list (`snapcraft`, `ghostty`) is
dropped: neither is needed in images, and Ghostty on a Linux desktop is installed by hand until a package
exists. The apt list's fonts are replaced by the Nerd Font casks; `fontconfig` and `unzip` join the basics. Formulae that ran under `brew services` get a
`[bootstrap.macos.launchd.agents]` entry or start from their own command; each is flagged during conversion.

### 4.2 Links and directories (`conf.d/dotfiles.toml`, `conf.d/bootstrap.toml`)

Shared by both systems, mirroring this Mac. `install` creates `~/.local/share/dots` and `~/.config/mise`
(§4.4) because mise needs them before it can read this config; every other link is here:

| Link | Target | Count |
| --- | --- | --- |
| `~/.config/<name>` | each top-level entry of `~/.local/share/dots/config` (one `symlink` entry each; `symlink-each` would link every file recursively) | All but the excluded: `mise` (`install`), `hk` (`setup:hooks`), `.gitignore`, `.vscode`, the package lists (`apt`, `flatpak`, `snap`, `flox`), and `glow`, `opencode`, `raycast`, `ssh`, which are real folders on this Mac (settings and keys restored from backup). This matches the containers, which linked all of `~/.config`, and links 12 entries this Mac does not link yet (`npm`, `claude`, `delta`, …) |
| `~/.config/kb` | `~/.local/share/dots/config/kodexb` | 1 alias; the broken `bunfig.toml` and `tealdeer` links are not recreated |
| `~/.zshenv`, `~/.bashrc`, `~/.profile` | their files under `~/.config` | 3 |
| `~/.ssh`, `~/.gnupg` | `~/.config/ssh`, `~/.config/gnupg` (copied by `install --secrets`) | 2 |
| `~/.local/bin/*` | each executable in `config/bin` (`symlink-each`) | 24 today; non-executables excluded or moved out of `config/bin` |

Folders for macOS-only tools (yabai, skhd, amethyst, rift, glide, ranma) are linked on Linux too. Every link
is `relative = true`, matching this Mac's links (`../.local/share/dots/config/<name>`), so stage 1 of §8 shows
them as unchanged.

`[bootstrap.directories]` creates the folders the old `install` created: `~/.local/{bin,share,state}`,
`~/.local/state/zim`, `~/.local/share/{zsh,npm,gems}`, `~/.cache/{zsh,npm,mise}`, and the XDG user folders
`~/{Desktop,Documents,Downloads,Movies,Music,Pictures,Projects,Work}` that the images' structure tests check. The
environment variables the old `install` exported are already set by the zsh config.

`[bootstrap.user]` sets `login_shell = "zsh"`; mise resolves the path and adds it to `/etc/shells`. The
`USER_ZDOTDIR` line in `/etc/zsh/zshenv` (Linux) stays in `install`, because `[bootstrap.files]` writes whole
files only.

### 4.3 Bootstrap task (`[tasks.bootstrap]`)

Runs last on every `mise bootstrap`; every step is idempotent and warns instead of failing:

1. `mise run -C ~/.local/share/dots setup:git:filters` (depends on `setup:age`, which skips when
   `~/.config/age/keys.txt` exists).
2. `mise run -C ~/.local/share/dots setup:hooks`.
3. Neovim providers and plugins, as the old `install` does: `npm` `neovim`, the `pynvim` venv, `gem`
   `neovim`, and a headless `Lazy! sync`.

### 4.4 `install`

```text
install [--user <name>] [--secrets <archive>] [--tz <zone>] [--nopasswd] [--branch <ref>] [-E <profile>] [--dry-run]
```

| Flag | Default | Effect |
| --- | --- | --- |
| `--user` | `roalcantara` | Target user; created only if missing |
| `--secrets` | none | Encrypted archive made by `prepare` (§4.6); the passphrase comes from `DOTS_SECRETS_PASSPHRASE` or a prompt |
| `--tz` | none (the current zone is kept) | Sets the timezone when it differs |
| `--nopasswd` | off; on in containers | Grants the user passwordless sudo |
| `--branch` | `main` | Branch to clone when `install` does not run from a checkout |
| `-E` | none; `container` in containers | Passed to `mise bootstrap`; `desktop` also prepares flatpak (step 2) |
| `--dry-run` | off | Prints `would: …` for every change, including the final `mise bootstrap` command, and makes none |

Bash, `set -euo pipefail`, one function per step. Every step tests before acting, so a second run changes
nothing:

1. **Detect** the OS (`darwin`, `linux`) and whether this is a container (the old `is_container` checks). A
   container turns on `--nopasswd`, `-E container` and `--skip user`.
2. **Root work**, directly when run as root, otherwise through `sudo` (which prompts on hosts):
   - The user and its primary group, if `id <user>` fails: `sysadminctl -addUser` on macOS, `groupadd` and
     `useradd -m -s "$(command -v zsh || echo /bin/bash)"` on Linux.
   - The timezone, when `--tz` is given and differs: `systemsetup -settimezone` on macOS, `/etc/localtime`
     and `/etc/timezone` on Linux.
   - Passwordless sudo, when on: `/etc/sudoers.d/<user>` written once, mode 440, checked with `visudo -cf`.
   - Linux: the `export USER_ZDOTDIR=<home>/.config/zsh` line in `/etc/zsh/zshenv`, added once.
   - Linux with `-E desktop`: `apt-get install flatpak` when missing.
   - Linux with `--secrets`: `apt-get install unzip` when missing (minimal Ubuntu lacks it).
   - **Open the archive:** `openssl enc -d -aes-256-cbc -pbkdf2 -iter 600000` into a temporary folder (mode
     700), then `unzip`. A wrong passphrase stops `install` with exit code 2. The folder is deleted on exit, and
     before the switch to the user, who receives its own copy.
   - When run as root from a checkout inside the user's home that another user owns (a repo `COPY`d into an
     image): `chown -R <user>` of that checkout.
3. **Switch to the user.** When run as root, `install` runs the remaining steps as the user
   (`sudo -u <user> -H`). A copy piped from `curl` is saved to a temporary file first so it can run itself.
4. **mise:** the pinned version into `~/.local/bin` (`curl https://mise.run` with `MISE_VERSION`), unless
   `mise --version` already reports it.
5. **Repo:** when `install` runs from a checkout of `dots`, that checkout is used where it is; otherwise
   `git clone --branch <ref>` into `~/Work/dots`, or `git pull --ff-only` when it is already there. Then
   `~/.local/share/dots` links to the checkout and `~/.config/mise` to its `config/mise`.
6. **Secrets**, when `--secrets` is given: from the opened archive, a fixed list, never overwriting an existing file —
   `age/keys.txt` (mode 600), `ssh/` and `gnupg/` (folders 700, files 600), `gh/hosts.yml`. `age/keys.txt` goes
   into the repo's `config/age/`, which `~/.config/age` links to (`config/.gitignore` keeps it out of git); the
   rest go into `~/.config`, as real folders. A
   `github_token` file is exported as `GITHUB_TOKEN` for this run only, unless `GITHUB_TOKEN` is already set,
   so mise avoids GitHub API rate limits; it is never stored.
7. **Flathub** (Linux with `-E desktop`): `flatpak remote-add --user --if-not-exists flathub …`.
8. **Bootstrap:** `mise bootstrap`, with `-E <profile>` and, in containers, `--skip user --yes`.

Packages, links and tools live only in the mise config; `install` holds none of them.

### 4.5 Docker images (`distros/{debian,ubuntu}/Dockerfile`)

The Dockerfiles copy the repo to `/home/<user>/Work/dots` and run, as root,
`./install --user "$USERNAME" --tz "$TZ"`, with `GITHUB_TOKEN` read from the build's `github_token` secret.
Images never receive a secrets archive: they are published, so no key may enter them. `install` detects the
container, creates the user, grants passwordless sudo and runs `mise bootstrap -E container --skip user` as
that user. A failing step fails the build. The mise version is the one pinned in `install`.

`mise run build --local` and `--publish` send `git -c filter.sops.smudge=cat -c filter.sops.required=false
archive HEAD` as the build context instead of the working tree, so SOPS-encrypted files stay encrypted in the
image. Uncommitted changes are therefore not in a local build: commit (or stash-commit) first.

### 4.6 `prepare` (`mise run prepare`, `script/prepare-secrets`)

```text
prepare-secrets [--fixture] [--output <file>]
```

Collects what `install --secrets` expects, zips it, and encrypts the zip with
`openssl enc -aes-256-cbc -pbkdf2 -iter 600000` (the passphrase from `DOTS_SECRETS_PASSPHRASE`, or an
`openssl` prompt). The archive is written mode 600, to `~/dots-secrets.zip.enc` by default; `*.zip.enc` is
git-ignored.

| Archive path | Taken from |
| --- | --- |
| `age/keys.txt` | `~/.local/share/dots/config/age/keys.txt` |
| `ssh/`, `gnupg/` | `~/.config/ssh`, `~/.config/gnupg`, without sockets (`S.*`) |
| `gh/hosts.yml` | `~/.config/gh/hosts.yml` |
| `github_token` | `gh auth token`, when `gh` is signed in |

`--fixture` writes the same layout with throwaway content instead (a new `ssh-keygen` key, a fake age key, a
fake `gh/hosts.yml`, no token) and the passphrase `dots-fixture`. Tests and the VM checks use it; it is never
committed.

## 5. Entry point

```sh
curl -fsSL https://raw.githubusercontent.com/roalcantara/dots/main/install | bash -s -- --secrets <archive>
```

A Linux desktop adds `-E desktop`. Later runs: `~/.local/share/dots/install`, or `mise bootstrap` once the
user, repo and secrets exist.

## 6. New-Mac runbook

0. **Before wiping the old Mac:** `mise run -C ~/Work/dots prepare -- --output /Volumes/meex900/bak/dots-secrets.zip.enc`.
1. Finish macOS setup; sign in to the Apple Account and the App Store; run `xcode-select --install`; connect
   the backup drive.
2. Run §5 with `--secrets /Volumes/meex900/bak/dots-secrets.zip.enc`; enter the passphrase when asked.
3. Unzip `config-<date>.zip` into `~/restore`, copy the app settings it holds (every `~/restore/.config` entry
   that is not a link in `~/.config` now) into `~/.config`, then restore `omp-<date>.zip` into `~`.
4. Restore `Work-<date>.zip` without the repo: `unzip Work-<date>.zip -x 'Work/dots/*'`.
5. Open a new shell; `mise bootstrap status` shows nothing pending. Delete `~/restore`.

## 7. Failures

- `install` stops at the first failing step; a rerun skips what is done.
- `mise bootstrap` is not transactional. A failed part is fixed and the command rerun; parts already applied
  are skipped.
- `mise dot undo` reverts dotfile changes.
- Image builds stop at the first failing step.
- A wrong archive passphrase stops `install` before any change; rerun with the right one.
- The Brewfile stays in the repo until the real Mac is set up (§1, criterion 5).

## 8. Testing

Each stage gates the next:

| # | Where | Checks |
| --- | --- | --- |
| 1 | This Mac, read-only | `mise bootstrap status` and `--dry-run` load the `conf.d` bootstrap tables and show almost nothing pending; `mise bootstrap packages status` matches the converted list against what is installed; `shellcheck` passes on `install` and `script/prepare-secrets`; the Bun specs pass (fixture archive, wrong passphrase, dry runs) |
| 2 | Debian image (required), Ubuntu image | Build succeeds; SOPS files in the image are still encrypted; inside the image, `install --secrets <fixture>` succeeds and a second run changes nothing; slow source builds are moved behind `env = "desktop"`; `install --user vscode` creates no new user |
| 3 | Ubuntu VM in Parallels (required) | The `curl` one-liner with `-E desktop` and the fixture archive; flatpak apps, Docker Engine, login shell, secrets with correct modes; a second run changes nothing |
| 4 | macOS guest in Parallels | The §6 runbook end to end with the fixture archive; casks, links, task, login shell, secrets with correct modes |
| 5 | This Mac, reinstalled | The §6 runbook with the real archive; then the deletions in §1 criterion 5 |

## 9. Risks

| Risk | Mitigation |
| --- | --- |
| `[bootstrap]` tables in `conf.d` files are not loaded | Test stage 1 checks it first; fall back to `config.toml` |
| A formula needs `brew services` or a skipped post-install step | Flag during conversion; launchd agent or a task step |
| Linux arm64 formulae without bottles build from source and slow image builds | `env = "desktop"` for those |
| `symlink-each` cannot skip non-executables in `config/bin` | Move non-executables out of `config/bin` |
| `mise bootstrap` is new and its keys may change | Pin the mise version in `install`; rerun `mise bootstrap status` after mise upgrades |
| `sysadminctl -addUser` needs an admin and does not give the new user a secure token | Only used when the user is missing, which a personal Mac never is; documented, not automated further |
| A piped `install` cannot re-run itself as the user | Saved to a temporary file before switching (§4.4 step 3) |
| The secrets archive is lost, or its passphrase forgotten | Keep the passphrase in Bitwarden; `prepare` can be rerun on any machine that still has the keys |
| `git archive` applies the SOPS smudge filter and decrypts files into the build context | The build disables it (`-c filter.sops.smudge=cat`); stage 2 checks that the image's SOPS files are encrypted |
