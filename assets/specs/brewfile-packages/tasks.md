<!-- markdownlint-disable -->
# One Brewfile for every package, minimal containers — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task by task. Steps use checkbox (`- [ ]`) syntax for
> tracking. Tick each box in this file as you finish it.

**Goal:** Every user package comes from `config/homebrew/Brewfile`, installed by real Homebrew from
`mise bootstrap`; containers get a minimal shell set; Preview stays green and within an image-size budget.

**Architecture:** A converter generates the Brewfile from today's `conf.d/packages.toml` and `[tools]`. A
`post-packages` hook installs Homebrew and runs `brew bundle`. The `bootstrap` task branches on the profile.
Validation runs three times: a local container build, the workflow under `act`, and the real PR in GitHub Actions.

**Tech stack:** Homebrew 7 (`brew bundle`), mise bootstrap (hooks, apt packages), Docker/BuildKit, Container
Structure Test, GitHub Actions, `act` 0.2.96, Python 3 (converter), Bun (repo tests).

**Design:** [design.md](./design.md). Read §3–§6 first.

## Design corrections found while planning (apply them; they override design.md)

1. **`uv` entries cannot pin Python.** `brew bundle`'s `uv` entry accepts only `with:` and `source:`, and sets
   `UV_PYTHON` to the newest Homebrew Python itself (`Library/Homebrew/bundle/extensions/uv.rb`), so the design's
   `UV_PYTHON` fallback does not work either. `graphifyy` and `code-review-graph` are installed by the desktop
   branch of the `bootstrap` task with `uv tool install --python 3.13` instead.
2. **`uv` is not in `packages.toml`** (it came from mise `[tools]`); the Brewfile adds it. **`starship` is no
   longer used** (the prompt is powerlevel10k, a zim module): it is not in the Brewfile, and Task 6a removes its
   config and references.
3. **`brew bundle list` already parses the Brewfile**, so the CI job needs no separate `ruby -c`.
4. **Homebrew strips the environment:** a Brewfile sees only `HOMEBREW_*` variables, so `DOTS_PROFILE` arrives as
   `nil` and containers would get every package. The profile variable is **`HOMEBREW_DOTS_PROFILE`** everywhere
   (Brewfile, hook, CI, docs; checked on Homebrew 7.0). A top-level `return unless desktop` does work.
5. **`brew "devcontainer"` is a formula** (the Dev Containers CLI), not the removed profile: keep it.

---

## Ground rules for the executor

- Work only in the worktree `~/Work/dots-brewfile`, branch `feat/brewfile-packages`. Never touch `~/Work/dots`.
- SOPS files are checked out encrypted here, so use this wrapper for every git command:

  ```bash
  g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }
  ```

- Commit with `HK=0 g commit …`; end every message with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Add files by path; never `g add -A`.
- `export MISE_AUTO_INSTALL=0 MISE_EXEC_AUTO_INSTALL=0` in every shell.
- Lint before each commit: TOML with `mise x taplo@0.10.0 -- taplo fmt --check <files>` (fix with
  `taplo fmt <files>`), Markdown with `mise x npm:markdownlint-cli@0.49.1 -- markdownlint <files>`, shell with
  `bash -n`.
- Docker must be running (`docker info` succeeds). Builds are slow: run them in the background and wait.
- **STOP** means: report to the owner and wait.

## File map

| File | Action | Task |
| --- | --- | --- |
| `script/brewfile-from-mise.py` | Create (one-off converter, deleted in Task 3) | 2 |
| `config/homebrew/Brewfile` | Create (generated) | 2 |
| `config/mise/conf.d/system.toml` | Create (apt only) | 3 |
| `config/mise/conf.d/packages.toml` | Delete | 3 |
| `config/mise/conf.d/bootstrap.toml` | Hook, task branches, XDG gates | 4 |
| `config/mise/config.toml` | Drop `[tools]`, `[settings.pypi]`, `up`/`brew:*` tasks | 5 |
| `config/mise/mise.lock` | Drop the removed tools | 5 |
| `config/mise/config.devcontainer.toml` | Delete | 5 |
| `install` | Drop the `devcontainer` case | 5 |
| `config/zsh/opt/rc.d/env.zsh`, `config/bash/bashrc` | `HOMEBREW_BUNDLE_FILE`; `brew shellenv` only | 5 |
| `distros/{debian,ubuntu}/container-structure-test.yml` | Minimal CST | 6, 6a |
| `config/starship/`, its link in `conf.d/dotfiles.toml` | Delete | 6a |
| `.github/workflows/preview.yml` | `brewfile` job, disk, timeout, size, `act` guards | 9 |
| `README.md`, `assets/guides/DOCKER_GUIDE.md`, `assets/specs/mise-bootstrap/design.md`, `AGENTS.md`, `.agents/skills/dots-context/SKILL.md` | Docs | 11 |

---

### Task 1: Containers' hard dependencies

- [x] **Step 1: Find tools zsh and git need at startup.**

```bash
cd ~/Work/dots-brewfile
grep -rnE '^\s*(eval "\$\(|source <\(|alias [a-z]+=)' config/zsh --include='*.zsh' | grep -oE '\b(zoxide|fzf|eza|bat|rg|fd|jq|nvim|delta|mise|direnv|atuin|thefuck|gh|sops|age|gopass|uv|bun|node)\b' | sort | uniq -c
grep -nE 'pager|delta|diff-so-fancy' config/git/config | head
```

- [x] **Step 2: Decide each tool.** For each tool printed that is **not** in the always-installed group
  (`zoxide fzf eza bat ripgrep fd jq neovim git-delta`): if its line runs unguarded at startup, wrap it in
  `if (( $+commands[<tool>] )); then … fi` (zsh) in the file grep named. Do not add tools to the group without
  asking: **STOP** if one seems required. Record what you changed in the PR description later.

- [x] **Step 3: Commit** any guards: `HK=0 g commit -m "fix(zsh): Guard optional tools at startup"` (skip if
  nothing changed).

---

### Task 2: Generate the Brewfile

**Files:** Create `script/brewfile-from-mise.py`, `config/homebrew/Brewfile`

- [x] **Step 1: Write the converter** `script/brewfile-from-mise.py`:

```python
#!/usr/bin/env python3
"""One-off: config/mise/conf.d/packages.toml + [tools] -> config/homebrew/Brewfile (keeps comments)."""
import re, sys, pathlib

CORE = ["zoxide", "fzf", "eza", "bat", "ripgrep", "fd", "jq", "neovim", "git-delta"]
UV_TOOLS = ["pynvim", "debugpy", "commit-check"]  # graphifyy, code-review-graph: bootstrap task (Python 3.13)

src = pathlib.Path("config/mise/conf.d/packages.toml").read_text().splitlines()
taps, formulae, casks, flatpaks = [], [], [], []
section = None
entry = re.compile(r'^"(brew|brew-cask|flatpak|apt):([^"]+)"\s*=\s*(\{[^}]*\}|"[^"]*")\s*(#.*)?$')
for line in src:
    if line.startswith("[bootstrap.brew.taps]"): section = "taps"; continue
    if line.startswith("[bootstrap.packages]"): section = "packages"; continue
    if section == "taps":
        m = re.match(r'^"([^"]+)"\s*=\s*"([^"]+)"', line)
        if m: taps.append(f'tap "{m[1]}", "{m[2]}"')
        continue
    if section != "packages": continue
    m = entry.match(line)
    if not m:
        if line.startswith("#") and formulae is not None: formulae.append(("#", line))
        continue
    mgr, name, value, comment = m[1], m[2], m[3], (m[4] or "").strip()
    if mgr == "apt": continue                       # goes to conf.d/system.toml (Task 3)
    os_ = re.search(r'os\s*=\s*"(\w+)"', value)
    gate = {"macos": " if OS.mac?", "linux": " if OS.linux?"}.get(os_[1], "") if os_ else ""
    pad = f"  {comment}" if comment else ""
    if mgr == "brew":
        if name in CORE: continue
        formulae.append((name, f'brew "{name}"{gate}{pad}'))
    elif mgr == "brew-cask":
        casks.append(f'cask "{name}"{gate or " if OS.mac?"}{pad}')
    elif mgr == "flatpak":
        flatpaks.append(f'flatpak "{name}"{gate or " if OS.linux?"}{pad}')

out = [
    "# Every user package (assets/specs/brewfile-packages/design.md). Installed by the post-packages hook in",
    "# config/mise/conf.d/bootstrap.toml; `brew bundle …` reads it through HOMEBREW_BUNDLE_FILE.",
    "# HOMEBREW_DOTS_PROFILE selects the groups (brew passes only HOMEBREW_* variables to a Brewfile):",
    "# container gets the first group only; desktop (the default) gets everything.",
    'desktop = ENV.fetch("HOMEBREW_DOTS_PROFILE", "desktop") == "desktop"',
    "",
    *taps,
    "",
    "# Everywhere, containers included: the minimal shell set",
    *[f'brew "{n}"' for n in CORE],
    "",
    "# Desktop only below. `brew bundle add` appends here, so new packages are desktop-only unless moved up.",
    "return unless desktop",
    "",
    "# Desktop: formulae",
    'brew "uv"                                  # Python tool installer (the uv entries below)',
    *[l for _, l in formulae],
    "",
    "# Desktop: Python tools (graphifyy and code-review-graph need Python 3.13: the bootstrap task installs them)",
    *[f'uv "{t}"' for t in UV_TOOLS],
    "",
    "# Desktop: casks (macOS)",
    *casks,
    "",
    "# Desktop: Flatpak apps (Linux; Flathub is configured by conf.d/bootstrap.toml)",
    *flatpaks,
    "",
]
missing = [n for n in CORE if not any(f'"brew:{n}"' in l for l in src)] 
print("core not in packages.toml (added anyway):", missing, file=sys.stderr)
dest = pathlib.Path("config/homebrew/Brewfile"); dest.parent.mkdir(parents=True, exist_ok=True)
dest.write_text("\n".join(out))
print(f"taps {len(taps)} core {len(CORE)} formulae {sum(1 for n,_ in formulae if n!='#')} casks {len(casks)} flatpaks {len(flatpaks)}")
```

- [x] **Step 2: Run it.**

```bash
cd ~/Work/dots-brewfile && python3 script/brewfile-from-mise.py
```

  Expected: `core not in packages.toml (added anyway): []` and a count line with `taps 3`, `casks 34`,
  `flatpaks 10`, and formulae = 83 minus the 9 core ones (= 74).

- [x] **Step 3: Check both groups parse and list.**

```bash
export HOMEBREW_NO_AUTO_UPDATE=1
HOMEBREW_DOTS_PROFILE=container brew bundle list --all --file config/homebrew/Brewfile | sort > "$TMPDIR/bf-container"
HOMEBREW_DOTS_PROFILE=desktop   brew bundle list --all --file config/homebrew/Brewfile | sort > "$TMPDIR/bf-desktop"
wc -l "$TMPDIR/bf-container" "$TMPDIR/bf-desktop"; cat "$TMPDIR/bf-container"
```

  Expected: no error; the container list is exactly the 3 taps plus the 9 core formulae (12 lines; if it is
  longer, the profile variable is not reaching the Brewfile); the desktop list is much
  longer and includes `ghostty`, `pynvim`, `uv`. Neither contains `starship`. On a parse error, fix the converter (not the Brewfile) and re-run.

- [x] **Step 4: Compare with this Mac.** Expect almost everything already installed:

```bash
HOMEBREW_DOTS_PROFILE=desktop brew bundle check --verbose --file config/homebrew/Brewfile 2>&1 | tail -20
```

  Note what it reports missing. On 2026-11-04 (dry run) it was 12: five self-updating casks, two `uv` tools, and five
  tap or out-of-date formulae; real Homebrew already sees mise's bottles in `/opt/homebrew/Cellar`. **STOP** if it reports more than 20 formulae or casks missing that
  `mise bootstrap packages status` (run from `~`) reports as installed: real Homebrew does not adopt mise's
  bottles, and the owner must decide on the migration.

- [x] **Step 5: Commit** the Brewfile and the converter (the converter is removed in Task 3 once
  `packages.toml` is gone):

```bash
g add script/brewfile-from-mise.py config/homebrew/Brewfile
HK=0 g commit -m "feat(packages): Generate one Brewfile from the mise package lists

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: apt prerequisites in `system.toml`; delete `packages.toml`

- [x] **Step 1: Create `config/mise/conf.d/system.toml`:**

```toml
# Linux system packages: only what Homebrew needs to install itself, plus desktop services. Every other
# package is in config/homebrew/Brewfile (assets/specs/brewfile-packages/design.md).
[bootstrap.packages]
"apt:build-essential" = { os = "linux" }
"apt:procps" = { os = "linux" }
"apt:curl" = { os = "linux" }
"apt:file" = { os = "linux" }
"apt:git" = { os = "linux" }
"apt:ca-certificates" = { os = "linux" }
"apt:zsh" = { os = "linux" }
"apt:flatpak" = { os = "linux", env = "desktop" }
"apt:docker.io" = { os = "linux", env = "desktop" }
```

- [x] **Step 2: Delete the old list and the converter; fix the stale comment.**

```bash
g rm -q config/mise/conf.d/packages.toml script/brewfile-from-mise.py
sed -i '' 's/for the system-wide flatpak apps in packages.toml/for the system-wide flatpak apps in config\/homebrew\/Brewfile/' config/mise/conf.d/bootstrap.toml
grep -n 'packages.toml' config/mise/conf.d/bootstrap.toml
```

  Expected: the `grep` prints nothing.

- [x] **Step 3: Lint and commit.**

```bash
mise x taplo@0.10.0 -- taplo fmt --check config/mise/conf.d/system.toml config/mise/conf.d/bootstrap.toml
g add config/mise/conf.d/system.toml config/mise/conf.d/bootstrap.toml
HK=0 g commit -m "refactor(packages): Keep only Homebrew's apt prerequisites in mise

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Install Homebrew, run the Brewfile, branch the bootstrap task

**Files:** Modify `config/mise/conf.d/bootstrap.toml`

- [x] **Step 1: Add the hook** at the end of `bootstrap.toml`:

```toml

# Homebrew and every user package (assets/specs/brewfile-packages/design.md §4.3). Runs after the apt
# prerequisites; a failure stops the bootstrap.
[bootstrap.hooks.post-packages]
run = '''
#!/usr/bin/env bash
set -euo pipefail
brew=""
for b in "$(command -v brew || true)" /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  [ -n "$b" ] && [ -x "$b" ] && { brew="$b"; break; }
done
if [ -z "$brew" ]; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  for b in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do [ -x "$b" ] && brew="$b"; done
fi
eval "$("$brew" shellenv)"
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_ENV_HINTS=1
HOMEBREW_DOTS_PROFILE="${MISE_ENV:-desktop}" brew bundle install --no-upgrade \
  --file "$HOME/.local/share/dots/config/homebrew/Brewfile"
'''
```

- [x] **Step 2: Branch the `bootstrap` task.** In its `run`, make these three edits:

  a. Replace the line
  `for d in /opt/homebrew/bin /home/linuxbrew/.linuxbrew/bin; do [ -d "$d" ] && PATH="$d:$PATH"; done` with:

```bash
for b in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do [ -x "$b" ] && eval "$("$b" shellenv)"; done
desktop=true
case ",${MISE_ENV:-desktop}," in *,desktop,*) ;; *) desktop=false ;; esac
```

  b. Replace `mise run -C "$dots" setup:hooks || warn "setup:hooks"` with:

```bash
# Containers: git filters only (cheap); everything below is desktop-only.
$desktop || exit 0
mise run -C "$dots" setup:hooks || warn "setup:hooks"

# Python tools that need 3.13 (no wheels for the newest Python); the Brewfile's uv entries cannot pin it.
for tool in graphifyy code-review-graph; do
  uv tool list 2>/dev/null | grep -q "^$tool " || uv tool install --python 3.13 "$tool" || warn "uv $tool"
done
```

  c. Delete the two lines

```bash
# devcontainer: minimal, so no agent skills, Neovim providers or plugins.
case ",${MISE_ENV:-}," in *,devcontainer,*) exit 0 ;; esac
```

- [x] **Step 3: Gate the XDG user folders.** In `bootstrap.toml`, for each of `~/Desktop`, `~/Documents`,
  `~/Downloads`, `~/Movies`, `~/Music`, `~/Pictures`, add `env = "desktop"` under its
  `[bootstrap.directories."…"]` header (next to `mode = "0700"`).

- [x] **Step 4: Check.**

```bash
python3 -c "import tomllib;tomllib.load(open('config/mise/conf.d/bootstrap.toml','rb'))" && echo toml-ok
python3 - <<'EOF'
import tomllib, subprocess
c = tomllib.load(open("config/mise/conf.d/bootstrap.toml", "rb"))
for name, script in [("hook", c["bootstrap"]["hooks"]["post-packages"]["run"]), ("task", c["tasks"]["bootstrap"]["run"])]:
    r = subprocess.run(["bash", "-n"], input=script, text=True, capture_output=True)
    print(name, "syntax", "ok" if r.returncode == 0 else r.stderr)
EOF
grep -c 'env = "desktop"' config/mise/conf.d/bootstrap.toml
```

  Expected: `toml-ok`, `hook syntax ok`, `task syntax ok`, and a count of at least 6.

- [x] **Step 5: Lint and commit.**
```bash
mise x taplo@0.10.0 -- taplo fmt --check config/mise/conf.d/bootstrap.toml
g add config/mise/conf.d/bootstrap.toml
HK=0 g commit -m "feat(bootstrap): Install Homebrew and the Brewfile; desktop-only setup steps

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Remove the old package paths and the `devcontainer` profile

- [x] **Step 1: `config/mise/config.toml`.** Delete, exactly:
  - the `[settings.pypi]` table (`[settings.pypi]` and `uvx = true`);
  - the whole `[tools]` table: its comment lines and the `"uv"` and five `"pipx:…"` lines;
  - the tasks `[tasks.up]`, `[tasks."brew:search"]`, `[tasks."brew:info"]`, `[tasks."brew:add"]`,
    `[tasks."brew:rm"]`, each from its header to the line before the next `[tasks…]` header, plus the comment line
    `# Homebrew without brew: …` above `brew:search`.

  Check: `grep -nE 'pipx|pypi|tasks.up|brew:(search|info|add|rm)|^\[tools\]' config/mise/config.toml` prints nothing,
  and `python3 -c "import tomllib;tomllib.load(open('config/mise/config.toml','rb'))"` succeeds.

- [x] **Step 2: `config/mise/mise.lock`.** Remove the removed tools' entries:

```bash
python3 - <<'EOF'
import pathlib, re
p = pathlib.Path("config/mise/mise.lock"); s = p.read_text()
blocks = re.split(r"(?m)^(?=\[\[tools\.)", s)
keep = [b for b in blocks if not re.match(r'\[\[tools\."?(pipx:|uv"?\]\])', b)]
p.write_text("".join(keep)); print(len(blocks) - len(keep), "blocks removed")
EOF
grep -cE 'pipx:|tools\.uv' config/mise/mise.lock
```

  Expected: some blocks removed and a final count of `0`.

- [x] **Step 3: The profile.**

```bash
g rm -q config/mise/config.devcontainer.toml
python3 - <<'EOF'
import pathlib
p = pathlib.Path("install"); s = p.read_text()
old = '''  # Minimal: no system packages (apt, Homebrew); config.devcontainer.toml installs the few tools it needs.
  devcontainer) BOOTSTRAP_ARGS+=("--force-dotfiles" "--skip" "user,packages") ;;
'''
assert s.count(old) == 1; s = s.replace(old, "")
s = s.replace("DOTS_PROFILE (desktop | container | devcontainer)", "DOTS_PROFILE (desktop | container)")
p.write_text(s)
EOF
bash -n install && grep -c devcontainer install
```

  Expected: `0`.

- [x] **Step 4: Shell PATH.** Homebrew is now real, so `brew shellenv` alone sets PATH.
  - `config/bash/bashrc`: replace the block starting `# Load Homebrew if it exists and hasn't been loaded yet`
    (the `if … elif … fi` that adds `$HOMEBREW_PREFIX/bin` "without brew") with:

```bash
# Homebrew (installed by mise bootstrap)
if ! command -v brew >/dev/null && [ -x "$HOMEBREW_PREFIX/bin/brew" ]; then
  eval "$("$HOMEBREW_PREFIX"/bin/brew shellenv)"
fi
export HOMEBREW_BUNDLE_FILE="$HOME/.local/share/dots/config/homebrew/Brewfile"
```

  - `config/zsh/opt/rc.d/env.zsh`: after the line `export HOMEBREW_NO_ANALYTICS=1 …` add:

```zsh
    export HOMEBREW_BUNDLE_FILE=$HOME/.local/share/dots/config/homebrew/Brewfile  # brew bundle from anywhere
```

  Check: `bash -n config/bash/bashrc && zsh -n config/zsh/opt/rc.d/env.zsh && echo ok`.

- [x] **Step 5: Commit.**

```bash
mise x taplo@0.10.0 -- taplo fmt --check config/mise/config.toml
g add config/mise/config.toml config/mise/mise.lock install config/bash/bashrc config/zsh/opt/rc.d/env.zsh
HK=0 g commit -m "refactor(mise): Drop mise-managed packages, the brew tasks and the devcontainer profile

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Minimal CST

**Files:** `distros/debian/container-structure-test.yml`, `distros/ubuntu/container-structure-test.yml` (same
edits in both)

- [x] **Step 1: Replace the tools test.** Find the `commandTests` entry named
  `core tools should be installed by mise bootstrap` and replace the whole entry with:

```yaml
  - name: Homebrew should be installed
    command: /home/linuxbrew/.linuxbrew/bin/brew
    args: [--version]
    expectedOutput: ['Homebrew \d']
  - name: the container group of the Brewfile should be on PATH in a login shell
    command: zsh
    args: [-lic, "for t in zoxide fzf eza bat rg fd jq nvim delta; do command -v $t >/dev/null || { echo missing $t; exit 1; }; done; echo ok"]
    expectedOutput: [ok]
  - name: a login shell should start without errors
    command: zsh
    args: [-lic, exit]
    exitCode: 0
    excludedError: ['.+']
  - name: desktop-only parts should be absent
    command: bash
    args: [-c, "for p in ~/.agents/skills ~/.local/share/gopass/password-store ~/.local/share/nvim/lazy; do [ ! -e $p ] || { echo present $p; exit 1; }; done; echo ok"]
    expectedOutput: [ok]
```

- [x] **Step 2: Remove** the `commandTests` entry named
  `Neovim's Python provider (pynvim-python) should import pynvim`, and the six `fileExistenceTests` entries named
  `~/Desktop dir (XDG_DESKTOP_DIR)`, `~/Documents dir (XDG_DOCUMENTS_DIR)`, `~/Downloads dir (XDG_DOWNLOAD_DIR)`,
  `~/Movies dir (XDG_VIDEOS_DIR)`, `~/Music dir (XDG_MUSIC_DIR)` and `~/Pictures dir (XDG_PICTURES_DIR)`, each
  with all its lines.

- [x] **Step 3: Check and commit.**

```bash
for d in debian ubuntu; do python3 -c "import yaml,sys;yaml.safe_load(open('distros/$d/container-structure-test.yml'))" 2>/dev/null \
  || ruby -ryaml -e "YAML.load_file('distros/$d/container-structure-test.yml')"; echo "$d yaml ok"; done
grep -cE 'pynvim|XDG_(DESKTOP|DOCUMENTS|DOWNLOAD|VIDEOS|MUSIC|PICTURES)' distros/*/container-structure-test.yml
g add distros/debian/container-structure-test.yml distros/ubuntu/container-structure-test.yml
HK=0 g commit -m "test(distros): Check the minimal container instead of the desktop set

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

  Expected: both `yaml ok`, and both counts `0`.

---

### Task 6a: Remove `starship`

The prompt is powerlevel10k (`config/zsh/.zimrc`), so `starship` is unused.

- [x] **Step 1: Delete its config and link.**

```bash
cd ~/Work/dots-brewfile
g rm -rq config/starship
grep -v '^"~/.config/starship" = ' config/mise/conf.d/dotfiles.toml > "$TMPDIR/dotfiles.toml" && mv "$TMPDIR/dotfiles.toml" config/mise/conf.d/dotfiles.toml
grep -c starship config/mise/conf.d/dotfiles.toml
```

  Expected: `0`.

- [x] **Step 2: CST.** In both `distros/{debian,ubuntu}/container-structure-test.yml`, delete the
  `globalEnvVars` entries `STARSHIP_CONFIG_HOME` and `STARSHIP_CONFIG` (key and value lines), and the two
  `fileExistenceTests` entries `~/.config/starship dir (STARSHIP_CONFIG_HOME)` and
  `~/.config/starship/starship.toml (STARSHIP_CONFIG)` with all their lines.

- [x] **Step 3: Comments and docs.**
  - `config/zsh/opt/rc.d/zim.zsh`: in the two comments, replace `zim-starship` with `the prompt module`.
  - `README.md`: delete the `Starship prompt` row of the Configurations table.
  - `assets/guides/DOCKER_GUIDE.md`: in the `globalEnvVars` line, replace `npm/starship config` with `npm config`.

- [x] **Step 4: Check and commit.**

```bash
git -c filter.sops.smudge=cat grep -n -i starship -- . ':!CHANGELOG.md' ':!assets/specs' ':!docs' ':!graphify-out' \
  ':!config/kodexb' ':!config/snippets' ':!config/vscode'
zsh -n config/zsh/opt/rc.d/zim.zsh && echo zsh-ok
g add config/mise/conf.d/dotfiles.toml distros/debian/container-structure-test.yml distros/ubuntu/container-structure-test.yml \
  config/zsh/opt/rc.d/zim.zsh README.md assets/guides/DOCKER_GUIDE.md
HK=0 g commit -m "chore: Remove starship, unused since the prompt moved to powerlevel10k

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

  Expected: the `grep` prints nothing (bookmarks, snippets and the VS Code theme list are reference data, not
  usage), then `zsh-ok`.

---

### Task 7: Validate locally in a container

The `local` Docker target copies the **committed** tree (`git archive HEAD`), so everything must be committed.

- [x] **Step 1: Build Ubuntu** (native arm64; 10–20 minutes the first time):

```bash
cd ~/Work/dots-brewfile
time mise run build --local --distro ubuntu --tag brewfile > "$TMPDIR/build-ubuntu.log" 2>&1; echo "exit=$?"
tail -5 "$TMPDIR/build-ubuntu.log"
grep -nE 'bootstrap: .*failed|Error|error:' "$TMPDIR/build-ubuntu.log" | head -20
```

  Expected: `exit=0`. In the log: Homebrew installs, `brew bundle` installs 9 formulae plus their dependencies,
  and no `skills add`, `gopass`, `Lazy`, `npm install -g neovim` lines. A `bootstrap: … failed, continuing` line
  for `setup:git:filters` is acceptable only if it says why (report it).

  If the build fails, read the first error, fix it in the right task's file, commit, and rebuild. Common causes:
  - `brew: command not found` in the hook → the `shellenv` block in Task 4 Step 1;
  - Homebrew asks for `sudo` → the base image's `vscode` user has passwordless sudo; check `sudo -n true` inside
    `docker run --rm -it mcr.microsoft.com/devcontainers/base:ubuntu`;
  - a formula fails to build from source → it has no bottle for arm64 Linux; **STOP** and report which.

- [x] **Step 2: Size.**

```bash
docker image inspect dots:ubuntu-brewfile --format '{{.Size}}' | awk '{printf "%.2f GB\n", $1/1e9}'
docker history --human dots:ubuntu-brewfile | head -8
```

  Record the size. Expected under 2.0 GB. **STOP** if over 2.0 GB, with the `docker history` output.

- [x] **Step 3: CST.**

```bash
mise run test --image dots:ubuntu-brewfile --config distros/ubuntu/container-structure-test.yml 2>&1 | tail -15
```

  Expected: `PASS` for every test, `Failures: 0`. A failing `a login shell should start without errors` prints
  the stderr: fix the tool guard (Task 1) and rebuild.

- [x] **Step 4: Debian.** Repeat Steps 1–3 with `--distro debian`, image `dots:debian-brewfile`, config
  `distros/debian/container-structure-test.yml`.

- [x] **Step 5: Interactive smoke check** (optional, 1 minute):

```bash
docker run --rm -it dots:ubuntu-brewfile -c 'zoxide --version; nvim --version | head -1; brew bundle check --file ~/.local/share/dots/config/homebrew/Brewfile; echo profile=$(cat ~/.config/mise/miserc.local.toml 2>/dev/null)'
```

  Expected: versions print and `The Brewfile's dependencies are satisfied.` (with `HOMEBREW_DOTS_PROFILE` unset the check
  uses the desktop group, so it may list missing desktop packages: that is expected; re-run with
  `HOMEBREW_DOTS_PROFILE=container brew bundle check …` and expect satisfied).

---

### Task 8: Migrate this Mac (STOP gate)

- [x] **Step 1: Dry run.**

```bash
cd ~ && export HOMEBREW_NO_AUTO_UPDATE=1
HOMEBREW_DOTS_PROFILE=desktop brew bundle check --verbose --file ~/Work/dots-brewfile/config/homebrew/Brewfile 2>&1 | tail -30
```

- [x] **Step 2: STOP.** Report the missing list to the owner. Do **not** run `brew bundle install` or
  `mise bootstrap` on this Mac; the owner runs the migration after merging.

---

### Task 9: CI workflow

**Files:** Modify `.github/workflows/preview.yml`

- [x] **Step 1: Platforms from a variable** (so `act` can build arm64 locally). Change the workflow-level
  `PLATFORMS: linux/amd64` to:

```yaml
  PLATFORMS: ${{ vars.PLATFORMS || 'linux/amd64' }}
```

- [x] **Step 2: Add the `brewfile` job** under `jobs:`, before `lint:`:

```yaml
  brewfile:
    name: Brewfile parses (desktop and container)
    runs-on: ubuntu-24.04
    if: github.event.pull_request.draft == false
    timeout-minutes: 10
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - name: Set up Homebrew
        run: |
          brew=/home/linuxbrew/.linuxbrew/bin/brew
          [ -x "$brew" ] || NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
          echo "/home/linuxbrew/.linuxbrew/bin" >> "$GITHUB_PATH"
      - name: List both groups
        env:
          HOMEBREW_NO_AUTO_UPDATE: 1
        run: |
          for p in container desktop; do
            echo "::group::$p"
            HOMEBREW_DOTS_PROFILE=$p brew bundle list --all --file config/homebrew/Brewfile
            echo "::endgroup::"
          done
```

- [x] **Step 3: `validate` changes.**
  - Add `timeout-minutes: 30` under `runs-on:` of `validate`.
  - Add `needs: [lint, brewfile]` (replacing `needs: lint`).
  - As the **first** step of `validate`, before `Setup outputs`:

```yaml
      - name: Free disk space
        if: env.ACT != 'true'
        run: |
          sudo rm -rf /usr/share/dotnet /opt/ghc /usr/local/lib/android /usr/local/share/boost "$AGENT_TOOLSDIRECTORY"
          df -h /
```

  - Add `if: env.ACT != 'true'` to the `Login to Docker Hub` step.
  - In `Build and export to Docker`, replace the `cache-from:` and `cache-to:` blocks with (no cache under `act`):

```yaml
          cache-from: ${{ env.ACT != 'true' && format('type=gha,scope=build-{0}-amd64
            type=registry,ref=docker.io/{1}-cache:{0}', matrix.distro, env.REGISTRY_IMAGE) || '' }}
          cache-to: ${{ env.ACT != 'true' && format('type=gha,scope=build-{0}-amd64,mode=max
            type=registry,ref=docker.io/{1}-cache:{0},mode=max', matrix.distro, env.REGISTRY_IMAGE) || '' }}
```

  - Right after `Build and export to Docker`, add:

```yaml
      - name: Check the image size
        env:
          IMAGE: ${{ steps.setup.outputs.IMAGE_NAME }}-amd64
          BUDGET_BYTES: ${{ vars.IMAGE_BUDGET_BYTES || '2000000000' }}
        run: |
          size=$(docker image inspect "$IMAGE" --format '{{.Size}}')
          echo "image size: $((size / 1000000)) MB (budget $((BUDGET_BYTES / 1000000)) MB)" | tee -a "$GITHUB_STEP_SUMMARY"
          [ "$size" -le "$BUDGET_BYTES" ] || { echo "::error::image is over budget"; exit 1; }
```

- [x] **Step 4: Lint the workflow.**

```bash
cd ~/Work/dots-brewfile
mise x aqua:rhysd/actionlint@latest -- actionlint .github/workflows/preview.yml
```

  Expected: no output. Fix what it reports.

- [x] **Step 5: Check `publish.yml`.** `grep -nE 'devcontainer|packages\.toml|-E ' .github/workflows/publish.yml`;
  change any reference to the removed profile or file. Expected: nothing to change.

- [x] **Step 6: Commit.**

```bash
g add .github/workflows/preview.yml .github/workflows/publish.yml
HK=0 g commit -m "ci(preview): Parse the Brewfile, free disk, cap time and image size

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10: Validate the workflow locally with `act`

`act` runs the jobs in Docker on this Mac. `ACT=true` is set automatically, which skips the disk cleanup, the
Docker Hub login and the remote caches (Task 9). The `remote` build target clones the PR branch from GitHub, so
**push the branch first** (no PR yet).

- [ ] **Step 1: Push and write a pull_request event.**

```bash
cd ~/Work/dots-brewfile
g push -u origin feat/brewfile-packages
cat > "$TMPDIR/pr-event.json" <<'EOF'
{ "pull_request": { "number": 0, "draft": false, "head": { "ref": "feat/brewfile-packages" }, "base": { "ref": "main" } } }
EOF
```

- [ ] **Step 2: The `brewfile` job.**

```bash
act pull_request -e "$TMPDIR/pr-event.json" -j brewfile \
  -P ubuntu-24.04=catthehacker/ubuntu:act-24.04 --container-architecture linux/arm64 2>&1 | tail -20
```

  Expected: `Job succeeded`, with both groups listed. (The act image has no Homebrew, so the job's setup step
  installs it: a few minutes.)

- [ ] **Step 3: The `validate` job for Ubuntu, arm64.**

```bash
act pull_request -e "$TMPDIR/pr-event.json" -j validate --matrix distro:ubuntu \
  -P ubuntu-latest=catthehacker/ubuntu:act-latest --container-architecture linux/arm64 \
  --var PLATFORMS=linux/arm64 -s GH_TOKEN="$(gh auth token)" \
  > "$TMPDIR/act-validate.log" 2>&1; echo "exit=$?"
grep -nE 'image size|Job succeeded|Job failed|::error' "$TMPDIR/act-validate.log" | tail -10
```

  Expected: `exit=0`, an `image size:` line under budget, and `Job succeeded`. The tag names `-amd64` even on
  arm64; that is only a name. If `act` fails on an action it cannot emulate (for example the JUnit report upload),
  note it, check that the steps before it succeeded, and continue: Task 12 covers the real run.

---

### Task 11: Docs

- [ ] **Step 1: README.md.** Make these edits:
  - **Install → profiles table:** delete the `devcontainer` row; in the text above it, drop
    `config/mise/miserc.local.toml` if it now reads oddly (keep the step).
  - **How it works → table:** replace the `conf.d/packages.toml` row with two rows:

    ```markdown
    | [`config/homebrew/Brewfile`](config/homebrew/Brewfile) | Every user package: formulae, casks, taps, `uv` tools, Flatpak apps. `HOMEBREW_DOTS_PROFILE=container` gets only the first group |
    | [`config/mise/conf.d/system.toml`](config/mise/conf.d/system.toml) | apt packages Homebrew needs on Linux |
    ```

    In the `config.toml` row, remove "`[tools]` mise installs itself (…)" and the `up`, `brew:*` task names. Delete
    the `config.<profile>.toml` row.
  - **Day to day → Check the state:** replace `mise bootstrap packages status   # packages only` with
    `brew bundle check --verbose        # packages: what the Brewfile wants but is missing`.
  - **Day to day → Find, add and remove packages:** replace the whole subsection body with:

    ````markdown
    ```sh
    brew search <text>                   # find a formula or cask
    brew info <name>                     # show one
    brew bundle add <name> [--cask]      # declare it in the Brewfile (then: brew bundle install)
    brew bundle remove <name> [--cask]   # remove it from the Brewfile (then: brew bundle cleanup --force)
    brew bundle install                  # install everything the Brewfile declares that is missing
    ```

    `brew bundle add` appends to the end of the file, below `return unless desktop`, so a new package is
    desktop-only; move its line up only if containers need it. Or edit
    [`config/homebrew/Brewfile`](config/homebrew/Brewfile) by hand:

    ```ruby
    brew "ripgrep"                       # above `return unless desktop`: containers too
    brew "gnu-sed" if OS.mac?            # macOS only
    cask "ghostty" if OS.mac?            # an app
    tap "oven-sh/bun", "https://github.com/oven-sh/homebrew-bun.git"
    uv "pynvim"                          # a Python tool
    flatpak "dev.zed.Zed" if OS.linux?   # a Linux app (Flathub)
    ```
    ````

  - **Day to day → Update:** replace the block with:

    ```sh
    brew update && brew upgrade  # upgrade every package
    brew bundle cleanup          # list installed packages the Brewfile does not declare (--force removes them)
    mise upgrade                 # upgrade mise itself and repo task tools
    mise bootstrap -E <profile>  # re-apply after editing the config
    ```

  - **Gotchas:** delete the `brew:` "not on PATH in a script" line; add
    `- **\`brew bundle cleanup\` only lists** what it would remove; add \`--force\` to remove it.`
  - **Playbooks:** rename the first row to `Test \`install\` in a container` and keep its link (its anchor changes
    in Step 2; update the link to `#testing-install-in-a-container`).

- [ ] **Step 2: `assets/guides/DOCKER_GUIDE.md`.**
  - Rename `## Testing \`install\` in a container (\`devcontainer\` profile)` to `## Testing \`install\` in a container`.
  - In that section: replace `DOTS_PROFILE=devcontainer` with `DOTS_PROFILE=container`; replace the intro
    sentence about the `devcontainer` profile with: "The `container` profile installs Homebrew and the Brewfile's
    first group only (the minimal shell set), and skips agent skills, the gopass store, oMLX models and the Neovim
    plugins."; delete the paragraph that starts "The `devcontainer` profile skips agent skills" (agent skills are
    desktop-only now).
  - Add a short section before `## See also`:

    ```markdown
    ## Image size budget

    Preview fails a PR whose image is larger than `IMAGE_BUDGET_BYTES` (a repository variable; default 2 GB).
    The container profile installs only the Brewfile's first group; anything added there grows every image.
    ```

- [ ] **Step 3: `assets/specs/mise-bootstrap/design.md`.** Under its `## 4. Components` heading's package
  subsection (the first one that mentions `packages.toml`), add the line:
  `> Superseded (2026-11-04): packages now come from \`config/homebrew/Brewfile\`; see
  [brewfile-packages](../brewfile-packages/design.md).`

- [ ] **Step 4: `AGENTS.md`, `.agents/skills/dots-context/SKILL.md`.**
  `grep -nE 'packages\.toml|devcontainer profile|config\.devcontainer|mise run brew|mise run up' AGENTS.md .agents/skills/dots-context/SKILL.md`
  and update each hit to the Brewfile equivalent.

- [ ] **Step 5: Stale-term sweep, links, lint, commit.**

```bash
cd ~/Work/dots-brewfile
grep -rnE 'packages\.toml|config\.devcontainer|DOTS_PROFILE=devcontainer|mise run (up|brew:)' README.md AGENTS.md assets/guides .agents/skills/dots-context
mise x npm:markdownlint-cli@0.49.1 -- markdownlint README.md assets/guides/DOCKER_GUIDE.md AGENTS.md
g add README.md assets/guides/DOCKER_GUIDE.md assets/specs/mise-bootstrap/design.md AGENTS.md .agents/skills/dots-context/SKILL.md
HK=0 g commit -m "docs: Describe the Brewfile flow and the minimal container profile

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

  Expected: the `grep` prints nothing (spec files under `assets/specs/` are history and are not swept).

---

### Task 12: Open the PR and watch Preview

- [ ] **Step 1: Push and open.**

```bash
cd ~/Work/dots-brewfile && g push
gh pr create --base main --head feat/brewfile-packages --title "feat(packages): One Brewfile for every package; minimal containers" --body "$(cat <<'EOF'
Packages move to one `config/homebrew/Brewfile`, installed by real Homebrew from a `post-packages` hook in
`mise bootstrap`. Design and plan: `assets/specs/brewfile-packages/`.

- **Containers** get Homebrew plus the Brewfile's first group (zoxide, fzf, eza, bat, ripgrep, fd, jq, neovim,
  git-delta).
- **`starship` removed:** unused (the prompt is powerlevel10k); its config, link and CST checks are gone. Agent skills, the gopass store, oMLX models and Neovim plugins are desktop-only.
- **Removed:** `conf.d/packages.toml` (apt prerequisites move to `conf.d/system.toml`), mise `[tools]`, the
  `up`/`brew:*` tasks, and the `devcontainer` profile.
- **Preview:** a Brewfile parse job, free disk space, a 30-minute cap, and an image-size budget
  (`IMAGE_BUDGET_BYTES`, default 2 GB).

Verified locally: <Task 7 sizes and CST results for ubuntu and debian>; `act`: <Task 10 results>.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

  Replace both `<…>` placeholders with the real results before running the command.

- [ ] **Step 2: Watch the run** (it starts within a minute of opening the PR):

```bash
sleep 60; run=$(gh run list --branch feat/brewfile-packages --workflow Preview --limit 1 --json databaseId -q '.[0].databaseId')
gh run watch "$run" --exit-status; echo "exit=$?"
```

- [ ] **Step 3: Check the budget and timings.**

```bash
gh run view "$run" --json jobs -q '.jobs[] | "\(.name): \(.conclusion) in \(((.completedAt|fromdate)-(.startedAt|fromdate))/60|floor) min"'
gh run view "$run" --log | grep -E 'image size:' 
```

  Expected: every job `success`; `validate` jobs under 30 minutes; both `image size:` lines under budget.

- [ ] **Step 4: If it fails**, read `gh run view "$run" --log-failed | tail -60`, fix the cause in the matching
  task's file, commit, push, and repeat Steps 2–3. After three failed attempts, **STOP** and report.

- [ ] **Step 5: Set the budget** from the real sizes: the larger image size plus 20%, rounded up to 100 MB. Ask the
  owner to set it (`gh variable set IMAGE_BUDGET_BYTES --body <bytes>`): it is a repository setting, so do not set
  it yourself.

- [ ] **Step 6: Report** to the owner: the PR link, both image sizes, job times, the Task 8 missing list, and any
  zsh guards added in Task 1.
