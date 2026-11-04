<!-- markdownlint-disable -->
# Rewrite the README as an operator manual — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task by task. Steps use checkbox (`- [ ]`) syntax for
> tracking. Tick each box in this file as you finish it.

**Goal:** Replace `README.md` with the operator manual in [design.md](./design.md) §3, after moving the content
that lives only in the README (§4) to the guides that own it.

**Architecture:** Docs only. Tasks 1–5 move or delete content outside the README; Task 6 rewrites the README in
one go from the full text given here; Task 7 verifies commands, links, stale terms and lint.

**Tech stack:** Markdown, `markdownlint-cli` 0.49.1, Python 3 (for the move and link-check scripts), mise.

---

## Ground rules for the executor

- Work **only** in the worktree `~/Work/dots-readme`, branch `docs/readme-rewrite`. Check with
  `git -C ~/Work/dots-readme branch --show-current`. Never touch `~/Work/dots` (the owner has uncommitted work
  there).
- **SOPS files are checked out encrypted in this worktree**, so plain `git status`, `git add` and `git commit`
  fail on `config/.env`. In every shell, define and use this wrapper instead of `git`:

  ```bash
  g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }
  ```

- Commit with `HK=0 g commit ...` (the hooks need tools this worktree does not set up). End every commit message
  with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Lint every Markdown file you change before committing:

  ```bash
  cd ~/Work/dots-readme && mise x npm:markdownlint-cli@0.49.1 -- markdownlint <files>
  ```

  Expected: no output. Files starting with `<!-- markdownlint-disable` are exempt by design.
- Add files by path. Never `g add -A`.
- Set `export MISE_AUTO_INSTALL=0 MISE_EXEC_AUTO_INSTALL=0` in every shell.

## File map

| File | Action | Task |
| --- | --- | --- |
| `AGENTS.md` | Add `## Workflow` (moved from the README) | 1 |
| `assets/README.md` | Fix the link to the moved section | 1 |
| `assets/guides/DOCKER_GUIDE.md` | Add the container `install` playbook (moved) | 2 |
| `config/bin/README.md` | Add the helpers table (moved) | 3 |
| `assets/guides/TESTING_GUIDE.md` | Add the zsh benchmark section | 4 |
| `assets/guides/homebrew-recipes.md` | Delete | 5 |
| `README.md` | Rewrite | 6 |

---

### Task 1: Move Agent Workflow to `AGENTS.md`

**Files:** Modify `AGENTS.md`, `assets/README.md`

- [ ] **Step 1: Add the section.** In `AGENTS.md`, insert this block right before the line `## Specs and guides`:

```markdown
## Workflow

Features follow Spec-Driven Development (SDD):

1. **Plan:** read [`assets/guides/GLOSSARY.md`](assets/guides/GLOSSARY.md) and the relevant guides; write
   `requirements.md`, `design.md` and `tasks.md` under `assets/specs/<feature-slug>/`; stop for review once the
   specs are approved.
2. **Implement:** execute `assets/specs/<feature-slug>/tasks.md` step by step; keep every quality gate
   (`mise run -C assets test all`, linters, type checks) at zero warnings and errors; commit atomically with
   [Conventional Commits](assets/guides/GIT_COMMITS_GUIDE.md).

```

- [ ] **Step 2: Fix the link.** In `assets/README.md`, replace `[README.md](../README.md#agent-workflow)` with
  `[AGENTS.md](../AGENTS.md#workflow)`.

  Check: `grep -n 'agent-workflow' assets/README.md` prints nothing; `grep -n 'AGENTS.md#workflow' assets/README.md`
  prints one line.

- [ ] **Step 3: Lint and commit.**

```bash
cd ~/Work/dots-readme
mise x npm:markdownlint-cli@0.49.1 -- markdownlint AGENTS.md assets/README.md
g add AGENTS.md assets/README.md
HK=0 g commit -m "docs(agents): Move the SDD workflow out of the README

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Move the container `install` playbook to `DOCKER_GUIDE.md`

**Files:** Modify `assets/guides/DOCKER_GUIDE.md`

- [ ] **Step 1: Copy the section.** The README section `### Testing \`install\` in a container (\`devcontainer\`
  profile)` runs up to (not including) the `---` line before `### Terminal Helpers`. Copy it, promoted to `##`,
  right before `## See also` in `DOCKER_GUIDE.md`:

```bash
cd ~/Work/dots-readme
python3 - <<'EOF'
import pathlib
readme = pathlib.Path("README.md").read_text()
start = readme.index("### Testing `install` in a container (`devcontainer` profile)")
end = readme.index("\n---\n\n### Terminal Helpers", start)
section = readme[start + 1:end].strip() + "\n\n"   # ### -> ##
guide = pathlib.Path("assets/guides/DOCKER_GUIDE.md")
text = guide.read_text()
anchor = "## See also"
assert text.count(anchor) == 1
guide.write_text(text.replace(anchor, section + anchor))
print(section.splitlines()[0])
EOF
```

  Expected: `## Testing \`install\` in a container (\`devcontainer\` profile)`.

- [ ] **Step 2: Lint and commit.** (Do not edit the README yet; Task 6 replaces it whole.)

```bash
mise x npm:markdownlint-cli@0.49.1 -- markdownlint assets/guides/DOCKER_GUIDE.md
g add assets/guides/DOCKER_GUIDE.md
HK=0 g commit -m "docs(docker): Move the container install playbook into the Docker guide

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Move the helpers table to `config/bin/README.md`

**Files:** Modify `config/bin/README.md`

- [ ] **Step 1: Copy the table.** It is the Markdown table inside the README's `### Terminal Helpers
  (\`config/bin\`)` section. Seven of its rows name scripts that no longer exist (`xc-usage`, `xc-md`,
  `xc-skills`, `osx`, `xcz`, `yw`, `keyring`), and four current scripts are missing. The script below drops rows
  whose linked script is gone, adds the four, rewrites links relative to `config/bin/`, and inserts the result as
  a new `## TOOLS` section right before `## DEPENDENCIES`:

```bash
cd ~/Work/dots-readme
python3 - <<'EOF'
import pathlib, re
readme = pathlib.Path("README.md").read_text()
start = readme.index("### Terminal Helpers (`config/bin`)")
end = readme.index("## Benchmarks", start)
lines = [l for l in readme[start:end].splitlines() if l.startswith("|")]
def alive(row):
    targets = re.findall(r"\]\(config/bin/([^)]+)\)", row)
    return all(pathlib.Path("config/bin", t).exists() for t in targets)
rows = lines[:2] + [l for l in lines[2:] if alive(l)]
rows += [
    "| [`xcg`](config/bin/xcg) | fzf-driven git branch manager | `xcg` |",
    "| [`xc-sec`](config/bin/xc-sec) | Redact sensitive information in files (in place, with timestamped backups) | `xc-sec --help` |",
    "| [`zsys`](config/bin/zsys) | PATH, command, file, and setup diagnostic utilities | `zsys --help` |",
    "| [`yb`](config/bin/yb) | yabai wrapper | `yb --help` |",
]
lines = rows
table = "\n".join(lines).replace("](config/bin/", "](")
# [Fabric][20] is a README reference link; keep it plain here.
table = table.replace("[Fabric][20]", "Fabric")
section = "## TOOLS\n\n" + table + "\n\n"
target = pathlib.Path("config/bin/README.md")
text = target.read_text()
anchor = "## DEPENDENCIES"
assert text.count(anchor) == 1
target.write_text(text.replace(anchor, section + anchor, 1))
print(len(lines), "table lines")
EOF
```

  Expected: `17 table lines` (header, separator, 11 kept rows, 4 added). Markdown tables need no column
  alignment, so the uneven widths are fine.

- [ ] **Step 2: Lint and commit.**

```bash
mise x npm:markdownlint-cli@0.49.1 -- markdownlint config/bin/README.md
g add config/bin/README.md
HK=0 g commit -m "docs(bin): List the terminal helpers in the bin README

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

  If markdownlint reports errors that already existed in the file before your change (check with
  `g stash; markdownlint config/bin/README.md; g stash pop`), commit anyway and list them in the PR.

---

### Task 4: Add the zsh benchmark to `TESTING_GUIDE.md`

**Files:** Modify `assets/guides/TESTING_GUIDE.md`

- [ ] **Step 1: Add the section** right before the line `## Enforcement`:

```markdown
## Zsh startup

From the repository root:

| Command | Does |
| --- | --- |
| `mise run zsh:baseline` | Capture a parity baseline before changing `config/zsh` |
| `mise run zsh:verify` | Check zsh syntax and parity against that baseline |
| `mise run zsh:bench` | Benchmark zsh startup across terminal contexts |

All three run `script/zsh-verify.sh`.

```

- [ ] **Step 2: Lint and commit.**

```bash
cd ~/Work/dots-readme
mise x npm:markdownlint-cli@0.49.1 -- markdownlint assets/guides/TESTING_GUIDE.md
g add assets/guides/TESTING_GUIDE.md
HK=0 g commit -m "docs(testing): Document the zsh verify and bench tasks

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Delete the Brewfile-era guide

**Files:** Delete `assets/guides/homebrew-recipes.md`

- [ ] **Step 1: Check what links to it.**

```bash
cd ~/Work/dots-readme && git grep -n 'homebrew-recipes' -- ':!docs/superpowers'
```

  Expected: only `README.md` (replaced in Task 6). If anything else prints, remove that link line too and add
  the file to the commit below.

- [ ] **Step 2: Delete and commit.**

```bash
g rm -q assets/guides/homebrew-recipes.md
HK=0 g commit -m "docs(guides): Delete the Brewfile-era Homebrew recipes

Packages are declared in config/mise/conf.d/packages.toml; the README covers them.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Rewrite the README

**Files:** Replace `README.md`

- [ ] **Step 1: Write the file.** Replace the whole of `README.md` with exactly the text between the two
  `~~~~` fence lines below (the fences are not part of the file):

~~~~markdown
# dots

[![Preview](https://github.com/roalcantara/dots/actions/workflows/preview.yml/badge.svg)](https://github.com/roalcantara/dots/actions/workflows/preview.yml)

Sets up a machine — shell, editor, packages, secrets and agent skills — from one declarative
[mise](https://mise.jdx.dev) config, on macOS, Debian/Ubuntu and containers.

> Last reviewed: 2026-11-04

## Install

On a fresh macOS or Debian/Ubuntu machine (macOS: run `xcode-select --install` first, for `git`):

```sh
curl -fsSL https://raw.githubusercontent.com/roalcantara/dots/main/install | bash
```

[`install`](install) then:

1. installs `git` (Linux, if missing) and the pinned mise;
2. clones this repo into `~/.local/share/dots`;
3. asks for the age key (hidden input; keep it in your password manager);
4. signs `gh` in to GitHub (a browser device flow);
5. runs `mise bootstrap --adopt`, which restores the encrypted secrets from the private `dots-history` repo;
6. links `~/.config/mise` to `config/mise/` and records the profile in `config/mise/miserc.local.toml`;
7. runs `mise bootstrap -E <profile>`: packages, links, directories, login shell and the `bootstrap` task.

It creates no user and sets no timezone. A second run changes nothing.

| Variable | Default | |
| --- | --- | --- |
| `DOTS_PROFILE` | `desktop` | Which profile to apply (below) |
| `DOTS_BRANCH` | `main` | Branch to clone; to try a branch, fetch `install` from it too |
| `DOTS_REPO` | `https://github.com/roalcantara/dots.git` | Repository to clone |
| `DOTS_HISTORY` | `https://github.com/roalcantara/dots-history.git` | Encrypted history to restore |
| `DOTS_AGE_KEY` | — | The key itself, for tests; otherwise it is prompted |

| Profile | For | Skips |
| --- | --- | --- |
| `desktop` | A real machine | Nothing; moves an existing `~/.bashrc`, `~/.profile`, `~/.zshenv`, `~/.ssh`, `~/.gnupg` aside first |
| `container` | Docker images | The login shell; replaces the image's dotfiles |
| `devcontainer` | Fast container tests | The login shell, system packages (apt, Homebrew), the Neovim setup and agent skills |

Later, to apply config changes: `mise bootstrap -E <profile>`.

## How it works

`install` prepares the machine and hands over to `mise bootstrap`. mise reads `~/.config/mise`, which links to
`config/mise/` in this repo, so editing a file there and re-running `mise bootstrap` applies it.

| File | Holds |
| --- | --- |
| [`config/mise/config.toml`](config/mise/config.toml) | `[tools]` mise installs itself (`npm:`, `pipx:`, `aqua:`), settings, the encrypted history (`[dotfiles]` track entries), and the `up`, `brew:*` and `backup` tasks |
| [`config/mise/conf.d/packages.toml`](config/mise/conf.d/packages.toml) | `[bootstrap.packages]`: Homebrew formulae and casks, apt and flatpak packages, with `os` and `env` gates |
| [`config/mise/conf.d/bootstrap.toml`](config/mise/conf.d/bootstrap.toml) | Directories, system files, the login shell, and the `bootstrap` task (git filters, hooks, gopass store, oMLX models, agent skills, Neovim) |
| [`config/mise/conf.d/dotfiles.toml`](config/mise/conf.d/dotfiles.toml) | Links from `~/.config/*` into this repo |
| `config/mise/config.<profile>.toml` | Per-profile overrides ([`devcontainer`](config/mise/config.devcontainer.toml): the minimal tool set) |
| [`config/agents/`](config/agents) | The agent skills lock, `review.csv`, and agent commands |
| [`mise.toml`](mise.toml) | Repo tasks: `build`, `test`, `start`, `setup:*`, `zsh:*`, `skills:*` |

## Day to day

### Check the state

```sh
mise bootstrap status            # every part: packages, files, dotfiles, tools, login shell
mise bootstrap status --missing  # same, but exits 1 when anything differs from the config
mise bootstrap plan              # what applying would change
mise bootstrap packages status   # packages only
mise outdated                    # mise tools with a newer version
mise dot status                  # secrets history: tracked files, unsaved changes, last push
```

### Find, add and remove packages

```sh
mise run brew:search <text>          # search Homebrew formulae and casks
mise run brew:info <name> [--cask]   # show one
mise run brew:add <name> [--cask]    # declare it in conf.d/packages.toml and install it
mise run brew:rm <name> [--cask]     # remove it from conf.d/packages.toml and uninstall it
```

Or edit [`conf.d/packages.toml`](config/mise/conf.d/packages.toml) by hand, then run `mise bootstrap -E <profile>`:

```toml
[bootstrap.packages]
"brew:ripgrep" = "latest"                       # everywhere
"brew:gnu-sed" = { os = "macos" }               # macOS only
"brew:act" = { env = "desktop" }                # desktop profile only
"brew-cask:ghostty" = { os = "macos" }          # a cask
"brew:oven-sh/bun/bun" = { os = "macos" }       # from a tap declared in [bootstrap.brew.taps]
"apt:build-essential" = { os = "linux" }        # Debian/Ubuntu package
"flatpak:dev.zed.Zed" = { env = "desktop" }     # Linux desktop app (Flathub)
```

mise installs Homebrew bottles and casks itself, without `brew`. Tools mise can install directly (`npm:`,
`pipx:`, `aqua:`) go in `[tools]` of [`config.toml`](config/mise/config.toml) instead.

### Update

```sh
mise run up                  # upgrade every package, then prune undeclared ones (asks first)
mise upgrade                 # upgrade mise [tools]
mise bootstrap -E <profile>  # re-apply after editing the config
```

### Secrets

`~/.config/ssh`, `~/.config/gnupg` and `~/.config/gopass` are tracked, encrypted, in the private `dots-history`
repo. After changing one:

```sh
mise dot save   # record a checkpoint
mise dot sync   # push it
```

On another machine: `mise dot sync && mise dot pull`.

### Agent skills

Skills come from [`config/agents/skill-lock.json`](config/agents/skill-lock.json), the `skills` CLI's own lock
(both paths it reads link there), so `skills add <repo> -g` and `skills update` show up as a git diff: commit it.

```sh
mise run skills:restore   # install every locked skill that is missing (the bootstrap task runs this)
mise run skills:audit     # list skills whose source is not confirmed in config/agents/review.csv
```

## Configurations

| Area | Config |
| --- | --- |
| Zsh (shell, functions, plugins) | [`config/zsh`](config/zsh/README.md) |
| Neovim | [`config/nvim`](config/nvim/README.md) |
| Git | [`config/git`](config/git/README.md) |
| Git hooks (hk) | [`config/hk`](config/hk/README.md) |
| SSH | [`config/ssh`](config/ssh/README.md) |
| SOPS (encrypted files in this repo) | [`config/sops`](config/sops/README.md) |
| Terminal helpers (`~/.local/bin`) | [`config/bin`](config/bin/README.md) |
| Helix | [`config/helix`](config/helix/README.md) |
| bat | [`config/bat`](config/bat/README.md) |
| Starship prompt | [`config/starship`](config/starship) |
| Ghostty | [`config/ghostty`](config/ghostty) |
| Window management (macOS) | [`config/amethyst`](config/amethyst), [`config/yabai`](config/yabai), [`config/skhd`](config/skhd) |
| mise | [`config/mise`](config/mise) |
| Agent skills and commands | [`config/agents`](config/agents) |

## Playbooks

| Playbook | Where |
| --- | --- |
| Test `install` in a container (`devcontainer` profile) | [Docker guide](assets/guides/DOCKER_GUIDE.md#testing-install-in-a-container-devcontainer-profile) |
| Build, run and structure-test the Docker images | [Docker guide](assets/guides/DOCKER_GUIDE.md) |
| Run the tests (BDD and integration specs) | [Testing guide](assets/guides/TESTING_GUIDE.md#verification-gates) |
| Verify and benchmark zsh startup | [Testing guide](assets/guides/TESTING_GUIDE.md#zsh-startup) |
| Prepare a reinstall (backups, new-Mac runbook) | [mise-bootstrap design §6](assets/specs/mise-bootstrap/design.md#6-new-mac-runbook) |
| Work on this repo with an agent | [AGENTS.md](AGENTS.md) |

## Gotchas

- **`mise x` tries to install every missing global tool** and fails: prefix it with
  `MISE_AUTO_INSTALL=0 MISE_EXEC_AUTO_INSTALL=0`.
- **`mise dot sync` hangs:** GitHub HTTPS signs in through `gh`; check `gh auth status`.
- **A new shell lacks the profile's tools:** they load through `config/mise/miserc.local.toml`, which `install`
  writes; re-run `install` or create it with `env = ["<profile>"]`.
- **`brew:` packages are not on PATH in a script:** they live in the Homebrew prefix (`/opt/homebrew/bin`,
  `/home/linuxbrew/.linuxbrew/bin`), which only an interactive shell adds.
- **`skills add` and `skills update` write the committed lock** through its link: review the diff.
- **A skill deleted upstream cannot be restored:** the lock records no commit; keep a backup.
- **Encrypted files (`config/.env`) look like gibberish in git:** run `mise run setup:git:filters`.

## Repository layout

| Path | |
| --- | --- |
| [`install`](install) | The one-liner's script |
| [`config/`](config) | Everything linked into `~/.config`, plus the mise config |
| [`assets/`](assets) | Specs (`assets/specs/`), guides (`assets/guides/`), tests |
| [`distros/`](distros) | Debian and Ubuntu Dockerfiles and structure tests |
| [`script/`](script) | Repo scripts: SOPS filters, zsh checks, the skills audit and restore |
| [`mise.toml`](mise.toml), [`hk.pkl`](hk.pkl) | Repo tasks and git hooks |

## License

[MIT](LICENSE)
~~~~

- [ ] **Step 2: Lint.**

```bash
cd ~/Work/dots-readme && mise x npm:markdownlint-cli@0.49.1 -- markdownlint README.md
```

  Expected: no output. The repo config allows long lines in tables; if `MD013` (line length) fires on a table
  row, leave the row as is and add `<!-- markdownlint-disable MD013 -->` as the first line of the file.

- [ ] **Step 3: Commit.**

```bash
g add README.md
HK=0 g commit -m "docs(readme): Rewrite as an operator manual

Install, where things are declared, checking state, managing and updating
packages, secrets, agent skills, configurations, playbooks and gotchas.
Drops the Brewfile, Flox and bundle instructions.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Verify

- [ ] **Step 1: No stale terms.**

```bash
cd ~/Work/dots-readme && grep -niE 'brewfile|bundle|flox|config/homebrew|homebrew-recipes' README.md
```

  Expected: no output.

- [ ] **Step 2: Every link resolves.** Run:

```bash
cd ~/Work/dots-readme
python3 - <<'EOF'
import pathlib, re, sys
def slug(h):
    h = re.sub(r"[`*_]", "", h.strip().lower())
    h = re.sub(r"[^\w\s-]", "", h)
    return re.sub(r"\s", "-", h)
def anchors(path):
    return {slug(l.lstrip("#")) for l in path.read_text().splitlines() if l.startswith("#")}
# Broken on main before this branch; out of scope.
known = {
    "assets/guides/TESTING_GUIDE.md: missing ./FISHERY_GUIDE.md",
    "assets/guides/TESTING_GUIDE.md: missing ../../src/__tests__/index.ts",
    "config/bin/README.md: missing tests/",
    "config/bin/README.md: missing tests/xc-git.spec.ts",
}
bad = 0
def report(msg):
    global bad
    if msg not in known:
        print(msg); bad += 1
for f in ["README.md", "AGENTS.md", "assets/README.md", "assets/guides/DOCKER_GUIDE.md",
          "assets/guides/TESTING_GUIDE.md", "config/bin/README.md"]:
    src = pathlib.Path(f)
    for target in re.findall(r"\]\(([^)\s]+)\)", src.read_text()):
        if re.match(r"[a-z]+:", target): continue
        file, _, frag = target.partition("#")
        dest = (src.parent / file).resolve() if file else src.resolve()
        if not dest.exists():
            report(f"{f}: missing {target}"); continue
        if frag and dest.suffix == ".md" and frag not in anchors(dest):
            report(f"{f}: no heading for #{frag} in {file or f}")
print("broken:", bad); sys.exit(1 if bad else 0)
EOF
```

  Expected: `broken: 0`. Fix any broken link in the file it names (wrong path or heading), re-run, and commit
  the fix with `docs: Fix README links`.

- [ ] **Step 3: The read-only commands run.** These need the real checkout, so run them from `~`:

```bash
cd ~ && export MISE_AUTO_INSTALL=0 MISE_EXEC_AUTO_INSTALL=0
for c in "mise bootstrap status" "mise bootstrap plan" "mise bootstrap packages status" "mise outdated" \
         "mise dot status" "mise run brew:search ripgrep" "mise run brew:info ripgrep"; do
  timeout 120 ${=c} >/dev/null 2>&1; echo "$c -> exit $?"
done
```

  (`${=c}` is zsh word splitting; in bash use `$c`.) Expected: `exit 0` for all seven (checked on 2026-11-04).

- [ ] **Step 4: Lint everything changed.**

```bash
cd ~/Work/dots-readme
mise x npm:markdownlint-cli@0.49.1 -- markdownlint README.md AGENTS.md assets/README.md \
  assets/guides/DOCKER_GUIDE.md assets/guides/TESTING_GUIDE.md config/bin/README.md
```

  Expected: no output, except errors that existed before this branch (Task 3 Step 2).

---

### Task 8: Pull request

- [ ] **Step 1: Push and open it.**

```bash
cd ~/Work/dots-readme
g push -u origin docs/readme-rewrite
gh pr create --base main --head docs/readme-rewrite --title "docs(readme): Rewrite as an operator manual" --body "$(cat <<'EOF'
Rewrites `README.md` as a manual for managing a machine set up from this repo. Design and plan:
`assets/specs/readme-rewrite/`.

- **Install:** the one-liner, what `install` does, its variables, and the three profiles.
- **How it works:** which file under `config/mise/` declares what.
- **Day to day:** check the state, find, add and remove packages, update, secrets, agent skills.
- **Configurations, playbooks, gotchas, layout.**

Removed: the Brewfile, Flox and `mise run bundle` instructions (`config/homebrew` no longer exists), the
DISTRO/MISE tooling table, and `assets/guides/homebrew-recipes.md`.

Moved: the SDD workflow to `AGENTS.md` (link in `assets/README.md` updated), the container `install` playbook to
`DOCKER_GUIDE.md`, the helpers table to `config/bin/README.md`, the zsh benchmark to `TESTING_GUIDE.md`.

Verified: every README read-only command exits 0 on macOS; every relative link in the changed files resolves.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 2: Report** the PR link to the owner.
