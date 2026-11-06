# A `dev` profile on top of `desktop` — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `install` sets up `desktop`; `mise run setup dev` records and applies `desktop,dev`, which adds the Brewfile's `# DEVTOOLS` section, the agent skills restore and the Python 3.13 tools.

**Architecture:** The profile is a comma-separated list everywhere it is read (Brewfile via `HOMEBREW_DOTS_PROFILE`, the post-packages hook, the bootstrap task via `MISE_ENV`). A global `setup` task writes `miserc.local.toml` and runs `mise bootstrap -E <list>`.

**Tech Stack:** Homebrew Brewfile (Ruby), mise tasks/hooks (bash), `usage` args, Bun `bun:test`.

Spec: [`docs/superpowers/specs/2026-11-05-dev-profile-design.md`](../specs/2026-11-05-dev-profile-design.md).

---

## Ground rules

`~/Work/dots`, branch `fix/brew-sudo`. Git: `g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }`
(no SOPS files change here). Named paths only. No push until the owner says so (one PR for everything).

## Task 1: Open points (done 2026-11-05, scratch mise config)

- [x] P1: a task sees `MISE_ENV=desktop,dev` both with `-E desktop,dev` and from `miserc.local.toml`.
- [x] P2: a global `setup` task and the repo's `setup:age` coexist (`mise run setup dev`, `mise run setup:age`).
- [x] P3: the `<profile>` arg is `$usage_profile`; `choices` rejects other values.

## Task 2: Brewfile reads the profile as a list

**Files:** `config/homebrew/Brewfile` (owner's DEVTOOLS split is already in the working tree);
create `test/integration/bootstrap/brewfile-profiles.spec.ts`.

- [ ] **Failing spec:**

```ts
#!/usr/bin/env bun
// The Brewfile's groups per profile: HOMEBREW_DOTS_PROFILE is a comma-separated list (container | desktop | desktop,dev).
import { describe, expect, it } from "bun:test";
import { join } from "node:path";

const BREWFILE = join(import.meta.dir, "../../../config/homebrew/Brewfile");
const brew = Bun.which("brew");
const list = (profile: string) => {
  const p = Bun.spawnSync([brew as string, "bundle", "list", "--all", "--file", BREWFILE], {
    env: { ...process.env, HOMEBREW_DOTS_PROFILE: profile, HOMEBREW_NO_AUTO_UPDATE: "1" }, stdout: "pipe", stderr: "pipe",
  });
  return p.stdout.toString().split("\n");
};

describe.skipIf(!brew)("Brewfile profiles", () => {
  const container = list("container"), desktop = list("desktop"), dev = list("desktop,dev");
  it("minimal group everywhere", () => { for (const l of [container, desktop, dev]) expect(l).toContain("fzf"); });
  it("desktop entries for desktop and desktop,dev only", () => {
    expect(container).not.toContain("gopass");
    expect(desktop).toContain("gopass");
    expect(dev).toContain("gopass");
  });
  it("DEVTOOLS entries for desktop,dev only", () => {
    expect(desktop).not.toContain("shellcheck");
    expect(dev).toContain("shellcheck");
  });
  it("dev alone implies desktop", () => expect(list("dev")).toContain("gopass"));
});
```

- [ ] Run: fails (`desktop,dev` lists only the minimal group).
- [ ] Brewfile: replace the header's `desktop = ENV.fetch(…) == "desktop"` with

```ruby
# HOMEBREW_DOTS_PROFILE is the mise profile list (brew passes only HOMEBREW_* variables to a Brewfile):
# container gets the first group; desktop everything down to DEVTOOLS; dev (with desktop) everything.
profiles = ENV.fetch("HOMEBREW_DOTS_PROFILE", "desktop").split(",").map(&:strip)
dev = profiles.include?("dev")
desktop = dev || profiles.include?("desktop")
```

  and under `# DEVTOOLS` add `return unless dev`. Update the header comment lines 3–4.
- [ ] Run: passes. `HOMEBREW_DOTS_PROFILE=<p> brew bundle list --all --file config/homebrew/Brewfile` parses for all three.
- [ ] Commit: `feat(packages): Split the Brewfile into desktop and dev`.

## Task 3: post-packages hook passes the list

**Files:** `config/mise/conf.d/bootstrap.toml` (hook), `test/integration/bootstrap/post-packages.spec.ts`.

- [ ] **Failing tests** (append to `describe("post-packages hook", …)`):

```ts
  it("desktop,dev: passes the whole list to the full Brewfile run", () => {
    const r = hook({ MISE_ENV: "desktop,dev" });
    expect(r.code).toBe(0);
    expect(calls()).toEqual([`container ${join(t, "Brewfile")}`, `desktop,dev ${join(t, "Brewfile")}`]);
  });

  it("reads a two-env miserc.local.toml when MISE_ENV is unset", () => {
    mkdirSync(join(t, ".local", "share", "dots", "config", "mise"), { recursive: true });
    writeFileSync(join(t, ".local", "share", "dots", "config", "mise", "miserc.local.toml"), 'env = ["desktop", "dev"]\n');
    const r = hook({});
    expect(r.code).toBe(0);
    expect(calls()[1]).toBe(`desktop,dev ${join(t, "Brewfile")}`);
  });

  it("container in a list still stops after the core group", () => {
    const r = hook({ MISE_ENV: "container" });
    expect(calls()).toEqual([`container ${join(t, "Brewfile")}`]);
    expect(r.code).toBe(0);
  });
```

- [ ] Run: the miserc test fails (the sed reads one quoted value only).
- [ ] Hook changes: the miserc fallback becomes
  `profile="$(sed -n 's/^env *= *\[\(.*\)\].*/\1/p' "$HOME/.local/share/dots/config/mise/miserc.local.toml" | tr -d '" ' )"`
  (yields `desktop,dev`), and the container test becomes `case ",${profile}," in *,container,*) … exit 0 ;; esac`.
- [ ] Run: `bun test integration/bootstrap/post-packages.spec.ts` passes. Commit:
  `fix(bootstrap): Read the profile as a list in the hook`.

## Task 4: dev gates in the bootstrap task

**Files:** `config/mise/conf.d/bootstrap.toml` (`[tasks.bootstrap]`), `test/integration/bootstrap/skills-snippet.spec.ts`.

- [ ] Wrap the Python 3.13 loop and the skills block in markers that a spec can run: change the Python block to

```bash
# dev-python: begin
# Python tools that need 3.13 (no wheels for the newest Python); the Brewfile's uv entries cannot pin it. dev only.
if $dev; then
  for tool in graphifyy code-review-graph; do
    uv tool list 2>/dev/null | grep -q "^$tool " || uv tool install --python 3.13 "$tool" || warn "uv $tool"
  done
fi
# dev-python: end
```

  and the skills block body to run only `if $dev; then … fi`, keeping its `# skills: begin/end` markers outside the
  `if`. Next to `desktop=true …`, add:

```bash
dev=false
case ",${MISE_ENV:-desktop}," in *,dev,*) dev=true ;; esac
```

- [ ] Tests: in `skills-snippet.spec.ts`, the snippet now needs `dev`; prepend `dev=${DEV:-true}` to the evaluated
  script and add:

```ts
  it("does nothing without the dev profile", () => {
    const r = snippet({ DEV: "false" });
    expect(r.out).not.toContain("restoring agent skills");
    expect(existsSync(join(t, "calls"))).toBe(false);
  });
```

  (import `existsSync`). Add a `dev-python` spec in the same file: with `DEV=false` a stub `uv` is never called with
  `tool install`; with `DEV=true` it is, for both tools.
- [ ] Run: `bun test integration/bootstrap` passes. Commit: `feat(bootstrap): Run skills and Python tools only for dev`.

## Task 5: `mise run setup <desktop|dev>`

**Files:** create `config/mise/conf.d/setup.toml`, `test/integration/bootstrap/setup-task.spec.ts`.

- [ ] **Failing spec:**

```ts
#!/usr/bin/env bun
// `mise run setup <desktop|dev>` records the profile in miserc.local.toml and runs the bootstrap with it.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const task = (Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/setup.toml"), "utf8")) as {
  tasks: { setup: { run: string; usage: string } };
}).tasks.setup;

let t: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "setup-task-"));
  mkdirSync(join(t, "bin"));
  mkdirSync(join(t, ".local", "share", "dots", "config", "mise"), { recursive: true });
  writeFileSync(join(t, "bin", "mise"), `#!/bin/sh\necho "$@" > "${join(t, "mise.args")}"\n`);
  chmodSync(join(t, "bin", "mise"), 0o755);
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

const run = (profile: string) =>
  Bun.spawnSync(["bash", "-c", task.run], {
    env: { PATH: `${join(t, "bin")}:/usr/bin:/bin`, HOME: t, usage_profile: profile }, stdout: "pipe", stderr: "pipe",
  });
const miserc = () => readFileSync(join(t, ".local", "share", "dots", "config", "mise", "miserc.local.toml"), "utf8");
const args = () => readFileSync(join(t, "mise.args"), "utf8").trim();

describe("setup task", () => {
  it("accepts only desktop and dev", () => expect(task.usage).toContain('choices "desktop" "dev"'));
  it("dev: records desktop,dev and bootstraps it", () => {
    expect(run("dev").exitCode).toBe(0);
    expect(miserc()).toBe('env = ["desktop", "dev"]\n');
    expect(args()).toBe("bootstrap -E desktop,dev --yes");
  });
  it("desktop: records desktop and bootstraps it", () => {
    expect(run("desktop").exitCode).toBe(0);
    expect(miserc()).toBe('env = ["desktop"]\n');
    expect(args()).toBe("bootstrap -E desktop --yes");
  });
});
```

- [ ] Run: fails (no file). Create `config/mise/conf.d/setup.toml` with the spec §3.2 task. Run: passes.
- [ ] Check for real: `mise tasks | grep -E '^setup '` lists it; `mise run setup bogus` exits non-zero.
- [ ] Commit: `feat(mise): Add mise run setup <desktop|dev>`.

## Task 6: Docs and CI

- [ ] README "Install": after the curl line, "This sets up **desktop**. Add the development tools later with
  `mise run setup dev` (`mise run setup desktop` switches back)." plus the spec §2 table.
- [ ] `docs/REINSTALL.md` Phase 4 (reinstall): the same two lines.
- [ ] `.github/workflows/preview.yml` "Brewfile parses": add the `desktop,dev` profile to the loop.
- [ ] `hk check`. Commit: `docs: Describe the desktop and dev profiles`.

## Task 7: Verification

- [ ] `cd test && bun test integration/bootstrap` (all pass); `hk check`.
- [ ] Brewfile parses for `container`, `desktop`, `desktop,dev`.
- [ ] `mise bootstrap -E desktop,dev --dry-run` on this Mac lists nothing unexpected.
- [ ] Report; the owner pushes `fix/brew-sudo` and opens one PR.
