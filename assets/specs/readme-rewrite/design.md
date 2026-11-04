<!-- markdownlint-disable -->
# Rewrite the README as an operator manual — design

## 1. Goal

Make `README.md` the one place that answers "how do I…" for a machine set up from this repo: install it, see
what state it is in, add, remove and update packages, sync secrets, restore agent skills, and find the
playbooks and per-tool configuration. Remove everything that describes the retired setup (Brewfile, Flox,
`mise run bundle`, the DISTRO/MISE tooling table).

**Reader:** the owner, months later, on any machine (`crafting-effective-readmes`: Config type for what is here
and how to extend it, Internal type for setup and runbooks).

**Done when:**

1. Every command in the README runs as written on this Mac (or, for Linux-only lines, is marked so).
2. No README text mentions `Brewfile`, `bundle`, `Flox`, `config/homebrew`, `config/flox` or
   `homebrew-recipes.md`.
3. Content that lived only in the README has moved (§4) and every link into it still resolves.
4. `markdownlint` passes on every changed file.

**Out of scope:** writing READMEs for config folders that lack one (starship, ghostty, …), rewriting the guides
beyond the moves in §4, and the release/CHANGELOG flow.

## 2. Findings (2026-11-04)

| Finding | Evidence |
| --- | --- |
| The package sections document a deleted setup | "Homebrew Configuration" and the "Git Hooks" block run `mise run bundle …` in `config/homebrew`, which no longer exists |
| The tooling table is stale | "OVEREVIEW" (sic) splits tools into DISTRO and MISE; almost everything is now `brew:` in `config/mise/conf.d/packages.toml` |
| The current commands are undocumented | `mise bootstrap status`/`plan`, `mise bootstrap packages status`, `mise outdated`, `mise run up`, `mise run brew:add|rm|search|info`, `mise dot …`, `mise run skills:*` appear nowhere in the README |
| `assets/guides/homebrew-recipes.md` is Brewfile-era | Every command in it uses `brew bundle` |
| `assets/README.md:29` links to `README.md#agent-workflow` | Moving that section breaks the link |
| `zsh:bench` is not in `TESTING_GUIDE.md` | Only the README's Benchmarks section has it |
| `DOCKER_GUIDE.md` already covers `build`, `test`, `start` | Its task table, lines 20–22 |
| Config folders with a README | `bat`, `bin`, `git`, `helix`, `hk`, `nvim`, `sops`, `ssh`, `zsh` |

## 3. README outline

Target length: 200–250 lines. Each section names the commands it must show; prose stays to one or two sentences
per command.

1. **dots** — one sentence: what it sets up (shell, editor, packages, secrets, agent skills) and where it runs
   (macOS, Debian/Ubuntu, containers). The Preview badge. `> Last reviewed: <date>`.
2. **Install**
   - The one-liner, and the macOS prerequisite (`xcode-select --install`).
   - What `install` does, as a numbered list: install mise, clone to `~/.local/share/dots`, read the age key, link
     `~/.config/mise`, sign `gh` in, `mise bootstrap --adopt` (secrets from `dots-history`), record the profile in
     `config/mise/miserc.local.toml`, `mise bootstrap -E <profile>`.
   - The environment variables table (`DOTS_BRANCH`, `DOTS_REPO`, `DOTS_HISTORY`, `DOTS_PROFILE`, `DOTS_AGE_KEY`).
   - A profiles table: `desktop` (everything), `container` (no login shell; replaces the image's dotfiles),
     `devcontainer` (also no system packages, Neovim setup or agent skills).
   - Later runs: `mise bootstrap -E <profile>`; a second run changes nothing.
3. **How it works**
   - Three lines: `install` prepares the machine and hands over to `mise bootstrap`; mise reads
     `~/.config/mise` (a link to `config/mise/`); the root `mise.toml` holds repo tasks.
   - **Where things are declared** table:

     | File | Holds |
     | --- | --- |
     | `config/mise/config.toml` | `[tools]` mise installs itself, `[settings]`, the encrypted history (`[dotfiles]` track entries), and the `up`/`brew:*`/`backup` tasks |
     | `config/mise/conf.d/packages.toml` | `[bootstrap.packages]`: Homebrew formulae and casks, apt and flatpak packages, with `os`/`env` gates |
     | `config/mise/conf.d/bootstrap.toml` | Directories, system files, login shell, and the `bootstrap` task (git filters, hooks, gopass store, oMLX models, skills, Neovim) |
     | `config/mise/conf.d/dotfiles.toml` | Links from `~/.config/*` into this repo |
     | `config/mise/config.<profile>.toml` | Per-profile overrides (`devcontainer`: the minimal tool set) |
     | `config/agents/` | The agent skills lock, `review.csv`, and the owner's commands |
     | `mise.toml` (repo root) | Repo tasks: `build`, `test`, `start`, `setup:*`, `zsh:*`, `skills:*` |

4. **Day to day**
   - **Check the state:** `mise bootstrap status` (and `--missing`, which exits 1 when anything differs),
     `mise bootstrap plan`, `mise bootstrap packages status`, `mise outdated`, `mise dot status`.
   - **Find, add and remove packages:** `mise run brew:search <text>`, `mise run brew:info <name> [--cask]`,
     `mise run brew:add <name> [--cask]`, `mise run brew:rm <name> [--cask]`. Then the entry syntax by hand, one
     example each: a formula, `os = "macos"`, `env = "desktop"`, a cask, a third-party tap (`owner/tap/name`),
     an `apt:` and a `flatpak:` entry. Tools mise installs itself go in `[tools]` of `config.toml`
     (`npm:`, `pipx:`, `aqua:`).
   - **Update:** `mise run up` (upgrade every package, then prune undeclared ones; it asks first),
     `mise upgrade` (mise tools), `mise bootstrap -E <profile>` (re-apply after editing the config).
   - **Secrets:** what is tracked (`~/.config/ssh`, `~/.config/gnupg`, `~/.config/gopass`), then
     `mise dot save`, `mise dot sync` (push), `mise dot pull` (on another machine).
   - **Agent skills:** `skills add <repo> -g` and `skills update` change `config/agents/skill-lock.json` (commit
     it); `mise run skills:restore` installs what is missing; `mise run skills:audit` writes `review.csv`.
5. **Configurations** — one table row per area: what it configures and a link to its folder README where one
   exists. Rows: zsh, nvim, git, hk (hooks), ssh, sops, bin (terminal helpers), helix, bat, starship, ghostty,
   window management (amethyst, yabai, skhd), mise, agents.
6. **Playbooks** — one line and a link each:

   | Playbook | Where |
   | --- | --- |
   | Test `install` in a container (`devcontainer` profile) | `assets/guides/DOCKER_GUIDE.md` (moved, §4) |
   | Build, run and structure-test the Docker images | `assets/guides/DOCKER_GUIDE.md` |
   | Run the tests (BDD and integration specs) | `assets/guides/TESTING_GUIDE.md` |
   | Benchmark zsh startup (`mise run zsh:bench`) | `assets/guides/TESTING_GUIDE.md` (added, §4) |
   | Prepare a reinstall (backups, new-Mac runbook) | `assets/specs/mise-bootstrap/design.md` §6 |
   | Work on this repo with an agent | `AGENTS.md` (moved, §4) |

7. **Gotchas** — one line each, with the fix:
   - `mise x …` on a host with missing global tools tries to install them all: prefix
     `MISE_AUTO_INSTALL=0 MISE_EXEC_AUTO_INSTALL=0`.
   - GitHub HTTPS (the history push) authenticates through `gh`; `mise dot sync` hangs if `gh` is signed out.
   - A new shell sees the profile's tools only through `config/mise/miserc.local.toml`, which `install` writes.
   - `brew:` packages live in the Homebrew prefix; non-interactive scripts must put it on PATH.
   - `skills add`/`update` write the committed lock through its link: review the diff.
   - The skills lock records no commit: a skill deleted upstream cannot be restored.
   - SOPS-encrypted files (`config/.env`) need the git filters from `mise run setup:git:filters`.
8. **Repository layout** — a short tree of the top level (`install`, `config/`, `assets/`, `distros/`,
   `script/`, `mise.toml`, `hk.pkl`) with one line each.
9. **License** — one line, linking `LICENSE`.

## 4. Moves and deletions

| Content | From | To |
| --- | --- | --- |
| Agent Workflow (SDD steps) | README | `AGENTS.md`, new section `## Workflow`; fix `assets/README.md:29` to link `../AGENTS.md#workflow` |
| Test `install` in a container | README | `assets/guides/DOCKER_GUIDE.md`, new section of the same name |
| Terminal Helpers table | README | `config/bin/README.md` (merge rows it lacks) |
| zsh benchmark commands | README "Benchmarks" | `assets/guides/TESTING_GUIDE.md` |
| Overview, Key Features, badges except Preview, OVEREVIEW, Homebrew Configuration, Git Hooks block, Documentation & Verification, Docker & DevContainers, Contributing, Acknowledgements | README | Deleted |
| `assets/guides/homebrew-recipes.md` | — | Deleted; its row in `assets/guides/README.md`, if any, too |

## 5. Verification

| Check | How |
| --- | --- |
| Commands run | Run each read-only command from §3.4 on this Mac (`status`, `plan`, `packages status`, `outdated`, `dot status`, `brew:search`, `brew:info`); expect no error |
| No stale terms | `grep -niE 'brewfile|bundle|flox|config/homebrew|homebrew-recipes' README.md` prints nothing |
| Links resolve | Every relative link in the changed files points at an existing file or heading |
| Lint | `markdownlint` on every changed file |
