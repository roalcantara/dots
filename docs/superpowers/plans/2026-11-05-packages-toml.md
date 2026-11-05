# One packages.toml for every package — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `config/homebrew/Brewfile` and `config/mise/conf.d/system.toml` with one `config/mise/conf.d/packages.toml`, using mise's built-in managers plus three in-repo package-manager plugins (`cask:`, `uv:`, `npm:`) that call real Homebrew, uv and npm.

**Architecture:** `[bootstrap.packages]` holds every entry; entries without `env` are the minimal (container) set, the rest carry `{ env = "desktop" }`. The plugins live in `config/mise/plugins/<name>/` (Lua: `PackageInstalled` + `PackageInstall`). Homebrew itself is installed by a bootstrap hook; the plugins run once their host program (`brew`, `uv`, `npm`) exists.

**Tech Stack:** mise bootstrap (packages, hooks, package-manager plugins in Lua), Homebrew, uv, npm, Bun `bun:test`, Docker + container-structure-test.

Spec: [`docs/superpowers/specs/2026-11-05-packages-toml-design.md`](../specs/2026-11-05-packages-toml-design.md).

---

## Ground rules

- Work in `~/Work/dots` on branch `feat/mise-packages` (owner's choice; note `~/.local/share/dots` → `~/Work/dots`, so
  edits are live on this Mac: do not run `mise bootstrap` or `mise bootstrap packages apply` on the Mac outside the
  steps that say so).
- Git: `g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }` for reads and for commits that touch no
  SOPS file (none in this plan). Stage named paths only. Conventional Commits, subject ≤ 50 chars.
- Never print secrets. No push, no PR.
- Spikes run in throwaway containers or a scratch `HOME`/`MISE_CONFIG_DIR`, never against the real config.

## File structure

| Path | Change | Responsibility |
| --- | --- | --- |
| `config/mise/plugins/cask/` | Create | `cask:` manager: real `brew install/upgrade --cask` |
| `config/mise/plugins/uv/` | Create | `uv:` manager: `uv tool install/upgrade` |
| `config/mise/plugins/npm/` | Create | `npm:` manager: `npm install -g <pkg>@latest` |
| `config/mise/conf.d/packages.toml` | Create | Every package (from the Brewfile and system.toml) |
| `config/mise/conf.d/system.toml` | Delete | Merged into packages.toml |
| `config/homebrew/Brewfile` | Delete | Replaced |
| `config/mise/conf.d/bootstrap.toml` | Modify | Homebrew install hook; plugin pass; drop brew bundle + reminder |
| `test/integration/packages/plugins.spec.ts` | Create | Plugin hooks against stub `brew`/`uv`/`npm` |
| `test/integration/packages/packages-toml.spec.ts` | Create | packages.toml shape checks |
| `test/integration/bootstrap/post-packages.spec.ts` | Delete | Tested the removed hook |
| `test/mise.toml` | Modify | Add the `packages` domain to `integration … all` and `test:specs` |
| `.github/workflows/preview.yml` | Modify | "Brewfile parses" → "packages.toml parses" |
| `distros/*/container-structure-test.yml`, docs, shell rc files, `script/backup.ts`, `config/restic/backup.toml`, `config/vscode/settings.json` | Modify | Drop Brewfile references |

---

### Task 0: Baseline

- [ ] `cd ~/Work/dots && git status --short` is empty; `g log --oneline origin/main..HEAD` shows the 5 branch commits.
- [ ] Record counts: `cd test && for d in bin backup bootstrap agents hooks; do bun test integration/$d 2>&1 | grep -E '^\s*[0-9]+ (pass|fail)'; done`
  (known: 2–3 `xc-git fixup-suggest` failures in `bin`), and `hk check --all`.

### Task 1: Spikes (decision gate — STOP and report before Task 2)

Work dir: `S=$(mktemp -d "${TMPDIR:-/tmp}/pkg-spike.XXXX")`. Linux spikes in a fresh container:
`docker run --rm -it -v "$S:/spike" --entrypoint bash ubuntu:26.04` (or the repo's `dots:ubuntu-*` base if 26.04 is
unavailable) with `apt-get update && apt-get install -y curl ca-certificates sudo` and mise installed by
`curl -fsSL https://mise.run | MISE_VERSION=v2026.10.22 sh` (the version `install` pins; repeat S1/S2 with the latest
mise if they fail).

A minimal plugin for the spikes, `$S/plugins/echo/`:

```lua
-- metadata.lua
PLUGIN = { name = "echo", version = "0.0.1", description = "spike" }
```

```toml
# mise.plugin.toml
[package-manager]
requires = ["uv"]
supports_version_pins = false
```

```lua
-- hooks/package_installed.lua
function PLUGIN:PackageInstalled(ctx)
  local out = {}
  for _, p in ipairs(ctx.packages) do table.insert(out, { name = p.name, state = "missing" }) end
  return { packages = out }
end
```

```lua
-- hooks/package_install.lua
local cmd = require("cmd")
function PLUGIN:PackageInstall(ctx)
  for _, p in ipairs(ctx.packages) do cmd.exec('echo "installed $PKG" >> /tmp/echo.log', { env = { PKG = p.name } }) end
end
```

| # | Question | How | Record |
| --- | --- | --- | --- |
| S4 | How is an in-repo plugin declared? | Try, in order, in a scratch config: `[bootstrap.plugins] echo = "file://$S/plugins/echo"`, `echo = "$S/plugins/echo"`, then `mise plugins link echo "$S/plugins/echo"` with no `[bootstrap.plugins]`. Each time: `mise bootstrap packages status` with `"echo:x" = "latest"` | The form that lists `echo:x` |
| S6 | What does mise do with a plugin entry whose `requires` program is missing? | `requires = ["uv"]` with no uv on PATH; `mise bootstrap packages apply` | skipped (and exit code) vs error |
| S1 | Same run: do `brew:uv`/`brew:node` install before plugins that require them? | Scratch config: `"brew:uv" = "latest"`, `"echo:x" = "latest"`; clean container; one `mise bootstrap packages apply` | Did `/tmp/echo.log` get a line in the first run? |
| S7 | Does mise's `brew:` work on Linux before real Homebrew exists? | Same container, before any Homebrew install | Installs (where?) or fails |
| S2 | Does one failing package stop the run? | Add `"brew:definitely-not-a-formula" = "latest"` with `"brew:jq" = "latest"` | jq installed? exit code? message |
| S3 | Third-party taps (`oven-sh/bun`) | `[bootstrap.brew.taps] "oven-sh/bun" = "https://github.com/oven-sh/homebrew-bun.git"`, `"brew:oven-sh/bun/bun" = "latest"` | Installs, or the trust error and the documented key that fixes it |
| S5 | Arch-specific entry | `mise bootstrap packages --help` and the packages docs for an `arch` key; try `"flatpak:com.discordapp.Discord" = { arch = "x64" }` with `status` | Accepted key, or rejected |

- [ ] Run each spike; write the results into a "Spike results" table appended to the spec (§5), one row per spike.
- [ ] **Decide the hook layout** from S1/S6/S7 and write it into the spec §4.3:
  - **Layout P (pass-through):** S1 yes → Homebrew installed in a `pre-packages` hook is enough *only if* its
    prerequisites exist; since `apt:` prerequisites install in the same phase, layout P needs S7 (mise's `brew:` works
    without Homebrew) or a `pre-packages` hook that installs Homebrew's apt prerequisites itself.
  - **Layout Q (second pass, expected):** S6 = skipped → keep installing Homebrew in `post-packages`, then in the same
    hook run `mise bootstrap packages apply` again so the `cask:`, `uv:`, `npm:` managers (now available) install.
- [ ] If S2 shows one failure stops everything with no option to continue, or S4 has no working form: **stop and
  report**; do not start Task 2. In the report, say whether the spec's §5.1 fallback applies (pinned `[tools]` with a
  lockfile for uv/npm; a hook for casks) so the owner can choose it without another design round.
- [ ] Commit the spec update: `g add docs/superpowers/specs/2026-11-05-packages-toml-design.md && g commit -m "docs(specs): Record the packages.toml spikes"`.

### Task 2: The plugins (TDD)

**Files:** `config/mise/plugins/{cask,uv,npm}/{metadata.lua,mise.plugin.toml,hooks/package_installed.lua,hooks/package_install.lua}`, `test/integration/packages/plugins.spec.ts`, `test/mise.toml`.

- [ ] **Step 1: Failing spec.** It writes a scratch mise config that declares the three plugins (S4 form) with one
  entry each, puts stub `brew`/`uv`/`npm` first on `PATH`, and runs `mise bootstrap packages status` and
  `mise bootstrap packages apply` with `HOME`, `MISE_CONFIG_DIR`, `MISE_DATA_DIR`, `MISE_STATE_DIR`,
  `MISE_CACHE_DIR` in a temp dir. Each stub appends its arguments to `$STUB_LOG` and answers the read commands:

```ts
#!/usr/bin/env bun
// The cask:, uv: and npm: package-manager plugins, driven by mise against stub brew/uv/npm.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const PLUGINS = join(import.meta.dir, "../../../config/mise/plugins");
const mise = Bun.which("mise") as string;

// brew: `list --cask --versions` prints "zed 1.0"; install/upgrade log their args.
const STUBS: Record<string, string> = {
  brew: `#!/bin/sh\necho "brew $*" >> "$STUB_LOG"\n[ "$1 $2 $3" = "list --cask --versions" ] && echo "zed 1.0"\nexit 0\n`,
  uv: `#!/bin/sh\necho "uv $*" >> "$STUB_LOG"\n[ "$1 $2" = "tool list" ] && printf 'pynvim v0.6.0\\n- pynvim-python\\n'\nexit 0\n`,
  npm: `#!/bin/sh\necho "npm $*" >> "$STUB_LOG"\ncase "$*" in "ls -g --depth=0 --json") echo '{"dependencies":{"react-devtools":{"version":"6.0.0"}}}' ;; esac\nexit 0\n`,
};

let t: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "pkg-plugins-"));
  mkdirSync(join(t, "bin"));
  for (const [n, body] of Object.entries(STUBS)) { writeFileSync(join(t, "bin", n), body); chmodSync(join(t, "bin", n), 0o755); }
  mkdirSync(join(t, "config"));
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function run(packages: string, args: string[]) {
  // PLUGIN_DECL is the S4 form; replace this function body's declaration if S4 chose `mise plugins link`.
  const decl = ["cask", "uv", "npm"].map((p) => `${p} = "${join(PLUGINS, p)}"`).join("\n");
  writeFileSync(join(t, "config", "config.toml"), `[bootstrap.plugins]\n${decl}\n\n[bootstrap.packages]\n${packages}\n`);
  const p = Bun.spawnSync([mise, "bootstrap", "packages", ...args], {
    env: {
      PATH: `${join(t, "bin")}:/usr/bin:/bin`, HOME: t, STUB_LOG: join(t, "log"), MISE_YES: "1",
      MISE_CONFIG_DIR: join(t, "config"), MISE_DATA_DIR: join(t, "data"), MISE_STATE_DIR: join(t, "state"), MISE_CACHE_DIR: join(t, "cache"),
    },
    stdout: "pipe", stderr: "pipe", timeout: 60_000,
  });
  let log = ""; try { log = readFileSync(join(t, "log"), "utf8"); } catch {}
  return { code: p.exitCode, out: p.stdout.toString() + p.stderr.toString(), log };
}

describe("cask: plugin", () => {
  it("reports an installed cask and installs a missing one with real brew", () => {
    const r = run('"cask:zed" = "latest"\n"cask:codex" = "latest"', ["apply"]);
    expect(r.code).toBe(0);
    expect(r.log).toContain("brew install --cask codex");
    expect(r.log).not.toContain("brew install --cask zed");
  });
});

describe("uv: plugin", () => {
  it("installs a missing tool and leaves an installed one", () => {
    const r = run('"uv:pynvim" = "latest"\n"uv:debugpy" = "latest"', ["apply"]);
    expect(r.code).toBe(0);
    expect(r.log).toContain("uv tool install debugpy");
    expect(r.log).not.toContain("uv tool install pynvim");
  });
});

describe("npm: plugin", () => {
  it("installs a missing global at latest and leaves an installed one", () => {
    const r = run('"npm:react-devtools" = "latest"\n"npm:bun-dap-x" = "latest"', ["apply"]);
    expect(r.code).toBe(0);
    expect(r.log).toContain("npm install -g bun-dap-x@latest");
    expect(r.log).not.toContain("npm install -g react-devtools");
  });
  it("handles scoped packages", () => {
    const r = run('"npm:@vscode/js-debug-browsers" = "latest"', ["apply"]);
    expect(r.log).toContain("npm install -g @vscode/js-debug-browsers@latest");
  });
});

describe("failures", () => {
  it("a failing install fails the apply", () => {
    writeFileSync(join(t, "bin", "uv"), `#!/bin/sh\n[ "$1 $2" = "tool list" ] && exit 0\nexit 3\n`);
    const r = run('"uv:debugpy" = "latest"', ["apply"]);
    expect(r.code).not.toBe(0);
  });
});
```

  If a package name needs quoting in TOML keys (`"npm:@vscode/js-debug-browsers"`), keep the key quoted as above.
  Add `packages` to the domains loop in `test/mise.toml` (`for domain in backup bootstrap agents hooks packages`).

- [ ] **Step 2:** `cd test && bun test integration/packages/plugins.spec.ts` → FAIL (no plugins).
- [ ] **Step 3: Write the plugins.** Shared shape (shown for `uv`; `cask` and `npm` differ only in the commands and
  parsing, given below):

`config/mise/plugins/uv/metadata.lua`
```lua
PLUGIN = { name = "uv", version = "1.0.0", description = "uv tools (uv tool install), one version each" }
```

`config/mise/plugins/uv/mise.plugin.toml`
```toml
[package-manager]
requires = ["uv"]
supports_version_pins = false
```

`config/mise/plugins/uv/hooks/package_installed.lua`
```lua
local cmd = require("cmd")
function PLUGIN:PackageInstalled(ctx)
  -- `uv tool list` prints "<name> v<version>" per tool, then "- <executable>" lines.
  local have = {}
  for line in cmd.exec("uv tool list 2>/dev/null || true"):gmatch("[^\n]+") do
    local name, version = line:match("^(%S+) v(%S+)")
    if name then have[name] = version end
  end
  local out = {}
  for _, p in ipairs(ctx.packages) do
    if have[p.name] then table.insert(out, { name = p.name, state = "installed", version = have[p.name] })
    else table.insert(out, { name = p.name, state = "missing" }) end
  end
  return { packages = out }
end
```

`config/mise/plugins/uv/hooks/package_install.lua`
```lua
local cmd = require("cmd")
function PLUGIN:PackageInstall(ctx)
  for _, p in ipairs(ctx.packages) do
    if ctx.dry_run then print("would install uv tool " .. p.name)
    else cmd.exec('uv tool install "$PKG"', { env = { PKG = p.name } }) end
  end
end
```

`cask` — `requires = ["brew"]`; installed: `brew list --cask --versions 2>/dev/null || true`, each line
`^(%S+) (%S+)`; install: `brew install --cask "$PKG"`.
`npm` — `requires = ["npm"]`; installed: `npm ls -g --depth=0 --json 2>/dev/null || true`, parsed with
`require("json").decode(out).dependencies` (name → `.version`); install: `npm install -g "$PKG@latest"`.

  If `cmd.exec` does not raise on a non-zero exit (check in Step 4's failure test), wrap each install:
  `local ok, err = pcall(cmd.exec, …); if not ok then error(err) end` or check the documented return.
  `--update` (`ctx.update`) runs the same hook: add `package_upgrade.lua` per plugin with `uv tool upgrade "$PKG"`,
  `brew upgrade --cask "$PKG"`, `npm install -g "$PKG@latest"`.

- [ ] **Step 4:** run the spec → all pass; `hk check` (stylua/luacheck if configured, else none for Lua).
- [ ] **Step 5:** commit: `g add config/mise/plugins test/integration/packages/plugins.spec.ts test/mise.toml && g commit -m "feat(mise): Add cask, uv and npm package plugins"`.

### Task 3: packages.toml

**Files:** create `config/mise/conf.d/packages.toml`, `test/integration/packages/packages-toml.spec.ts`; delete `config/mise/conf.d/system.toml`.

- [ ] **Step 1: Generate a draft** with a one-off script (not committed) that maps the Brewfile line by line:

```bash
python3 - <<'EOF' > /tmp/packages.draft.toml
import re
desktop = False
for raw in open("config/homebrew/Brewfile"):
    line = raw.rstrip("\n")
    if line.startswith("return unless desktop"): desktop = True; continue
    m = re.match(r'^(brew|cask|uv|npm|flatpak) "([^"]+)"(.*)$', line)
    if not m:
        if line.startswith("#"): print(line)
        continue
    kind, name, rest = m.groups()
    comment = rest.split("#", 1)[1].strip() if "#" in rest else ""
    mac = "if OS.mac?" in rest
    intel = "Hardware::CPU.intel?" in rest
    mgr = {"brew": "brew", "uv": "uv", "npm": "npm", "flatpak": "flatpak"}.get(kind)
    if kind == "cask":
        mgr = "brew-cask" if (mac or name.startswith("font-")) else "cask"
    opts = []
    if desktop: opts.append('env = "desktop"')
    if kind == "brew" and mac: opts.append('os = "macos"')
    val = "{ " + ", ".join(opts) + " }" if opts else '"latest"'
    key = f'"{mgr}:{name}"'
    tail = f"  # {comment}" if comment else ""
    if intel: tail += "  # Flathub builds it for x86_64 only (spike S5)"
    print(f"{key} = {val}{tail}")
EOF
```

  Then assemble `packages.toml`: a header comment; `[bootstrap.brew.taps]` (the 3 Brewfile taps plus
  `xykong/tap` = `https://github.com/xykong/homebrew-tap.git`, and the trust key from S3 if any);
  `[bootstrap.plugins]` (S4 form, paths `~/.local/share/dots/config/mise/plugins/<name>`); `[bootstrap.packages]`:
  first the `system.toml` entries (apt, flatpak, fonts — fonts already `brew-cask:`), then the draft. Remove the
  duplicate font lines (they are in both). Apply S5 to Discord. Keep `cask_args appdir` out (mise installs to
  `/Applications`; confirm in S-run on the Mac with `status`).

- [ ] **Step 2: Shape spec** `test/integration/packages/packages-toml.spec.ts`:

```ts
#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const cfg = Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/packages.toml"), "utf8")) as {
  bootstrap: { packages: Record<string, unknown>; plugins?: Record<string, unknown> };
};
const pkgs = Object.entries(cfg.bootstrap.packages);
const MANAGERS = ["apt", "brew", "brew-cask", "flatpak", "cask", "uv", "npm"];
const minimal = pkgs.filter(([, v]) => typeof v === "string" || !(v as { env?: string }).env).map(([k]) => k);

describe("packages.toml", () => {
  it("is the only package list", () => {
    expect(existsSync(join(REPO, "config/homebrew/Brewfile"))).toBe(false);
    expect(existsSync(join(REPO, "config/mise/conf.d/system.toml"))).toBe(false);
  });
  it("every entry uses a known manager", () => {
    for (const [k] of pkgs) expect(MANAGERS).toContain(k.split(":")[0]);
  });
  it("no package is declared twice", () => {
    const names = pkgs.map(([k]) => k);
    expect(new Set(names).size).toBe(names.length);
  });
  it("declares the three plugins", () => {
    for (const p of ["cask", "uv", "npm"]) expect(Object.keys(cfg.bootstrap.plugins ?? {})).toContain(p);
  });
  it("the minimal set is the container shell set plus Homebrew's apt prerequisites", () => {
    for (const k of ["brew:zoxide", "brew:fzf", "brew:eza", "brew:bat", "brew:ripgrep", "brew:fd", "brew:jq", "brew:neovim", "brew:git-delta", "apt:git", "apt:curl"]) expect(minimal).toContain(k);
    expect(minimal.filter((k) => !k.startsWith("apt:")).length).toBe(9);
  });
});
```

- [ ] **Step 3:** delete `config/homebrew/Brewfile` and `config/mise/conf.d/system.toml` (`g rm`); run the spec → pass.
- [ ] **Step 4: Mac check (read-only):** `MISE_ENV=desktop mise bootstrap packages status` lists every desktop entry
  as installed (or names the few that are not). Anything unexpected: stop and report.
- [ ] **Step 5:** commit `feat(packages): Move every package to packages.toml`.

### Task 4: Bootstrap hooks

**File:** `config/mise/conf.d/bootstrap.toml`; delete `test/integration/bootstrap/post-packages.spec.ts`.

- [ ] Replace the `[bootstrap.hooks.post-packages]` body (layout Q; adapt per Task 1's decision) with: find or install
  Homebrew (the current lines up to `export HOMEBREW_NO_AUTO_UPDATE…`, unchanged), then
  `mise bootstrap packages apply` (the plugin managers are now available). Drop everything about
  `HOMEBREW_BUNDLE_FILE`, `bundle()`, profiles, `brew-bundle.*`, `DOTS_STRICT`. Keep the container cleanup:
  `if [ "${MISE_ENV:-}" = container ]; then brew cleanup --prune=all || true; rm -rf "$HOME/.cache/Homebrew"; fi`.
- [ ] In `[tasks.bootstrap]`: remove the `failed_file=…`/`remind`/`trap remind EXIT` block and its comment.
- [ ] Update the Flathub comment that names the Brewfile (line ~152) to name packages.toml.
- [ ] `g rm test/integration/bootstrap/post-packages.spec.ts`; `cd test && bun test integration/bootstrap` → pass.
- [ ] Commit `refactor(bootstrap): Install packages through mise only`.

### Task 5: References and docs

- [ ] `rg -n 'Brewfile|HOMEBREW_DOTS_PROFILE|HOMEBREW_BUNDLE_FILE|brew-bundle|brew bundle' -g '!docs/superpowers/**' -g '!CHANGELOG.md'`
  and fix every hit: `README.md`, `AGENTS.md` (layout table), `docs/DOCKER.md`, `docs/REINSTALL.md`,
  `config/zsh/opt/rc.d/env.zsh` and `config/bash/bashrc` (drop the `HOMEBREW_BUNDLE_FILE` export),
  `config/vscode/settings.json` (file association), `config/restic/backup.toml` and `script/backup.ts` (the audit's
  `brew bundle check` → `mise bootstrap packages status`; update `test/integration/backup` expectations if they
  assert the command), `config/kodexb/sources/*.yml` (text only).
- [ ] Re-run the rg: only CHANGELOG and old specs/plans may still match.
- [ ] Commit `docs: Describe packages.toml`.

### Task 6: CI and container tests

- [ ] `.github/workflows/preview.yml`: replace the "Brewfile parses (desktop and container)" job with
  "packages.toml parses": install mise, then `MISE_ENV=desktop mise bootstrap packages status` and
  `MISE_ENV=container mise bootstrap packages status` with `MISE_CONFIG_DIR=$GITHUB_WORKSPACE/config/mise`.
- [ ] `distros/{debian,ubuntu}/container-structure-test.yml`: replace any Brewfile path check with packages.toml.
- [ ] Commit `ci: Check packages.toml instead of the Brewfile`.

### Task 7: Verification

- [ ] All domains: counts vs Task 0, plus the new `packages` specs; `hk check --all`.
- [ ] `mise run build --local --distro ubuntu --tag pkgs` then
  `mise run test --image dots:ubuntu-pkgs --config distros/ubuntu/container-structure-test.yml` (AGENTS.md gate).
- [ ] Image size vs the baseline (`docker image ls dots`), noted in the report.
- [ ] Report commits, counts, spike results, the build/CST output, anything skipped.

### Task 8: Owner steps

1. On this Mac: `mise bootstrap -E desktop` installs nothing new; `mise bootstrap packages status` is all installed.
2. On a fresh Ubuntu VM: `install` from the branch (`DOTS_BRANCH=feat/mise-packages`); zed, claude-code, codex,
   copilot-cli install; `uv tool list` shows pynvim, debugpy, commit-check once each.
3. Push and open the PR when satisfied (title `feat(packages): …` to cut a release).
