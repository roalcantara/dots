<!-- markdownlint-disable -->
# Setting up machines with `mise bootstrap` — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for
> tracking.

**Goal:** Rewrite `install` as a short, idempotent entry point that prepares a machine, opens an encrypted
secrets archive and runs `mise bootstrap`, which applies one declarative config (packages, links, directories,
login shell, setup task) on macOS, Debian/Ubuntu and the `distros/` images.

**Architecture:** `install` (Bash, macOS bash 3.2 compatible) does only what mise cannot: create the user,
sudo, timezone, `/etc/zsh/zshenv`, flatpak, open the secrets archive, switch from root to the user, install a
pinned mise, place the repo and secrets. `script/prepare-secrets` (`mise run prepare`) builds that archive.
Everything else lives in `config/mise/conf.d/{bootstrap,packages,dotfiles}.toml`, which the existing
`~/.config/mise` link makes live on this Mac, so every config task is checked read-only here first.

**Tech Stack:** Bash, OpenSSL (`enc -aes-256-cbc -pbkdf2`), zip/unzip, mise 2026.10.21 (`mise bootstrap`,
native Homebrew), Bun (integration specs), Docker, container-structure-test, Parallels (Ubuntu and macOS VMs).

**Spec:** [design.md](./design.md). **Report:** [report.md](./report.md).

**Success criteria (design.md §1):** the Debian image and an Ubuntu VM run `install` with the fixture archive
successfully, and a second run changes nothing; then the macOS guest; then the real Mac.

---

## Before you start

- Work on a branch: `git -C ~/Work/dots switch -c feat/mise-bootstrap`.
- Commits are signed with `~/.ssh/id_ed25519_github`; load it first (`ssh-add ~/.ssh/id_ed25519_github`) or
  `git commit` fails with "incorrect passphrase".
- Stage your own paths only (`git add <paths>`); other agents may have work in progress.
- Never run `mise bootstrap` (without `status`, `plan` or `--dry-run`) or `install` (without `--dry-run`) on
  this Mac before Task 11: it is the machine being backed up.
- `install` and `prepare-secrets` must run under macOS's `/bin/bash` 3.2: no `mapfile`, no `${var,,}`, and
  empty arrays expanded as `"${a[@]+"${a[@]}"}"` because `set -u` rejects them otherwise.
- Never commit a secrets archive, real or fixture (`*.zip.enc` is git-ignored from Task 4).

## File map

| Path | Task | Responsibility |
| --- | --- | --- |
| `config/mise/conf.d/dotfiles.toml` | 1 | Every link except `~/.local/share/dots` and `~/.config/mise` |
| `config/mise/conf.d/bootstrap.toml` | 2 | Directories, login shell, `bootstrap` task |
| `config/mise/conf.d/packages.toml` | 3 | Taps and packages for macOS and Linux |
| `config/mise/config.toml` | 3 | `[tools]` gains the Brewfile's `go` and `uv` entries |
| `script/prepare-secrets`, `mise.toml` (`[tasks.prepare]`), `.gitignore` | 4 | The encrypted secrets archive |
| `assets/integration/install/prepare-secrets.spec.ts` | 4 | Archive layout, modes, encryption |
| `install` | 5 | Entry point (rewritten) |
| `assets/integration/install/install.spec.ts` | 5 | `install` behaviour, through `--dry-run` and the fixture archive |
| `distros/{debian,ubuntu}/Dockerfile`, `container-structure-test.yml` | 6 | Images built by `install`, no secrets |
| `mise.toml` (`[tasks."build"]`) | 6 | Committed tree as context; drop `--package-manager` and `--group` |
| `README.md`, `assets/guides/DOCKER_GUIDE.md`, `AGENTS.md`, `.agents/skills/dots-context/SKILL.md` | 9 | New flow |
| `config/flox`, `config/bin/purge_flox`, `config/homebrew`, `config/apt`, `config/flatpak`, `config/snap` | 11 | Deleted after the real Mac |

---

### Task 1: Links (`conf.d/dotfiles.toml`) and the conf.d spike

This task also settles three behaviours the mise docs leave open: whether `[dotfiles]` in a `conf.d` file is
loaded, whether `~` expands in `source`, and whether `relative = true` reproduces this Mac's links.

**Files:**
- Create: `config/mise/conf.d/dotfiles.toml`

- [x] **Step 1: Record this Mac's current links (the expected result)**

Run:
```bash
find ~/.config ~ ~/.local/bin -maxdepth 1 -type l -exec sh -c 'printf "%s -> %s\n" "$1" "$(readlink "$1")"' _ {} \; | sort > /tmp/links-before.txt
wc -l /tmp/links-before.txt
```
Expected: about 64 lines (35 in `~/.config`, 5 in `~`, 24 in `~/.local/bin`).

- [x] **Step 2: Write the config**

```toml
# Links into this repo (assets/specs/mise-bootstrap/design.md §4.2). `install` links ~/.local/share/dots and
# ~/.config/mise itself, because mise needs them before it can read this file.
[dotfiles]
# The list is static: compare it with git ls-files config | cut -d/ -f2 | sort -u when config/ changes.
# One link per top-level entry of config/ (mode symlink: the whole folder or file). symlink-each would link
# every file recursively. Not linked: mise (install), hk (setup:hooks), non-config files, the package lists,
# delta (its only file, .env, is git-ignored), and folders that are real on the Mac (app settings and keys
# restored from backup).
"~/.config/.env" = { source = "~/.local/share/dots/config/.env", relative = true }
"~/.config/.markdownlint.yml" = { source = "~/.local/share/dots/config/.markdownlint.yml", relative = true }
"~/.config/.profile" = { source = "~/.local/share/dots/config/.profile", relative = true }
"~/.config/age" = { source = "~/.local/share/dots/config/age", relative = true }
"~/.config/amethyst" = { source = "~/.local/share/dots/config/amethyst", relative = true }
"~/.config/atlassian" = { source = "~/.local/share/dots/config/atlassian", relative = true }
"~/.config/bash" = { source = "~/.local/share/dots/config/bash", relative = true }
"~/.config/bat" = { source = "~/.local/share/dots/config/bat", relative = true }
"~/.config/bin" = { source = "~/.local/share/dots/config/bin", relative = true }
"~/.config/claude" = { source = "~/.local/share/dots/config/claude", relative = true }
"~/.config/cog" = { source = "~/.local/share/dots/config/cog", relative = true }
"~/.config/cursor" = { source = "~/.local/share/dots/config/cursor", relative = true }
"~/.config/dinky" = { source = "~/.local/share/dots/config/dinky", relative = true }
"~/.config/fabric" = { source = "~/.local/share/dots/config/fabric", relative = true }
"~/.config/ghostty" = { source = "~/.local/share/dots/config/ghostty", relative = true }
"~/.config/git" = { source = "~/.local/share/dots/config/git", relative = true }
"~/.config/github" = { source = "~/.local/share/dots/config/github", relative = true }
"~/.config/glide" = { source = "~/.local/share/dots/config/glide", relative = true }
"~/.config/helix" = { source = "~/.local/share/dots/config/helix", relative = true }
"~/.config/homebrew" = { source = "~/.local/share/dots/config/homebrew", relative = true }
"~/.config/kodexb" = { source = "~/.local/share/dots/config/kodexb", relative = true }
"~/.config/kb" = { source = "~/.local/share/dots/config/kodexb", relative = true } # alias
"~/.config/npm" = { source = "~/.local/share/dots/config/npm", relative = true }
"~/.config/nvim" = { source = "~/.local/share/dots/config/nvim", relative = true }
"~/.config/ranma" = { source = "~/.local/share/dots/config/ranma", relative = true }
"~/.config/rift" = { source = "~/.local/share/dots/config/rift", relative = true }
"~/.config/ripgrep" = { source = "~/.local/share/dots/config/ripgrep", relative = true }
"~/.config/skhd" = { source = "~/.local/share/dots/config/skhd", relative = true }
"~/.config/snippets" = { source = "~/.local/share/dots/config/snippets", relative = true }
"~/.config/sops" = { source = "~/.local/share/dots/config/sops", relative = true }
"~/.config/starship" = { source = "~/.local/share/dots/config/starship", relative = true }
"~/.config/television" = { source = "~/.local/share/dots/config/television", relative = true }
"~/.config/tombi" = { source = "~/.local/share/dots/config/tombi", relative = true }
"~/.config/vscode" = { source = "~/.local/share/dots/config/vscode", relative = true }
"~/.config/yabai" = { source = "~/.local/share/dots/config/yabai", relative = true }
"~/.config/zsh" = { source = "~/.local/share/dots/config/zsh", relative = true }
"~/.config/zsh-patina" = { source = "~/.local/share/dots/config/zsh-patina", relative = true }
"~/.zshenv" = { source = "~/.config/zsh/.zshenv", relative = true }
"~/.bashrc" = { source = "~/.config/bash/bashrc", relative = true }
"~/.profile" = { source = "~/.config/.profile", relative = true }
# ~/.config/ssh and ~/.config/gnupg are real folders: created by bootstrap.toml, filled by install --secrets.
"~/.ssh" = { source = "~/.config/ssh", relative = true }
"~/.gnupg" = { source = "~/.config/gnupg", relative = true }
# Links each executable file of config/bin; this Mac's links are absolute, so relative is left off.
# Keep the exclude list in step when adding non-executables to config/bin.
"~/.local/bin" = { source = "~/.local/share/dots/config/bin", mode = "symlink-each", exclude = [
  ".editorconfig",
  ".vscode",
  "HANDOFF-USAGE-MIGRATION.md",
  "LICENSE",
  "README.md",
  "mise.lock",
  "mise.toml",
  "src",
] }
```

- [x] **Step 3: Check it read-only**

Run:
```bash
cd ~ && mise dot status 2>&1 | tee /tmp/dot-status.txt | head -80
```
Expected, all three must hold:
1. The entries are listed at all (so `[dotfiles]` in `conf.d` loads).
2. No error about a missing source (so `~` expands in `source`).
3. Existing links (`~/.config/zsh`, `~/.zshenv`, `~/.local/bin/gitx`, …) show as unchanged; only the entries
   this Mac does not link yet (`npm`, `claude`, `delta`, `dinky`, `github`, `tombi`, …) show as missing.

- [x] **Step 4: If check 2 fails, use a template instead of `~`**

```bash
sed -i '' -e 's|source = "~/|source = "{{env.HOME}}/|g' ~/Work/dots/config/mise/conf.d/dotfiles.toml
```
Rerun Step 3.

- [x] **Step 5: If check 3 shows existing links as changed**

Read the reported target in `/tmp/dot-status.txt`. If it differs only in form (for example
`../Work/dots/config/zsh` instead of `../.local/share/dots/config/zsh`, because mise resolved the
`~/.local/share/dots` link) and still reaches the same file, accept it and write one line under "Findings". Any
other difference (a wrong file, an absolute path despite `relative = true`) stops the task: report it.

- [x] **Step 6: Confirm nothing changed on disk**

Run:
```bash
find ~/.config ~ ~/.local/bin -maxdepth 1 -type l -exec sh -c 'printf "%s -> %s\n" "$1" "$(readlink "$1")"' _ {} \; | sort | diff /tmp/links-before.txt -
```
Expected: no output.

- [x] **Step 7: Commit**

```bash
cd ~/Work/dots && git add config/mise/conf.d/dotfiles.toml assets/specs/mise-bootstrap/tasks.md
git commit -m "feat(mise): Declare dotfile links for mise bootstrap"
```

---

### Task 2: Directories, login shell and setup task (`conf.d/bootstrap.toml`)

**Files:**
- Create: `config/mise/conf.d/bootstrap.toml`

- [x] **Step 1: Write the config**

```toml
# Machine setup applied by `mise bootstrap` (assets/specs/mise-bootstrap/design.md §4.2–4.3).

# Folders the shell config and tools expect, plus the XDG user folders the images' structure tests check.
[bootstrap.directories."~/.local/bin"]
[bootstrap.directories."~/.local/state/zim"]
[bootstrap.directories."~/.local/share/zsh"]
[bootstrap.directories."~/.local/share/npm"]
[bootstrap.directories."~/.local/share/gems"]
[bootstrap.directories."~/.cache/zsh"]
mode = "0700"
[bootstrap.directories."~/.cache/npm"]
[bootstrap.directories."~/.cache/mise"]
# Private (0700), as macOS creates them; bootstrap would otherwise reset them to 0755.
[bootstrap.directories."~/Desktop"]
mode = "0700"
[bootstrap.directories."~/Documents"]
mode = "0700"
[bootstrap.directories."~/Downloads"]
mode = "0700"
[bootstrap.directories."~/Movies"]
mode = "0700"
[bootstrap.directories."~/Music"]
mode = "0700"
[bootstrap.directories."~/Pictures"]
mode = "0700"
[bootstrap.directories."~/Projects"]
[bootstrap.directories."~/Work"]

# Real folders the ~/.ssh and ~/.gnupg links point to; install --secrets fills them.
[bootstrap.directories."~/.config/ssh"]
mode = "0700"

[bootstrap.directories."~/.config/gnupg"]
mode = "0700"

[bootstrap.user]
login_shell = "zsh"

# Runs last on every `mise bootstrap`, so every step checks before acting and only warns on failure.
[tasks.bootstrap]
description = "Repo git filters and hooks, Neovim providers and plugins"
run = '''
#!/usr/bin/env bash
dots="$HOME/.local/share/dots"
nvim_cfg="$HOME/.config/nvim"
warn() { printf 'bootstrap: %s failed, continuing\n' "$1" >&2; }

mise run -C "$dots" setup:git:filters || warn "setup:git:filters"
mise run -C "$dots" setup:hooks || warn "setup:hooks"

[ -d "$nvim_cfg" ] || exit 0
if command -v npm >/dev/null && ! npm ls -g neovim >/dev/null 2>&1; then
  npm install -g neovim || warn "npm neovim"
fi
if command -v python3 >/dev/null && ! "$nvim_cfg/.venv/bin/python" -c 'import pynvim' 2>/dev/null; then
  { { [ -x "$nvim_cfg/.venv/bin/python" ] || python3 -m venv "$nvim_cfg/.venv"; } &&
    "$nvim_cfg/.venv/bin/pip" install -q pynvim; } || warn "pynvim venv"
fi
if command -v gem >/dev/null && ! gem list -i neovim >/dev/null 2>&1; then
  gem install neovim || warn "gem neovim"
fi
# restore (not sync) installs the lockfile's versions, so a rerun changes nothing; bounded so a network stall
# cannot hang an unattended run.
if command -v nvim >/dev/null; then
  limit=""
  if command -v timeout >/dev/null; then limit="timeout 600"; elif command -v gtimeout >/dev/null; then limit="gtimeout 600"; fi
  $limit nvim --headless "+Lazy! restore" +qa </dev/null || warn "nvim Lazy restore"
fi
'''
```

- [x] **Step 2: Check it read-only**

Run:
```bash
cd ~ && mise bootstrap status 2>&1 | tee /tmp/bootstrap-status.txt | grep -iE 'director|user|login|task' | head -30
```
Expected: the 18 directories show as present or create (`~/Projects`); the login shell shows the resolved Homebrew/apt zsh (it differs on this Mac, whose shell is /usr/local/bin/zsh); no parse error.
If an unknown key is reported, fix its name from `mise bootstrap files --help` / `mise bootstrap user --help`
and rerun.

- [x] **Step 3: Commit**

```bash
cd ~/Work/dots && git add config/mise/conf.d/bootstrap.toml
git commit -m "feat(mise): Add bootstrap directories, login shell and setup task"
```

---

### Task 3: Packages (`conf.d/packages.toml`) and Go/uv tools

**Files:**
- Create: `config/mise/conf.d/packages.toml`
- Modify: `config/mise/config.toml` (the `[tools]` table, line 104)

- [x] **Step 1: Write the one-off converter (not committed)**

Create `/tmp/brewfile-to-mise.ts`:
```ts
// Converts config/homebrew/Brewfile into [bootstrap.brew.taps] and [bootstrap.packages] entries.
// Formulae without a Linux bottle in Homebrew's API get os = "macos"; casks are macOS-only except fonts.
const brewfile = await Bun.file(`${process.env.HOME}/Work/dots/config/homebrew/Brewfile`).text();

async function hasLinuxBottle(name: string): Promise<boolean> {
  if (name.includes("/")) return false; // tap formulae: no core API entry
  const r = await fetch(`https://formulae.brew.sh/api/formula/${name}.json`);
  if (!r.ok) return false;
  const files = Object.keys((await r.json())?.bottle?.stable?.files ?? {});
  return files.some((k) => k.endsWith("_linux"));
}

const taps: string[] = [];
const packages: string[] = [];
const skipped = new Set(["mise"]); // install provides the pinned mise
for (const line of brewfile.split("\n")) {
  const m = line.match(/^(#\s*)?(tap|brew|cask)\s+"([^"]+)"[^#]*(#.*)?$/);
  if (!m) {
    if (/^# [A-Z]/.test(line)) packages.push("", line); // section headings
    continue;
  }
  const [, off, kind, name, comment = ""] = m;
  if (kind === "tap") {
    const [owner, repo] = name.split("/");
    if (!off) taps.push(`"${name}" = "https://github.com/${owner}/homebrew-${repo}.git"`);
    continue;
  }
  if (skipped.has(name)) continue;
  const key = kind === "brew" ? `brew:${name}` : `brew-cask:${name}`;
  let value = '"latest"';
  if (kind === "cask") value = name.startsWith("font-") ? '{ os = ["linux", "macos"] }' : '{ os = "macos" }';
  else if (!off && !(await hasLinuxBottle(name))) value = '{ os = "macos" }';
  packages.push(`${off ? "# " : ""}"${key}" = ${value}${comment ? ` ${comment}` : ""}`);
}

console.log(`# Packages applied by \`mise bootstrap\` (assets/specs/mise-bootstrap/design.md §4.1).
# Converted from the Brewfile; edit here from now on. mise installs Homebrew bottles and casks itself.

[bootstrap.brew.taps]
${taps.join("\n")}

[bootstrap.packages]${packages.join("\n")}

# LINUX
"apt:zsh" = { os = "linux" }
"apt:git" = { os = "linux" }
"apt:ca-certificates" = { os = "linux" }
"apt:gnupg" = { os = "linux" }
"apt:unzip" = { os = "linux" }
"apt:wget" = { os = "linux" }
"apt:fontconfig" = { os = "linux" }
"apt:docker.io" = { os = "linux", env = "desktop" }
"brew:ollama" = { os = "linux", env = "desktop" }

# LINUX DESKTOP APPS (install -E desktop adds flatpak and the Flathub remote)
"flatpak-user:com.visualstudio.code" = "latest"
"flatpak-user:dev.zed.Zed" = "latest"
"flatpak-user:com.getpostman.Postman" = "latest"
"flatpak-user:io.github.shiftey.Desktop" = "latest"
"flatpak-user:org.chromium.Chromium" = "latest"
"flatpak-user:com.brave.Browser" = "latest"
"flatpak-user:com.discordapp.Discord" = "latest"
"flatpak-user:io.github.mimbrero.WhatsAppDesktop" = "latest"
"flatpak-user:com.bitwarden.desktop" = "latest"
"flatpak-user:org.videolan.VLC" = "latest"`);
```

- [x] **Step 2: Generate the file**

Run:
```bash
bun /tmp/brewfile-to-mise.ts > ~/Work/dots/config/mise/conf.d/packages.toml
grep -c '^"brew:' ~/Work/dots/config/mise/conf.d/packages.toml
grep -c '^"brew-cask:' ~/Work/dots/config/mise/conf.d/packages.toml
grep -c 'os = "macos"' ~/Work/dots/config/mise/conf.d/packages.toml
```
Expected: 84 `brew:` lines (83 converted from the Brewfile, which skips `mise`, plus the Linux `brew:ollama`),
38 `brew-cask:` lines, and the macOS-only count printed (record it under "Findings").

- [x] **Step 3: Compare with what is installed on this Mac**

Run:
```bash
cd /tmp && mise bootstrap packages import -n -p /tmp/never.toml 2>&1 | grep -o '"brew:[^"]*"' | sort -u > /tmp/installed.txt
grep -o '^"brew:[^"]*"' ~/Work/dots/config/mise/conf.d/packages.toml | sort -u > /tmp/declared.txt
comm -23 /tmp/installed.txt /tmp/declared.txt
```
Expected: the formulae installed here but not in the Brewfile. Show the list to the owner; add the ones they
want to keep as `"brew:<name>" = "latest"` in the `# CORE FORMULAE` section.

- [x] **Step 4: Flag formulae that ran as services**

Run:
```bash
brew services list 2>/dev/null | awk 'NR>1 && $2!="none" {print $1, $2}'
```
Expected: the formulae Homebrew runs as services. For each one also declared in `packages.toml`, write one line
under "Findings" (name and how it starts today); Task 10 checks each on the macOS guest.

- [x] **Step 5: Add the Go and uv tools**

In `config/mise/config.toml`, inside `[tools]`, after `go = "latest"`, add:
```toml
# From the Brewfile's `go` and `uv` lines (cmd/go and cmd/gofmt come with Go itself).
"go:mvdan.cc/gofumpt" = "latest"
"go:golang.org/x/tools/gopls" = "latest"
"go:github.com/brutski/go-code-graph/cmd/import-neo4j" = "latest"
"go:github.com/brutski/go-code-graph/cmd/mcp-server" = "latest"
"go:github.com/brutski/go-code-graph/cmd/analyze" = "latest"
"go:github.com/brutski/go-code-graph/cmd/server" = "latest"
"pipx:debugpy" = "latest"
"pipx:graphifyy" = "latest"
"pipx:code-review-graph" = "latest"
```
(`go-code-graph-wrapper` is not a module path and is not in `~/go/bin`, so it is dropped.)

- [x] **Step 6: Check it read-only**

Run:
```bash
cd ~ && mise bootstrap packages status 2>&1 | tee /tmp/packages-status.txt | tail -25
cd ~ && mise ls --missing 2>&1 | head -20
```
Expected: the file parses; Linux entries show as skipped; formulae and casks show as installed or missing.
Record the missing ones under "Findings". `mise ls --missing` lists the new Go and pipx tools; do not install
them here.

- [x] **Step 7: Commit**

```bash
cd ~/Work/dots && git add config/mise/conf.d/packages.toml config/mise/config.toml assets/specs/mise-bootstrap/tasks.md
git commit -m "feat(mise): Declare packages and Go/uv tools for mise bootstrap"
```

---

### Task 4: The secrets archive (`prepare`), test first

**Files:**
- Create: `assets/integration/install/prepare-secrets.spec.ts`
- Create: `script/prepare-secrets`
- Modify: `mise.toml` (add `[tasks.prepare]`), `.gitignore` (add `*.zip.enc`)

- [x] **Step 1: Write the failing spec**

```ts
#!/usr/bin/env bun
// prepare-secrets: the archive install --secrets opens. Uses --fixture or a fake HOME; never real keys.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, rmSync, statSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";

const repo = resolve(import.meta.dir, "../../..");
const script = join(repo, "script/prepare-secrets");

let dir: string;
beforeEach(() => {
  dir = mkdtempSync(join(tmpdir(), "prepare-secrets-"));
});
afterEach(() => rmSync(dir, { recursive: true, force: true }));

function sh(cmd: string[], env: Record<string, string> = {}) {
  const r = Bun.spawnSync(cmd, { env: { PATH: process.env.PATH ?? "", HOME: dir, ...env }, stdout: "pipe", stderr: "pipe" });
  return { code: r.exitCode, out: r.stdout.toString(), err: r.stderr.toString() };
}

function open(archive: string, pass: string, out = join(dir, "opened.zip")) {
  return sh(["openssl", "enc", "-d", "-aes-256-cbc", "-pbkdf2", "-iter", "600000", "-md", "sha256",
    "-in", archive, "-out", out, "-pass", `pass:${pass}`]);
}

function put(path: string, body = "x\n") {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, body);
}

describe("prepare-secrets", () => {
  it("rejects unknown options", () => {
    const r = sh(["/bin/bash", script, "--bogus"]);
    expect(r.code).toBe(2);
    expect(r.err).toContain("unknown option '--bogus'");
  });

  it("writes an encrypted, owner-only fixture archive with the install layout", () => {
    const archive = join(dir, "fixture.zip.enc");
    const made = sh(["/bin/bash", script, "--fixture", "--output", archive]);
    expect(made.code).toBe(0);
    expect(made.out.trim()).toBe(archive);
    expect(statSync(archive).mode & 0o777).toBe(0o600);

    const zip = join(dir, "fixture.zip");
    expect(open(archive, "dots-fixture", zip).code).toBe(0);
    const listing = sh(["unzip", "-l", zip]).out;
    for (const path of ["age/keys.txt", "ssh/id_ed25519", "ssh/id_ed25519.pub", "gnupg/README", "gh/hosts.yml"]) {
      expect(listing).toContain(path);
    }
    expect(listing).not.toContain("github_token");
  });

  it("cannot be opened with another passphrase", () => {
    const archive = join(dir, "fixture.zip.enc");
    sh(["/bin/bash", script, "--fixture", "--output", archive]);
    const opened = open(archive, "wrong", join(dir, "x.zip"));
    const listed = sh(["unzip", "-l", join(dir, "x.zip")]);
    expect(opened.code !== 0 || listed.code !== 0).toBe(true);
  });

  it("forces mode 600 when the output already exists with mode 644", () => {
    const archive = join(dir, "fixture.zip.enc");
    writeFileSync(archive, "old");
    chmodSync(archive, 0o644);
    expect(sh(["/bin/bash", script, "--fixture", "--output", archive]).code).toBe(0);
    expect(statSync(archive).mode & 0o777).toBe(0o600);
  });

  it("leaves no output file when a stage fails", () => {
    const bin = join(dir, "bin");
    mkdirSync(bin);
    writeFileSync(join(bin, "zip"), "#!/bin/sh\nexit 1\n");
    chmodSync(join(bin, "zip"), 0o755);
    const archive = join(dir, "fixture.zip.enc");
    const r = sh(["/bin/bash", script, "--fixture", "--output", archive], { PATH: `${bin}:${process.env.PATH}` });
    expect(r.code).not.toBe(0);
    expect(existsSync(archive)).toBe(false);
  });

  it("fixture ignores an ambient DOTS_SECRETS_PASSPHRASE", () => {
    const archive = join(dir, "fixture.zip.enc");
    const made = sh(["/bin/bash", script, "--fixture", "--output", archive], { DOTS_SECRETS_PASSPHRASE: "other" });
    expect(made.code).toBe(0);
    expect(open(archive, "dots-fixture").code).toBe(0);
  });

  it("packs a fake home, skipping runtime files and the missing token", () => {
    const home = join(dir, "home");
    const cfg = join(home, ".config");
    put(join(home, ".local/share/dots/config/age/keys.txt"));
    put(join(cfg, "ssh/keys/id_test.key"));
    symlinkSync("keys/id_test.key", join(cfg, "ssh/id_test"));
    for (const f of ["ssh/S.agent", "gnupg/.#lk0x1", "gnupg/random_seed", "gnupg/pubring.kbx~", "gnupg/pubring.kbx", "gh/hosts.yml"]) {
      put(join(cfg, f));
    }
    const bin = join(dir, "bin");
    mkdirSync(bin);
    writeFileSync(join(bin, "gh"), "#!/bin/sh\nexit 1\n");
    chmodSync(join(bin, "gh"), 0o755);
    const archive = join(dir, "real.zip.enc");
    const r = sh(["/bin/bash", script, "--output", archive],
      { HOME: home, XDG_CONFIG_HOME: cfg, DOTS_SECRETS_PASSPHRASE: "t", PATH: `${bin}:${process.env.PATH}` });
    expect(r.err).toBe("");
    expect(r.code).toBe(0);
    expect(open(archive, "t").code).toBe(0);
    const listing = sh(["unzip", "-l", join(dir, "opened.zip")]).out;
    for (const path of ["age/keys.txt", "ssh/id_test", "ssh/keys/id_test.key", "gnupg/pubring.kbx", "gh/hosts.yml"]) {
      expect(listing).toContain(path);
    }
    for (const path of ["S.agent", ".#lk0x1", "random_seed", "pubring.kbx~", "github_token"]) {
      expect(listing).not.toContain(path);
    }
  });

  it("rejects a link pointing outside the archive", () => {
    const home = join(dir, "home");
    const cfg = join(home, ".config");
    mkdirSync(join(cfg, "ssh"), { recursive: true });
    symlinkSync("/etc/hosts", join(cfg, "ssh/id_bad"));
    const archive = join(dir, "bad.zip.enc");
    const r = sh(["/bin/bash", script, "--output", archive],
      { HOME: home, XDG_CONFIG_HOME: cfg, DOTS_SECRETS_PASSPHRASE: "t" });
    expect(r.code).toBe(1);
    expect(r.err).toContain("is a link to");
    expect(existsSync(archive)).toBe(false);
  });
});
```

- [x] **Step 2: Run it to see it fail**

Run: `cd ~/Work/dots/assets && bun test integration/install/prepare-secrets.spec.ts`
Expected: FAIL; `script/prepare-secrets` does not exist.

- [x] **Step 3: Write `script/prepare-secrets`**

```bash
#!/usr/bin/env bash
# Packs the files `install --secrets` expects into an AES-256 encrypted zip.
# USAGE: prepare-secrets [--fixture] [--output <file>]
#   --fixture  throwaway keys and the passphrase "dots-fixture", for tests; never commit the result
# The passphrase is prompted by default; DOTS_SECRETS_PASSPHRASE is for tests and CI (inline values end up in
# shell history).
# Design: assets/specs/mise-bootstrap/design.md (§4.6). Must run under macOS bash 3.2.
set -euo pipefail

OUTPUT="$HOME/dots-secrets.zip.enc"
FIXTURE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --fixture) FIXTURE=1; shift ;;
    --output) OUTPUT="${2:?--output needs a file}"; shift 2 ;;
    -h | --help) sed -n '2,6s/^# \{0,1\}//p' "$0"; exit 0 ;;
    *) printf "prepare-secrets: unknown option '%s'\n" "$1" >&2; exit 2 ;;
  esac
done

stage="$(mktemp -d)"
work="$(mktemp -d)"
trap 'rm -rf "$stage" "$work"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
chmod 700 "$stage" "$work"

if [ "$FIXTURE" = 1 ]; then
  mkdir -p "$stage/age" "$stage/ssh" "$stage/gnupg" "$stage/gh"
  printf '# throwaway fixture key, not a real one\nAGE-SECRET-KEY-1DOTSFIXTURE\n' >"$stage/age/keys.txt"
  ssh-keygen -q -t ed25519 -N '' -C dots-fixture -f "$stage/ssh/id_ed25519"
  printf 'throwaway fixture\n' >"$stage/gnupg/README"
  printf 'github.com:\n  user: dots-fixture\n' >"$stage/gh/hosts.yml"
  DOTS_SECRETS_PASSPHRASE=dots-fixture
  export DOTS_SECRETS_PASSPHRASE
else
  cfg="${XDG_CONFIG_HOME:-$HOME/.config}"
  key="$HOME/.local/share/dots/config/age/keys.txt"
  if [ -f "$key" ]; then
    mkdir -p "$stage/age"
    cp "$key" "$stage/age/keys.txt"
  fi
  for dir in ssh gnupg; do
    if [ -d "$cfg/$dir" ]; then tar -C "$cfg" --exclude 'S.*' --exclude 's.*' --exclude '.#lk*' --exclude random_seed --exclude '*~' -cf - "$dir" | tar -C "$stage" -xf -; fi
  done
  if [ -f "$cfg/gh/hosts.yml" ]; then
    mkdir -p "$stage/gh"
    cp "$cfg/gh/hosts.yml" "$stage/gh/hosts.yml"
  fi
  if ! { command -v gh >/dev/null && gh auth token >"$stage/github_token" 2>/dev/null; }; then
    rm -f "$stage/github_token"
  fi
fi

# A link must stay inside the archive: a missing or outside target would pack the wrong file or nothing.
stage_real="$(cd "$stage" && pwd -P)"
while IFS= read -r link; do
  rel="${link#"$stage"/}"
  target="$(readlink "$link")"
  resolved=""
  case "$target" in
    /*) ;;
    *) if [ -e "$link" ] && base="$(cd "$(dirname "$link")" && cd "$(dirname "$target")" && pwd -P)"; then
         resolved="$base/$(basename "$target")"
       fi ;;
  esac
  case "$resolved" in
    "$stage_real"/*) ;;
    *)
      printf 'prepare-secrets: %s is a link to %s, outside the archive or missing; replace it with a file or a link inside the folder\n' "$rel" "$target" >&2
      exit 1
      ;;
  esac
done < <(find "$stage" -type l)

pass=()
if [ -n "${DOTS_SECRETS_PASSPHRASE:-}" ]; then pass=(-pass env:DOTS_SECRETS_PASSPHRASE); fi
# openssl enc has no authentication (zip CRCs catch corruption); acceptable for an archive the owner carries.
# Zip to a file (links are stored, which a pipe cannot take), encrypt inside the work folder, then move into place:
# a failure never leaves a partial or world-readable $OUTPUT.
umask 077
(cd "$stage" && zip -qr -y "$work/secrets.zip" .)
openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -md sha256 -salt -in "$work/secrets.zip" -out "$work/out.enc" "${pass[@]+"${pass[@]}"}"
mv -f "$work/out.enc" "$OUTPUT"
chmod 600 "$OUTPUT"
printf '%s\n' "$OUTPUT"
```
Then: `chmod +x ~/Work/dots/script/prepare-secrets`.

- [x] **Step 4: Add the task and the ignore rule**

In `mise.toml`, after `[tasks."setup:hooks"]` and its `run` block, add:
```toml
[tasks.prepare]
description = "Pack the secrets `install --secrets` expects into an encrypted archive (--fixture for tests)"
run = "script/prepare-secrets"
```
In `.gitignore` (repo root), add:
```gitignore
# Secrets archives from `mise run prepare`; never commit them, not even fixtures.
*.zip.enc
```

- [x] **Step 5: Run the spec and lint**

Run:
```bash
cd ~/Work/dots/assets && bun test integration/install/prepare-secrets.spec.ts
cd ~/Work/dots && shellcheck script/prepare-secrets && mise run prepare --help | head -3
```
Expected: PASS, 8 tests; no shellcheck findings; the usage text prints.

- [ ] **Step 6: Make the real archive (owner, interactive)**

Ask the owner to run, entering a passphrase they store in Bitwarden:
```bash
cd ~/Work/dots && mise run prepare -- --output /Volumes/meex900/backups/dots-secrets.zip.enc
```
Expected: the path prints; `ls -l` shows `-rw-------`. Not committed.

- [x] **Step 7: Commit**

```bash
cd ~/Work/dots && git add script/prepare-secrets assets/integration/install/prepare-secrets.spec.ts mise.toml .gitignore
git commit -m "feat(secrets): Add prepare task for an encrypted secrets archive"
```

---

### Task 5: Rewrite `install` (test first)

**Files:**
- Create: `assets/integration/install/install.spec.ts`
- Modify: `install` (full rewrite)

- [x] **Step 1: Write the failing spec**

```ts
#!/usr/bin/env bun
// install behaviour through --dry-run and the fixture archive: checks read the real machine, nothing changes.
import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from "bun:test";
import {
  chmodSync,
  copyFileSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readdirSync,
  readFileSync,
  readlinkSync,
  realpathSync,
  rmSync,
  statSync,
  symlinkSync,
  writeFileSync,
} from "node:fs";
import { tmpdir, userInfo } from "node:os";
import { join, resolve } from "node:path";

const repo = resolve(import.meta.dir, "../../..");
const script = join(repo, "install");
const me = userInfo().username;
const isMac = process.platform === "darwin";

let fixtureDir: string;
let fixture: string;
beforeAll(() => {
  fixtureDir = mkdtempSync(join(tmpdir(), "install-fixture-"));
  fixture = join(fixtureDir, "fixture.zip.enc");
  const r = Bun.spawnSync(["/bin/bash", join(repo, "script/prepare-secrets"), "--fixture", "--output", fixture]);
  if (r.exitCode !== 0) throw new Error(`prepare-secrets failed: ${r.stderr}`);
});
afterAll(() => rmSync(fixtureDir, { recursive: true, force: true }));

let home: string;
beforeEach(() => {
  home = mkdtempSync(join(tmpdir(), "install-home-"));
});
afterEach(() => rmSync(home, { recursive: true, force: true }));

const dotsTemps = () => readdirSync("/tmp").filter((n) => n.startsWith("dots-"));
const newTemps = (before: string[]) => dotsTemps().filter((n) => !before.includes(n));

function run(args: string[], env: Record<string, string> = {}) {
  const r = Bun.spawnSync(["/bin/bash", script, ...args], {
    env: { PATH: process.env.PATH ?? "", HOME: home, DOTS_CONTAINER: "0", ...env },
    stdout: "pipe",
    stderr: "pipe",
  });
  return { code: r.exitCode, out: r.stdout.toString(), err: r.stderr.toString() };
}

describe("install", () => {
  describe("arguments", () => {
    it("prints usage with --help", () => {
      const r = run(["--help"]);
      expect(r.code).toBe(0);
      expect(r.out).toContain("--secrets <archive>");
      expect(r.out).toContain("--dry-run");
    });

    it.each([
      [["--bogus"], "unknown option '--bogus'"],
      [["--user", "Bad Name"], "invalid user name 'Bad Name'"],
      [["--secrets", "/no/such/file.zip.enc"], "is not a file"],
      [["--tz", "x'; y", "--dry-run"], "invalid timezone"],
      [["--tz", "../x", "--dry-run"], "invalid timezone"],
      [["--branch", "../../a/b/c", "--dry-run"], "invalid branch"],
      [["--branch", "-x", "--dry-run"], "invalid branch"],
    ])("rejects %p", (args, message) => {
      const r = run(args as string[]);
      expect(r.code).toBe(2);
      expect(r.err).toContain(message as string);
    });
  });

  describe("dry run as the current user", () => {
    it("keeps the existing user and plans mise, links and bootstrap", () => {
      const r = run(["--user", me, "--dry-run"]);
      expect(r.code).toBe(0);
      expect(r.out).toContain(`user ${me} exists`);
      expect(r.out).toMatch(/ v\d{4}\.\d+\.\d+\n/);
      expect(r.out).toContain(`would: ln -snf ${repo} ${home}/.local/share/dots`);
      expect(r.out).toContain(`would: ln -snf ../.local/share/dots/config/mise ${home}/.config/mise`);
      expect(r.out).toContain(`would: ${home}/.local/bin/mise bootstrap`);
      expect(r.out).toContain("mise bootstrap -E desktop");
    });

    it("changes no link that is already right", () => {
      mkdirSync(join(home, ".local/share"), { recursive: true });
      mkdirSync(join(home, ".config"), { recursive: true });
      symlinkSync(repo, join(home, ".local/share/dots"));
      symlinkSync("../.local/share/dots/config/mise", join(home, ".config/mise"));
      const r = run(["--user", me, "--dry-run"]);
      expect(r.code).toBe(0);
      expect(r.out).not.toContain("would: ln");
      expect(r.out.match(/is linked/g)?.length).toBe(2);
    });
  });

  describe("secrets archive", () => {
    it("opens the archive and plans copying without overwriting", () => {
      const r = run(["--user", me, "--secrets", fixture, "--dry-run"], { DOTS_SECRETS_PASSPHRASE: "dots-fixture" });
      expect(r.code).toBe(0);
      expect(r.out).toMatch(/would: cp -R \S+\/files\/ssh /);
      expect(r.out).toContain(`${home}/.config/ssh`);
      expect(r.out).toMatch(/would: install -m 0600 \S+\/files\/gh\/hosts\.yml /);
      expect(r.out).toContain("config/age/keys.txt"); // planned, or reported as existing on a set-up Mac
    });

    it("stops with exit code 2 on a wrong passphrase", () => {
      const r = run(["--user", me, "--secrets", fixture, "--dry-run"], { DOTS_SECRETS_PASSPHRASE: "wrong" });
      expect(r.code).toBe(2);
      expect(r.err).toContain("cannot open");
      expect(r.out).not.toContain("would: cp");
    });
  });

  describe("dry run for another user", () => {
    it("plans creating a missing user and stops before switching", () => {
      const r = run(["--user", "dots-test-nobody", "--dry-run"]);
      expect(r.code).toBe(0);
      expect(r.out).toContain(isMac ? "sysadminctl -addUser dots-test-nobody" : "useradd -m -g dots-test-nobody");
      expect(r.out).toContain("would: continue as dots-test-nobody");
    });
  });

  describe("temporary files", () => {
    it("leaves none after a dry run or a wrong passphrase", () => {
      const before = dotsTemps();
      const ok = run(["--user", me, "--secrets", fixture, "--dry-run"], { DOTS_SECRETS_PASSPHRASE: "dots-fixture" });
      expect(ok.code).toBe(0);
      const bad = run(["--user", me, "--secrets", fixture, "--dry-run"], { DOTS_SECRETS_PASSPHRASE: "wrong" });
      expect(bad.code).toBe(2);
      expect(newTemps(before)).toEqual([]);
    });
  });

  describe("the user stage", () => {
    const mk = (template: string, dir = false) =>
      Bun.spawnSync(["mktemp", ...(dir ? ["-d"] : []), template]).stdout.toString().trim();

    it("rejects a DOTS_SECRETS path that is not a plain dots-secrets folder, and deletes nothing", () => {
      const victim = mkdtempSync(join(tmpdir(), "install-victim-"));
      writeFileSync(join(victim, "keep"), "x");
      const r = run(["--user", me], {
        DOTS_STAGE: "user",
        DOTS_SECRETS: `/tmp/dots-secrets.abcdef/..${victim}`,
      });
      expect(r.code).toBe(2);
      expect(r.err).toContain("untrusted");
      expect(readFileSync(join(victim, "keep"), "utf8")).toBe("x");
      rmSync(victim, { recursive: true, force: true });
    });

    it("does not delete a trusted folder under --dry-run", () => {
      const dir = mk("/tmp/dots-secrets.XXXXXX", true);
      const r = run(["--user", me, "--dry-run"], { DOTS_STAGE: "user", DOTS_SECRETS: dir });
      const kept = statSync(dir).isDirectory();
      rmSync(dir, { recursive: true, force: true });
      expect(r.code).toBe(0);
      expect(kept).toBe(true);
    });
  });

  describe("a real run in a fake checkout and home", () => {
    let base: string;
    let checkout: string;
    let stubs: string;
    beforeEach(() => {
      base = mkdtempSync(join(tmpdir(), "install-real-"));
      checkout = realpathSync(base) + "/checkout";
      stubs = join(base, "stubs");
      mkdirSync(join(checkout, "script"), { recursive: true });
      mkdirSync(join(checkout, "config/mise"), { recursive: true });
      mkdirSync(join(checkout, "config/age"), { recursive: true });
      copyFileSync(script, join(checkout, "install"));
      mkdirSync(join(home, ".local/bin"), { recursive: true });
      const mise = join(home, ".local/bin/mise");
      writeFileSync(
        mise,
        '#!/bin/sh\nif [ "$1" = --version ]; then echo "2026.10.21 stub"; else echo "$*" >> "$HOME/mise.log"; fi\n',
      );
      chmodSync(mise, 0o755);
      mkdirSync(stubs);
      writeFileSync(join(stubs, "flatpak"), "#!/bin/sh\nexit 0\n");
      chmodSync(join(stubs, "flatpak"), 0o755);
      mkdirSync(join(home, ".config/gh"), { recursive: true });
      writeFileSync(join(home, ".config/gh/hosts.yml"), "mine\n");
    });
    afterEach(() => rmSync(base, { recursive: true, force: true }));

    const real = () =>
      Bun.spawnSync(["/bin/bash", join(checkout, "install"), "--user", me, "--secrets", fixture], {
        env: {
          PATH: `${stubs}:${process.env.PATH ?? ""}`,
          HOME: home,
          DOTS_CONTAINER: "0",
          DOTS_SECRETS_PASSPHRASE: "dots-fixture",
        },
        stdout: "pipe",
        stderr: "pipe",
      });
    const mode = (p: string) => statSync(p).mode & 0o777;

    it("places links and secrets, bootstraps, and changes nothing on a second run", () => {
      const before = dotsTemps();
      const r = real();
      expect(r.stderr.toString()).toBe("");
      expect(r.exitCode).toBe(0);
      expect(readlinkSync(join(home, ".local/share/dots"))).toBe(checkout);
      expect(readlinkSync(join(home, ".config/mise"))).toBe("../.local/share/dots/config/mise");
      expect(mode(join(home, ".config/ssh"))).toBe(0o700);
      for (const f of readdirSync(join(home, ".config/ssh"))) {
        if (statSync(join(home, ".config/ssh", f)).isFile()) expect(mode(join(home, ".config/ssh", f))).toBe(0o600);
      }
      expect(mode(join(checkout, "config/age/keys.txt"))).toBe(0o600);
      expect(readFileSync(join(home, "mise.log"), "utf8")).toContain("bootstrap -E desktop");
      expect(readFileSync(join(home, ".config/gh/hosts.yml"), "utf8")).toBe("mine\n");
      expect(newTemps(before)).toEqual([]);

      const mtimes = () =>
        [join(checkout, "config/age/keys.txt"), ...readdirSync(join(home, ".config/ssh")).map((f) => join(home, ".config/ssh", f))].map(
          (p) => statSync(p).mtimeMs,
        );
      const m1 = mtimes();
      const r2 = real();
      expect(r2.exitCode).toBe(0);
      expect(mtimes()).toEqual(m1);
      expect(readFileSync(join(home, "mise.log"), "utf8").match(/bootstrap/g)?.length).toBe(2);
      expect(newTemps(before)).toEqual([]);
    });

    it("runs the script the root stage writes, as the user stage, and removes what it was handed", () => {
      const mk = (template: string, dir = false) =>
        Bun.spawnSync(["mktemp", ...(dir ? ["-d"] : []), template]).stdout.toString().trim();
      const emitted = mk("/tmp/dots-install.XXXXXX");
      const env = {
        PATH: `${stubs}:${process.env.PATH ?? ""}`,
        HOME: home,
        DOTS_CONTAINER: "0",
      };
      // DOTS_INSTALL_EMIT_SCRIPT makes a dry run write the script switch_to_user would hand over, and stop.
      const gen = Bun.spawnSync(["/bin/bash", join(checkout, "install"), "--user", me, "--dry-run"], {
        env: { ...env, DOTS_INSTALL_EMIT_SCRIPT: emitted },
      });
      expect(gen.exitCode).toBe(0);
      chmodSync(emitted, 0o755);
      const secrets = mk("/tmp/dots-secrets.XXXXXX", true);
      mkdirSync(join(secrets, "ssh"));
      writeFileSync(join(secrets, "ssh/id"), "key\n");
      writeFileSync(join(secrets, "github_token"), "tok");
      const r = Bun.spawnSync(["/bin/bash", emitted, "--user", me], {
        env: { ...env, DOTS_STAGE: "user", DOTS_SECRETS: secrets, DOTS_CHECKOUT: checkout },
        stdout: "pipe",
        stderr: "pipe",
      });
      const left = [existsSync(secrets), existsSync(emitted)];
      rmSync(secrets, { recursive: true, force: true });
      rmSync(emitted, { force: true });
      expect(r.stderr.toString()).toBe("");
      expect(r.exitCode).toBe(0);
      expect(left).toEqual([false, false]);
      expect(mode(join(home, ".config/ssh"))).toBe(0o700);
      expect(mode(join(home, ".config/ssh/id"))).toBe(0o600);
      expect(readFileSync(join(home, "mise.log"), "utf8")).toContain("bootstrap -E desktop");
    });
  });

  describe("containers", () => {
    it("uses the container profile, skips the login shell and plans passwordless sudo", () => {
      const r = run(["--user", me, "--dry-run"], { DOTS_CONTAINER: "1" });
      expect(r.code).toBe(0);
      expect(r.out).toContain("profile container");
      expect(r.out).toContain("visudo -cf");
      expect(r.out).toContain("mise bootstrap -E container --skip user --yes");
    });
  });
});
```

- [x] **Step 2: Run it against the old `install`**

Run: `cd ~/Work/dots/assets && bun test integration/install/install.spec.ts`
Expected: FAIL. The old script has no `--secrets <archive>` usage, rejects `--user`, and has no `--dry-run`.

- [x] **Step 3: Replace `install` with the new script**

Overwrite `install` with:
```bash
#!/usr/bin/env bash
# Prepares this machine for the dotfiles and hands over to `mise bootstrap`.
# Every step checks before acting, so running it again changes nothing.
# Design: assets/specs/mise-bootstrap/design.md (§4.4). Must run under macOS bash 3.2.
set -euo pipefail

MISE_PIN="2026.10.21"
REPO="roalcantara/dots"

# init_globals sets every other global; the user stage re-runs the functions without this top-level code.
init_globals() {
  TARGET_USER="roalcantara"
  SECRETS="" # the archive passed with --secrets
  SECRETS_SRC="" # the folder its files are read from once opened
  SECRETS_TMP=""
  TZ_NAME=""
  NOPASSWD=0
  BRANCH="main"
  PROFILE=""
  PROFILE_GIVEN=0
  DRY_RUN=0
  SKIP_USER=0
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  SELF="${BASH_SOURCE[0]:-}"
  MISE="$HOME/.local/bin/mise"
  DOTS_DIR=""
  STAGE=first
  APT_UPDATED=0
  ARGS=()
  CLEAN=()
}

usage() {
  cat <<'EOF'
Usage: install [options]
  --user <name>        target user (default: roalcantara); created when missing
  --secrets <archive>  encrypted archive from `mise run prepare`; the passphrase comes from
                       DOTS_SECRETS_PASSPHRASE, or openssl asks for it
  --tz <zone>          timezone to set, such as America/Sao_Paulo
  --nopasswd           grant the user passwordless sudo (always on in containers)
  --branch <ref>       branch to clone (default: main)
  -E <profile>         mise profile: desktop (the default on hosts) or container (the default in containers)
  --dry-run            print what would change and change nothing
EOF
}

log() { printf '==> %s\n' "$*"; }
die() {
  printf 'install: %s\n' "$1" >&2
  exit "${2:-1}"
}
# track registers a path for removal on exit; cleanup removes them all, so traps never override each other.
track() { CLEAN+=("$1"); }
cleanup() {
  local p
  [ "${#CLEAN[@]}" -gt 0 ] || return 0
  for p in "${CLEAN[@]}"; do
    [ -z "$p" ] || rm -rf "$p" 2>/dev/null || true
  done
  return 0
}
# act runs a command, or prints it under --dry-run.
act() { if [ "$DRY_RUN" = 1 ]; then printf 'would: %s\n' "$*"; else "$@"; fi; }
# act_root is act through sudo, unless already root.
act_root() { if [ "$(id -u)" -eq 0 ]; then act "$@"; else act sudo "$@"; fi; }
# check_root runs a read-only check as root without ever prompting.
check_root() { if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo -n "$@" 2>/dev/null; fi; }

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --user) TARGET_USER="${2:?--user needs a name}"; shift 2 ;;
      --secrets) SECRETS="${2:?--secrets needs an archive}"; shift 2 ;;
      --tz) TZ_NAME="${2:?--tz needs a zone}"; shift 2 ;;
      --nopasswd) NOPASSWD=1; shift ;;
      --branch) BRANCH="${2:?--branch needs a ref}"; shift 2 ;;
      -E) PROFILE="${2:?-E needs a profile}"; PROFILE_GIVEN=1; shift 2 ;;
      --dry-run) DRY_RUN=1; shift ;;
      -h | --help) usage; exit 0 ;;
      *) usage >&2; die "unknown option '$1'" 2 ;;
    esac
  done
  local re_user='^[a-z_][a-z0-9_-]*$' re_tz='^[A-Za-z0-9_][A-Za-z0-9_+-]*(/[A-Za-z0-9_][A-Za-z0-9_+-]*)*$' re_ref='^[A-Za-z0-9._/-]+$'
  [[ "$TARGET_USER" =~ $re_user ]] || die "invalid user name '$TARGET_USER'" 2
  if [ -n "$TZ_NAME" ]; then
    [[ "$TZ_NAME" =~ $re_tz ]] || die "invalid timezone '$TZ_NAME'" 2
    [ -f "/usr/share/zoneinfo/$TZ_NAME" ] || die "invalid timezone '$TZ_NAME'" 2
  fi
  if [[ ! "$BRANCH" =~ $re_ref ]] || [[ "$BRANCH" == -* ]] || [[ "$BRANCH" == *..* ]]; then
    die "invalid branch '$BRANCH'" 2
  fi
  # The user stage receives the opened files instead (DOTS_SECRETS) and may not be able to read the archive.
  if [ "$STAGE" != user ] && [ -n "$SECRETS" ] && [ ! -f "$SECRETS" ]; then
    die "--secrets '$SECRETS' is not a file" 2
  fi
}

is_container() {
  case "${DOTS_CONTAINER:-}" in 1) return 0 ;; 0) return 1 ;; esac
  [ -f /.dockerenv ] || [ -f /run/.containerenv ] || [ -n "${REMOTE_CONTAINERS:-}" ] || [ -n "${CODESPACES:-}" ] ||
    { [ -f /proc/1/cgroup ] && grep -qE 'docker|containerd' /proc/1/cgroup; }
}

detect() {
  case "$OS" in darwin | linux) ;; *) die "unsupported system '$OS'" 2 ;; esac
  if is_container; then
    NOPASSWD=1
    SKIP_USER=1
    PROFILE="${PROFILE:-container}"
  else
    PROFILE="${PROFILE:-desktop}"
  fi
  if [ "$DRY_RUN" = 0 ] && [ "$(id -u)" -ne 0 ] && [ "$(id -un)" != "$TARGET_USER" ]; then
    die "run as root or as $TARGET_USER" 2
  fi
  log "system: $OS${PROFILE:+, profile $PROFILE}"
}

user_home() {
  local home
  home="$(eval echo "~$TARGET_USER")" # TARGET_USER is validated in parse_args
  if [ "$home" = "~$TARGET_USER" ]; then
    if [ "$OS" = darwin ]; then home="/Users/$TARGET_USER"; else home="/home/$TARGET_USER"; fi
  fi
  printf '%s\n' "$home"
}

# checkout_dir prints the dots checkout this script runs from, if any.
checkout_dir() {
  local dir
  if [ "$STAGE" = user ]; then # the regenerated script has no checkout beside it
    dir="${DOTS_CHECKOUT:-}"
    if [ -n "$dir" ] && [ -d "$dir/config/mise" ]; then printf '%s\n' "$dir"; return 0; fi
    return 1
  fi
  if [ -z "$SELF" ] || [ ! -f "$SELF" ]; then return 1; fi
  dir="$(cd "$(dirname "$SELF")" && pwd -P)"
  [ -d "$dir/config/mise" ] || return 1
  printf '%s\n' "$dir"
}

# --- root steps -------------------------------------------------------------------------------------------

ensure_user() {
  if id "$TARGET_USER" >/dev/null 2>&1; then
    log "user $TARGET_USER exists"
    return
  fi
  if [ "$OS" = darwin ]; then
    act_root sysadminctl -addUser "$TARGET_USER" -fullName "$TARGET_USER" -shell /bin/zsh -password - -admin
  else
    getent group "$TARGET_USER" >/dev/null || act_root groupadd "$TARGET_USER"
    act_root useradd -m -g "$TARGET_USER" -s "$(command -v zsh || echo /bin/bash)" "$TARGET_USER"
    if getent group sudo >/dev/null; then act_root usermod -aG sudo "$TARGET_USER"; fi
  fi
}

current_tz() {
  if [ -f /etc/timezone ]; then cat /etc/timezone; else readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||'; fi
}

ensure_timezone() {
  [ -n "$TZ_NAME" ] || return 0
  if [ "$(current_tz)" = "$TZ_NAME" ]; then
    log "timezone is $TZ_NAME"
    return
  fi
  if [ "$OS" = darwin ]; then
    act_root systemsetup -settimezone "$TZ_NAME"
  else
    act_root ln -snf "/usr/share/zoneinfo/$TZ_NAME" /etc/localtime
    # shellcheck disable=SC2016 # single-quoted on purpose: sh expands $1
  act_root sh -c 'printf "%s\n" "$1" > /etc/timezone' sh "$TZ_NAME"
  fi
}

ensure_nopasswd() {
  [ "$NOPASSWD" = 1 ] || return 0
  local file="/etc/sudoers.d/$TARGET_USER" tmp
  if check_root test -f "$file"; then
    log "passwordless sudo for $TARGET_USER is set"
    return
  fi
  tmp="$(mktemp /tmp/dots-sudoers.XXXXXX)"
  track "$tmp"
  printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$TARGET_USER" >"$tmp"
  act_root visudo -cf "$tmp"
  act_root install -m 0440 "$tmp" "$file"
  rm -f "$tmp"
}

ensure_zdotdir() {
  [ "$OS" = linux ] || return 0
  local line
  line="export USER_ZDOTDIR=$(user_home)/.config/zsh"
  if grep -qxF "$line" /etc/zsh/zshenv 2>/dev/null; then
    log "/etc/zsh/zshenv sets USER_ZDOTDIR"
    return
  fi
  act_root mkdir -p /etc/zsh
  # shellcheck disable=SC2016 # single-quoted on purpose: sh expands $1
  act_root sh -c 'printf "%s\n" "$1" >> /etc/zsh/zshenv' sh "$line"
}

# apt_install updates the package lists once, then installs without prompting.
apt_install() {
  if [ "$APT_UPDATED" = 0 ]; then
    act_root env DEBIAN_FRONTEND=noninteractive apt-get update -qq
    APT_UPDATED=1
  fi
  act_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
}

ensure_flatpak() {
  if [ "$OS" != linux ] || [ "$PROFILE" != desktop ]; then return 0; fi
  if command -v flatpak >/dev/null; then
    log "flatpak is installed"
    return
  fi
  apt_install flatpak
}

ensure_unzip() {
  if [ -z "$SECRETS" ] || command -v unzip >/dev/null; then return 0; fi
  [ "$OS" = linux ] || die "unzip is required to open --secrets"
  apt_install unzip
}

# open_secrets decrypts and unpacks the archive into an owner-only temporary folder, removed on exit.
open_secrets() {
  [ -n "$SECRETS" ] || return 0
  command -v unzip >/dev/null || die "unzip is required to open --secrets"
  SECRETS_TMP="$(mktemp -d /tmp/dots-secrets.XXXXXX)"
  chmod 700 "$SECRETS_TMP"
  track "$SECRETS_TMP"
  local pass=()
  if [ -n "${DOTS_SECRETS_PASSPHRASE:-}" ]; then pass=(-pass env:DOTS_SECRETS_PASSPHRASE); fi
  if ! openssl enc -d -aes-256-cbc -pbkdf2 -iter 600000 -md sha256 -in "$SECRETS" -out "$SECRETS_TMP/secrets.zip" \
    "${pass[@]+"${pass[@]}"}" || ! unzip -q "$SECRETS_TMP/secrets.zip" -d "$SECRETS_TMP/files" 2>/dev/null; then
    die "cannot open '$SECRETS': wrong passphrase, or not an archive from prepare" 2
  fi
  rm -f "$SECRETS_TMP/secrets.zip"
  unset DOTS_SECRETS_PASSPHRASE
  SECRETS_SRC="$SECRETS_TMP/files"
}

# ensure_ownership gives the user a checkout another user copied into its home (an image's COPY).
ensure_ownership() {
  local repo home owner
  repo="$(checkout_dir)" || return 0
  home="$(user_home)"
  case "$repo" in "$home"/*) ;; *) return 0 ;; esac
  owner="$(stat -c %U "$repo" 2>/dev/null || stat -f %Su "$repo")"
  [ "$owner" = "$TARGET_USER" ] || act_root chown -R "$TARGET_USER" "$repo"
}

# emit_script writes the code this run is executing to a file, for the user to run (it cannot read root's files).
emit_script() {
  {
    printf '#!/usr/bin/env bash\nset -euo pipefail\n'
    declare -p MISE_PIN REPO
    declare -f
    printf 'main "$@"\n'
  } >"$1"
  chmod 0755 "$1"
}

# switch_to_user re-runs this code as the target user, unless it already is that user. The user gets the code in a
# file of its own and, when there are secrets, a copy of them; exec skips the EXIT trap, so root's temps go first.
switch_to_user() {
  [ "$(id -un)" != "$TARGET_USER" ] || return 0
  if [ "$DRY_RUN" = 1 ]; then
    printf 'would: continue as %s\n' "$TARGET_USER"
    exit 0
  fi
  [ "$(id -u)" -eq 0 ] || die "run as root or as $TARGET_USER" 2
  local script copy="" checkout home container=0 fwd=()
  home="$(user_home)"
  checkout="$(checkout_dir || true)"
  script="$(mktemp /tmp/dots-install.XXXXXX)"
  track "$script"
  emit_script "$script"
  chown "$TARGET_USER" "$script"
  if [ -n "$SECRETS_SRC" ] || [ -n "${GITHUB_TOKEN:-}" ]; then
    copy="$(mktemp -d /tmp/dots-secrets.XXXXXX)"
    track "$copy"
    (
      umask 077
      if [ -n "$SECRETS_SRC" ]; then cp -R "$SECRETS_SRC"/. "$copy"/; fi
      if [ -n "${GITHUB_TOKEN:-}" ]; then printf '%s' "$GITHUB_TOKEN" >"$copy/github_token"; fi
    )
    chown -R "$TARGET_USER" "$copy"
  fi
  if is_container; then container=1; fi
  fwd=(${ARGS[@]+"${ARGS[@]}"})
  if [ "$PROFILE_GIVEN" = 0 ]; then fwd+=(-E "$PROFILE"); fi
  # Everything root made except the two things handed over.
  local p
  if [ "${#CLEAN[@]}" -gt 0 ]; then
    for p in "${CLEAN[@]}"; do
      if [ "$p" != "$script" ] && [ "$p" != "$copy" ]; then rm -rf "$p" 2>/dev/null || true; fi
    done
  fi
  cd "$home" 2>/dev/null || cd /
  exec sudo -u "$TARGET_USER" -H env DOTS_STAGE=user DOTS_SECRETS="$copy" DOTS_CHECKOUT="$checkout" \
    DOTS_CONTAINER="$container" bash "$script" "${fwd[@]}"
}

# trust_user_stage accepts what the root stage handed over only when it is a real folder this user owns whose
# name is exactly a mktemp template of ours (dots-secrets.XXXXXX in /tmp), and removes it on exit. The running
# script is removed the same way when its name is exactly /tmp/dots-install.XXXXXX. A dry run removes neither.
trust_user_stage() {
  local dir="${DOTS_SECRETS:-}" owner re_secrets='^/tmp/dots-secrets\.[A-Za-z0-9]{6}$' re_script='^/tmp/dots-install\.[A-Za-z0-9]{6}$'
  if [ -n "$dir" ]; then
    owner="$(stat -c %u "$dir" 2>/dev/null || stat -f %u "$dir" 2>/dev/null || true)"
    if [[ ! "$dir" =~ $re_secrets ]] || [ -L "$dir" ] || [ ! -d "$dir" ] || [ "$owner" != "$(id -u)" ]; then
      die "untrusted DOTS_SECRETS '$dir'" 2
    fi
    SECRETS_SRC="$dir"
    if [ "$DRY_RUN" = 0 ]; then track "$dir"; fi
  fi
  if [ "$DRY_RUN" = 0 ] && [[ "$0" =~ $re_script ]]; then track "$0"; fi
}

# --- user steps -------------------------------------------------------------------------------------------

ensure_mise() {
  case "$("$MISE" --version 2>/dev/null || true)" in
    "$MISE_PIN "*)
      log "mise $MISE_PIN is installed"
      return
      ;;
  esac
  local dir
  dir="$(mktemp -d /tmp/dots-mise.XXXXXX)"
  track "$dir"
  # shellcheck disable=SC2016 # single-quoted on purpose: sh expands $1 and $2
  act sh -c 'curl -fsSL https://mise.run -o "$1" && MISE_VERSION="$2" sh "$1"' sh "$dir/mise.sh" "v$MISE_PIN"
}

ensure_link() {
  local target="$1" path="$2"
  if [ -L "$path" ] && [ "$(readlink "$path")" = "$target" ]; then
    log "$path is linked"
    return
  fi
  if [ -e "$path" ] && [ ! -L "$path" ]; then die "$path exists and is not a link; move it away and rerun"; fi
  if [ -L "$path" ]; then log "relinking $path (was $(readlink "$path"))"; fi
  act mkdir -p "$(dirname "$path")"
  act ln -snf "$target" "$path"
}

ensure_repo() {
  if DOTS_DIR="$(checkout_dir)"; then
    log "using checkout $DOTS_DIR"
  else
    DOTS_DIR="$HOME/Work/dots"
    if [ -d "$DOTS_DIR/.git" ]; then
      act git -C "$DOTS_DIR" pull --ff-only
    else
      act git clone --branch "$BRANCH" "https://github.com/$REPO.git" "$DOTS_DIR"
    fi
  fi
  ensure_link "$DOTS_DIR" "$HOME/.local/share/dots"
  ensure_link "../.local/share/dots/config/mise" "$HOME/.config/mise"
}

copy_secret_file() {
  local src="$1" dst="$2"
  [ -f "$src" ] || return 0
  if [ -e "$dst" ]; then
    log "$dst exists"
    return
  fi
  act mkdir -p "$(dirname "$dst")"
  act install -m 0600 "$src" "$dst"
}

copy_secret_dir() {
  local src="$1" dst="$2"
  [ -d "$src" ] || return 0
  if [ -e "$dst" ]; then
    log "$dst exists"
    return
  fi
  local old
  old="$(umask)"
  umask 077
  act cp -R "$src" "$dst"
  umask "$old"
  act find "$dst" -type d -exec chmod 700 {} +
  act find "$dst" -type f -exec chmod 600 {} +
}

ensure_secrets() {
  [ -n "$SECRETS_SRC" ] || return 0
  copy_secret_file "$SECRETS_SRC/age/keys.txt" "$DOTS_DIR/config/age/keys.txt"
  copy_secret_file "$SECRETS_SRC/gh/hosts.yml" "$HOME/.config/gh/hosts.yml"
  copy_secret_dir "$SECRETS_SRC/ssh" "$HOME/.config/ssh"
  copy_secret_dir "$SECRETS_SRC/gnupg" "$HOME/.config/gnupg"
  if [ -z "${GITHUB_TOKEN:-}" ] && [ -f "$SECRETS_SRC/github_token" ]; then
    GITHUB_TOKEN="$(cat "$SECRETS_SRC/github_token")"
    export GITHUB_TOKEN
    log "GITHUB_TOKEN set for this run"
  fi
}

ensure_flathub() {
  if [ "$OS" != linux ] || [ "$PROFILE" != desktop ]; then return 0; fi
  act flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

run_bootstrap() {
  local args=(bootstrap)
  if [ -n "$PROFILE" ]; then args+=(-E "$PROFILE"); fi
  if [ "$SKIP_USER" = 1 ]; then args+=(--skip user --yes); fi
  cd "$HOME"
  act "$MISE" "${args[@]}"
}

main() {
  init_globals
  trap cleanup EXIT
  # DOTS_STAGE=user is honoured only when not root (the switch runs sudo -u <user>). That is the only check: the
  # handed-over paths are vetted in trust_user_stage. A first stage drops all three variables.
  if [ "${DOTS_STAGE:-}" = user ] && [ "$(id -u)" -ne 0 ]; then STAGE=user; fi
  if [ "$STAGE" != user ]; then unset DOTS_STAGE DOTS_SECRETS DOTS_CHECKOUT; fi
  if [ $# -gt 0 ]; then ARGS=("$@"); fi
  parse_args "$@"
  # DOTS_INSTALL_EMIT_SCRIPT=<file> (dry run only): write the script switch_to_user hands over, and stop. For specs.
  if [ "$DRY_RUN" = 1 ] && [ -n "${DOTS_INSTALL_EMIT_SCRIPT:-}" ]; then
    emit_script "$DOTS_INSTALL_EMIT_SCRIPT"
    exit 0
  fi
  detect
  if [ "$STAGE" = user ]; then
    [ "$(id -un)" = "$TARGET_USER" ] || die "the user stage must run as $TARGET_USER" 2
    trust_user_stage
  else
    ensure_user
    ensure_timezone
    ensure_nopasswd
    ensure_zdotdir
    ensure_flatpak
    ensure_unzip
    open_secrets
    ensure_ownership
    switch_to_user
  fi
  ensure_mise
  ensure_repo
  ensure_secrets
  ensure_flathub
  run_bootstrap
}

main "$@"
```

- [x] **Step 4: Run both specs**

Run: `cd ~/Work/dots/assets && bun test integration/install/`
Expected: PASS, 27 tests (8 prepare-secrets, 19 install).

- [x] **Step 5: Lint and check bash 3.2**

Run:
```bash
cd ~/Work/dots && shellcheck install script/prepare-secrets && /bin/bash -n install && /bin/bash --version | head -1
HOME=$(mktemp -d) DOTS_CONTAINER=0 /bin/bash ./install --user "$(id -un)" --dry-run | tail -3
```
Expected: no shellcheck findings; `/bin/bash` reports 3.2.x; the dry run ends with
`would: <tmp>/.local/bin/mise bootstrap` and exits 0.

- [ ] **Step 6: Dry-run against the real home with the real archive (read-only)**

Ask the owner to run (it prompts for the archive's passphrase):
```bash
cd ~/Work/dots && ./install --secrets /Volumes/meex900/backups/dots-secrets.zip.enc --dry-run
```
Expected: `user roalcantara exists`, both links `is linked`, every secret reported as `exists` (this Mac already
has them), and only the mise install (unless `~/.local/bin/mise` is 2026.10.21) and the final `mise bootstrap`
as `would:` lines.

- [x] **Step 7: Commit**

```bash
cd ~/Work/dots && git add install assets/integration/install/install.spec.ts
git commit -m "feat(install): Rewrite install as the entry point to mise bootstrap"
```

---

### Task 6: Images built by `install`, from the committed tree

**Files:**
- Modify: `distros/debian/Dockerfile`, `distros/ubuntu/Dockerfile` (full rewrite)
- Modify: `distros/debian/container-structure-test.yml`, `distros/ubuntu/container-structure-test.yml`
- Modify: `mise.toml` (`[tasks."build"]`)

- [ ] **Step 0: Check Docker Hub for images built by the old stages (owner)**

The old `local` and `publish` stages copied this Mac's working tree, in which `config/.env` and
`config/ssh/keys/*.key` are decrypted. Ask the owner to check the Docker Hub repository for `dots` tags built
with `--local` or `--publish`. If any exists: delete it, and rotate the GitHub, GitHub deploy and Bitbucket SSH
keys. Record the answer under "Findings".

- [x] **Step 1: Rewrite the Debian Dockerfile**

```dockerfile
# syntax=docker/dockerfile:1.7

# A Debian development container set up by ./install (mise bootstrap).
# Images never receive a secrets archive; only GITHUB_TOKEN, from a build secret, for GitHub API limits.
# https://mcr.microsoft.com/en-us/artifact/mar/devcontainers/base/tags
FROM mcr.microsoft.com/devcontainers/base:debian AS base

ARG TZ=America/Sao_Paulo
ARG TERM=xterm-256color
ARG BRANCH=main
# hadolint ignore=DL3064
ARG USERNAME=vscode
ARG GITHUB_REPO=roalcantara/dots

ENV CLICOLOR=1 \
    TZ=$TZ \
    TERM="$TERM" \
    COLORTERM=truecolor \
    USER="$USERNAME" \
    HOME="/home/$USERNAME" \
    GITHUB_REPO="$GITHUB_REPO" \
    BRANCH="$BRANCH" \
    DEBIAN_FRONTEND=noninteractive \
    PATH="/home/$USERNAME/.local/bin:/home/linuxbrew/.linuxbrew/bin:$PATH"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Committed tree (sent by `mise run build --local` as a git archive)
FROM base AS local
COPY . /home/$USERNAME/Work/dots
RUN --mount=type=secret,id=github_token \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    GITHUB_TOKEN="$(cat /run/secrets/github_token 2>/dev/null || true)" \
    "/home/$USERNAME/Work/dots/install" --user "$USERNAME" --tz "$TZ"
USER $USERNAME
WORKDIR /home/$USERNAME
SHELL ["/usr/bin/zsh", "-c"]
ENTRYPOINT ["/usr/bin/zsh", "-il"]

# GitHub branch: mise run build (the default)
FROM base AS remote
# hadolint ignore=DL4006
RUN --mount=type=secret,id=github_token \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    export GITHUB_TOKEN="$(cat /run/secrets/github_token 2>/dev/null || true)"; \
    curl -fsSL "https://raw.githubusercontent.com/${GITHUB_REPO}/${BRANCH}/install" \
      | bash -s -- --user "$USERNAME" --tz "$TZ" --branch "$BRANCH"
USER $USERNAME
WORKDIR /home/$USERNAME
SHELL ["/usr/bin/zsh", "-c"]
ENTRYPOINT ["/usr/bin/zsh", "-il"]

# Docker Hub: mise run build --publish (the committed tree, as local)
FROM local AS publish
```

- [x] **Step 2: Derive the Ubuntu Dockerfile**

```bash
cd ~/Work/dots && sed -e 's/A Debian development/An Ubuntu development/' -e 's/base:debian AS base/base:ubuntu AS base/' \
  distros/debian/Dockerfile > distros/ubuntu/Dockerfile
diff distros/debian/Dockerfile distros/ubuntu/Dockerfile
```
Expected: exactly two differing lines (the comment and the `FROM`).

- [x] **Step 3: Update the structure tests (both files)**

In each `container-structure-test.yml`, replace the whole `# FLOX` block (from `  # FLOX` to the end of the
`expectedOutput` list, before `# HOME DIRECTORIES`) with:
```yaml
  # MISE
  - name: mise should be installed
    command: /home/vscode/.local/bin/mise
    args: [--version]
    exitCode: 0
  - name: core tools should be installed by mise bootstrap
    command: bash
    args: [-c, "for t in age bat eza fd fzf jq nvim rg sops starship zoxide; do command -v $t >/dev/null || { echo missing $t; exit 1; }; done"]
    exitCode: 0
  - name: SOPS-filtered files should stay encrypted in the image
    command: bash
    args: [-c, "! grep -q 'BEGIN OPENSSH PRIVATE KEY' /home/vscode/Work/dots/config/ssh/keys/*.key"]
    exitCode: 0
```
and change two expectations:
```yaml
  - name: ~/.bashrc file
    path: /home/vscode/.bashrc
    shouldExist: true
    permissions: Lrwxrwxrwx
```
```yaml
  - name: ~/.config dir (XDG_CONFIG_HOME)
    path: /home/vscode/.config
    shouldExist: true
    permissions: drwxr-xr-x
```

Also change the `permissions` of the `~/Desktop`, `~/Documents`, `~/Downloads`, `~/Movies`, `~/Music`, `~/Pictures` and `~/.cache/zsh` tests to `drwx------` (bootstrap creates them 0700).

- [x] **Step 4: Build local images from the committed tree; drop flox and groups**

In `mise.toml`, `[tasks."build"]`:
1. Delete the usage lines `flag "--group <group>" help="Build arg GROUPNAME"` and
   `flag "--package-manager <pm>" help="Package manager" default="flox"`, and delete both blocks:
```bash
if [ -n "${usage_group:-}" ]; then
  DOCKER_CMD+=(--build-arg=GROUPNAME="$usage_group")
fi
```
```bash
if [ -n "${usage_package_manager:-}" ]; then
  DOCKER_CMD+=(--build-arg=PACKAGE_MANAGER="$usage_package_manager")
fi
```
2. Replace the final block, from `if [ "${usage_publish:-false}" = "true" ]; then` to the end of the `run`
   script, with:
```bash
# local and publish build the committed tree: the working tree holds decrypted SOPS files (config/.env,
# config/ssh/keys/*.key). The smudge filter is disabled so git archive exports them encrypted.
if [ "${usage_publish:-false}" = "true" ] || [ "${usage_local:-false}" = "true" ]; then
  target=local
  [ "${usage_publish:-false}" = "true" ] && target=publish
  DOCKER_CMD+=(--target="$target" -)
  echo "  ==> git archive HEAD | ${DOCKER_CMD[*]}"
  git -c filter.sops.smudge=cat -c filter.sops.required=false archive --format=tar HEAD | eval "${DOCKER_CMD[*]}"
else
  DOCKER_CMD+=(--target=remote .)
  echo "  ==> ${DOCKER_CMD[*]}"
  eval "${DOCKER_CMD[*]}"
fi
```

- [x] **Step 5: Lint**

Run: `cd ~/Work/dots && hk check --all`
Expected: hadolint, shellcheck and the YAML/TOML checks pass for the changed files.

- [x] **Step 6: Commit**

```bash
cd ~/Work/dots && git add distros/debian distros/ubuntu mise.toml
git commit -m "feat(distros): Build images with install, from the committed tree"
```

---

### Task 7: Success criterion 1 — the Debian image (and the Ubuntu image)

**Files:** none (verification); findings go under "Findings".

- [ ] **Step 1: Build Debian**

Run: `cd ~/Work/dots && mise run build --local --distro debian --tag local`
Expected: the build succeeds. A formula that fails on Linux arm64, or builds from source for minutes: add
`env = "desktop"` to its entry in `conf.d/packages.toml`, commit, record it under "Findings", and rebuild (the
build uses the committed tree).

- [ ] **Step 2: Check the image holds no decrypted secrets**

Run:
```bash
docker run --rm --entrypoint bash dots:debian-local -c 'head -c 40 ~/Work/dots/config/ssh/keys/id_ed25519_github.key; echo; grep -c "ENC\[" ~/Work/dots/config/.env'
```
Expected: the key file does not start with `-----BEGIN OPENSSH PRIVATE KEY-----` (it shows SOPS data), and
`config/.env` has at least one `ENC[` value. If either fails, stop: the image must not be pushed.

- [ ] **Step 3: Run `install` with the fixture archive, as root, then again (criterion 1)**

Run:
```bash
cd ~/Work/dots && fixture=$(mktemp -d)/fixture.zip.enc && script/prepare-secrets --fixture --output "$fixture"
docker run --rm --user root -v "$fixture:/tmp/fixture.zip.enc:ro" -e DOTS_SECRETS_PASSPHRASE=dots-fixture \
  -e GITHUB_TOKEN="$(gh auth token)" --entrypoint bash dots:debian-local -c '
    set -e
    ~vscode/Work/dots/install --user vscode --secrets /tmp/fixture.zip.enc
    stat -c "%a %n" ~vscode/.config/ssh ~vscode/.config/ssh/id_ed25519 ~vscode/.config/gh/hosts.yml
    echo "--- second run"
    ~vscode/Work/dots/install --user vscode --secrets /tmp/fixture.zip.enc --dry-run | grep "^would:"'
```
Expected: the first run exits 0; the modes are `700`, `600`, `600`; the second (dry) run, which as root stops
at `would: continue as vscode`, prints no other `would:` line. Then confirm the user stage too:
```bash
docker run --rm --entrypoint bash dots:debian-local -c '~/Work/dots/install --dry-run | grep "^would:"'
```
Expected: one line only, `would: /home/vscode/.local/bin/mise bootstrap -E container --skip user --yes`.

- [ ] **Step 4: Run the structure tests**

Run: `cd ~/Work/dots && mise run test --image dots:debian-local --config distros/debian/container-structure-test.yml`
Expected: all tests pass, including "SOPS-filtered files should stay encrypted in the image".

- [ ] **Step 5: Repeat Steps 1–4 for the Ubuntu image**

Use `--distro ubuntu`, `dots:ubuntu-local` and `distros/ubuntu/container-structure-test.yml`.
Expected: the same results.

- [ ] **Step 6: Commit findings**

```bash
cd ~/Work/dots && git add config/mise/conf.d/packages.toml assets/specs/mise-bootstrap/tasks.md
git commit -m "test(distros): Verify images built by install and mise bootstrap"
```

---

### Task 8: Success criterion 2 — an Ubuntu VM in Parallels (with the owner)

**Files:** none (verification); findings go under "Findings".

- [ ] **Step 1: Create the VM**

Parallels → New → Download Ubuntu 24.04 (arm64); 4 cores, 8 GB, 64 GB; user `roalcantara` created by the
installer, with sudo. Take a snapshot named `clean` before the first run.

- [ ] **Step 2: Copy the fixture archive into the VM**

On this Mac:
```bash
cd ~/Work/dots && script/prepare-secrets --fixture --output /tmp/fixture.zip.enc
```
Then drag `/tmp/fixture.zip.enc` into the VM's home folder (Parallels Tools), or use
`scp /tmp/fixture.zip.enc roalcantara@<vm-ip>:~/`.

- [ ] **Step 3: Run the one-liner from the pushed branch (criterion 2)**

In the VM (the branch must be pushed first: `git push -u origin feat/mise-bootstrap`):
```bash
sudo apt-get update && sudo apt-get install -y curl
export GITHUB_TOKEN=<a token from `gh auth token` on the Mac> DOTS_SECRETS_PASSPHRASE=dots-fixture
curl -fsSL https://raw.githubusercontent.com/roalcantara/dots/feat/mise-bootstrap/install \
  | bash -s -- --branch feat/mise-bootstrap --secrets ~/fixture.zip.enc
```
Expected: exits 0, prompting for the sudo password where needed. Then check:
```bash
getent passwd roalcantara | cut -d: -f7          # zsh
stat -c '%a %n' ~/.config/ssh ~/.config/ssh/id_ed25519   # 700, 600
flatpak list --user --app | wc -l                # 10
docker --version                                 # Docker Engine
ls -l ~/.local/share/dots ~/.config/mise ~/.config/zsh   # links into ~/Work/dots
```

- [ ] **Step 4: Run it again (idempotency)**

```bash
~/.local/share/dots/install --secrets ~/fixture.zip.enc --dry-run | grep '^would:'
```
Expected: only `would: flatpak remote-add --user --if-not-exists flathub …` (a no-op by design) and
`would: … mise bootstrap -E desktop`. Then `mise bootstrap status -E desktop` shows nothing pending.

- [ ] **Step 5: Record the result**

Write the outcome of Steps 3–4 under "Findings"; fix any failure in the config or `install` (with a spec case
where it is testable), commit, revert the VM to the `clean` snapshot, and rerun Steps 3–4.

---

### Task 9: Docs

**Files:**
- Modify: `README.md` (the `## Install` section, lines 30–70)
- Modify: `assets/guides/DOCKER_GUIDE.md`
- Modify: `AGENTS.md`, `.agents/skills/dots-context/SKILL.md`

- [ ] **Step 1: Replace the README install section**

Replace everything from `## Install` up to (not including) `### OVEREVIEW` with:
````markdown
## Install

`install` prepares a machine (user, sudo, timezone, mise, this repo, secrets) and hands over to
[`mise bootstrap`](https://mise.jdx.dev/bootstrap.html), which applies `config/mise/conf.d/`: packages, links,
directories, login shell and the setup task. It runs on macOS and Debian/Ubuntu, in containers too, and a second
run changes nothing.

```sh
curl -fsSL https://raw.githubusercontent.com/roalcantara/dots/main/install | bash -s -- --secrets dots-secrets.zip.enc
```

| Option | Default | |
| --- | --- | --- |
| `--user <name>` | `roalcantara` | Target user; created when missing |
| `--secrets <archive>` | — | Encrypted archive from `mise run prepare` (passphrase prompted, or `DOTS_SECRETS_PASSPHRASE`) |
| `--tz <zone>` | — | Timezone to set |
| `--nopasswd` | on in containers | Passwordless sudo for the user |
| `--branch <ref>` | `main` | Branch to clone |
| `-E <profile>` | `desktop` on hosts, `container` in containers | `desktop` adds workstation-only entries (GUI apps, heavy toolchains); flatpak on Linux |
| `--dry-run` | — | Print what would change; change nothing |

Make the secrets archive on a machine that has the keys: `mise run prepare -- --output <file>`. It holds the
age key, `~/.config/ssh`, `~/.config/gnupg`, `gh` hosts and a GitHub token, encrypted with AES-256. Keep its
passphrase in Bitwarden. `mise run prepare -- --fixture` makes a throwaway archive for tests.

Later runs: `~/.local/share/dots/install`, or `mise bootstrap` directly.

````

- [ ] **Step 2: Update the Docker guide**

In `assets/guides/DOCKER_GUIDE.md`:
1. Lines 26–27: replace "`../../install` and `../../config/flox`" with "`../../install`".
2. The targets table (lines 52–54) becomes:
```markdown
| `local` | `git archive HEAD` (SOPS files kept encrypted) copied to `~/Work/dots`; run `./install` — commit first |
| `remote` | `curl` `install` from GitHub; default for CI and production-like builds |
| `publish` | Same as `local`, tagged for Docker Hub |
```
3. Line 57: remove "`, `PACKAGE_MANAGER` (default `flox`)".
4. Delete the paragraph starting "Both disable Nix syscall filtering" (line 59 and its continuation).
5. The second targets table (lines 79–81): `local` and `publish` rows say "`git archive HEAD` + `./install`".
6. Replace the "**Local** sets `DOTS_EMBEDDED=1`…" and "**Publish** optimizes layer caching…" paragraphs
   (lines 86–97) with: "**Local** and **publish** build from `git archive HEAD` with the SOPS smudge filter
   disabled, so encrypted files stay encrypted in the image; uncommitted changes are not included. `install`
   runs as root, creates the user, grants passwordless sudo and runs `mise bootstrap -E container --skip user`
   as that user. Images never receive a secrets archive, only `GITHUB_TOKEN` from the `github_token` build
   secret."
7. Delete the `--package-manager` row of the build flags table (line 121).
8. Delete the whole `## Flox in the image` section (from line 181 to the next `##` heading).

- [ ] **Step 3: Update agent guides**

In `AGENTS.md` and `.agents/skills/dots-context/SKILL.md`, delete the line
`- \`flox-environments\` — when editing config/flox or Flox environments` (and its table row in the skill),
and in `.agents/skills/dots-context/SKILL.md` replace the `| **Flox** | Declarative env in config/flox/flox.toml |`
row with `| **mise bootstrap** | Machine setup in config/mise/conf.d/, entered through install |`.

- [ ] **Step 4: Lint and commit**

```bash
cd ~/Work/dots && hk check --all
git add README.md assets/guides/DOCKER_GUIDE.md AGENTS.md .agents/skills/dots-context/SKILL.md
git commit -m "docs: Describe install, prepare and mise bootstrap"
```

---

### Task 10: macOS guest in Parallels (with the owner)

**Files:** none; findings go under "Findings".

- [ ] **Step 1: Create the guest**

Parallels → New → "Install macOS from the recovery partition" (or the current IPSW); 4 cores, 8 GB, 128 GB.
Complete Setup Assistant with a user named `roalcantara`; sign in to the Apple Account if the VM allows it.
Run `xcode-select --install`. Snapshot `clean`.

- [ ] **Step 2: Run the runbook (design.md §6) with the fixture archive**

Copy `/tmp/fixture.zip.enc` (Task 8 Step 2) into the guest's home, then:
```bash
export DOTS_SECRETS_PASSPHRASE=dots-fixture GITHUB_TOKEN=<token>
curl -fsSL https://raw.githubusercontent.com/roalcantara/dots/feat/mise-bootstrap/install \
  | bash -s -- --branch feat/mise-bootstrap --secrets ~/fixture.zip.enc
```
Expected: it completes; casks and formulae install; `~/.config` entries are links; `~/.config/ssh` is a real
folder with mode 700 and files 600; `~/.local/share/dots` → `~/Work/dots`; login shell is zsh.

- [ ] **Step 3: Check idempotency**

Run: `~/.local/share/dots/install --secrets ~/fixture.zip.enc --dry-run | grep '^would:'`
Expected: only `would: … mise bootstrap`. Then `mise bootstrap status` shows nothing pending.

- [ ] **Step 4: Check services flagged in Task 3 Step 4**

For each, confirm it runs or note how it must be started; add a `[bootstrap.macos.launchd.agents]` entry or a
`[tasks.bootstrap]` line where needed, then commit with `fix(mise): …`.

---

### Task 11: Reinstall this Mac, then delete the old pieces

**Files:**
- Delete: `config/flox/`, `config/bin/purge_flox`, `config/homebrew/`, `config/apt/`, `config/flatpak/`, `config/snap/`

- [ ] **Step 1: Reinstall and run the runbook**

Merge `feat/mise-bootstrap` into `main`, then follow design.md §6 on the reinstalled Mac with
`--secrets /Volumes/meex900/backups/dots-secrets.zip.enc` (the real archive from Task 4 Step 6).

- [ ] **Step 2: Delete the old pieces**

```bash
cd ~/Work/dots && git rm -r config/flox config/bin/purge_flox config/homebrew config/apt config/flatpak config/snap
```

- [ ] **Step 3: Remove their links and references**

Remove `"flox"`, `"apt"`, `"flatpak"`, `"snap"` from the `exclude` list in `config/mise/conf.d/dotfiles.toml`
(they no longer exist), then:
```bash
cd ~ && rm -f ~/.config/homebrew && mise dot status | head -5
cd ~/Work/dots && git grep -nE 'flox|Brewfile|config/homebrew' -- ':!CHANGELOG.md' ':!assets/specs'
```
Expected: `git grep` prints nothing; fix any line it prints.

- [ ] **Step 4: Commit**

```bash
cd ~/Work/dots && git add config/mise/conf.d/dotfiles.toml && git commit -m "refactor: Remove flox, the Brewfile and the old package lists"
```

---

## Findings

Record here what each task's checks show (one line each): conf.d loading, `~` in `source`, link forms, the
macOS-only formula count, installed-but-undeclared formulae and the owner's decision, Homebrew services, Linux
formulae moved behind `env = "desktop"`, Docker Hub tags from the old stages, the Ubuntu VM run.
- Task 1: `/tmp/links-before.txt` has 77 links, not about 64. Link form mise would write was not observable without apply.
- Task 1: `[dotfiles]` in a `conf.d` file loads (mise 2026.10.21); multi-line inline tables parse.
- Task 1: `~` expands in `source` (no missing-source error), so the `{{env.HOME}}` fallback is not needed.
- Task 1: `symlink-each` links every file recursively (1394 under config/), so `~/.config` has one `symlink` entry per config/ entry; it stays only for `~/.local/bin`.
- Task 1: the file has 43 entries (36 `~/.config/<name>`, `~/.config/kb`, 5 `$HOME` links, `~/.local/bin`); `mise dot status` reports 36 up to date and 7 not.
- Task 1: delta not linked: config/delta holds only a git-ignored .env.
- Task 1: 5 missing (`claude`, `dinky`, `github`, `npm`, `tombi`): this Mac never linked them.
- Task 1: `~/.config/cog` differs only in form (absolute link to `~/Work/dots/config/cog`, relative requested; same target).
- Task 1: `~/.local/bin` differs (17 linked, 2 missing); apply would remove 6 stale links (`keyring`, `osx`, `xc-foo`, `xc-skills`, `xc-usage`, `yw`), all broken links to scripts no longer in `config/bin`, so the removal is correct cleanup.
- Task 2: empty `[bootstrap.directories."..."]` tables parse and default to mode 0755, which would loosen the macOS private folders; the seven (`~/Desktop`, `Documents`, `Downloads`, `Movies`, `Music`, `Pictures`, `~/.cache/zsh`) are pinned to 0700.
- Task 2: all 18 directories parse; only `~/Projects` is `create`, the rest unchanged; the `bootstrap` task is listed by `mise tasks ls`.
- Task 2: `login_shell = "zsh"` resolves via PATH to Homebrew's `/opt/homebrew/bin/zsh` (apt's on Linux), the canonical shell; this Mac's `/usr/local/bin/zsh` shows `differs`, which is expected.
- Task 3: converter gave 84 `brew:` (one is Linux `ollama`), 38 `brew-cask:`, 62 `os = "macos"`; the Brewfile lists `mole` twice (duplicate TOML key), so the second copy and its comment were removed: 83 `brew:`, 59 macOS-only (after git-delta and node were found to have Linux bottles).
- Task 3: installed but not in the Brewfile, owner chose not to add: block-goose-cli, dust, deja, ncdu (mise is provided by install).
- Task 3: Homebrew services running here: none.
- Task 3: `packages status`: 119 installed, 10 skipped (Linux flatpaks), 1 missing: `brew-cask mark-text`.
- Task 3: `mise ls --missing`: `go:golang.org/x/tools/gopls`, `go:mvdan.cc/gofumpt`, `pipx:debugpy` (versions resolved); the four `go-code-graph` tools timed out resolving (3s); `graphifyy` and `code-review-graph` are already installed.
- Task 3: delta and nodejs were Homebrew aliases; renamed to git-delta and node. The Brewfile listed mole twice (duplicate dropped). Both have Linux bottles, so they are not macOS-only.
- Task 3: WhatsApp flatpak ID `io.github.mimbrero.WhatsAppDesktop` (not on Flathub) replaced by `com.rtosta.zapzap` (verified on Flathub); the unused taps table was removed.
- Task 3: 8 GNU/apt duplicates (bash, coreutils, findutils, gawk, gnu-sed, less, git, zsh) are now macOS-only; 12 heavy formulae are `env = "desktop"` (openjdk, rust, mermaid-cli, cairo, lua-language-server, fabric-ai, pup, wakatime-cli, bbrew, python@3.14, ruby-lsp, solargraph); macOS-only count is now 65, `env = "desktop"` lines 15.
- Task 3: `packages status` without `-E`: 107 installed, 10 skipped, 12 desktop entries not listed, only `mark-text` missing; with `-E desktop`: 119 installed, only `mark-text` missing.
- Design: desktop profile = workstations; install defaults hosts to it.
- Task 4: `mise run prepare --help` is intercepted by mise (prints the task help); `mise run prepare -- --help` reaches the script (use `--` for options). Spec failed first (2 of 3, exit 127), then passed 3/3; shellcheck clean; works under /bin/bash 3.2.57; fixture .enc is unreadable by unzip, a second run yields a different ssh key; no staging leftovers. Step 6 (real archive) skipped: owner-interactive.
- Task 4: Output is atomic and owner-only: encrypted in a work folder, then `mv -f` and `chmod 600` onto `--output`; INT/TERM/HUP exit 130/143 and the EXIT trap cleans both folders.
- Task 4: `zip -y` (store links) cannot write to a pipe ("zip -0 not supported for I/O on pipes"), so the zip goes to a file in the work folder before `openssl enc`.
- Task 4: Staged links must resolve inside the archive (absolute or missing targets exit 1 with `is a link to`); ssh/ and gnupg/ copies skip `S.*`, `s.*`, `.#lk*`, `random_seed`, `*~`.
- Task 4: The fixture forces the passphrase `dots-fixture` over any ambient value; `openssl enc` pins `-md sha256` (spec and Task 5 decrypt updated); it has no authentication, noted in the script. 8 tests now.
- Task 5: Spec failed first on the old `install` (0 pass, 10 fail; every spec invocation starts with an option the old parser rejects with exit 1 before any setup, so the run was safe); then 18/18 passed (8 prepare-secrets + 10 install); shellcheck clean, `/bin/bash` 3.2.57 syntax ok; fake-HOME dry run ends with `would: <tmp>/.local/bin/mise bootstrap -E desktop`; real-home dry run reports user exists and both links `is linked`. Step 6 (real archive and passphrase) skipped: owner-interactive.
- Task 6: Step 0 (Docker Hub check) left unticked for the owner. Dockerfiles rewritten; Ubuntu differs from Debian in two lines. Both CST files: FLOX block replaced by MISE, `.bashrc` now a symlink, `.config` a dir, six XDG dirs and `~/.cache/zsh` 0700 (Ubuntu keeps its own `~/` mode). `mise.toml` build: group and package-manager flags removed, no leftover `usage_group`/`PACKAGE_MANAGER`/`GROUPNAME`; local/publish pipe `git archive` into `docker build ... -`. Check: the archive of `config/ssh/keys/id_ed25519_github.key` starts with SOPS JSON (`"data": "ENC[AES256_GCM`), not the OpenSSH header. Deviation: `# hadolint ignore=DL4006` added to the remote stage (hadolint does not see the base stage's pipefail SHELL; plan block synced). Risk for Task 7: `install --tz` validates against `/usr/share/zoneinfo`; devcontainers base images are expected to ship tzdata, unverified. `hk check --all` fails on unrelated pre-existing shfmt diffs (config/nvim, config/raycast scripts), aborting other steps; hadolint and yamllint pass on their own.
- Task 5 review: `--tz` and `--branch` are validated (exit 2); root commands take values as `sh -c` arguments, never interpolated; the root-to-user switch writes the running code (`declare -f`) to `/tmp/dots-install.*` and hands the user an owned copy of the secrets and `GITHUB_TOKEN` in `/tmp/dots-secrets.*`; one `cleanup` list removes every temp path; apt updates once and installs non-interactively; the passphrase is unset after opening. Now 24 tests (8 + 16), including a real run in a fake checkout and home with a stub `mise`.
- Task 5 review: deviation: the "run as root or as <user>" check in `detect` is skipped under `--dry-run`, so a dry run for another user still plans the user and stops at `would: continue as <user>` (an existing spec case). Linux paths (apt, sudo switch) are untested here; the regenerated script was checked by running it as the user stage on this Mac.
- Task 5 review: copy_secret_dir keeps `umask 077` in the script (not a subshell) so the dry-run line stays `would: cp -R src dst`; `find` fixes the modes.
- Task 5 re-review: the root stage chowns the handed-over script and `cleanup` tolerates failures; before `exec` it removes every other root temp (secrets_tmp, sudoers tmp). The user stage trusts `DOTS_SECRETS` and `$0` only by exact mktemp names (`/tmp/dots-secrets.XXXXXX`, `/tmp/dots-install.XXXXXX`), a real folder owned by the user, and removes neither under `--dry-run`. The switch forwards `DOTS_CONTAINER=<1|0>` and appends `-E <profile>` unless given.
- Task 5 re-review: deviation: `DOTS_CONTAINER` is not unset in a first stage, because it is a documented override (specs and users set it); the other three handoff variables are. `DOTS_INSTALL_EMIT_SCRIPT=<file>` (dry run only) writes the script `switch_to_user` would hand over, so a spec runs that exact code as the user stage. Now 27 tests (8 + 19).
