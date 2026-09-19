# Stack Benchmark — Plan 1: Foundation (repo, contract, harness, baseline)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the standalone `~/Work/bench` repo with a frozen, mutation-verified behavior contract for `xc-puts`, `gitx`, `xc-skills`, `xc-sec`, plus a benchmark harness that measures any stack. Validate the harness on the original scripts.

**Architecture:** A black-box contract in `bun test` runs each tool inside a throwaway sandbox: temp HOME, a controlled PATH, fake `gum`/`fzf`/`pbcopy`/`glow`/`bat`, a deterministic git fixture, and fixed dates. It compares normalized stdout, stderr, exit code, fake-program calls, filesystem, and repo state against golden files recorded from the originals. `CONTRACT_BIN_DIR` points the same suite at any stack. The benchmark harness reuses the sandbox, with `bench/stubs` in place of the fakes, and drives `hyperfine` and `/usr/bin/time`.

**Tech Stack:** Bun 1.4 (`bun test`, TypeScript), usage 6.9, hyperfine, scc, lizard, jscpd, gitleaks, all pinned with mise.

**Spec:** `config/bin/docs/experiments/2026-09-19-stack-benchmark-design.md` (dots repo), copied into `~/Work/bench/docs/design.md` in Task 1.

**Plan series:**

- **Plan 1 (this one):** foundation.
- **Plan 2:** port brief and isolated builds per stack.
- **Plan 3:** evolve exercise, scoring, report, and publication readiness.

Plans 2 and 3 are outlined at the end and written once this plan lands.

---

## Pre-port amendments to the spec

These came out of reading the originals while writing this plan. They are recorded in `docs/design.md` (Task 1), **before any port exists**, so the pre-registration stays honest.

1. **git calls are not compared argument by argument.** The contract checks repo state instead: local refs with tracking, origin refs, `log --all`, and `status`. Argument-level comparison is kept only for `gum`, `fzf`, `pbcopy`, `wl-copy`, `xclip`, `xsel`, `glow`, `bat`, and `skills`. Reason: a port may legitimately use different read-only git commands, or libgit2. Skipping a real git operation still fails, because the repo state differs.
2. **`rg` and `python3` are not faked.** They are real host tools. The `xc-sec` contract is assertion-based and neutral about implementation, so a port may drop them.
3. **Argument-parse errors** (cases marked `stderr: "nonempty"`) compare the exit code and stdout exactly, and only require stderr to be non-empty. Reason: ports must not be forced to reproduce `usage`'s exact error text. `--help` output is still compared exactly (spec §6.6).
4. **The shell-function length metric** uses a small awk counter, because lizard cannot parse zsh/bash. Rust and TypeScript use lizard.
5. **The `xc-sec` output format is pinned** in Task 10. The spec §8 did not define it.
6. **Result folders use `BENCH_HOST_LABEL`** (default: a CPU-model slug), never the real hostname, so the results can be published.
7. **Goldens are per platform** (`contract/golden/<platform>/…`). Plan 1 records `darwin` only. Linux goldens are recorded in Plan 3 for the Flexibility score.
8. **Known current behavior recorded as-is**, not fixed:
   - `gitx` declares `fzr`, `fzf`, `fzw`, `fze`, `fzd`, `fzhs`, `fzhh`, `fzunstage`, and `fzdiff` but does not implement them. They print help and exit 1.
   - `gitx tail|strip|preview <args>` fail argument parsing under the `usage` shebang (`unexpected word`).

## File structure (`~/Work/bench`)

| Path                                  | Responsibility                                                  |
| ------------------------------------- | --------------------------------------------------------------- |
| `mise.toml`                           | Pinned tools + tasks (`contract`, `contract:record`, `mutate`, `bench`, `check`) |
| `package.json`, `tsconfig.json`       | TypeScript tooling for contract and bench                       |
| `docs/design.md`                      | Spec copy + amendments (frozen)                                 |
| `docs/methodology.md`                 | How the contract and probes work (publishable)                  |
| `docs/plans/`                         | This plan and the later plans                                   |
| `originals/bin/{xc-puts,gitx,xc-skills}` | Snapshot of the dots scripts under test                      |
| `originals/reference/xc-sec`          | Pre-spec `xc-sec`, informational only (not a contract target)   |
| `originals/SOURCE.md`                 | Dots commit SHA and file hashes                                 |
| `contract/lib/tools.ts`               | Finds the real binaries (usage, bash, zsh, bun, git, rg)        |
| `contract/lib/sandbox.ts`             | Temp HOME/work, PATH, env, run, snapshot, dispose               |
| `contract/lib/normalize.ts`           | Replaces sandbox paths, timestamps, backup stamps               |
| `contract/lib/calls.ts`               | Parses the fake-program call log                                |
| `contract/lib/fixtures.ts`            | Deterministic git repo + skills tree builders, repo state       |
| `contract/lib/case.ts`                | `Case` type                                                     |
| `contract/lib/golden.ts`              | Record/compare goldens                                          |
| `contract/lib/run-case.ts`            | Glue: sandbox → run → observe → golden                          |
| `contract/lib/*.test.ts`              | Unit tests for the lib                                          |
| `contract/fakes/{_fake,fzf,gum,…}`    | Fake external programs (bash)                                   |
| `contract/cases/<tool>.cases.ts`      | Case inputs per tool                                            |
| `contract/<tool>.contract.test.ts`    | Suite entry per tool                                            |
| `contract/golden/darwin/<tool>/*.json`| Recorded goldens                                                |
| `contract/mutations.ts`, `contract/mutate.ts` | Mutation list and runner                                |
| `contract/mutation-report.md`         | Generated evidence that the contract kills mutants              |
| `bench/stubs/{git,gum,fzf}`           | Minimal `sh` stubs for P2/P4/P6/P7                              |
| `bench/floors/usage-zsh`              | P0 floor program for shell stacks (Plan 2 adds Rust/Bun floors) |
| `bench/stacks.ts`                     | Stack registry (Plan 2 adds entries)                            |
| `bench/probes.ts`                     | Typical call per tool, and its setup                            |
| `bench/measure.ts`                    | hyperfine, peak RSS, burst                                      |
| `bench/footprint.ts`                  | Disk footprint projection for 23 tools                          |
| `bench/static.ts`                     | scc, lizard, jscpd, and shell function-length metrics           |
| `bench/machine.ts`                    | Machine and tool-version info                                   |
| `bench/run.ts`                        | CLI orchestrator writing `results/`                             |
| `.github/workflows/contract.yml`      | CI (enabled once the repo is published)                         |

---

### Task 1: Scaffold the bench repo

**Files:**

- Create: `~/Work/bench/{README.md,LICENSE,.gitignore,mise.toml,package.json,tsconfig.json}`
- Create: `~/Work/bench/docs/design.md`, `~/Work/bench/docs/plans/2026-09-19-plan-1-foundation.md`

- [ ] **Step 1: Create the repo and pin tools**

```bash
mkdir -p ~/Work/bench && cd ~/Work/bench && git init -q -b main
mise use --pin bun@1.4.2 usage@6.9.1 hyperfine@latest scc@latest gitleaks@latest pipx:lizard@latest npm:jscpd@latest
mise install
```

Expected: `mise.toml` has a `[tools]` table with exact versions.

- [ ] **Step 2: Add the tasks to `mise.toml`** (append below `[tools]`)

```toml
[env]
BENCH_ROOT = "{{ config_root }}"

[tasks.check]
description = "Typecheck + unit tests for contract/bench libraries"
run = ["bunx tsc --noEmit", "bun test contract/lib"]

[tasks.contract]
description = "Run the frozen contract against CONTRACT_BIN_DIR (default: originals/bin)"
run = "bun test contract"

[tasks."contract:record"]
description = "Record goldens from originals (refuses when CONTRACT_BIN_DIR is set)"
run = "BENCH_RECORD=1 bun test contract"

[tasks.mutate]
description = "Prove the contract kills mutants of the originals"
run = "bun contract/mutate.ts"

[tasks.bench]
description = "Run benchmark probes: mise run bench -- [--stack ID]... [--quick] [--session N]"
run = "bun bench/run.ts"
```

- [ ] **Step 3: Write `package.json`, `tsconfig.json`, `.gitignore`**

`package.json`:

```json
{
  "name": "bench",
  "private": true,
  "type": "module",
  "devDependencies": { "@types/bun": "1.4.2", "typescript": "5.9.3" }
}
```

`tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ESNext", "module": "ESNext", "moduleResolution": "bundler",
    "strict": true, "noEmit": true, "types": ["bun"], "skipLibCheck": true
  },
  "include": ["contract", "bench"]
}
```

`.gitignore`:

```gitignore
node_modules/
stacks/*/target/
stacks/*/dist/
.tmp/
```

Run: `bun install`. Expected: `bun.lock` created. If `@types/bun@1.4.2` or `typescript@5.9.3` does not resolve, pin the nearest available versions and note them in the commit message.

- [ ] **Step 4: Write `LICENSE` and the README skeleton**

Copy the MIT license: `cp ~/Work/dots/config/bin/LICENSE LICENSE` (update the year/holder line if needed).

`README.md`:

```markdown
# bench — which stack for small CLI tools called in hot paths?

Compares zsh + [usage](https://usage.jdx.dev), autoloaded zsh functions,
Rust + usage-rs, and Bun (usage shebang and compiled) by porting the same
real-world tools under a frozen behavior contract and measuring them.

- Design and pre-registered thresholds: [docs/design.md](docs/design.md)
- Methodology: [docs/methodology.md](docs/methodology.md)
- Results: _pending_

## Reproduce

    mise install
    mise run contract      # behavior contract against the originals
    mise run bench -- --quick
```

- [ ] **Step 5: Copy the spec and this plan, and append the amendments**

```bash
cp ~/Work/dots/config/bin/docs/experiments/2026-09-19-stack-benchmark-design.md docs/design.md
cp ~/Work/dots/config/bin/docs/experiments/2026-09-19-stack-benchmark-plan-1-foundation.md docs/plans/2026-09-19-plan-1-foundation.md
```

Append to `docs/design.md` a `## 12. Pre-port amendments (2026-09-19)` section containing the eight numbered items from "Pre-port amendments to the spec" above, copied verbatim.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "chore: Scaffold bench repo with design and pinned toolchain"
```

---

### Task 2: Snapshot the originals

**Files:**

- Create: `originals/bin/{xc-puts,gitx,xc-skills}`, `originals/reference/xc-sec`, `originals/SOURCE.md`

- [ ] **Step 1: Copy the scripts and record their provenance**

```bash
cd ~/Work/bench
D=~/Work/dots/config/bin
mkdir -p originals/bin originals/reference
cp "$D"/{xc-puts,gitx,xc-skills} originals/bin/ && chmod +x originals/bin/*
cp "$D"/xc-sec originals/reference/xc-sec
{
  echo "# Source of originals"
  echo
  echo "- Repo: dots, path \`config/bin\`"
  echo "- Commit: \`$(git -C "$D" rev-parse HEAD)\`"
  echo "- Captured: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- Working-tree status of these files at capture:"
  echo
  echo '```text'
  git -C "$D" status --short -- xc-puts gitx xc-skills xc-sec
  echo '```'
  echo
  echo "| File | sha256 |"
  echo "| ---- | ------ |"
  for f in originals/bin/* originals/reference/*; do echo "| \`$f\` | \`$(shasum -a 256 "$f" | cut -c1-16)\` |"; done
  echo
  echo "\`xc-sec\` is informational only: its contract comes from design §8, not from this script."
} > originals/SOURCE.md
cat originals/SOURCE.md
```

Expected: SOURCE.md lists a SHA, shows `?? xc-sec` (untracked in dots), and gives four hashes.

- [ ] **Step 2: Scrub personal data**

Run: `grep -nE 'roalcantara|fr3ak|/Users/' originals -r || echo clean`
Expected: `clean`. If anything matches, replace it with a neutral value (for example `$HOME`) and note the edit in SOURCE.md under a `## Edits` heading.

- [ ] **Step 3: Commit**

```bash
git add originals && git commit -m "chore: Snapshot original scripts under test"
```

---

### Task 3: Tool resolution + sandbox

**Files:**

- Create: `contract/lib/tools.ts`, `contract/lib/sandbox.ts`, `contract/lib/sandbox.test.ts`

- [ ] **Step 1: Write the failing test** — `contract/lib/sandbox.test.ts`

```ts
import { afterEach, expect, test } from "bun:test";
import { existsSync, writeFileSync, chmodSync, mkdirSync } from "node:fs";
import { join } from "node:path";
import { Sandbox } from "./sandbox";

let sb: Sandbox | undefined;
afterEach(() => sb?.dispose());

test("isolates HOME and PATH", () => {
  sb = new Sandbox();
  const r = sb.exec(["/bin/sh", "-c", 'printf "%s|%s" "$HOME" "$PATH"'], {});
  const [home, path] = r.stdout.split("|");
  expect(home).toBe(sb.home);
  expect(path.split(":").slice(0, 2)).toEqual([sb.fakes, sb.tools]);
  expect(path).not.toContain("/opt/homebrew");
});

test("links required real tools", () => {
  sb = new Sandbox();
  for (const t of ["usage", "bash", "zsh", "bun", "git"]) expect(existsSync(join(sb.tools, t))).toBe(true);
});

test("snapshot records files, dirs and symlinks relative to home/work", () => {
  sb = new Sandbox();
  mkdirSync(join(sb.home, "d"));
  writeFileSync(join(sb.home, "d", "f.txt"), "hi\n");
  sb.exec(["/bin/ln", "-s", join(sb.home, "d"), join(sb.work, "l")], {});
  const snap = sb.snapshot();
  expect(snap["~/d"]).toBe("dir");
  expect(snap["~/d/f.txt"]).toBe("file:hi\n");
  expect(snap["work/l"]).toBe(`link:${join(sb.home, "d")}`);
});

test("hide removes a fake from PATH", () => {
  sb = new Sandbox();
  expect(existsSync(join(sb.fakes, "gum"))).toBe(true);
  sb.hide(["gum"]);
  expect(existsSync(join(sb.fakes, "gum"))).toBe(false);
});

test("dispose removes the sandbox", () => {
  const s = new Sandbox();
  s.dispose();
  expect(existsSync(s.root)).toBe(false);
});
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bun test contract/lib/sandbox.test.ts`
Expected: FAIL — `Cannot find module './sandbox'`.

- [ ] **Step 3: Write `contract/lib/tools.ts`**

```ts
import { realpathSync } from "node:fs";

/** Real binaries linked into every sandbox. `rg` and `python3` are optional host tools. */
export const REQUIRED_TOOLS = ["usage", "bash", "zsh", "bun", "git"] as const;
export const OPTIONAL_TOOLS = ["rg", "python3"] as const;

const cache = new Map<string, string | null>();

/** Absolute path of a real tool, preferring mise-managed installs over shims. */
export function findTool(name: string): string | null {
  if (cache.has(name)) return cache.get(name)!;
  let found: string | null = null;
  if (name === "bun") found = process.execPath;
  if (!found) {
    const viaMise = Bun.spawnSync(["mise", "which", name], { stdout: "pipe", stderr: "ignore" });
    const out = viaMise.stdout.toString().trim();
    if (viaMise.exitCode === 0 && out) found = out;
  }
  if (!found) {
    const onPath = Bun.which(name);
    if (onPath) found = realpathSync(onPath);
  }
  cache.set(name, found);
  return found;
}

export function tool(name: string): string {
  const p = findTool(name);
  if (!p) throw new Error(`required tool not found on host: ${name}`);
  return p;
}
```

- [ ] **Step 4: Write `contract/lib/sandbox.ts`**

```ts
import { cpSync, lstatSync, mkdirSync, mkdtempSync, readdirSync, readFileSync, readlinkSync, realpathSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { createHash } from "node:crypto";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { findTool, OPTIONAL_TOOLS, REQUIRED_TOOLS, tool } from "./tools";

export const ROOT = realpathSync(join(import.meta.dir, "..", ".."));
export const CONTRACT_FAKES = join(ROOT, "contract", "fakes");

/** Directory holding the tools under test. Defaults to the originals snapshot. */
export function binDir(): string {
  const d = process.env.CONTRACT_BIN_DIR;
  return d ? realpathSync(d) : join(ROOT, "originals", "bin");
}

export interface ExecResult { exitCode: number; stdout: string; stderr: string }
export interface ExecOptions { stdin?: string; env?: Record<string, string>; cwd?: string; timeoutMs?: number }

/** A throwaway HOME + work dir with a controlled PATH. Always call dispose(). */
export class Sandbox {
  readonly root = realpathSync(mkdtempSync(join(tmpdir(), "bench-sb-")));
  readonly home = join(this.root, "home");
  readonly work = join(this.root, "work");
  readonly repo = join(this.work, "repo");
  readonly fakes = join(this.root, "fakes");
  readonly tools = join(this.root, "tools");
  readonly log = join(this.root, "calls.log");

  /** @param fakesSrc directory of fake programs to expose; null exposes none. */
  constructor(fakesSrc: string | null = CONTRACT_FAKES) {
    for (const d of [this.home, this.work, this.fakes, this.tools]) mkdirSync(d, { recursive: true });
    if (fakesSrc) cpSync(fakesSrc, this.fakes, { recursive: true, verbatimSymlinks: true });
    for (const t of REQUIRED_TOOLS) symlinkSync(tool(t), join(this.tools, t));
    for (const t of OPTIONAL_TOOLS) {
      const p = findTool(t);
      if (p) symlinkSync(p, join(this.tools, t));
    }
    writeFileSync(join(this.home, ".gitconfig"), "[init]\n\tdefaultBranch = main\n[advice]\n\tdetachedHead = false\n");
    writeFileSync(this.log, "");
  }

  hide(names: string[]): void {
    for (const n of names) rmSync(join(this.fakes, n), { force: true });
  }

  env(extra: Record<string, string> = {}): Record<string, string> {
    return {
      HOME: this.home,
      PATH: [this.fakes, this.tools, binDir(), "/usr/bin", "/bin", "/usr/sbin", "/sbin"].join(":"),
      TERM: "dumb",
      TZ: "UTC",
      LANG: "en_US.UTF-8",
      LC_ALL: "en_US.UTF-8",
      XDG_CONFIG_HOME: join(this.home, ".config"),
      GIT_CONFIG_NOSYSTEM: "1",
      GIT_CONFIG_GLOBAL: join(this.home, ".gitconfig"),
      GIT_EDITOR: "true",
      EDITOR: "true",
      VISUAL: "true",
      GIT_PAGER: "cat",
      PAGER: "cat",
      GIT_AUTHOR_NAME: "Bench",
      GIT_AUTHOR_EMAIL: "bench@example.invalid",
      GIT_COMMITTER_NAME: "Bench",
      GIT_COMMITTER_EMAIL: "bench@example.invalid",
      GIT_AUTHOR_DATE: "2026-01-01T00:00:00Z",
      GIT_COMMITTER_DATE: "2026-01-01T00:00:00Z",
      BENCH_FAKE_LOG: this.log,
      ...extra,
    };
  }

  exec(argv: string[], o: ExecOptions): ExecResult {
    const r = Bun.spawnSync(argv, {
      cwd: o.cwd ?? this.work,
      env: this.env(o.env),
      stdin: new TextEncoder().encode(o.stdin ?? ""),
      stdout: "pipe",
      stderr: "pipe",
      timeout: o.timeoutMs ?? 20_000,
    });
    return { exitCode: r.exitCode ?? -1, stdout: r.stdout.toString(), stderr: r.stderr.toString() };
  }

  /** Runs a tool from binDir(), with a fresh call log. */
  run(toolName: string, argv: string[], o: ExecOptions): ExecResult {
    writeFileSync(this.log, "");
    return this.exec([join(binDir(), toolName), ...argv], o);
  }

  /** Files, dirs and symlinks under ~ and work/, excluding git internals. */
  snapshot(): Record<string, string> {
    const out: Record<string, string> = {};
    const walk = (abs: string, rel: string) => {
      for (const name of readdirSync(abs).sort()) {
        if (name === ".git" || name.endsWith(".git") || name === ".gitconfig") continue;
        const a = join(abs, name);
        const r = `${rel}/${name}`;
        const st = lstatSync(a);
        if (st.isSymbolicLink()) out[r] = `link:${readlinkSync(a)}`;
        else if (st.isDirectory()) {
          out[r] = "dir";
          walk(a, r);
        } else {
          const buf = readFileSync(a);
          out[r] = buf.length <= 4096 ? `file:${buf.toString("utf8")}` : `sha256:${createHash("sha256").update(buf).digest("hex")}`;
        }
      }
    };
    walk(this.home, "~");
    walk(this.work, "work");
    return out;
  }

  dispose(): void {
    rmSync(this.root, { recursive: true, force: true });
  }
}
```

The test expects a `gum` fake to exist. Create a placeholder so this task passes; Task 4 replaces it:

```bash
mkdir -p contract/fakes && printf '#!/bin/bash\nexit 0\n' > contract/fakes/gum && chmod +x contract/fakes/gum
```

- [ ] **Step 5: Run the tests**

Run: `bun test contract/lib/sandbox.test.ts`
Expected: 5 pass.

- [ ] **Step 6: Commit**

```bash
git add contract && git commit -m "feat(contract): Add sandbox with controlled HOME, PATH and snapshot"
```

---

### Task 4: Fakes + call-log parser

**Files:**

- Create: `contract/fakes/_fake`, `contract/fakes/fzf`, symlinks `contract/fakes/{gum,pbcopy,wl-copy,xclip,xsel,glow,bat,skills}` → `_fake`
- Create: `contract/lib/calls.ts`, `contract/lib/calls.test.ts`

- [ ] **Step 1: Write the failing test** — `contract/lib/calls.test.ts`

```ts
import { afterEach, expect, test } from "bun:test";
import { Sandbox } from "./sandbox";
import { readCalls } from "./calls";

let sb: Sandbox | undefined;
afterEach(() => sb?.dispose());

test("generic fake logs argv and prints canned output", () => {
  sb = new Sandbox();
  const r = sb.exec(["gum", "style", "--foreground", "#fff", "a b"], { env: { BENCH_FAKE_GUM_OUT: "styled" } });
  expect(r.stdout).toBe("styled");
  expect(readCalls(sb)).toEqual([{ tool: "gum", args: ["style", "--foreground", "#fff", "a b"] }]);
});

test("clipboard fakes capture stdin", () => {
  sb = new Sandbox();
  sb.exec(["pbcopy"], { stdin: "one\ntwo\n" });
  expect(readCalls(sb)).toEqual([{ tool: "pbcopy", args: [] }, { tool: "pbcopy.stdin", args: ["one\ntwo\n"] }]);
});

test("fake exit code is configurable", () => {
  sb = new Sandbox();
  expect(sb.exec(["glow", "x"], { env: { BENCH_FAKE_GLOW_EXIT: "3" } }).exitCode).toBe(3);
});

test("fzf fake picks lines by index and supports cancel", () => {
  sb = new Sandbox();
  expect(sb.exec(["fzf", "-m"], { stdin: "a\nb\nc\n", env: { BENCH_FAKE_FZF_PICK: "1,3" } }).stdout).toBe("a\nc\n");
  expect(sb.exec(["fzf"], { stdin: "a\nb\n" }).stdout).toBe("a\n");
  expect(sb.exec(["fzf"], { stdin: "a\n", env: { BENCH_FAKE_FZF_PICK: "none" } }).exitCode).toBe(130);
});
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bun test contract/lib/calls.test.ts`
Expected: FAIL — `Cannot find module './calls'`.

- [ ] **Step 3: Write the fakes**

`contract/fakes/_fake`:

```bash
#!/bin/bash
# Generic fake: logs argv (fields separated by \x1f), captures stdin for
# clipboard tools, prints $BENCH_FAKE_<NAME>_OUT, exits $BENCH_FAKE_<NAME>_EXIT.
name=${0##*/}
{ printf '%s' "$name"; printf '\x1f%s' "$@"; printf '\n'; } >>"$BENCH_FAKE_LOG"
case " pbcopy wl-copy xclip xsel " in
  *" $name "*) { printf '%s.stdin\x1f' "$name"; tr '\n' '\036'; printf '\n'; } >>"$BENCH_FAKE_LOG" ;;
esac
key=$(printf '%s' "$name" | tr 'a-z-' 'A-Z_')
out="BENCH_FAKE_${key}_OUT"
code="BENCH_FAKE_${key}_EXIT"
[ -n "${!out:-}" ] && printf '%s' "${!out}"
exit "${!code:-0}"
```

`contract/fakes/fzf`:

```bash
#!/bin/bash
# fzf fake: logs argv, reads all stdin, prints the lines chosen by
# BENCH_FAKE_FZF_PICK (comma-separated, 1-based; default 1; "none" = cancel).
{ printf 'fzf'; printf '\x1f%s' "$@"; printf '\n'; } >>"$BENCH_FAKE_LOG"
input=$(cat)
pick=${BENCH_FAKE_FZF_PICK:-1}
[ "$pick" = none ] && exit 130
IFS=, read -ra idx <<<"$pick"
for i in "${idx[@]}"; do printf '%s\n' "$input" | sed -n "${i}p"; done
```

```bash
cd contract/fakes && rm -f gum && chmod +x _fake fzf
for n in gum pbcopy wl-copy xclip xsel glow bat skills; do ln -s _fake "$n"; done
cd ../..
```

- [ ] **Step 4: Write `contract/lib/calls.ts`**

```ts
import { readFileSync } from "node:fs";
import type { Sandbox } from "./sandbox";

export interface Call { tool: string; args: string[] }

/** Parses the fake call log: one line per call, fields split by \x1f, \x1e = newline in captured stdin. */
export function readCalls(sb: Sandbox): Call[] {
  return readFileSync(sb.log, "utf8")
    .split("\n")
    .filter(Boolean)
    .map((line) => {
      const [tool, ...args] = line.split("\x1f");
      return { tool, args: args.map((a) => a.replaceAll("\x1e", "\n")) };
    });
}
```

- [ ] **Step 5: Run the tests**

Run: `bun test contract/lib`
Expected: all pass (9).

- [ ] **Step 6: Commit**

```bash
git add contract && git commit -m "feat(contract): Add argv-logging fakes for gum, fzf, clipboard and viewers"
```

---

### Task 5: Normalizer + golden store + case runner

**Files:**

- Create: `contract/lib/normalize.ts`, `contract/lib/case.ts`, `contract/lib/golden.ts`, `contract/lib/run-case.ts`, `contract/lib/normalize.test.ts`

- [ ] **Step 1: Write the failing test** — `contract/lib/normalize.test.ts`

```ts
import { afterEach, expect, test } from "bun:test";
import { Sandbox, binDir } from "./sandbox";
import { normalize } from "./normalize";

let sb: Sandbox | undefined;
afterEach(() => sb?.dispose());

test("replaces sandbox root, bin dir, timestamps and backup stamps", () => {
  sb = new Sandbox();
  const raw = `${sb.home}/x ${binDir()}/gitx 2026-09-19 18:24:10 f.bak.20260919182410 2026-09-19T18:24:10`;
  expect(normalize(raw, sb)).toBe("<SB>/home/x <BIN>/gitx <TS> f.bak.<STAMP> <TS>");
});

test("leaves git short hashes and plain numbers alone", () => {
  sb = new Sandbox();
  expect(normalize("abc1234 42", sb)).toBe("abc1234 42");
});
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bun test contract/lib/normalize.test.ts`
Expected: FAIL — `Cannot find module './normalize'`.

- [ ] **Step 3: Write `contract/lib/normalize.ts`**

```ts
import { binDir, type Sandbox } from "./sandbox";

export function normalize(s: string, sb: Sandbox): string {
  return s
    .replaceAll(sb.root, "<SB>")
    .replaceAll(binDir(), "<BIN>")
    .replace(/\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}/g, "<TS>")
    .replace(/\.bak\.\d{14}/g, ".bak.<STAMP>");
}

/** Deep-normalizes any JSON-serializable value (keys included). */
export function normalizeDeep<T>(value: T, sb: Sandbox): T {
  return JSON.parse(normalize(JSON.stringify(value), sb));
}
```

- [ ] **Step 4: Write `contract/lib/case.ts`**

```ts
import type { Sandbox } from "./sandbox";

export type Where = "work" | "home" | "repo";

export interface Case {
  /** Unique, filename-safe id; becomes the golden file name. */
  id: string;
  argv: string[] | ((sb: Sandbox) => string[]);
  stdin?: string;
  env?: Record<string, string>;
  cwd?: Where;
  /** Fakes to remove from PATH (simulates "tool not installed"). */
  hide?: string[];
  setup?: (sb: Sandbox) => void;
  /** Capture git repo state (sb.repo + origin) after the run. */
  repo?: boolean;
  /** Argument-parse errors: compare stderr only as non-empty (amendment 3). */
  stderr?: "nonempty";
  note?: string;
}
```

- [ ] **Step 5: Write `contract/lib/golden.ts`**

```ts
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { expect } from "bun:test";
import { ROOT } from "./sandbox";

export const GOLDEN_DIR = join(ROOT, "contract", "golden", process.platform);

export function matchGolden(toolName: string, id: string, observed: unknown): void {
  const file = join(GOLDEN_DIR, toolName, `${id}.json`);
  if (process.env.BENCH_RECORD === "1") {
    if (process.env.CONTRACT_BIN_DIR) throw new Error("goldens may only be recorded from originals (unset CONTRACT_BIN_DIR)");
    mkdirSync(dirname(file), { recursive: true });
    writeFileSync(file, `${JSON.stringify(observed, null, 2)}\n`);
    return;
  }
  if (!existsSync(file)) throw new Error(`missing golden ${file}; run: mise run contract:record`);
  expect(observed).toEqual(JSON.parse(readFileSync(file, "utf8")));
}
```

- [ ] **Step 6: Write `contract/lib/run-case.ts`**

`repoState` is imported from `fixtures.ts`, which Task 6 creates. Write this file now; it will typecheck after Task 6.

```ts
import type { Case } from "./case";
import { readCalls } from "./calls";
import { repoState } from "./fixtures";
import { matchGolden } from "./golden";
import { normalizeDeep } from "./normalize";
import { Sandbox } from "./sandbox";

export function runCase(toolName: string, c: Case): void {
  const sb = new Sandbox();
  try {
    if (c.hide) sb.hide(c.hide);
    c.setup?.(sb);
    const argv = typeof c.argv === "function" ? c.argv(sb) : c.argv;
    const cwd = c.cwd === "home" ? sb.home : c.cwd === "repo" ? sb.repo : sb.work;
    const r = sb.run(toolName, argv, { stdin: c.stdin, env: c.env, cwd });
    const observed = normalizeDeep(
      {
        exitCode: r.exitCode,
        stdout: r.stdout,
        stderr: c.stderr === "nonempty" ? (r.stderr.length > 0 ? "<nonempty>" : "") : r.stderr,
        calls: readCalls(sb),
        fs: sb.snapshot(),
        repo: c.repo ? repoState(sb) : null,
      },
      sb,
    );
    matchGolden(toolName, c.id, observed);
  } finally {
    sb.dispose();
  }
}
```

- [ ] **Step 7: Run the normalizer tests**

Run: `bun test contract/lib/normalize.test.ts`
Expected: 2 pass.

- [ ] **Step 8: Commit**

```bash
git add contract && git commit -m "feat(contract): Add normalizer, golden store and case runner"
```

---

### Task 6: Fixtures (git repo, skills tree, repo state)

**Files:**

- Create: `contract/lib/fixtures.ts`, `contract/lib/fixtures.test.ts`

- [ ] **Step 1: Write the failing test** — `contract/lib/fixtures.test.ts`

```ts
import { afterEach, expect, test } from "bun:test";
import { Sandbox } from "./sandbox";
import { buildRepo, repoState, skillsTree } from "./fixtures";
import { existsSync } from "node:fs";
import { join } from "node:path";

const boxes: Sandbox[] = [];
afterEach(() => { while (boxes.length) boxes.pop()!.dispose(); });
const box = () => { const s = new Sandbox(); boxes.push(s); return s; };

test("repo fixture is deterministic across sandboxes", () => {
  const a = box(); buildRepo(a);
  const b = box(); buildRepo(b);
  expect(repoState(a)).toEqual(repoState(b));
});

test("repo fixture has main, merged, open and gone branches", () => {
  const s = box(); buildRepo(s);
  const state = repoState(s).join("\n");
  expect(state).toContain("refs/heads/feature/merged");
  expect(state).toContain("refs/heads/feature/open");
  expect(state).toMatch(/refs\/heads\/feature\/gone \w+ \[gone\]/);
});

test("skills tree creates global, claude and local skills", () => {
  const s = box(); skillsTree(s);
  expect(existsSync(join(s.home, ".agents/skills/alpha/SKILL.md"))).toBe(true);
  expect(existsSync(join(s.home, ".claude/skills/gamma/SKILL.md"))).toBe(true);
  expect(existsSync(join(s.work, ".agents/skills/local-one/SKILL.md"))).toBe(true);
});
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bun test contract/lib/fixtures.test.ts`
Expected: FAIL — `Cannot find module './fixtures'`.

- [ ] **Step 3: Write `contract/lib/fixtures.ts`**

```ts
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import type { Sandbox } from "./sandbox";
import { tool } from "./tools";

export function git(sb: Sandbox, cwd: string, ...args: string[]): string {
  const r = Bun.spawnSync([tool("git"), ...args], { cwd, env: sb.env(), stdout: "pipe", stderr: "pipe" });
  if (r.exitCode !== 0) throw new Error(`git ${args.join(" ")} failed: ${r.stderr.toString()}`);
  return r.stdout.toString();
}

function write(path: string, content: string): void {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, content);
}

export const originDir = (sb: Sandbox) => join(sb.work, "origin.git");

/**
 * main: init, second (pushed; origin/HEAD -> main)
 * feature/merged: at main (merged)
 * feature/open: +1 commit, pushed
 * feature/gone: pushed then deleted on origin (tracking = gone)
 */
export function buildRepo(sb: Sandbox): void {
  const repo = sb.repo;
  const origin = originDir(sb);
  mkdirSync(repo, { recursive: true });
  git(sb, sb.work, "init", "-q", "--bare", "-b", "main", origin);
  git(sb, repo, "init", "-q", "-b", "main");
  write(join(repo, "a.txt"), "one\n");
  git(sb, repo, "add", ".");
  git(sb, repo, "commit", "-q", "-m", "init");
  write(join(repo, "a.txt"), "one\ntwo\n");
  git(sb, repo, "commit", "-q", "-am", "second");
  git(sb, repo, "remote", "add", "origin", origin);
  git(sb, repo, "push", "-q", "-u", "origin", "main");
  git(sb, repo, "remote", "set-head", "origin", "main");
  git(sb, repo, "branch", "feature/merged");
  git(sb, repo, "checkout", "-q", "-b", "feature/open");
  write(join(repo, "b.txt"), "open\n");
  git(sb, repo, "add", ".");
  git(sb, repo, "commit", "-q", "-m", "open work");
  git(sb, repo, "push", "-q", "-u", "origin", "feature/open");
  git(sb, repo, "checkout", "-q", "-b", "feature/gone", "main");
  git(sb, repo, "push", "-q", "-u", "origin", "feature/gone");
  git(sb, repo, "push", "-q", "origin", "--delete", "feature/gone");
  git(sb, repo, "checkout", "-q", "main");
}

/** Unstaged edit to a.txt plus an untracked file. */
export function dirty(sb: Sandbox): void {
  write(join(sb.repo, "a.txt"), "one\ntwo\nthree\n");
  write(join(sb.repo, "new.txt"), "new\n");
}

/** Staged edit to a.txt. */
export function staged(sb: Sandbox): void {
  dirty(sb);
  git(sb, sb.repo, "add", "a.txt");
}

/** One local commit on main not yet pushed. */
export function ahead(sb: Sandbox): void {
  write(join(sb.repo, "c.txt"), "ahead\n");
  git(sb, sb.repo, "add", "c.txt");
  git(sb, sb.repo, "commit", "-q", "-m", "ahead");
}

/** Remote "upstream" with one extra commit on main. */
export function withUpstream(sb: Sandbox): void {
  const up = join(sb.work, "upstream.git");
  const tmp = join(sb.work, "upstream-work");
  git(sb, sb.work, "clone", "-q", "--bare", originDir(sb), up);
  git(sb, sb.work, "clone", "-q", up, tmp);
  write(join(tmp, "up.txt"), "upstream\n");
  git(sb, tmp, "add", "up.txt");
  git(sb, tmp, "commit", "-q", "-m", "upstream change");
  git(sb, tmp, "push", "-q", "origin", "main");
  git(sb, sb.repo, "remote", "add", "upstream", up);
}

export function repoState(sb: Sandbox): string[] {
  const g = (cwd: string, ...a: string[]) =>
    git(sb, cwd, ...a).trim().split("\n").filter(Boolean);
  return [
    "# refs",
    ...g(sb.repo, "for-each-ref", "--format=%(refname) %(objectname:short) %(upstream:track)"),
    "# origin",
    ...g(originDir(sb), "for-each-ref", "--format=%(refname) %(objectname:short)"),
    "# log",
    ...g(sb.repo, "log", "--all", "--topo-order", "--format=%h %s"),
    "# status",
    ...g(sb.repo, "status", "--short", "--branch"),
  ];
}

export function skillsTree(sb: Sandbox): void {
  write(join(sb.home, ".agents/skills/alpha/SKILL.md"), "# alpha\n");
  write(join(sb.home, ".agents/skills/beta/SKILL.md"), "# beta\n");
  write(join(sb.home, ".agents/skills/.hidden/SKILL.md"), "# hidden\n");
  write(join(sb.home, ".claude/skills/alpha/SKILL.md"), "# alpha\n");
  write(join(sb.home, ".claude/skills/gamma/SKILL.md"), "# gamma\n");
  write(join(sb.work, ".agents/skills/local-one/SKILL.md"), "# local\n");
}
```

Note: `withUpstream` creates `upstream-work/` and `upstream.git` under `work/`. `snapshot()` skips names ending in `.git`, but `upstream-work/` will appear in the fs snapshot. That is fine: its contents are deterministic.

- [ ] **Step 4: Run the tests**

Run: `bun test contract/lib && bunx tsc --noEmit`
Expected: all lib tests pass; tsc reports no errors.

- [ ] **Step 5: Commit**

```bash
git add contract && git commit -m "feat(contract): Add deterministic git and skills fixtures"
```

---

### Task 7: `xc-puts` contract

**Files:**

- Create: `contract/cases/xc-puts.cases.ts`, `contract/xc-puts.contract.test.ts`, `contract/golden/darwin/xc-puts/*.json`

- [ ] **Step 1: Write the cases** — `contract/cases/xc-puts.cases.ts`

```ts
import type { Case } from "../lib/case";

const variants: Array<[string, string[]]> = [
  ["plain", ["hello"]],
  ["green", ["--green", "Success!"]],
  ["red", ["--red", "Error!"]],
  ["yellow", ["--yellow", "Warning!"]],
  ["blue", ["--blue", "Note"]],
  ["prefix", ["--prefix", "SETUP", "Message!"]],
  ["prefix-green", ["--prefix", "SETUP", "--green", "Done"]],
  ["debug", ["--debug", "dbg"]],
  ["info", ["--info", "inf"]],
  ["warn", ["--warn", "wrn"]],
  ["error", ["--error", "err"]],
  ["fatal", ["--fatal", "fat"]],
  ["prefix-warn", ["--prefix", "SETUP", "--warn", "Message!"]],
  ["short-flags", ["-p", "X", "-g", "short"]],
];

export const cases: Case[] = [
  { id: "no-args", argv: [] },
  { id: "help", argv: ["--help"] },
  { id: "version", argv: ["--version"] },
  { id: "unknown-flag", argv: ["--nope", "x"], stderr: "nonempty" },
  ...variants.flatMap(([id, argv]): Case[] => [
    { id: `${id}.gum`, argv },
    { id: `${id}.no-gum`, argv, hide: ["gum"] },
  ]),
];
```

- [ ] **Step 2: Write the suite** — `contract/xc-puts.contract.test.ts`

```ts
import { describe, expect, test } from "bun:test";
import { cases } from "./cases/xc-puts.cases";
import { runCase } from "./lib/run-case";

describe("xc-puts", () => {
  test("case ids are unique", () => expect(new Set(cases.map((c) => c.id)).size).toBe(cases.length));
  for (const c of cases) test(c.id, () => runCase("xc-puts", c), 20_000);
});
```

- [ ] **Step 3: Run it to verify it fails** (no goldens yet)

Run: `bun test contract/xc-puts.contract.test.ts`
Expected: FAIL — `missing golden …/xc-puts/no-args.json`.

- [ ] **Step 4: Record goldens from the originals**

Run: `BENCH_RECORD=1 bun test contract/xc-puts.contract.test.ts`
Expected: all pass; 32 files in `contract/golden/darwin/xc-puts/`.

- [ ] **Step 5: Review the goldens by hand** (this is the step that catches a wrong baseline)

Run: `for f in contract/golden/darwin/xc-puts/{no-args,green.gum,green.no-gum,info.no-gum,prefix-warn.gum}.json; do echo "== $f"; cat "$f"; done`

Check each of these; any failure is a bug to fix before committing:

- `no-args`: `exitCode` 1, help text in `stderr`.
- `green.gum`: `calls` = `[{tool:"gum",args:["style","--foreground","#04B575","Success!"]}]`.
- `green.no-gum`: `stdout` = `"\u001b[32mSuccess!\u001b[39m\n"`.
- `info.no-gum`: `stdout` contains `<TS>` and `INFO`.
- `prefix-warn.gum`: `calls[0].args` = `["log","--time","DateTime","--level","warn","--prefix=SETUP","Message!"]`.

- [ ] **Step 6: Verify replay is stable**

Run: `bun test contract/xc-puts.contract.test.ts` twice.
Expected: all pass both times.

- [ ] **Step 7: Commit**

```bash
git add contract && git commit -m "test(contract): Add xc-puts contract with gum and plain goldens"
```

---

### Task 8: `gitx` contract

**Files:**

- Create: `contract/cases/gitx.cases.ts`, `contract/gitx.contract.test.ts`, `contract/golden/darwin/gitx/*.json`

- [ ] **Step 1: Write the cases** — `contract/cases/gitx.cases.ts`

```ts
import type { Case } from "../lib/case";
import { ahead, buildRepo, dirty, git, staged, withUpstream } from "../lib/fixtures";
import type { Sandbox } from "../lib/sandbox";

const repo = (...extra: Array<(sb: Sandbox) => void>) => (sb: Sandbox) => {
  buildRepo(sb);
  for (const f of extra) f(sb);
};
const inRepo = (id: string, argv: string[], extra: Partial<Case> = {}, ...setup: Array<(sb: Sandbox) => void>): Case => ({
  id, argv, cwd: "repo", repo: true, setup: repo(...setup), ...extra,
});
const amendMain = (sb: Sandbox) => git(sb, sb.repo, "commit", "-q", "--amend", "-m", "second (amended)");
const newBranch = (sb: Sandbox) => git(sb, sb.repo, "branch", "feature/unpushed");
const tag = (sb: Sandbox) => git(sb, sb.repo, "tag", "v1");

const UNIMPLEMENTED = ["fzr", "fzf", "fzw", "fze", "fzd", "fzhs", "fzhh", "fzunstage", "fzdiff"];

export const cases: Case[] = [
  // help / dispatch
  { id: "no-args", argv: [] },
  { id: "help", argv: ["--help"] },
  { id: "version", argv: ["--version"] },
  { id: "unknown-subcommand", argv: ["bogus"], stderr: "nonempty" },
  ...UNIMPLEMENTED.map((s): Case => ({ id: `unimplemented-${s}`, argv: [s], note: "declared but not implemented in original" })),

  // text filters (no repo)
  { id: "grep-commit", argv: ["grep-commit"], stdin: "abc1234 fix thing\n" },
  { id: "tail-stdin", argv: ["tail"], stdin: "one two three\n" },
  { id: "tail-args", argv: ["tail", "a", "b", "c"], stderr: "nonempty", note: "usage spec declares no args" },
  { id: "grep-branch", argv: ["grep-branch"], stdin: "* feature/open\n  main\n" },
  { id: "strip-no-args", argv: ["strip"] },
  { id: "strip-args", argv: ["strip", "M  a.txt"], stderr: "nonempty", note: "usage spec declares no args" },

  // read-only queries
  inRepo("branches", ["branches"]),
  inRepo("head-branch", ["head-branch"]),
  inRepo("remote-branches", ["remote-branches"]),
  inRepo("remote-branches-origin", ["remote-branches", "origin"]),
  inRepo("root-commit", ["root-commit"]),
  inRepo("lol", ["lol"]),
  inRepo("fzlog", ["fzlog"]),
  inRepo("preview", ["preview", "M  a.txt"], { stderr: "nonempty" }, dirty),

  // branch management
  inRepo("cnb", ["cnb", "feature/x"]),
  inRepo("cnb-missing", ["cnb"]),
  inRepo("nb", ["nb", "feature/y"]),
  inRepo("nb-missing", ["nb"]),
  inRepo("clear-merged", ["clear-merged"]),
  inRepo("clear-gone", ["clear-gone"]),

  // sync with remotes
  inRepo("uu", ["uu"]),
  inRepo("uup", ["uup"], {}, withUpstream),
  inRepo("p", ["p"], {}, ahead),
  inRepo("pf", ["pf"], {}, amendMain),
  inRepo("pa", ["pa"], {}, newBranch),
  inRepo("pt", ["pt"], {}, tag),
  inRepo("pc", ["pc"], {}, (sb) => git(sb, sb.repo, "checkout", "-q", "-b", "feature/pc")),
  inRepo("pp", ["pp"], {}, ahead),

  // history rewriting
  inRepo("rebase-from", ["rebase-from", "HEAD~1"]),
  inRepo("edit", ["edit", "HEAD"]),
  inRepo("drop", ["drop", "HEAD"]),
  inRepo("reword", ["reword", "HEAD"]),
  inRepo("fix-root", ["fix-root"], {}, staged),
  inRepo("fix", ["fix", "HEAD~1"], {}, staged),
  inRepo("fixup", ["fixup", "HEAD"], {}, staged),
  inRepo("squash", ["squash", "HEAD"], {}, staged),
  inRepo("fix-all", ["fix-all", "HEAD"], {}, dirty),
  inRepo("squash-all", ["squash-all", "HEAD"], {}, dirty),

  // fzf pickers (fake fzf picks line BENCH_FAKE_FZF_PICK)
  inRepo("fzb", ["fzb"]),
  inRepo("fzc", ["fzc"], { env: { BENCH_FAKE_FZF_PICK: "2" } }),
  inRepo("fzc-cancel", ["fzc"], { env: { BENCH_FAKE_FZF_PICK: "none" } }),
  inRepo("fza", ["fza"], { env: { BENCH_FAKE_FZF_PICK: "1,2" } }, dirty),
  inRepo("fzu", ["fzu"], {}, dirty),
  inRepo("fzus", ["fzus"], {}, staged),
];
```

- [ ] **Step 2: Write the suite** — `contract/gitx.contract.test.ts`

```ts
import { describe, expect, test } from "bun:test";
import { cases } from "./cases/gitx.cases";
import { runCase } from "./lib/run-case";

describe("gitx", () => {
  test("case ids are unique", () => expect(new Set(cases.map((c) => c.id)).size).toBe(cases.length));
  for (const c of cases) test(c.id, () => runCase("gitx", c), 30_000);
});
```

- [ ] **Step 3: Run it to verify it fails**

Run: `bun test contract/gitx.contract.test.ts`
Expected: FAIL — missing goldens.

- [ ] **Step 4: Record**

Run: `BENCH_RECORD=1 bun test contract/gitx.contract.test.ts`
Expected: all pass; one golden per case.

- [ ] **Step 5: Review the goldens by hand**

Check:

- `branches.stdout` lists `feature/gone`, `feature/merged`, `feature/open`, `main` (one per line).
- `clear-merged.repo` no longer has `refs/heads/feature/merged`.
- `clear-gone.repo` no longer has `refs/heads/feature/gone`.
- `p.repo` `# origin` section: `refs/heads/main` hash equals the local main hash.
- `fza.repo` status shows both files staged.
- `unimplemented-fzr.exitCode` is 1.
- `drop.repo` log no longer contains `second`.

Any surprise means the fixture or setup is wrong: fix the fixture, re-record, re-check.

- [ ] **Step 6: Verify replay is stable (3 runs)**

Run: `for i in 1 2 3; do bun test contract/gitx.contract.test.ts || break; done`
Expected: pass ×3. If any case flakes, the cause is nondeterminism (usually dates or ordering). Fix it in `fixtures.ts` or `normalize.ts`; never delete the case.

- [ ] **Step 7: Commit**

```bash
git add contract && git commit -m "test(contract): Add gitx contract with repo-state goldens"
```

---

### Task 9: `xc-skills` contract

**Files:**

- Create: `contract/cases/xc-skills.cases.ts`, `contract/xc-skills.contract.test.ts`, `contract/golden/darwin/xc-skills/*.json`

- [ ] **Step 1: Write the cases** — `contract/cases/xc-skills.cases.ts`

```ts
import { mkdirSync, symlinkSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import type { Case } from "../lib/case";
import { skillsTree } from "../lib/fixtures";
import type { Sandbox } from "../lib/sandbox";

const withSkills = (...extra: Array<(sb: Sandbox) => void>) => (sb: Sandbox) => {
  skillsTree(sb);
  for (const f of extra) f(sb);
};
/** A stale symlink in the claude-code target that --prune must remove. */
const staleLink = (sb: Sandbox) => {
  const dir = join(sb.home, ".gemini/antigravity/skills");
  mkdirSync(dir, { recursive: true });
  symlinkSync(join(sb.home, ".claude/skills/removed"), join(dir, "removed"));
};
/** A regular (non-symlink) skill inside an agent dir, for collect. */
const strayInCursor = (sb: Sandbox) => {
  const d = join(sb.home, ".cursor/skills/stray");
  mkdirSync(d, { recursive: true });
  writeFileSync(join(d, "SKILL.md"), "# stray\n");
};
const empty = (sb: Sandbox) => mkdirSync(join(sb.work, "empty"), { recursive: true });

export const cases: Case[] = [
  { id: "no-args", argv: [] },
  { id: "help", argv: ["--help"] },
  { id: "unknown-subcommand", argv: ["bogus"], stderr: "nonempty" },

  // ls (non-tty => raw listing)
  { id: "ls-default", argv: ["ls"], setup: withSkills() },
  { id: "ls-raw", argv: ["ls", "--raw"], setup: withSkills() },
  { id: "ls-local", argv: ["ls", "-l"], setup: withSkills() },
  { id: "ls-source", argv: (sb) => ["ls", "-s", join(sb.home, ".claude/skills")], setup: withSkills() },
  { id: "ls-missing-dir", argv: (sb) => ["ls", "-s", join(sb.work, "nope")], setup: withSkills() },
  { id: "ls-empty-dir", argv: (sb) => ["ls", "-s", join(sb.work, "empty")], setup: withSkills(empty) },
  { id: "ls-source-no-arg", argv: ["ls", "-s"], setup: withSkills(), stderr: "nonempty" },
  { id: "ls-unknown-flag", argv: ["ls", "--bogus"], setup: withSkills(), stderr: "nonempty" },

  // hidden helpers
  { id: "preview-glow", argv: (sb) => ["__preview", join(sb.home, ".agents/skills/alpha")], setup: withSkills() },
  { id: "preview-bat", argv: (sb) => ["__preview", join(sb.home, ".agents/skills/alpha")], setup: withSkills(), hide: ["glow"] },
  { id: "preview-plain", argv: (sb) => ["__preview", join(sb.home, ".agents/skills/alpha")], setup: withSkills(), hide: ["glow", "bat"] },
  { id: "clip", argv: ["__clip"], stdin: "alpha\nbeta\n" },

  // sync
  { id: "sync-default", argv: ["sync"], setup: withSkills() },
  { id: "sync-dry-run", argv: ["sync", "--dry-run"], setup: withSkills() },
  { id: "sync-agent", argv: (sb) => ["sync", "-s", join(sb.home, ".claude/skills"), "-a", "antigravity"], setup: withSkills() },
  { id: "sync-agents-repeat", argv: ["sync", "-a", "claude-code", "-a", "cursor"], setup: withSkills() },
  { id: "sync-local-agent", argv: ["sync", "-l", "-a", "cursor"], setup: withSkills() },
  { id: "sync-prune", argv: ["sync", "-a", "antigravity", "--prune"], setup: withSkills(staleLink) },
  { id: "sync-target-dry-prune", argv: (sb) => ["sync", "-s", join(sb.home, ".claude/skills"), "-t", join(sb.home, ".gemini/antigravity/skills"), "--dry-run", "--prune"], setup: withSkills(staleLink) },
  { id: "sync-targets-repeat", argv: (sb) => ["sync", "-t", join(sb.work, "t1"), "-t", join(sb.work, "t2")], setup: withSkills() },
  { id: "sync-unknown-agent", argv: ["sync", "-a", "nope"], setup: withSkills() },

  // collect
  { id: "collect-dry-run", argv: ["collect", "--dry-run", "-a", "cursor"], setup: withSkills(strayInCursor) },
  { id: "collect", argv: ["collect", "-a", "cursor"], setup: withSkills(strayInCursor) },
  { id: "collect-default", argv: ["collect"], setup: withSkills(strayInCursor) },
];
```

- [ ] **Step 2: Cross-check against the existing dots spec**

Run: `grep -oE "it\\((\"|')[^\"']+" ~/Work/dots/assets/integration/bin/xc-skills.spec.ts | sed -E "s/it\\([\"']//"`

For every listed scenario, whose input (argv + filesystem setup) is not already covered by a case above, append a case to `cases` in the same style, with a descriptive `id`. Acceptance: each of the 44 existing scenarios maps to at least one case id. Record the mapping as a comment block at the bottom of the cases file (`// dots spec → case id`).

- [ ] **Step 3: Write the suite** — `contract/xc-skills.contract.test.ts`

```ts
import { describe, expect, test } from "bun:test";
import { cases } from "./cases/xc-skills.cases";
import { runCase } from "./lib/run-case";

describe("xc-skills", () => {
  test("case ids are unique", () => expect(new Set(cases.map((c) => c.id)).size).toBe(cases.length));
  for (const c of cases) test(c.id, () => runCase("xc-skills", c), 20_000);
});
```

- [ ] **Step 4: Run to fail, record, review**

```bash
bun test contract/xc-skills.contract.test.ts            # FAIL: missing goldens
BENCH_RECORD=1 bun test contract/xc-skills.contract.test.ts
```

Review by hand:

- `ls-raw.stdout` lists `alpha` and `beta` paths but not `.hidden`.
- `sync-agent.fs` has `~/.gemini/antigravity/skills/alpha` → `link:…/.claude/skills/alpha`.
- `sync-prune.fs` has no `…/removed` entry.
- `sync-dry-run.fs` equals the plain `skillsTree` layout (nothing written).
- `clip.calls` contains `pbcopy.stdin` with `alpha\nbeta\n`.
- `collect.fs` shows `~/.cursor/skills/stray` as a `link:` entry.

- [ ] **Step 5: Verify stable replay** — `bun test contract/xc-skills.contract.test.ts` twice; all pass.

- [ ] **Step 6: Commit**

```bash
git add contract && git commit -m "test(contract): Add xc-skills contract for ls, sync, collect and helpers"
```

---

### Task 10: `xc-sec` contract (assertion-based, from design §8)

**Files:**

- Create: `contract/xc-sec.contract.test.ts`

Pinned behavior (refines design §8; amendment 5):

- `xc-sec` with no args: help on stderr, exit 1. `--help`: exit 0, stdout contains `xc-sec`.
- `xc-sec scan [--profile balanced|strict] [paths…]`: targets = the 8 default history files under `$HOME` (`.zsh_history`, `.bash_history`, `.config/fish/fish_history`, `.python_history`, `.node_repl_history`, `.psql_history`, `.mysql_history`, `.lesshst`) followed by extra paths. Missing files are skipped silently. For each line matching any pattern (case-insensitive), print `<path>:<line>` (the secret is never printed). Exit 2 if anything matched, else 0.
- `xc-sec redact [--profile …] [--dry-run] [paths…]`: for each target with ≥1 matching line:
  - without `--dry-run`: copy it to `<path>.bak.<YYYYmmddHHMMSS>`, replace every match with `[REDACTED]` (patterns applied in listed order), print `redacted <path> (<n> lines)`;
  - with `--dry-run`: print `would redact <path> (<n> lines)` and write nothing.

  After a non-dry run with ≥1 file, print `backups: *.bak.<STAMP>`. With no matches at all, print `nothing to redact`. Exit 0.
- Invalid mode or profile: exit 1, stderr non-empty.

- [ ] **Step 1: Write the contract**

```ts
import { afterEach, describe, expect, test } from "bun:test";
import { existsSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { binDir, Sandbox } from "./lib/sandbox";

// Built at runtime so secret scanners do not flag this file.
const GH = ["gh", "p_", "x".repeat(36)].join("");
const OPENAI = ["OPENAI", "_API_KEY=sk-", "y".repeat(20)].join("");
const STRICT_ONLY = ["PASS", "WORD=hunter2"].join("");
const SAMPLE = ["echo hello", `export GITHUB=${GH}`, OPENAI, STRICT_ONLY, "ls -la", ""].join("\n");

const present = existsSync(join(binDir(), "xc-sec"));
let sb: Sandbox;
afterEach(() => sb?.dispose());

const setup = (content = SAMPLE) => {
  sb = new Sandbox();
  const f = join(sb.work, "s.txt");
  writeFileSync(f, content);
  return f;
};
const run = (...argv: string[]) => sb.run("xc-sec", argv, {});
const lines = (s: string) => s.split("\n").filter(Boolean);

describe.skipIf(!present)("xc-sec", () => {
  test("no args prints help to stderr and exits 1", () => {
    setup();
    const r = run();
    expect(r.exitCode).toBe(1);
    expect(r.stdout).toBe("");
    expect(r.stderr.length).toBeGreaterThan(0);
  });

  test("--help exits 0", () => {
    setup();
    const r = run("--help");
    expect(r.exitCode).toBe(0);
    expect(r.stdout).toContain("xc-sec");
  });

  test("scan balanced reports path:line and exits 2", () => {
    const f = setup();
    const r = run("scan", f);
    expect(r.exitCode).toBe(2);
    expect(lines(r.stdout)).toEqual([`${f}:2`, `${f}:3`]);
    expect(r.stdout).not.toContain(GH);
  });

  test("scan strict adds strict-only patterns", () => {
    const f = setup();
    expect(lines(run("scan", "--profile", "strict", f).stdout)).toEqual([`${f}:2`, `${f}:3`, `${f}:4`]);
  });

  test("scan is case-insensitive", () => {
    const f = setup("openai_api_key=abc\n");
    expect(lines(run("scan", f).stdout)).toEqual([`${f}:1`]);
  });

  test("scan clean file exits 0 with no output", () => {
    const f = setup("nothing here\n");
    const r = run("scan", f);
    expect(r.exitCode).toBe(0);
    expect(r.stdout).toBe("");
  });

  test("scan includes default history targets under HOME", () => {
    setup();
    const h = join(sb.home, ".zsh_history");
    writeFileSync(h, SAMPLE);
    expect(lines(run("scan").stdout)).toEqual([`${h}:2`, `${h}:3`]);
  });

  test("scan skips missing paths", () => {
    setup();
    const r = run("scan", join(sb.work, "missing.txt"));
    expect(r.exitCode).toBe(0);
    expect(r.stdout).toBe("");
  });

  test("redact rewrites matches and keeps a timestamped backup", () => {
    const f = setup();
    const r = run("redact", f);
    expect(r.exitCode).toBe(0);
    expect(readFileSync(f, "utf8").split("\n")).toEqual(["echo hello", "export GITHUB=[REDACTED]", "[REDACTED]", STRICT_ONLY, "ls -la", ""]);
    const baks = readdirSync(sb.work).filter((n) => /^s\.txt\.bak\.\d{14}$/.test(n));
    expect(baks.length).toBe(1);
    expect(readFileSync(join(sb.work, baks[0]), "utf8")).toBe(SAMPLE);
    const out = lines(r.stdout);
    expect(out[0]).toBe(`redacted ${f} (2 lines)`);
    expect(out.at(-1)).toMatch(/^backups: \*\.bak\.\d{14}$/);
  });

  test("redact strict also redacts strict-only lines", () => {
    const f = setup();
    expect(lines(run("redact", "--profile", "strict", f).stdout)[0]).toBe(`redacted ${f} (3 lines)`);
    expect(readFileSync(f, "utf8").split("\n")[3]).toBe("[REDACTED]");
  });

  test("redact --dry-run writes nothing", () => {
    const f = setup();
    const r = run("redact", "--dry-run", f);
    expect(r.exitCode).toBe(0);
    expect(lines(r.stdout)).toEqual([`would redact ${f} (2 lines)`]);
    expect(readFileSync(f, "utf8")).toBe(SAMPLE);
    expect(readdirSync(sb.work).some((n) => n.includes(".bak."))).toBe(false);
  });

  test("redact with no matches says so", () => {
    const f = setup("clean\n");
    const r = run("redact", f);
    expect(lines(r.stdout)).toEqual(["nothing to redact"]);
    expect(readdirSync(sb.work).some((n) => n.includes(".bak."))).toBe(false);
  });

  test("invalid profile exits 1", () => {
    const f = setup();
    const r = run("scan", "--profile", "bogus", f);
    expect(r.exitCode).toBe(1);
    expect(r.stderr.length).toBeGreaterThan(0);
  });

  test("invalid mode exits 1", () => {
    setup();
    const r = run("bogus");
    expect(r.exitCode).toBe(1);
    expect(r.stderr.length).toBeGreaterThan(0);
  });
});
```

- [ ] **Step 2: Confirm it is skipped for the originals and not vacuous**

```bash
bun test contract/xc-sec.contract.test.ts                        # 14 skipped (no originals/bin/xc-sec)
T=$(mktemp -d) && cp originals/reference/xc-sec "$T/" && chmod +x "$T/xc-sec"
CONTRACT_BIN_DIR="$T" bun test contract/xc-sec.contract.test.ts  # expect several FAILs (pre-spec script)
```

Expected: first run skips everything; second run fails at least the `--dry-run`, exit-2 and output-format tests. That proves the contract encodes the new spec rather than the old script.

- [ ] **Step 3: Scan for secrets**

Run: `gitleaks dir contract --no-banner`
Expected: `no leaks found`.

- [ ] **Step 4: Commit**

```bash
git add contract && git commit -m "test(contract): Add spec-derived xc-sec contract"
```

---

### Task 11: Mutation check + stub control

**Files:**

- Create: `contract/mutations.ts`, `contract/mutate.ts`, `contract/mutation-report.md` (generated)

- [ ] **Step 1: Write `contract/mutations.ts`**

```ts
export interface Mutation { id: string; tool: string; find: string; replace: string }

/** gitx: short-circuit a case branch with `exit 0` (the "dummy body" failure mode). */
const GITX_BRANCHES = [
  "branches", "head-branch", "cnb", "nb", "clear-merged", "clear-gone", "remote-branches", "root-commit",
  "uu", "uup", "p", "pf", "pa", "pt", "pc", "pp", "rebase-from", "edit", "drop", "reword", "fix-root", "fix",
  "fixup", "squash", "fix-all", "squash-all", "lol|fzl|fzlog", "fzb", "fza", "fzu", "fzus", "fzc",
  "grep-commit", "tail", "grep-branch", "strip", "preview",
];

/** Insert `return 0` at the top of a function body. */
const stubFn = (tool: string, fn: string): Mutation => ({
  id: `${tool}:${fn}`, tool, find: `${fn}() {\n`, replace: `${fn}() {\n  return 0\n`,
});

export const mutations: Mutation[] = [
  // xc-puts (flat script)
  { id: "xc-puts:gum-level", tool: "xc-puts", find: 'gum log --time DateTime --level "$level" "$message"', replace: ":" },
  { id: "xc-puts:gum-style", tool: "xc-puts", find: 'gum style --foreground "$color" "$message"', replace: ":" },
  { id: "xc-puts:plain", tool: "xc-puts", find: 'print "$message"', replace: ":" },
  { id: "xc-puts:red-color", tool: "xc-puts", find: 'color="#F44336"', replace: 'color="#000000"' },
  { id: "xc-puts:level-upper", tool: "xc-puts", find: "tr '[:lower:]' '[:upper:]'", replace: "cat" },
  { id: "xc-puts:prefix-color", tool: "xc-puts", find: 'print -P "%F{gray}${prefix_value}:%f ${zsh_color}${message}%f"', replace: 'print -P "${zsh_color}${message}%f"' },

  // gitx
  ...GITX_BRANCHES.map((b): Mutation => ({ id: `gitx:${b}`, tool: "gitx", find: `\n  ${b})\n`, replace: `\n  ${b})\n    exit 0\n` })),
  stubFn("gitx", "_gitx_branches"),
  stubFn("gitx", "_gitx_head_branch"),
  stubFn("gitx", "_gitx_root_commit"),

  // xc-skills
  stubFn("xc-skills", "cmd_ls"),
  stubFn("xc-skills", "cmd_sync"),
  stubFn("xc-skills", "cmd_collect"),
  stubFn("xc-skills", "resolve_agent_path"),
  stubFn("xc-skills", "_preview_skill"),
  stubFn("xc-skills", "_copy_to_clipboard"),
  { id: "xc-skills:dry-run-marker", tool: "xc-skills", find: "printf '[dry-run] '", replace: "printf ''" },
  { id: "xc-skills:sync-link", tool: "xc-skills", find: 'run_cmd /bin/ln -s "$target" "$out"', replace: "true" },
  { id: "xc-skills:collect-relink", tool: "xc-skills", find: 'run_cmd /bin/rm -f "$entry" && run_cmd /bin/ln -s "$src_file" "$entry"', replace: "true" },
];

/**
 * Mutants allowed to survive, each with a written justification (reviewed by a human).
 * Keep empty unless a mutant is provably equivalent.
 */
export const equivalent: Record<string, string> = {};
```

- [ ] **Step 2: Write `contract/mutate.ts`**

```ts
#!/usr/bin/env bun
import { chmodSync, cpSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { equivalent, mutations } from "./mutations";
import { ROOT } from "./lib/sandbox";

const ORIG = join(ROOT, "originals", "bin");
const TOOLS = ["xc-puts", "gitx", "xc-skills", "xc-sec"];

function suite(toolName: string, binDirPath: string): { exitCode: number; tests: number; failures: number } {
  const junit = join(binDirPath, `${toolName}.junit.xml`);
  const r = Bun.spawnSync(
    [process.execPath, "test", `contract/${toolName}.contract.test.ts`, "--reporter=junit", `--reporter-outfile=${junit}`],
    { cwd: ROOT, env: { ...process.env, CONTRACT_BIN_DIR: binDirPath, BENCH_RECORD: "" }, stdout: "ignore", stderr: "ignore" },
  );
  const xml = readFileSync(junit, "utf8");
  const tests = Number(xml.match(/<testsuites[^>]*tests="(\d+)"/)?.[1] ?? 0);
  const failures = Number(xml.match(/<testsuites[^>]*failures="(\d+)"/)?.[1] ?? 0);
  return { exitCode: r.exitCode ?? -1, tests, failures };
}

const rows: string[] = [];
let survivors = 0;

for (const m of mutations) {
  const dir = mkdtempSync(join(tmpdir(), "bench-mut-"));
  cpSync(ORIG, dir, { recursive: true });
  const file = join(dir, m.tool);
  const src = readFileSync(file, "utf8");
  const hits = src.split(m.find).length - 1;
  if (hits !== 1) throw new Error(`${m.id}: expected exactly 1 match, found ${hits}`);
  writeFileSync(file, src.replace(m.find, m.replace));
  const r = suite(m.tool, dir);
  const killed = r.exitCode !== 0;
  const status = killed ? "killed" : equivalent[m.id] ? `equivalent: ${equivalent[m.id]}` : "SURVIVED";
  if (!killed && !equivalent[m.id]) survivors++;
  rows.push(`| \`${m.id}\` | ${r.failures}/${r.tests} | ${status} |`);
  rmSync(dir, { recursive: true, force: true });
}

// Stub control: a tool that does nothing and exits 0 must fail >= 90% of its cases.
const stubRows: string[] = [];
let weakSuites = 0;
for (const t of TOOLS) {
  const dir = mkdtempSync(join(tmpdir(), "bench-stub-"));
  const f = join(dir, t);
  writeFileSync(f, "#!/bin/sh\nexit 0\n");
  chmodSync(f, 0o755);
  const r = suite(t, dir);
  const ratio = r.tests ? r.failures / r.tests : 0;
  if (ratio < 0.9) weakSuites++;
  stubRows.push(`| \`${t}\` | ${r.failures}/${r.tests} | ${(ratio * 100).toFixed(0)}% | ${ratio >= 0.9 ? "ok" : "WEAK"} |`);
  rmSync(dir, { recursive: true, force: true });
}

const report = [
  "# Mutation report",
  "",
  `Generated by \`mise run mutate\` on ${new Date().toISOString().slice(0, 10)}.`,
  "",
  "## Mutants of the originals",
  "",
  "| Mutant | Failing tests | Result |",
  "| ------ | ------------- | ------ |",
  ...rows,
  "",
  "## Stub control (`exit 0` binary)",
  "",
  "| Tool | Failing tests | Ratio | Result |",
  "| ---- | ------------- | ----- | ------ |",
  ...stubRows,
  "",
].join("\n");
writeFileSync(join(ROOT, "contract", "mutation-report.md"), report);
console.log(report);
if (survivors || weakSuites) {
  console.error(`\n${survivors} surviving mutant(s), ${weakSuites} weak suite(s)`);
  process.exit(1);
}
```

- [ ] **Step 3: Run it**

Run: `mise run mutate`
Expected: exit 0; every row `killed`; every stub-control row `ok`.

- [ ] **Step 4: Handle survivors (loop until clean)**

For each `SURVIVED` row, add a case in `contract/cases/<tool>.cases.ts` whose output or repo state depends on that code. For example, if `gitx:uup` survives, check that the `uup` case's `withUpstream` setup really puts a commit on `upstream/main`. Then re-record only the new cases: `BENCH_RECORD=1 bun test contract/<tool>.contract.test.ts -t '<new-id>'`. Re-review them, and re-run `mise run mutate`.

Add an entry to `equivalent` only when the mutated code truly cannot change observable behavior, and write the reason. Example: `"gitx:x": "branch output always goes to /dev/null and has no side effect"`.

- [ ] **Step 5: Commit**

```bash
git add contract && git commit -m "test(contract): Prove contract kills mutants and stub binaries"
```

---

### Task 12: Freeze the contract

**Files:**

- Create: `contract/README.md`, `contract/FROZEN`

- [ ] **Step 1: Write `contract/README.md`**

```markdown
# Behavior contract (frozen)

Black-box contract every stack must pass unchanged. Run against any build:

    CONTRACT_BIN_DIR=stacks/<id>/dist/bin mise run contract

- Goldens were recorded from `originals/bin` (see `originals/SOURCE.md`) and
  hand-reviewed. `mutation-report.md` proves the suite detects gutted logic.
- **Frozen:** files under `contract/` are read-only for ports. The freeze
  commit is recorded in `contract/FROZEN`. A port whose branch changes any
  file under `contract/` is disqualified (design §5.7).
- Fakes: `gum fzf pbcopy wl-copy xclip xsel glow bat skills` log their argv;
  git is real and checked through repo state (design amendment 1).
```

- [ ] **Step 2: Commit and record the freeze**

```bash
git add contract/README.md && git commit -m "docs(contract): Document frozen contract"
git rev-parse HEAD > contract/FROZEN
git add contract/FROZEN && git commit -m "chore(contract): Freeze contract at $(cut -c1-8 contract/FROZEN)"
```

- [ ] **Step 3: Add the freeze guard used in Plan 2 reviews**

Run (and keep the command in `contract/README.md` under a "Verify freeze" heading):

```bash
git diff --stat "$(cat contract/FROZEN)" -- contract ':!contract/FROZEN' ':!contract/mutation-report.md'
```

Expected: empty output.

---

### Task 13: Benchmark stubs, stack registry and probes

**Files:**

- Create: `bench/stubs/{git,gum,fzf}`, `bench/floors/usage-zsh`, `bench/stacks.ts`, `bench/probes.ts`

- [ ] **Step 1: Write the stubs** (minimal `sh`; count calls only when `BENCH_STUB_COUNT` is set)

`bench/stubs/git`:

```sh
#!/bin/sh
[ -n "$BENCH_STUB_COUNT" ] && printf . >>"$BENCH_STUB_COUNT"
printf '%s\n' '* main           1111111 [origin/main] second' '  feature/open   2222222 [origin/feature/open] open work' '  remotes/origin/HEAD -> origin/main' '  remotes/origin/main 1111111 second'
```

`bench/stubs/gum`:

```sh
#!/bin/sh
[ -n "$BENCH_STUB_COUNT" ] && printf . >>"$BENCH_STUB_COUNT"
exit 0
```

`bench/stubs/fzf`:

```sh
#!/bin/sh
[ -n "$BENCH_STUB_COUNT" ] && printf . >>"$BENCH_STUB_COUNT"
head -n 1
```

```bash
chmod +x bench/stubs/*
```

- [ ] **Step 1b: Write the P0 floor program** — `bench/floors/usage-zsh`

An empty program in the S1/original stack: the `usage` shebang, a spec, no work.

```zsh
#!/usr/bin/env -S usage zsh
#USAGE about "P0 floor: usage + zsh, no work"
```

```bash
chmod +x bench/floors/usage-zsh
```

- [ ] **Step 2: Write `bench/stacks.ts`**

```ts
import { join } from "node:path";
import { ROOT } from "../contract/lib/sandbox";
import { tool } from "../contract/lib/tools";

export const SAMPLE_TOOLS = ["xc-puts", "gitx", "xc-skills"] as const;
/** Total tools in config/bin; used to project disk footprint (design §7.1 P6b). */
export const TOTAL_TOOLS = 23;

export interface Stack {
  id: string;
  label: string;
  /** false = measured and reported, never scored (e.g. originals). */
  scored: boolean;
  /** Directory with one executable per tool name. */
  binDir: string;
  tools: readonly string[];
  /** Source dirs for static metrics (tests excluded). */
  srcDirs: string[];
  /** Files counted once in the footprint (runtimes, multicall binary). */
  shared: () => string[];
  /** Files counted per tool (script, binary or symlink). */
  perTool: (toolName: string) => string[];
  /** S1b only: autoload dir for in-process calls (P5). */
  inProcess?: { fpath: string };
  /** P0: argv of an empty program in this stack (design §7.1). */
  floor: string[];
}

const originalsBin = join(ROOT, "originals", "bin");

export const stacks: Stack[] = [
  {
    id: "s0-original",
    label: "Original dots scripts (reference)",
    scored: false,
    binDir: originalsBin,
    tools: SAMPLE_TOOLS,
    srcDirs: [originalsBin],
    shared: () => [tool("usage")],
    perTool: (t) => [join(originalsBin, t)],
    floor: [join(ROOT, "bench", "floors", "usage-zsh")],
  },
  // Plan 2 appends: s1-zsh, s1b-zsh-fn, s2-rust, s3i-bun, s3c-bun
];

export function getStack(id: string): Stack {
  const s = stacks.find((x) => x.id === id);
  if (!s) throw new Error(`unknown stack ${id}; known: ${stacks.map((x) => x.id).join(", ")}`);
  return s;
}
```

- [ ] **Step 3: Write `bench/probes.ts`**

```ts
import { buildRepo, skillsTree } from "../contract/lib/fixtures";
import type { Sandbox } from "../contract/lib/sandbox";

export interface Probe {
  argv: string[];
  cwd: "work" | "repo";
  setup: (sb: Sandbox) => void;
}

/** The "typical call" per tool (design §7.1). Fixed; do not tune per stack. */
export const probes: Record<string, Probe> = {
  "xc-puts": { argv: ["--green", "msg"], cwd: "work", setup: () => {} },
  gitx: { argv: ["branches"], cwd: "repo", setup: buildRepo },
  "xc-skills": { argv: ["ls", "--raw"], cwd: "work", setup: skillsTree },
};
```

- [ ] **Step 4: Typecheck and commit**

```bash
bunx tsc --noEmit
git add bench && git commit -m "feat(bench): Add stubs, stack registry and typical-call probes"
```

---

### Task 14: Measurement primitives

**Files:**

- Create: `bench/measure.ts`, `bench/footprint.ts`, `bench/measure.test.ts`

- [ ] **Step 1: Write the failing test** — `bench/measure.test.ts`

```ts
import { afterEach, expect, test } from "bun:test";
import { mkdtempSync, rmSync, writeFileSync, symlinkSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { Sandbox } from "../contract/lib/sandbox";
import { hyperfine, peakRssMB, percentile } from "./measure";
import { sizeBytes } from "./footprint";

let sb: Sandbox | undefined;
afterEach(() => sb?.dispose());

test("percentile", () => {
  expect(percentile([5, 1, 3, 2, 4], 50)).toBe(3);
  expect(percentile([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 95)).toBe(10);
});

test("hyperfine returns median and p95 in ms", () => {
  sb = new Sandbox(null);
  const [r] = hyperfine(sb, ["/usr/bin/true"], { runs: 5, warmup: 1, cwd: sb.work });
  expect(r.minMs).toBeGreaterThan(0);
  expect(r.medianMs).toBeGreaterThanOrEqual(r.minMs);
  expect(r.p95Ms).toBeGreaterThanOrEqual(r.medianMs);
});

test("peakRssMB reads /usr/bin/time", () => {
  sb = new Sandbox(null);
  expect(peakRssMB(sb, ["/usr/bin/true"], sb.work)).toBeGreaterThan(0);
});

test("sizeBytes sums files and ignores symlinks", () => {
  const d = mkdtempSync(join(tmpdir(), "bench-size-"));
  writeFileSync(join(d, "a"), "x".repeat(1000));
  symlinkSync(join(d, "a"), join(d, "l"));
  expect(sizeBytes(d)).toBe(1000);
  rmSync(d, { recursive: true });
});
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bun test bench/measure.test.ts`
Expected: FAIL — `Cannot find module './measure'`.

- [ ] **Step 3: Write `bench/measure.ts`**

```ts
import { readFileSync, writeFileSync, chmodSync, mkdtempSync, rmSync } from "node:fs";
import { join } from "node:path";
import type { Sandbox } from "../contract/lib/sandbox";
import { tool } from "../contract/lib/tools";

export interface Timing { command: string; minMs: number; medianMs: number; p95Ms: number; meanMs: number; stddevMs: number; runs: number }

export function percentile(values: number[], p: number): number {
  const s = [...values].sort((a, b) => a - b);
  const idx = Math.min(s.length - 1, Math.max(0, Math.ceil((p / 100) * s.length) - 1));
  return s[idx];
}

/** Runs hyperfine with -N (no intermediate shell) inside the sandbox env. */
export function hyperfine(sb: Sandbox, commands: string[], o: { runs: number; warmup: number; cwd: string; env?: Record<string, string> }): Timing[] {
  const out = join(sb.root, `hf-${Date.now()}.json`);
  const r = Bun.spawnSync(
    [tool("hyperfine"), "-N", "--warmup", String(o.warmup), "--runs", String(o.runs), "--style", "none", "--export-json", out, ...commands],
    { cwd: o.cwd, env: sb.env(o.env), stdout: "pipe", stderr: "pipe" },
  );
  if (r.exitCode !== 0) throw new Error(`hyperfine failed: ${r.stderr.toString()}`);
  const json = JSON.parse(readFileSync(out, "utf8")) as { results: Array<{ command: string; mean: number; stddev: number; times: number[] }> };
  return json.results.map((x) => ({
    command: x.command,
    minMs: Math.min(...x.times) * 1000,
    medianMs: percentile(x.times, 50) * 1000,
    p95Ms: percentile(x.times, 95) * 1000,
    meanMs: x.mean * 1000,
    stddevMs: (x.stddev ?? 0) * 1000,
    runs: x.times.length,
  }));
}

const RSS_MAC = /(\d+)\s+maximum resident set size/;
const RSS_LINUX = /Maximum resident set size \(kbytes\): (\d+)/;

export function parseRssMB(stderr: string): number {
  const mac = stderr.match(RSS_MAC);
  if (mac) return Number(mac[1]) / 1024 / 1024;
  const lin = stderr.match(RSS_LINUX);
  if (lin) return Number(lin[1]) / 1024;
  throw new Error(`no RSS in /usr/bin/time output:\n${stderr}`);
}

/** Peak RSS (MB) of the largest process in the call tree, via /usr/bin/time. */
export function peakRssMB(sb: Sandbox, argv: string[], cwd: string, env?: Record<string, string>): number {
  const flag = process.platform === "darwin" ? "-l" : "-v";
  const r = Bun.spawnSync(["/usr/bin/time", flag, ...argv], { cwd, env: sb.env(env), stdout: "ignore", stderr: "pipe" });
  return parseRssMB(r.stderr.toString());
}

export function medianRssMB(sb: Sandbox, argv: string[], cwd: string, runs = 10): number {
  return percentile(Array.from({ length: runs }, () => peakRssMB(sb, argv, cwd)), 50);
}

/** P7: N concurrent calls. Returns wall-time timing and summed peak RSS. */
export function burst(sb: Sandbox, argv: string[], cwd: string, o: { n: number; runs: number; warmup: number }): { wall: Timing; summedRssMB: number } {
  const quoted = argv.map((a) => `'${a.replaceAll("'", `'\\''`)}'`).join(" ");
  const wallScript = join(sb.root, "burst.sh");
  writeFileSync(wallScript, `#!/bin/bash\nfor i in $(seq 1 ${o.n}); do ${quoted} >/dev/null 2>&1 & done\nwait\n`);
  chmodSync(wallScript, 0o755);
  const [wall] = hyperfine(sb, [wallScript], { runs: o.runs, warmup: o.warmup, cwd });

  const dir = mkdtempSync(join(sb.root, "rss-"));
  const flag = process.platform === "darwin" ? "-l" : "-v";
  const rssScript = join(sb.root, "burst-rss.sh");
  writeFileSync(rssScript, `#!/bin/bash\nfor i in $(seq 1 ${o.n}); do /usr/bin/time ${flag} ${quoted} >/dev/null 2>"${dir}/$i" & done\nwait\n`);
  chmodSync(rssScript, 0o755);
  Bun.spawnSync([rssScript], { cwd, env: sb.env(), stdout: "ignore", stderr: "ignore" });
  let summed = 0;
  for (let i = 1; i <= o.n; i++) summed += parseRssMB(readFileSync(join(dir, String(i)), "utf8"));
  rmSync(dir, { recursive: true, force: true });
  return { wall, summedRssMB: summed };
}
```

- [ ] **Step 4: Write `bench/footprint.ts`**

```ts
import { lstatSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { type Stack, TOTAL_TOOLS } from "./stacks";

/** Apparent size of files; symlinks count 0; directories are summed. */
export function sizeBytes(path: string): number {
  const st = lstatSync(path);
  if (st.isSymbolicLink()) return 0;
  if (st.isDirectory()) return readdirSync(path).reduce((n, e) => n + sizeBytes(join(path, e)), 0);
  return st.size;
}

export interface Footprint { sharedMB: number; perToolMB: number; projectedMB: number }

/** P6b: shared + mean(per-tool) x TOTAL_TOOLS (design §7.1). */
export function footprint(s: Stack): Footprint {
  const mb = (b: number) => b / 1024 / 1024;
  const shared = s.shared().reduce((n, p) => n + sizeBytes(p), 0);
  const per = s.tools.map((t) => s.perTool(t).reduce((n, p) => n + sizeBytes(p), 0));
  const perTool = per.reduce((a, b) => a + b, 0) / per.length;
  return { sharedMB: mb(shared), perToolMB: mb(perTool), projectedMB: mb(shared + perTool * TOTAL_TOOLS) };
}
```

- [ ] **Step 5: Run the tests**

Run: `bun test bench/measure.test.ts && bunx tsc --noEmit`
Expected: 4 pass, no type errors.

- [ ] **Step 6: Commit**

```bash
git add bench && git commit -m "feat(bench): Add hyperfine, RSS, burst and footprint primitives"
```

---

### Task 15: Static metrics + machine info

**Files:**

- Create: `bench/static.ts`, `bench/machine.ts`, `bench/shell-fn-length.awk`

- [ ] **Step 1: Write `bench/shell-fn-length.awk`**

```awk
# Prints "<file>:<name> <length>" for each shell function whose opening
# line is `name() {` and whose body ends at the first line that is `}`
# at the same indentation.
match($0, /^([ \t]*)([A-Za-z_][A-Za-z0-9_:-]*)[ \t]*\(\)[ \t]*\{[ \t]*$/, m) {
  indent = m[1]; name = m[2]; start = FNR; next
}
name != "" && $0 == indent "}" { print FILENAME ":" name " " (FNR - start + 1); name = "" }
```

This needs gawk (the three-argument `match`). Add it: `mise use --pin gawk@latest`, and invoke it as `gawk`.

- [ ] **Step 2: Write `bench/static.ts`**

```ts
import { mkdtempSync, readFileSync, readdirSync, rmSync, statSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { ROOT } from "../contract/lib/sandbox";
import type { Stack } from "./stacks";

export interface StaticMetrics {
  codeLines: number;
  byLanguage: Record<string, number>;
  largestFile: { path: string; lines: number };
  largestFunction: { name: string; lines: number };
  duplicationPct: number;
}

const sh = (argv: string[]) => {
  const r = Bun.spawnSync(argv, { cwd: ROOT, stdout: "pipe", stderr: "pipe" });
  if (r.exitCode !== 0) throw new Error(`${argv[0]} failed: ${r.stderr.toString()}`);
  return r.stdout.toString();
};

function files(dirs: string[]): string[] {
  const out: string[] = [];
  const walk = (d: string) => {
    for (const e of readdirSync(d)) {
      const p = join(d, e);
      if (["node_modules", "target", "dist", ".git"].includes(e) || /\.test\.|\.spec\.|tests?$/.test(e)) continue;
      statSync(p).isDirectory() ? walk(p) : out.push(p);
    }
  };
  dirs.forEach(walk);
  return out;
}

export function staticMetrics(s: Stack): StaticMetrics {
  const fs = files(s.srcDirs);
  const scc = JSON.parse(sh(["scc", "--format", "json", "--by-file", "--no-cocomo", ...s.srcDirs])) as Array<{ Name: string; Code: number; Files: Array<{ Location: string; Code: number }> }>;
  const byLanguage = Object.fromEntries(scc.map((l) => [l.Name, l.Code]));
  const allFiles = scc.flatMap((l) => l.Files).filter((f) => fs.includes(f.Location) || fs.some((x) => x.endsWith(f.Location)));
  const largestFile = allFiles.reduce((a, f) => (f.Code > a.lines ? { path: f.Location, lines: f.Code } : a), { path: "", lines: 0 });

  let largestFunction = { name: "", lines: 0 };
  const shellFiles = fs.filter((f) => /^#!.*\b(zsh|bash|sh)\b/.test(readFileSync(f, "utf8").split("\n")[0]) || /\.(zsh|sh|bash)$/.test(f));
  if (shellFiles.length) {
    for (const line of sh(["gawk", "-f", join(ROOT, "bench", "shell-fn-length.awk"), ...shellFiles]).trim().split("\n").filter(Boolean)) {
      const [name, n] = line.split(" ");
      if (Number(n) > largestFunction.lines) largestFunction = { name, lines: Number(n) };
    }
  }
  const lizardFiles = fs.filter((f) => /\.(rs|ts)$/.test(f));
  if (lizardFiles.length) {
    // lizard --csv columns: NLOC,CCN,token,PARAM,length,location,file,function,long_name,start,end
    for (const row of sh(["lizard", "--csv", ...lizardFiles]).trim().split("\n").filter(Boolean)) {
      const cols = row.split(",");
      const length = Number(cols[4]);
      if (length > largestFunction.lines) largestFunction = { name: `${cols[6]}:${cols[7]}`.replaceAll('"', ""), lines: length };
    }
  }

  const out = mkdtempSync(join(tmpdir(), "bench-jscpd-"));
  sh(["jscpd", "--silent", "--reporters", "json", "--output", out, ...s.srcDirs]);
  const jscpd = JSON.parse(readFileSync(join(out, "jscpd-report.json"), "utf8")) as { statistics: { total: { percentage: number } } };
  rmSync(out, { recursive: true, force: true });

  const codeLines = Object.values(byLanguage).reduce((a, b) => a + b, 0);
  return { codeLines, byLanguage, largestFile, largestFunction, duplicationPct: jscpd.statistics.total.percentage };
}
```

Note: the originals are extension-less scripts, so `scc` may classify them by shebang or skip them. In Step 4, check that `codeLines` > 0 for `s0-original`. If it is 0, add `--remap-unknown "zsh:Shell,bash:BASH"` to the scc call.

- [ ] **Step 3: Write `bench/machine.ts`**

```ts
import { tool } from "../contract/lib/tools";

const out = (argv: string[]) => {
  const r = Bun.spawnSync(argv, { stdout: "pipe", stderr: "pipe" });
  return (r.stdout.toString() || r.stderr.toString()).trim().split("\n")[0];
};

export function machineInfo() {
  const cpu = process.platform === "darwin"
    ? out(["sysctl", "-n", "machdep.cpu.brand_string"])
    : out(["sh", "-c", "grep -m1 'model name' /proc/cpuinfo | cut -d: -f2"]);
  const memBytes = process.platform === "darwin"
    ? Number(out(["sysctl", "-n", "hw.memsize"]))
    : Number(out(["sh", "-c", "grep MemTotal /proc/meminfo | awk '{print $2*1024}'"]));
  const v = (name: string, arg = "--version") => { try { return out([tool(name), arg]); } catch { return "n/a"; } };
  return {
    date: new Date().toISOString(),
    label: hostLabel(cpu),
    platform: process.platform,
    arch: process.arch,
    os: out(["uname", "-sr"]),
    cpu,
    memGB: Math.round(memBytes / 1024 ** 3),
    versions: { hyperfine: v("hyperfine"), usage: v("usage"), bun: v("bun"), zsh: v("zsh"), bash: v("bash"), git: v("git") },
  };
}

/** Publishable host label (amendment 6): never the real hostname. */
export function hostLabel(cpu: string): string {
  return process.env.BENCH_HOST_LABEL ?? cpu.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}
```

- [ ] **Step 4: Smoke test on the originals**

Run: `bun -e 'import {staticMetrics} from "./bench/static"; import {getStack} from "./bench/stacks"; console.log(JSON.stringify(staticMetrics(getStack("s0-original")), null, 2))'`
Expected: `codeLines` > 1000; `largestFile.path` ends in `xc-skills`; `largestFunction.lines` > 40 (for example `cmd_sync`); `duplicationPct` is a number.

- [ ] **Step 5: Commit**

```bash
git add bench mise.toml && git commit -m "feat(bench): Add static metrics and publishable machine info"
```

---

### Task 16: Orchestrator (`mise run bench`)

**Files:**

- Create: `bench/run.ts`

`run.ts` also measures P0 (the stack floor) once per stack, and runs the preflight before timing each tool (design §7.1, rules adopted from `jdx/usage` `tasks/perf-*.sh`).

- [ ] **Step 1: Write `bench/run.ts`**

```ts
#!/usr/bin/env bun
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { parseArgs } from "node:util";
import { normalize } from "../contract/lib/normalize";
import { ROOT, Sandbox } from "../contract/lib/sandbox";
import { footprint } from "./footprint";
import { machineInfo } from "./machine";
import { burst, hyperfine, medianRssMB } from "./measure";
import { probes } from "./probes";
import { getStack, type Stack, stacks } from "./stacks";
import { staticMetrics } from "./static";

const { values } = parseArgs({
  options: {
    stack: { type: "string", multiple: true },
    quick: { type: "boolean", default: false },
    session: { type: "string", default: "1" },
  },
});
const cfg = values.quick ? { runs: 20, warmup: 3, burstRuns: 5 } : { runs: 100, warmup: 10, burstRuns: 20 };
const selected: Stack[] = values.stack?.length ? values.stack.map(getStack) : stacks;
const STUBS = join(ROOT, "bench", "stubs");

const machine = machineInfo();
const outRoot = join(ROOT, "results", `${machine.date.slice(0, 10)}-${machine.label}`);
const sessionDir = join(outRoot, `session-${values.session}${values.quick ? "-quick" : ""}`);
mkdirSync(sessionDir, { recursive: true });
writeFileSync(join(outRoot, "machine.json"), `${JSON.stringify(machine, null, 2)}\n`);

/** Sandbox with the probe's fixture, tools from `binDir`, and the given fakes. */
function prepared(stack: Stack, toolName: string, fakes: string | null) {
  process.env.CONTRACT_BIN_DIR = stack.binDir;
  const sb = new Sandbox(fakes);
  const probe = probes[toolName];
  probe.setup(sb);
  const cwd = probe.cwd === "repo" ? sb.repo : sb.work;
  const argv = [join(stack.binDir, toolName), ...probe.argv];
  return { sb, cwd, argv, probe };
}

/** Typical call once under stubs; normalized stdout. Throws on non-zero exit. */
function stubbedStdout(stack: Stack, toolName: string): string {
  const s = prepared(stack, toolName, STUBS);
  try {
    const r = s.sb.exec(s.argv, { cwd: s.cwd });
    if (r.exitCode !== 0) throw new Error(`[${stack.id}] ${toolName}: preflight exit ${r.exitCode}\n${r.stderr}`);
    return normalize(r.stdout, s.sb);
  } finally {
    s.sb.dispose();
  }
}

/**
 * Preflight (design §7.1): a probe is only timed if it does the same work as the
 * original. A fast failure or an empty body would otherwise look fast.
 */
function preflight(stack: Stack, toolName: string): void {
  const expected = stubbedStdout(getStack("s0-original"), toolName);
  const actual = stubbedStdout(stack, toolName);
  if (actual !== expected) {
    throw new Error(`[${stack.id}] ${toolName}: preflight stdout differs from original\n--- expected\n${expected}\n--- actual\n${actual}`);
  }
}

function loopScript(sb: Sandbox, name: string, body: string): string {
  const p = join(sb.root, `${name}.zsh`);
  writeFileSync(p, `#!/bin/zsh -f\n${body}\n`, { mode: 0o755 });
  return p;
}

for (const stack of selected) {
  const stackDir = join(sessionDir, stack.id);
  mkdirSync(stackDir, { recursive: true });

  // P0: the stack's floor (empty program), reported beside every tool
  process.env.CONTRACT_BIN_DIR = stack.binDir;
  const fsb = new Sandbox(STUBS);
  const [p0] = hyperfine(fsb, [stack.floor.join(" ")], { runs: cfg.runs, warmup: cfg.warmup, cwd: fsb.work });
  const p0Rss = medianRssMB(fsb, stack.floor, fsb.work);
  fsb.dispose();
  writeFileSync(join(stackDir, "floor.json"), `${JSON.stringify({ p0_floor: p0, p0_peak_rss_mb: p0Rss }, null, 2)}\n`);

  for (const toolName of stack.tools) {
    console.log(`[${stack.id}] ${toolName}`);
    preflight(stack, toolName);
    const q = (a: string) => `'${a.replaceAll("'", `'\\''`)}'`;

    // P1, P2, P4, P6a, P7 with stubs; stub floor for P2 adjustment
    const s = prepared(stack, toolName, STUBS);
    const cmd = s.argv.map(q).join(" ");
    const [p1] = hyperfine(s.sb, [`${s.argv[0]} --help`], { runs: cfg.runs, warmup: cfg.warmup, cwd: s.cwd });
    const [p2] = hyperfine(s.sb, [s.argv.join(" ")], { runs: cfg.runs, warmup: cfg.warmup, cwd: s.cwd });
    const countFile = join(s.sb.root, "stub-count");
    writeFileSync(countFile, "");
    s.sb.exec(s.argv, { cwd: s.cwd, env: { BENCH_STUB_COUNT: countFile } });
    const stubCalls = readFileSync(countFile, "utf8").length;
    const [stubFloor] = hyperfine(s.sb, [`${join(s.sb.fakes, "gum")}`], { runs: cfg.runs, warmup: cfg.warmup, cwd: s.cwd });
    const loop = loopScript(s.sb, "p4", `for i in {1..100}; do ${cmd} >/dev/null 2>&1; done`);
    const [p4] = hyperfine(s.sb, [loop], { runs: Math.max(5, cfg.runs / 10), warmup: 1, cwd: s.cwd });
    let p5: number | null = null;
    if (stack.inProcess) {
      const fn = loopScript(s.sb, "p5", `fpath=(${q(stack.inProcess.fpath)} $fpath); autoload -Uz ${toolName}; for i in {1..100}; do ${toolName} ${s.probe.argv.map(q).join(" ")} >/dev/null 2>&1; done`);
      p5 = hyperfine(s.sb, [fn], { runs: Math.max(5, cfg.runs / 10), warmup: 1, cwd: s.cwd })[0].medianMs / 100;
    }
    const p6a = medianRssMB(s.sb, s.argv, s.cwd);
    const p7 = burst(s.sb, s.argv, s.cwd, { n: 20, runs: cfg.burstRuns, warmup: 1 });
    s.sb.dispose();

    // P3: no fakes/stubs (real git; gum/fzf absent)
    const r = prepared(stack, toolName, null);
    const [p3] = hyperfine(r.sb, [r.argv.join(" ")], { runs: cfg.runs, warmup: cfg.warmup, cwd: r.cwd });
    r.sb.dispose();

    const result = {
      stack: stack.id, tool: toolName, config: cfg,
      p1_help: p1,
      p2_typical_stubbed: p2,
      p2_stub_calls: stubCalls,
      p2_stub_floor_ms: stubFloor.medianMs,
      p2_adjusted_ms: Math.max(0, p2.medianMs - stubCalls * stubFloor.medianMs),
      p3_typical_real: p3,
      p4_per_call_ms: p4.medianMs / 100,
      p5_in_process_ms: p5,
      p6a_peak_rss_mb: p6a,
      p7_burst: p7,
    };
    writeFileSync(join(stackDir, `${toolName}.json`), `${JSON.stringify(result, null, 2)}\n`);
  }
  writeFileSync(join(stackDir, "footprint.json"), `${JSON.stringify(footprint(stack), null, 2)}\n`);
  writeFileSync(join(stackDir, "static.json"), `${JSON.stringify(staticMetrics(stack), null, 2)}\n`);
}
delete process.env.CONTRACT_BIN_DIR;
console.log(`results: ${sessionDir}`);
```

- [ ] **Step 2: Typecheck**

Run: `bunx tsc --noEmit`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add bench && git commit -m "feat(bench): Add orchestrator writing per-session results"
```

---

### Task 17: Baseline run on the originals + sanity checks

**Files:**

- Create: `results/<date>-<label>/…` (generated), `docs/methodology.md`

- [ ] **Step 1: Quick run**

Run: `mise run bench -- --stack s0-original --quick`
Expected: prints `results: …/session-1-quick` and writes `xc-puts.json`, `gitx.json`, `xc-skills.json`, `footprint.json`, `static.json`.

- [ ] **Step 2: Sanity-check against the numbers measured during design**

```bash
D=$(ls -d results/*/session-1-quick | tail -1)/s0-original
for t in xc-puts gitx xc-skills; do
  jq -r --arg t "$t" '"\($t): P1 \(.p1_help.medianMs|floor)ms  P2 \(.p2_typical_stubbed.medianMs|floor)ms (min \(.p2_typical_stubbed.minMs|floor), adj \(.p2_adjusted_ms|floor))  P4 \(.p4_per_call_ms|floor)ms  RSS \(.p6a_peak_rss_mb|floor)MB  P7 \(.p7_burst.summedRssMB|floor)MB"' "$D/$t.json"
done
jq -r '"P0 floor: \(.p0_floor.medianMs)ms (min \(.p0_floor.minMs)), RSS \(.p0_peak_rss_mb)MB"' "$D/floor.json"
cat "$D/footprint.json"
```

Expected ranges (from the 2026-09-19 baseline in design §1); investigate anything outside them before continuing:

- `xc-puts` P2 ≈ 40–80 ms (baseline 57 ms); P1 < 10 ms (usage answers `--help` itself).
- Every P4 per call is within ±30% of the same tool's P2.
- P0 floor ≈ 6–10 ms (hello-world `usage zsh` measured 8.4 ms), and below every tool's P2.
- Every `minMs` ≤ `medianMs`.
- P6a between 2 and 60 MB.
- Footprint `sharedMB` ≈ 18 (the usage binary); `projectedMB` < 20.

- [ ] **Step 3: Write `docs/methodology.md`**

Write a short, publishable version of design §5–§7 plus amendments 1–8. Cover these points, one heading each:

- **Contract:** sandbox, fakes, repo state, normalization, per-platform goldens.
- **Mutation proof:** summary table of `contract/mutation-report.md`.
- **Probes P0–P7:** exact typical calls from `bench/probes.ts`; the P0 floor programs; the preflight rule; median for scoring and minimum for stability; the stub floor adjustment for P2.
- **Footprint projection:** the formula with `TOTAL_TOOLS = 23`.
- **Static metrics:** tools used and the shell awk counter.
- **Reproducing:** `mise install && mise run contract && mise run bench`.
- **Limits:** host-specific numbers; `/usr/bin/time` reports the max RSS in the process tree, not the sum.

- [ ] **Step 4: Commit**

```bash
git add results docs/methodology.md && git commit -m "bench: Record baseline for original scripts and document methodology"
```

---

### Task 18: CI workflow (inactive until published)

**Files:**

- Create: `.github/workflows/contract.yml`

- [ ] **Step 1: Write the workflow**

```yaml
name: contract
on: [push, pull_request]
jobs:
  contract:
    strategy:
      fail-fast: false
      matrix:
        os: [macos-latest, ubuntu-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - if: runner.os == 'Linux'
        run: sudo apt-get update && sudo apt-get install -y zsh
      - uses: jdx/mise-action@v2
      - run: bun install --frozen-lockfile
      - run: mise run check
      - name: Contract on originals (darwin goldens only until Plan 3)
        if: runner.os == 'macOS'
        run: mise run contract
      - run: gitleaks dir . --no-banner
```

- [ ] **Step 2: Lint locally**

Run: `mise run check && gitleaks dir . --no-banner`
Expected: typecheck and unit tests pass; `no leaks found`.

- [ ] **Step 3: Commit**

```bash
git add .github && git commit -m "ci: Run contract and secret scan on macOS and Linux"
```

---

## Definition of done (Plan 1)

- `mise run check`, `mise run contract`, and `mise run mutate` all exit 0 on the originals.
- `contract/FROZEN` holds the freeze commit, and the freeze-guard diff is empty.
- `results/<date>-<label>/session-1-quick/s0-original/` exists and passes the Task 17 sanity ranges.
- `gitleaks dir .` finds no leaks.

---

## Plan 2 outline — Ports (written after Plan 1 lands)

1. **Port brief template** (`docs/port-brief.md`): identical for every stack. It holds the contract path, `CONTRACT_BIN_DIR` usage, the time box (1 h / 3 h / 6 h), the build output layout `stacks/<id>/dist/bin/<tool>`, the `NOTES.md` template (time spent, native swaps, deviations), and the §6.3 style guide text for that stack only.
2. **One task per stack:** `s1-zsh`, `s1b-zsh-fn` (xc-puts and gitx only), `s2-rust` (workspace + multicall option), `s3-bun` (builds `s3i` shebang scripts and `s3c` compiled binaries from one source).
   - Each stack is built in its own worktree by a fresh subagent that receives only the brief.
   - Gate: `CONTRACT_BIN_DIR=stacks/<id>/dist/bin mise run contract` passes, and the freeze guard is empty.
3. **Equal review:** one `/code-review` pass per stack at the same level; fix, then re-run the contract.
4. **Register each stack** in `bench/stacks.ts` (binDir, srcDirs, shared/perTool, inProcess for S1b, and `floor`). Each stack ships its P0 floor program under `bench/floors/`: an empty Rust `main` (S2), an empty `usage exec bun` script with a `//USAGE` spec (S3i), an empty compiled Bun binary (S3c). S1b reuses `usage-zsh`.
5. **Full runs:** `mise run bench -- --session N` for N = 1..3, on a quiet machine, plugged in.

## Plan 3 outline — Evolve, verdict, publish

1. **`xc-sec` evolve builds** in S1, S2, S3i and S3c, against Task 10's contract. Record time to green, lines added, files touched, lib reuse, and whether `python3` was dropped.
2. **Linux goldens:** record in the `ubuntu-latest` job, commit them, and enable Linux contract runs for every stack (the Flexibility score).
3. **`bench/score.ts`:** turn the three sessions into per-criterion scores using the §7 bands and rubrics (including the pre-registered fluency ratings), apply the §9 rules, and write `docs/results.md` with charts. Show every figure as a ratio of S1 and of the stack's P0 floor. Check ±10% stability on per-session minimums. Compare the result against the pre-registered predictions.
3b. **Linux instruction counts (reported only):** a cachegrind job in CI measuring instructions per call for each stack; "not measurable" where valgrind cannot run the runtime.
3c. **Afterwards (not part of the verdict):** propose jdx/tak regression tracking for the winning stack in the rewrite.
4. **Publication readiness:** full-history gitleaks scan, personal-data grep, README TL;DR, final review. Creating and pushing the GitHub repo is left to the owner.
