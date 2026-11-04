# Repo close-out — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task by task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Remove everything obsolete, move `assets/` into `docs/` and `test/`, merge the docs into one canonical
set, get the test gate green, make `skills:restore` parallel and non-blocking, and log every bootstrap run.

**Architecture:** Mostly `git rm`/`git mv` and doc rewrites. Code changes are small and local:
`script/agent-skills.ts` (a worker pool, a background mode with a PID lock and an OS notifier),
`script/bootstrap-log.sh` (sourced by the post-packages hook and the bootstrap task), `install` (tees its output),
`config/bin/xc` (`-h`/`--help`), and the tests' path helpers.

**Tech stack:** bash, zsh, Bun 1.3 (`bun:test`, `Bun.spawn`), mise tasks, hk, Homebrew, Docker + CST.

**Spec:** [docs/superpowers/specs/2026-11-04-repo-closeout-design.md](../specs/2026-11-04-repo-closeout-design.md).
Read it first; section numbers below (§n) point into it.

## Ground rules

- Work only in the worktree `~/Work/dots-closeout`, branch `chore/repo-closeout`. Never touch `~/Work/dots`.
- Git has a SOPS filter. Use this wrapper for every git command:
  `g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }`
- Stage named paths only. Never `git add -A` or `git add .`.
- Commit messages: Conventional Commits, capitalized description, ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Let hk run; use `HK=0` only where a step says so.
- Do not push, open a PR, or run anything against `/Volumes/backups`. Task 14 is for the owner's go-ahead.
- Set `MISE_AUTO_INSTALL=0 MISE_EXEC_AUTO_INSTALL=0` for mise commands.
- If an expected output differs, stop and report what you saw. Do not improvise around a STOP.

## File map

| Path | Action |
| --- | --- |
| `.agent/`, `.claude/`, `.cursor/`, `.cursorignore`, `.specify/`, `graphify-out/`, `skills-lock.json`, `.agents/` | Delete |
| `assets/specs/`, `assets/.vscode/`, `assets/all/`, `assets/README.md`, `assets/integration/fixtures/`, `assets/scripts/`, `assets/guides/SKILLS.{md,yml}` | Delete |
| `docs/superpowers/plans/*`, `docs/superpowers/specs/*` older than 2026-11-04 | Delete |
| `config/cursor/`, `script/{skills.txt,skills.json,catalog_global_skills.py,fix_skill_commands.rb}`, `config/bin/HANDOFF-USAGE-MIGRATION.md` | Delete |
| `assets/integration/bin/{xc-md,xc-skills,xc-usage,keyring,osx,yw}.spec.ts`, `assets/integration/bin/fixtures/xc-usage/` | Delete |
| `assets/{mise.toml,package.json,tsconfig.json,features,integration}` | Move to `test/` |
| `assets/guides/*` | Merge into `docs/*.md` (Task 11), then delete |
| `hk.pkl`, `.gitignore`, `.markdownlintignore`, `.gitattributes`, `config/mise/conf.d/dotfiles.toml`, `config/homebrew/Brewfile`, `mise.toml` | Modify |
| `script/agent-skills.ts`, `test/integration/agents/agent-skills.spec.ts` | Modify (Tasks 6–7) |
| `script/bootstrap-log.sh`, `test/integration/bootstrap/bootstrap-log.spec.ts`, `test/integration/bootstrap/skills-snippet.spec.ts` | Create (Tasks 7–8) |
| `install`, `config/mise/conf.d/bootstrap.toml`, `config/zsh/opt/rc.d/sys.zsh` | Modify (Tasks 7–8) |
| `config/bin/xc`, BDD fixture and steps | Modify (Task 5) |
| `AGENTS.md`, `README.md`, `docs/{TESTING,CONTRIBUTING,DOCKER,REINSTALL,GLOSSARY}.md`, `config/zsh/README.md`, `config/bin/README.md` | Rewrite or create (Tasks 9–11) |

---

### Task 0: Baseline

- [ ] **Step 1:** Record what `main` looks like, for comparison at the end:

```bash
cd ~/Work/dots-closeout
g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }
export MISE_AUTO_INSTALL=0 MISE_EXEC_AUTO_INSTALL=0
g ls-files | wc -l > "$TMPDIR/closeout-files-before.txt"
(cd assets && bun install --frozen-lockfile 2>&1 | tail -1; for d in bin backup bootstrap agents hooks; do printf '%s: ' $d; bun test integration/$d/ 2>&1 | grep -E '^ *[0-9]+ (pass|fail)' | tr -s ' \n' ' '; echo; done) | tee "$TMPDIR/closeout-tests-before.txt"
docker image ls dots --format '{{.Tag}} {{.Size}}' | tee "$TMPDIR/closeout-images-before.txt"
```

  Expected (2026-11-04): `bin` has failures (the six specs for removed bins), `hooks` 5 pass 4 fail, `backup`,
  `bootstrap`, `agents` all pass. Keep the file; Task 13 compares against it.

---

### Task 1: Remove the declared-obsolete items and their references

**Files:** delete `.agent/ .claude/ .cursor/ .cursorignore .specify/ graphify-out/ config/cursor/`; modify
`hk.pkl`, `.gitignore`, `.markdownlintignore`, `.gitattributes`, `config/mise/conf.d/dotfiles.toml`.

- [ ] **Step 1: Delete.**

```bash
g rm -rq .agent .claude .cursor .cursorignore .specify graphify-out config/cursor
rm -rf .claude .cursor .specify graphify-out   # untracked leftovers (settings.local.json, caches)
```

- [ ] **Step 2: References.**
  - `hk.pkl:8`: `exclude = List("graphify-out", "node_modules", ".git")` → `exclude = List("node_modules", ".git")`.
  - `.gitignore`: delete the `# graphify` block (the comment and its four `graphify-out/…` lines, about 166–170).
  - `.markdownlintignore`: delete the lines `graphify-out/`, `.agent/`, `.claude/`. Keep `.agents/` until Task 9
    deletes that folder; keep `docs/superpowers/`.
  - `.gitattributes:2`: replace `# IDE agents skip config/.env via .cursorignore — do not add config/.env -diff here.`
    with `# Do not add config/.env -diff here: diff.sops decrypts it for git diff/log.`
  - `config/mise/conf.d/dotfiles.toml`: delete the line `"~/.config/cursor" = { … }`.

- [ ] **Step 3: Check.** `g grep -nE 'graphify-out|\.cursorignore|\.specify|kfc-settings|config/cursor' -- . ':!CHANGELOG.md' ':!assets/specs' ':!docs/superpowers'`
  prints only lines inside `AGENTS.md`, `README.md`, `.agents/` and `assets/guides/` (rewritten in Tasks 9–11).
  `hk check --all` passes.

- [ ] **Step 4: Commit.** `g rm` already staged the deletions; stage the edits with
  `g add hk.pkl .gitignore .markdownlintignore .gitattributes config/mise/conf.d/dotfiles.toml`, then
  `g commit -m "chore: Remove unused agent, editor and graph folders"` with the trailer.

---

### Task 2: Remove old specs, junk, the dead skills registry and stale specs

- [ ] **Step 1: Old specs and superpowers files** (§3, owner's choice to start fresh):

```bash
g rm -rq assets/specs
for f in docs/superpowers/plans/*.md docs/superpowers/specs/*.md; do
  case "$f" in *2026-11-04-repo-closeout*) ;; *) g rm -q "$f" ;; esac
done
ls docs/superpowers/plans docs/superpowers/specs
```

  Expected: only `2026-11-04-repo-closeout.md` and `2026-11-04-repo-closeout-design.md`.

- [ ] **Step 2: Save the runbook first.** `README.md:164` links into `assets/specs/mise-bootstrap/`. Before the
  commit, copy that design's §6 runbook text (`g show HEAD:assets/specs/mise-bootstrap/design.md`, the "§6" section)
  into `$TMPDIR/runbook.md`; Task 11 puts it into `docs/REINSTALL.md`. Then point `README.md:164` at
  `docs/REINSTALL.md` (the file appears in Task 11; the link checker runs in Task 13).

- [ ] **Step 3: Junk, the dead registry, the skills lock.**

```bash
g rm -rq assets/.vscode assets/all assets/README.md assets/integration/fixtures assets/scripts \
  assets/guides/SKILLS.md assets/guides/SKILLS.yml skills-lock.json \
  script/skills.txt script/skills.json script/catalog_global_skills.py script/fix_skill_commands.rb \
  config/bin/HANDOFF-USAGE-MIGRATION.md
g rm -rq .agents/skills/bun-development .agents/skills/bun-runtime
```

- [ ] **Step 4: Specs for removed bins.** Confirm each bin is gone, then remove its spec:

```bash
for b in xc-md xc-skills xc-usage keyring osx yw; do [ -e config/bin/$b ] && echo "STILL EXISTS: $b"; done
g rm -q assets/integration/bin/{xc-md,xc-skills,xc-usage,keyring,osx,yw}.spec.ts
g rm -rq assets/integration/bin/fixtures/xc-usage
grep -rn 'zshFunctionsDir' assets/integration/bin || true
```

  Expected: no `STILL EXISTS`. If `zshFunctionsDir` is no longer used, delete its line from
  `assets/integration/bin/support/paths.ts`.

- [ ] **Step 5: Legacy Brewfile comments** (old mise syntax):

```bash
grep -vE '^# "brew(-cask)?:' config/homebrew/Brewfile > "$TMPDIR/Brewfile" && mv "$TMPDIR/Brewfile" config/homebrew/Brewfile
HOMEBREW_DOTS_PROFILE=desktop brew bundle list --all --file config/homebrew/Brewfile | wc -l
```

  Expected: the same count as the committed file gives:
  `g show HEAD:config/homebrew/Brewfile > "$TMPDIR/Brewfile.old" && HOMEBREW_DOTS_PROFILE=desktop brew bundle list --all --file "$TMPDIR/Brewfile.old" | wc -l`
  (the removed lines were comments, so nothing installable changes).

- [ ] **Step 6: Comments citing `assets/specs/`.** List them and rewrite each: drop the citation, keep the reason in
  one line where it matters.

```bash
g grep -nE 'assets/specs|design\.md §|design\.md\)' -- . ':!CHANGELOG.md' ':!assets/guides' ':!AGENTS.md' ':!README.md' ':!.agents' ':!docs/superpowers'
```

  Expected list (2026-11-04): `hk.pkl:33`, `mise.toml:321`, `config/mise/conf.d/{dotfiles.toml:1,63, bootstrap.toml:1,148, system.toml:2}`,
  `config/homebrew/Brewfile:1`, `config/dinky/dinky.toml:3`, `script/backup.ts:3`, `script/agent-skills.ts:3`,
  `config/zsh/README.md`, `install:2`. Example: `# Homebrew and every user package (assets/specs/brewfile-packages/design.md §4.3). Runs after…`
  → `# Homebrew and every user package. Runs after…`. Rerun the grep: empty.

- [ ] **Step 7: Check and commit.** `hk check --all` passes. Commit the paths above:
  `chore: Remove old specs, the unused skills registry and stale files`.

---

### Task 3: App-config review (STOP for the owner)

- [ ] **Step 1:** Write `$TMPDIR/app-configs.md` with one row per config:

```bash
for c in opencode glow amethyst skhd rift ranma glide dinky claude/commands/opsx; do
  link=$(grep -c "config/${c%%/*}\"" config/mise/conf.d/dotfiles.toml)
  brew=$(grep -nE "\b${c%%/*}\b" config/homebrew/Brewfile | head -1 | cut -c1-60)
  last=$(g log -1 --format=%cs -- "config/$c")
  printf '| config/%s | linked=%s | %s | %s | keep/delete? |\n' "$c" "$link" "${brew:-not in Brewfile}" "$last"
done | tee "$TMPDIR/app-configs.md"
```

- [ ] **Step 2: STOP.** Show the table to the owner and wait for keep/delete on every row.
- [ ] **Step 3:** For each **delete**: `g rm -rq config/<c>` and remove its `dotfiles.toml` line (and any
  `.markdownlintignore`/README mention). Commit: `chore: Remove configs for apps that are not installed`.

---

### Task 4: Move `assets/` to `test/`

- [ ] **Step 1: Move.**

```bash
mkdir -p test
g mv assets/mise.toml assets/package.json assets/tsconfig.json assets/features assets/integration test/
mv assets/bun.lock test/bun.lock 2>/dev/null; mv assets/node_modules test/node_modules 2>/dev/null
ls assets   # only guides/ is left; Task 11 empties it
```

- [ ] **Step 2: Paths.**
  - `test/features/support/paths.ts`: the two `"assets/integration/bin/fixtures/…"` strings become
    `"test/integration/bin/fixtures/…"`. (`repoRoot` depth is unchanged.)
  - `grep -rn '"assets/\|assets/' test --include='*.ts' --include='*.toml' --include='*.json'` → fix every hit the
    same way.
  - Every `mise run -C assets` in the tree becomes `mise run -C test`:
    `g grep -l 'mise run -C assets' | xargs sed -i '' 's/mise run -C assets/mise run -C test/g'` (macOS `sed`).
- [ ] **Step 3: Track the lockfile.** In `.gitignore`, directly after the `*.lock` line, add `!test/bun.lock`.
  `g add test/bun.lock`. Check: `g check-ignore -v test/bun.lock` prints nothing.
- [ ] **Step 4: Root task.** In `mise.toml`, add next to the other test tasks:

```toml
[tasks."test:specs"]
description = "Run every BDD scenario and integration spec under test/"
run = "mise run -C test test all"
```

- [ ] **Step 5: `test all` runs every domain.** In `test/mise.toml`, the `test` task's `all)` branch becomes:

```bash
  all)
    mise run test bin
    for domain in backup bootstrap agents hooks; do mise run integration "$domain" all; done
    ;;
```

- [ ] **Step 6: Check and commit.** `(cd test && bun install --frozen-lockfile)` succeeds;
  `mise run -C test integration backup all` and `mise run -C test integration bootstrap all` pass.
  Commit: `test: Move the test suite from assets/ to test/`.

---

### Task 5: Green test gate

- [ ] **Step 1: BDD fixture.** Replace `test/integration/bin/fixtures/xc-launcher/bin/xc-sample` with:

```zsh
#!/usr/bin/env -S usage zsh
#USAGE about "Fixture tool for xc launcher discovery tests"

true
```

- [ ] **Step 2: BDD steps find `usage` and `jq`.** In `test/features/support/paths.ts`, add:

```ts
/** Folder holding the `usage` binary (Homebrew or mise), for subprocess PATHs; xc needs usage and jq. */
export const toolBin = dirname(Bun.which("usage") ?? "/opt/homebrew/bin/usage");
```

  (`dirname` is already imported.) In `test/features/step_definitions/bin/command-discovery.steps.ts`, import
  `toolBin` and change both `PATH: \`${binRoot}:/usr/bin:/bin\`` to `PATH: \`${binRoot}:${toolBin}:/usr/bin:/bin\``.
  If `jq` is not in `toolBin`, append `dirname(Bun.which("jq"))` the same way.

- [ ] **Step 3: `xc -h`.** In `config/bin/xc`, `_xc_main`, add before the `'')` branch:

```zsh
    -h|--help|help)
      usage zsh "$XC_LAUNCHER_SELF" --help
      exit 0
      ;;
```

  Check: `zsh config/bin/xc -h | head -3` prints `xc 0.1.0` and `Interactive launcher for xc-* tools`.

- [ ] **Step 4: BDD passes.** `mise run -C test bdd run --domain bin` → `3 scenarios (3 passed)`.

- [ ] **Step 5: The hooks spec.** `mise run -C test integration hooks all` failed 4 of 9 in the baseline
  (`installs a script shim`, `enforces rules under Apple git`, `rejects refactor`, `rejects an uncapitalized
  description`). Use superpowers:systematic-debugging: read `test/integration/hooks/hk-hooks.spec.ts` (it builds a
  temp repo and installs hk's hooks into it), run one failing case with output, and find the root cause. Likely
  suspects: the temp repo's hook install depends on `hk` on PATH or on `hk.pkl`'s new `exclude`, or the spec reads
  hooks from the main checkout (`git rev-parse --git-path hooks` in a linked worktree points at
  `~/Work/dots/.git/hooks`). Fix the cause in the spec or the config, not by skipping cases. If the cause is
  outside this repo (e.g. the installed hk version), STOP and report.

- [ ] **Step 6: Gate.** `mise run test:specs` → every domain passes, no skips except those guarded by a missing
  tool. `hk check --all` → clean. Commit: `test: Fix the xc scenarios and the hooks spec; run every domain`.

---

### Task 6: Parallel `skills:restore` (§6.1)

**Files:** modify `script/agent-skills.ts`, `test/integration/agents/agent-skills.spec.ts`.

- [ ] **Step 1: Spike** (decides the default). Two concurrent `skills add` into a temp home:

```bash
t=$(mktemp -d); mkdir -p "$t/home"
( HOME="$t/home" XDG_STATE_HOME="$t/s1" skills add vercel-labs/agent-skills -g -y -s find-skills -a claude-code >"$t/1.log" 2>&1 & \
  HOME="$t/home" XDG_STATE_HOME="$t/s2" skills add anthropics/skills -g -y -s pdf -a claude-code >"$t/2.log" 2>&1 & wait )
ls -la "$t/home/.agents/skills" "$t/home/.claude/skills"; tail -3 "$t/1.log" "$t/2.log"
```

  Expected: both skills present in `.agents/skills`, both links in `.claude/skills`, both logs end without an
  error. If a skill or link is missing, or a log shows `EEXIST`/a lock error, the default `SKILLS_JOBS` is **1**
  in Step 4 (write that down in the commit message). If either source name no longer resolves, pick any two
  sources from `config/agents/skill-lock.json`.

- [ ] **Step 2: Failing unit specs.** Append to `test/integration/agents/agent-skills.spec.ts` (and add `runPool`,
  `jobsFromEnv` to its import from `../../../script/agent-skills`):

```ts
describe("runPool", () => {
  it("never runs more than `jobs` workers at once and keeps input order", async () => {
    let running = 0, peak = 0;
    const out = await runPool([1, 2, 3, 4, 5], 2, async (n) => {
      running++; peak = Math.max(peak, running);
      await Bun.sleep(20);
      running--;
      return n * 10;
    });
    expect(peak).toBe(2);
    expect(out).toEqual([10, 20, 30, 40, 50]);
  });
  it("handles no items and more jobs than items", async () => {
    expect(await runPool([], 4, async (n: number) => n)).toEqual([]);
    expect(await runPool([1], 4, async (n) => n + 1)).toEqual([2]);
  });
});

describe("jobsFromEnv", () => {
  it("reads SKILLS_JOBS, falling back to the default on junk", () => {
    expect(jobsFromEnv({ SKILLS_JOBS: "3" })).toBe(3);
    expect(jobsFromEnv({})).toBe(DEFAULT_JOBS);
    expect(jobsFromEnv({ SKILLS_JOBS: "0" })).toBe(DEFAULT_JOBS);
    expect(jobsFromEnv({ SKILLS_JOBS: "x" })).toBe(DEFAULT_JOBS);
  });
});
```

  (Also import `DEFAULT_JOBS`.) Run `mise run -C test integration agents all` → fails: no export `runPool`.

- [ ] **Step 3: Implement the pool.** In `script/agent-skills.ts`, after `addCommand`:

```ts
/** Concurrent `skills add` runs; the spike in the close-out plan (Task 6) chose it. */
export const DEFAULT_JOBS = 6;

export function jobsFromEnv(env: Record<string, string | undefined>): number {
  const n = Number(env.SKILLS_JOBS);
  return Number.isInteger(n) && n >= 1 ? n : DEFAULT_JOBS;
}

/** Runs `worker` over `items`, at most `jobs` at once; results keep the input order. */
export async function runPool<T, R>(items: T[], jobs: number, worker: (item: T) => Promise<R>): Promise<R[]> {
  const results = new Array<R>(items.length);
  let next = 0;
  const lane = async () => {
    while (next < items.length) {
      const i = next++;
      results[i] = await worker(items[i] as T);
    }
  };
  await Promise.all(Array.from({ length: Math.max(1, Math.min(jobs, items.length)) }, lane));
  return results;
}
```

  If the spike chose 1, set `DEFAULT_JOBS = 1`.

- [ ] **Step 4: Failing restore spec with a stub `skills`.** Append to the `describe("restore command", …)` block's
  file (new `describe`):

```ts
describe("restore in parallel", () => {
  const script = join(import.meta.dir, "../../../script/agent-skills.ts");
  // Stub `skills add <source> -g -y -s <names…> [-a …]`: logs start/end and its XDG_STATE_HOME, sleeps,
  // creates each skill folder, and fails for the source o/bad.
  const STUB = `#!/usr/bin/env bun
import { appendFileSync, mkdirSync } from "node:fs";
const a = process.argv.slice(2); const source = a[1] ?? "";
const s = a.indexOf("-s"); const end = a.indexOf("-a");
const names = a.slice(s + 1, end === -1 ? undefined : end);
const t0 = Date.now(); await Bun.sleep(150);
for (const n of names) if (source !== "o/bad") mkdirSync(process.env.SKILLS_DIR + "/" + n, { recursive: true });
appendFileSync(process.env.STUB_LOG!, JSON.stringify({ source, t0, t1: Date.now(), state: process.env.XDG_STATE_HOME }) + "\\n");
process.exit(source === "o/bad" ? 1 : 0);
`;

  function setup() {
    const dir = tempDir();
    mkdirSync(join(dir, "bin"));
    writeFileSync(join(dir, "bin", "skills"), STUB);
    chmodSync(join(dir, "bin", "skills"), 0o755);
    mkdirSync(join(dir, "skills"));
    const skills: Lock["skills"] = {};
    for (const [name, source] of [["a1", "o/one"], ["a2", "o/one"], ["b1", "o/two"], ["c1", "o/three"], ["x1", "o/bad"]]) {
      skills[name as string] = { source: source as string, sourceUrl: `${source}` };
    }
    writeFileSync(join(dir, "lock.json"), JSON.stringify({ version: LOCK_VERSION, skills }));
    return dir;
  }
  function env(dir: string, extra: Record<string, string> = {}) {
    return {
      PATH: `${join(dir, "bin")}:${process.env.PATH}`, HOME: dir, XDG_STATE_HOME: join(dir, "state"),
      SKILL_LOCK: join(dir, "lock.json"), SKILLS_DIR: join(dir, "skills"), STUB_LOG: join(dir, "calls"),
      SKILLS_JOBS: "2", ...extra,
    };
  }
  const calls = (dir: string) =>
    readFileSync(join(dir, "calls"), "utf8").trim().split("\n").map((l) => JSON.parse(l) as { source: string; t0: number; t1: number; state: string });

  it("runs at most SKILLS_JOBS sources at once, each with its own state folder", () => {
    const dir = setup();
    try {
      const r = Bun.spawnSync(["bun", script, "restore"], { env: env(dir), stdout: "pipe", stderr: "pipe" });
      const firstPass = calls(dir).slice(0, 4); // 4 sources; a retry pass would append more
      const peak = Math.max(...firstPass.map((x) => firstPass.filter((y) => y.t0 < x.t1 && x.t0 < y.t1).length));
      expect(peak).toBeLessThanOrEqual(2);
      expect(new Set(firstPass.map((x) => x.state)).size).toBe(4);
      expect(r.stdout.toString()).toContain("✓ o/one (2)");
      expect(r.stdout.toString()).toContain("✗ o/bad");
      expect(r.exitCode).toBe(1);
      expect(r.stderr.toString()).toContain("x1");
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
});
```

  (Add `chmodSync` and `readFileSync` to the `node:fs` import if missing.) Run → fails (restore is serial and
  prints no `✓`).

- [ ] **Step 5: Implement the parallel restore.** Replace `function restore(): void { … }` with:

```ts
const dotsState = () => join(process.env.XDG_STATE_HOME ?? join(homedir(), ".local/state"), "dots");

type SourceRun = { source: string; names: string[]; code: number; log: string };

/** One `skills add`, with its own state folder (the CLI writes its lock there) and its own log. */
async function addSource(source: string, names: string[], agents: string[], runDir: string): Promise<SourceRun> {
  const slug = source.replace(/[^\w.-]+/g, "_");
  const state = join(runDir, "state", slug);
  mkdirSync(state, { recursive: true });
  const log = join(runDir, `${slug}.log`);
  const cmd = addCommand(source, names, agents);
  let code = 127, out = "", err = "";
  try {
    const p = Bun.spawn(cmd, { env: { ...process.env, XDG_STATE_HOME: state }, stdin: "ignore", stdout: "pipe", stderr: "pipe" });
    [out, err] = await Promise.all([new Response(p.stdout).text(), new Response(p.stderr).text()]);
    code = await p.exited;
  } catch (error) {
    // Bun throws when the executable is missing (e.g. `skills` not installed yet).
    err = `cannot run ${cmd[0]}: ${(error as Error).message}\n`;
  }
  writeFileSync(log, `$ ${cmd.join(" ")}\n${out}${err}`);
  console.log(code === 0 ? `✓ ${source} (${names.length})` : `✗ ${source} (exit ${code}), log: ${log}`);
  return { source, names, code, log };
}

/** Installs the missing locked skills; returns the exit code and the one-line result. */
async function restore(): Promise<{ code: number; result: string }> {
  const path = lockPath();
  const lock = readLock(path);
  const committed = run(["git", "show", "HEAD:config/agents/skill-lock.json"], repoRoot);
  const committedCount =
    !process.env.SKILL_LOCK && committed.code === 0 ? Object.keys((JSON.parse(committed.out) as Lock).skills ?? {}).length : 0;
  const problem = lockProblem(lock, committedCount);
  if (problem) {
    console.error(`skills:restore: ${problem}`);
    return { code: 1, result: problem };
  }
  const missing = missingSkills(lock, skillsDir());
  if (missing.length === 0) {
    console.log("skills:restore: every locked skill is installed");
    return { code: 0, result: "every locked skill is installed" };
  }
  const runDir = join(dotsState(), "skills-restore");
  rmSync(runDir, { recursive: true, force: true });
  mkdirSync(runDir, { recursive: true });
  const agents = lock.lastSelectedAgents ?? [];
  const jobs = jobsFromEnv(process.env);
  const runs = await runPool([...groupBySource(lock, missing)], jobs, ([source, names]) => addSource(source, names, agents, runDir));
  // `skills add` exits 0 when a requested skill is gone upstream, so check what is still missing.
  let still = missingSkills(lock, skillsDir()).filter((name) => missing.includes(name));
  // A parallel run can lose a race the CLI does not guard against: retry those sources once, one at a time.
  if (jobs > 1) {
    for (const r of runs.filter((r) => r.code === 0 && r.names.some((n) => still.includes(n)))) {
      Object.assign(r, await addSource(r.source, r.names.filter((n) => still.includes(n)), agents, runDir));
    }
    still = missingSkills(lock, skillsDir()).filter((name) => missing.includes(name));
  }
  const failed = runs.filter((r) => r.code !== 0).map((r) => r.source);
  const result = `${missing.length - still.length} of ${missing.length} installed, ${failed.length} source(s) failed`;
  console.log(`skills:restore: ${result}`);
  if (failed.length) console.error(`failed sources: ${failed.join(", ")} (logs: ${runDir})`);
  if (still.length) console.error(`not installed (gone upstream or failed): ${still.join(", ")}`);
  return { code: failed.length || still.length ? 1 : 0, result: still.length ? `${result}: ${still.join(", ")}` : result };
}
```

  and the entry point:

```ts
if (import.meta.main) {
  const [command, ...args] = process.argv.slice(2);
  if (command === "audit") audit(args.includes("--apply"));
  else if (command === "restore") process.exit((await restore()).code);
  else {
    console.error("usage: bun script/agent-skills.ts audit [--apply] | restore [--background]");
    process.exit(2);
  }
}
```

- [ ] **Step 6: Run.** `mise run -C test integration agents all` → all pass (old cases included: "lock version 2",
  "every locked skill is installed"). Commit: `feat(skills): Restore sources in parallel`.

---

### Task 7: Background restore and notification (§6.2)

**Files:** modify `script/agent-skills.ts`, `test/integration/agents/agent-skills.spec.ts`,
`config/mise/conf.d/bootstrap.toml`, `config/zsh/opt/rc.d/sys.zsh`; create
`test/integration/bootstrap/skills-snippet.spec.ts`.

- [ ] **Step 1: Failing unit specs** (import `notifyCommand`, `lockOwner`, `acquireLock`, `releaseLock`):

```ts
describe("notifyCommand", () => {
  const has = (cmds: string[]) => (c: string) => cmds.includes(c);
  it("uses osascript on macOS", () => {
    expect(notifyCommand("darwin", {}, has(["osascript"]), "t", 'a "b"')).toEqual([
      "osascript", "-e", 'display notification "a \\"b\\"" with title "t"',
    ]);
  });
  it("uses notify-send on Linux only with a session", () => {
    expect(notifyCommand("linux", { DISPLAY: ":0" }, has(["notify-send"]), "t", "b")).toEqual(["notify-send", "t", "b"]);
    expect(notifyCommand("linux", {}, has(["notify-send"]), "t", "b")).toBeNull();
    expect(notifyCommand("linux", { DISPLAY: ":0" }, has([]), "t", "b")).toBeNull();
  });
});

describe("PID lock", () => {
  it("is held by a live process and released only by its owner", () => {
    const dir = tempDir();
    try {
      const f = join(dir, "x.pid");
      expect(lockOwner(f)).toBeNull();
      expect(acquireLock(f)).toBe(true);
      expect(lockOwner(f)).toBe(process.pid);
      writeFileSync(f, "999999\n"); // a dead PID
      expect(lockOwner(f)).toBeNull();
      expect(acquireLock(f)).toBe(true);
      releaseLock(f);
      expect(existsSync(f)).toBe(false);
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
});
```

  And in `describe("restore in parallel")`, a background case:

```ts
  it("--background records the result, the failure marker and notifies", () => {
    const dir = setup();
    try {
      for (const n of ["osascript", "notify-send"]) {
        writeFileSync(join(dir, "bin", n), `#!/bin/sh\necho "$@" >> "${join(dir, "notified")}"\n`);
        chmodSync(join(dir, "bin", n), 0o755);
      }
      const r = Bun.spawnSync(["bun", script, "restore", "--background"], { env: env(dir, { DISPLAY: ":0" }), stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(1);
      const state = join(dir, "state", "dots");
      expect(readFileSync(join(state, "skills-restore.result"), "utf8")).toContain("4 of 5 installed, 1 source(s) failed: x1");
      expect(existsSync(join(state, "skills-restore.failed"))).toBe(true);
      expect(existsSync(join(state, "skills-restore.pid"))).toBe(false);
      expect(readFileSync(join(dir, "notified"), "utf8")).toContain("4 of 5 installed");
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });

  it("--background exits 0 while another restore holds the lock", () => {
    const dir = setup();
    try {
      mkdirSync(join(dir, "state", "dots"), { recursive: true });
      writeFileSync(join(dir, "state", "dots", "skills-restore.pid"), `${process.pid}\n`);
      const r = Bun.spawnSync(["bun", script, "restore", "--background"], { env: env(dir), stdout: "pipe" });
      expect(r.exitCode).toBe(0);
      expect(r.stdout.toString()).toContain("already running");
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
```

  Run → fails (no exports).

- [ ] **Step 2: Implement** in `script/agent-skills.ts` (add `dirname` is already imported):

```ts
/** The OS notification command, or null when this machine has no way to show one. */
export function notifyCommand(
  platform: string, env: Record<string, string | undefined>, has: (cmd: string) => boolean, title: string, body: string,
): string[] | null {
  if (platform === "darwin" && has("osascript")) {
    return ["osascript", "-e", `display notification ${JSON.stringify(body)} with title ${JSON.stringify(title)}`];
  }
  if (platform === "linux" && has("notify-send") && (env.DISPLAY || env.WAYLAND_DISPLAY || env.DBUS_SESSION_BUS_ADDRESS)) {
    return ["notify-send", title, body];
  }
  return null;
}

/** The PID in `pidFile` when that process is alive, else null. */
export function lockOwner(pidFile: string): number | null {
  let pid = 0;
  try {
    pid = Number(readFileSync(pidFile, "utf8").trim());
  } catch {
    return null;
  }
  if (!Number.isInteger(pid) || pid <= 0) return null;
  try {
    process.kill(pid, 0);
    return pid;
  } catch (error) {
    return (error as NodeJS.ErrnoException).code === "EPERM" ? pid : null;
  }
}

export function acquireLock(pidFile: string): boolean {
  const owner = lockOwner(pidFile);
  if (owner !== null && owner !== process.pid) return false;
  mkdirSync(dirname(pidFile), { recursive: true });
  writeFileSync(pidFile, `${process.pid}\n`);
  return true;
}

export function releaseLock(pidFile: string): void {
  if (lockOwner(pidFile) === process.pid) rmSync(pidFile, { force: true });
}

/** Background mode: the result file, the failure marker (read once by the next zsh) and the notification. */
function report(code: number, result: string): void {
  const dir = dotsState();
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, "skills-restore.result"), `${result}\n`);
  if (code !== 0) writeFileSync(join(dir, "skills-restore.failed"), `${result}\n`);
  else rmSync(join(dir, "skills-restore.failed"), { force: true });
  const cmd = notifyCommand(process.platform, process.env, (c) => Bun.which(c) !== null, "dots: agent skills", result);
  if (cmd) Bun.spawnSync(cmd, { stdout: "ignore", stderr: "ignore" });
}
```

  Entry point `restore` branch becomes:

```ts
  else if (command === "restore") {
    if (!args.includes("--background")) process.exit((await restore()).code);
    const pidFile = join(dotsState(), "skills-restore.pid");
    if (!acquireLock(pidFile)) {
      console.log("skills:restore: already running");
      process.exit(0);
    }
    let outcome = { code: 1, result: "skills:restore crashed; see the log" };
    try {
      outcome = await restore();
    } finally {
      report(outcome.code, outcome.result);
      releaseLock(pidFile);
    }
    process.exit(outcome.code);
  }
```

  Run `mise run -C test integration agents all` → pass.

- [ ] **Step 3: The bootstrap task.** In `config/mise/conf.d/bootstrap.toml`, replace the line
  `mise run -C "$dots" skills:restore || warn "skills:restore"` with:

```bash
# skills: begin
# Agent skills from config/agents/skill-lock.json, in the background: hundreds of skills must not hold up the
# bootstrap. A notification and ~/.local/state/dots/skills-restore.result report the outcome.
skills_state="${XDG_STATE_HOME:-$HOME/.local/state}/dots"
mkdir -p "$skills_state"
if [ -n "${DOTS_SKILLS_FOREGROUND:-}" ]; then
  mise run -C "$dots" skills:restore || warn "skills:restore"
else
  nohup mise run -C "$dots" skills:restore -- --background >"$skills_state/skills-restore.log" 2>&1 </dev/null &
  echo "bootstrap: restoring agent skills in the background (log: $skills_state/skills-restore.log)"
fi
# skills: end
```

  Check that `--background` reaches the script through mise (the task's `run` is
  `bun script/agent-skills.ts restore`; mise appends extra arguments). Safe check, with an empty lock so nothing
  installs:

```bash
d=$(mktemp -d); echo '{"version":3,"skills":{}}' > "$d/lock.json"
SKILL_LOCK="$d/lock.json" XDG_STATE_HOME="$d/state" mise run -C . skills:restore -- --background
cat "$d/state/dots/skills-restore.result"   # "every locked skill is installed" ⇒ the flag arrived
```

  If the result file is missing, the flag did not arrive: in the snippet, call
  `mise exec bun@1.3.14 -- bun "$dots/script/agent-skills.ts" restore --background` instead.

- [ ] **Step 4: Spec for the snippet.** `test/integration/bootstrap/skills-snippet.spec.ts`:

```ts
#!/usr/bin/env bun
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const task = (Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/bootstrap.toml"), "utf8")) as {
  tasks: { bootstrap: { run: string } };
}).tasks.bootstrap.run;
const SNIPPET = task.match(/# skills: begin\n[\s\S]*?# skills: end\n/)?.[0] ?? "";

let t: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "skills-snippet-"));
  mkdirSync(join(t, "bin"));
  // A stub mise that records its arguments and takes 2 s, like a slow restore.
  writeFileSync(join(t, "bin", "mise"), `#!/bin/sh\necho "$@" >> "${join(t, "calls")}"\nsleep 2\n`);
  chmodSync(join(t, "bin", "mise"), 0o755);
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function snippet(env: Record<string, string> = {}) {
  const started = Date.now();
  const p = Bun.spawnSync(["bash", "-c", `dots=/repo\nwarn() { echo "warn $1" >&2; }\n${SNIPPET}`], {
    env: { PATH: `${join(t, "bin")}:/usr/bin:/bin`, HOME: t, XDG_STATE_HOME: join(t, "state"), ...env },
    stdout: "pipe", stderr: "pipe",
  });
  return { code: p.exitCode, out: p.stdout.toString(), ms: Date.now() - started };
}

describe("bootstrap skills snippet", () => {
  it("is in the bootstrap task", () => expect(SNIPPET).toContain("--background"));

  it("returns at once and points at the log", () => {
    const r = snippet();
    expect(r.code).toBe(0);
    expect(r.ms).toBeLessThan(1500);
    expect(r.out).toContain("restoring agent skills in the background");
    expect(r.out).toContain(join(t, "state", "dots", "skills-restore.log"));
  });

  it("DOTS_SKILLS_FOREGROUND=1 waits for the restore", () => {
    const r = snippet({ DOTS_SKILLS_FOREGROUND: "1" });
    expect(r.ms).toBeGreaterThanOrEqual(2000);
    expect(readFileSync(join(t, "calls"), "utf8")).toContain("skills:restore");
  });
});
```

  Run `mise run -C test integration bootstrap all` → pass.

- [ ] **Step 5: The one-time zsh notice.** Append to `config/zsh/opt/rc.d/sys.zsh`:

```zsh
# A failed background skills restore (bootstrap task) is reported once, then forgotten.
() {
  local f="${XDG_STATE_HOME:-$HOME/.local/state}/dots/skills-restore.failed"
  [[ -s $f ]] || return 0
  print -u2 "dots: agent skills restore incomplete: $(<$f) (retry: mise run skills:restore)"
  rm -f -- "$f"
}
```

  Check: `zsh -n config/zsh/opt/rc.d/sys.zsh`; then
  `d=$(mktemp -d); mkdir -p $d/dots; echo "x failed" > $d/dots/skills-restore.failed; XDG_STATE_HOME=$d zsh -c 'source config/zsh/opt/rc.d/sys.zsh' ; ls $d/dots`
  prints the notice on stderr and the file is gone. If sourcing `sys.zsh` alone needs other startup files, test
  the block on its own.

- [ ] **Step 6: Commit.** `feat(bootstrap): Restore agent skills in the background with a notification`.

---

### Task 8: Bootstrap log (§6.3)

**Files:** create `script/bootstrap-log.sh`, `test/integration/bootstrap/bootstrap-log.spec.ts`; modify `install`,
`config/mise/conf.d/bootstrap.toml`.

- [ ] **Step 1: Failing spec.** `test/integration/bootstrap/bootstrap-log.spec.ts`:

```ts
#!/usr/bin/env bun
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, readlinkSync, rmSync, utimesSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const LIB = join(import.meta.dir, "../../../script/bootstrap-log.sh");
let t: string;
beforeEach(() => (t = mkdtempSync(join(tmpdir(), "bootstrap-log-"))));
afterEach(() => rmSync(t, { recursive: true, force: true }));
const logs = () => join(t, "state", "dots", "logs");

function run(body: string, env: Record<string, string> = {}) {
  const p = Bun.spawnSync(["bash", "-c", `. "${LIB}"\n${body}`], {
    env: { PATH: "/usr/bin:/bin", HOME: t, XDG_STATE_HOME: join(t, "state"), ...env }, stdout: "pipe", stderr: "pipe",
  });
  Bun.sleepSync(200); // tee flushes after the shell exits
  return { code: p.exitCode, out: p.stdout.toString() };
}

describe("bootstrap log", () => {
  it("tees output to a new dated log and links latest.log", () => {
    const r = run('echo "hello out"; echo "hello err" >&2');
    expect(r.out).toContain("hello out");
    const files = readdirSync(logs()).filter((f) => f.startsWith("bootstrap-"));
    expect(files.length).toBe(1);
    const text = readFileSync(join(logs(), files[0] as string), "utf8");
    expect(text).toContain("hello out");
    expect(text).toContain("hello err");
    expect(readlinkSync(join(logs(), "latest.log"))).toBe(files[0]);
  });

  it("appends to DOTS_LOG when install set it", () => {
    mkdirSync(logs(), { recursive: true });
    const f = join(logs(), "bootstrap-20261104-000000.log");
    writeFileSync(f, "from install\n");
    run('echo "from hook"', { DOTS_LOG: f });
    expect(readFileSync(f, "utf8")).toBe("from install\nfrom hook\n");
  });

  it("reuses latest.log written in the last 30 minutes (hook, then task, of one direct run)", () => {
    run('echo "hook"');
    run('echo "task"');
    const files = readdirSync(logs()).filter((f) => f.startsWith("bootstrap-"));
    expect(files.length).toBe(1);
    expect(readFileSync(join(logs(), files[0] as string), "utf8")).toBe("hook\ntask\n");
  });

  it("keeps the 10 newest logs", () => {
    mkdirSync(logs(), { recursive: true });
    for (let i = 0; i < 12; i++) {
      const f = join(logs(), `bootstrap-20260101-0000${String(i).padStart(2, "0")}.log`);
      writeFileSync(f, "old\n");
      const when = new Date(Date.now() - (60 + i) * 60_000); // older than 30 min, so not reused
      utimesSync(f, when, when);
    }
    run('echo "new"');
    expect(readdirSync(logs()).filter((f) => f.startsWith("bootstrap-")).length).toBe(10);
    expect(existsSync(join(logs(), "latest.log"))).toBe(true);
  });
});
```

  Run → fails: `script/bootstrap-log.sh` missing.

- [ ] **Step 2: Implement** `script/bootstrap-log.sh`:

```bash
# shellcheck shell=bash
# Sourced by the post-packages hook and the bootstrap task: copy this script's output into the run's log in
# ~/.local/state/dots/logs. install sets DOTS_LOG for its whole run; a direct `mise bootstrap` reuses a log
# written in the last 30 minutes (the hook's, for the task), else starts a new one. Keeps the 10 newest.
dots_log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dots/logs"
mkdir -p "$dots_log_dir"
if [ -z "${DOTS_LOG:-}" ]; then
  if [ -n "$(find -L "$dots_log_dir/latest.log" -mmin -30 2>/dev/null)" ]; then
    DOTS_LOG="$dots_log_dir/$(readlink "$dots_log_dir/latest.log")"
  else
    DOTS_LOG="$dots_log_dir/bootstrap-$(date +%Y%m%d-%H%M%S).log"
    : >"$DOTS_LOG"
    ln -sfn "$(basename "$DOTS_LOG")" "$dots_log_dir/latest.log"
  fi
fi
# shellcheck disable=SC2012 # names are ours, no spaces
ls -1t "$dots_log_dir"/bootstrap-*.log 2>/dev/null | tail -n +11 | while IFS= read -r old; do rm -f -- "$old"; done
export DOTS_LOG
exec > >(tee -a "$DOTS_LOG") 2>&1
```

  Run `mise run -C test integration bootstrap all` → pass. `shellcheck script/bootstrap-log.sh` → clean.

- [ ] **Step 3: Wire the hook and the task.** In `config/mise/conf.d/bootstrap.toml`:
  - In `[bootstrap.hooks.post-packages]`, after `set -euo pipefail`, add
    `. "$HOME/.local/share/dots/script/bootstrap-log.sh"`.
  - In `[tasks.bootstrap]`, after the `dots="$HOME/.local/share/dots"` line, add `. "$dots/script/bootstrap-log.sh"`.
  Then `mise run -C test integration bootstrap all` → still pass (the post-packages spec runs the hook with
  `HOME` set to a temp folder: if it now fails because `$HOME/.local/share/dots/script/bootstrap-log.sh` is
  missing there, make the hook's line `[ -r "$f" ] && . "$f"` with `f=…`, and the same in the task).

- [ ] **Step 4: `install`.** After the variables block (after `export PATH="$HOME/.local/bin:$PATH"`), add the
  same logic inline (the repository is not cloned yet, so it cannot source the script):

```bash
# Log the whole run (both mise bootstrap runs included) for debugging; prompts use /dev/tty and stay out of it.
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dots/logs"
mkdir -p "$LOG_DIR"
export DOTS_LOG="$LOG_DIR/bootstrap-$(date +%Y%m%d-%H%M%S).log"
: >"$DOTS_LOG"
ln -sfn "$(basename "$DOTS_LOG")" "$LOG_DIR/latest.log"
exec > >(tee -a "$DOTS_LOG") 2>&1
echo "install: log: $DOTS_LOG"
```

  Check: `bash -n install`; `shellcheck install`; `grep -n '/dev/tty' install` shows the key prompt still reads
  from and writes to `/dev/tty`.

- [ ] **Step 5: Commit.** `feat(bootstrap): Log every install and bootstrap run`.

---

### Task 9: `AGENTS.md` (the single agent entry)

**Files:** rewrite `AGENTS.md`; delete `.agents/`.

- [ ] **Step 1:** Read `AGENTS.md`, `.agents/skills/dots-context/SKILL.md`, `dots-quality-gate/SKILL.md`,
  `dots-testing/SKILL.md`, and the routing doc deleted in Task 1:
  `g show "$(g log --diff-filter=D --format=%h -1 -- .cursor)^:.cursor/dots-skill-routing.md"`.
- [ ] **Step 2:** Write `AGENTS.md` with exactly these sections, keeping only what is true after Tasks 1–8:
  1. **What this repo is** (3 lines): `install` + `mise bootstrap`, one Brewfile, `config/<app>` linked into
     `~/.config`, Docker images in `distros/`.
  2. **Layout**: a table of top-level folders (from §1 of the spec plus `test/`, `docs/`).
  3. **Workflow**: brainstorm → spec in `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` → plan in
     `docs/superpowers/plans/YYYY-MM-DD-<topic>.md` → implement in a worktree. Old specs live in git history only.
  4. **Quality gate**: `mise run test:specs`, `hk check --all`, `mise run zsh:verify` for zsh changes,
     `mise run build --local --distro <d>` + `mise run test --image …` for Dockerfile, CST or bootstrap changes.
  5. **Hard rules**: the SOPS git filter wrapper; never `git add -A`; never print or commit secrets
     (`config/.env`, `config/ssh/keys/*.key`, `config/age/keys.txt`); no push or PR unless asked; Conventional
     Commits with a capitalized description (link `docs/CONTRIBUTING.md`).
  6. **Useful skills** (only ones that exist in the global skills and fit dots): `systematic-debugging`,
     `mise-tasks`, `mise-expert`, `bash-scripting`, `docker-expert`, `writing-plans`, `brainstorming`,
     `verification-before-completion`, `receiving-code-review`. One line each.
  7. **Docs**: links to `README.md` and each `docs/*.md`.
- [ ] **Step 3:** `g rm -rq .agents`; remove `.agents/` from `.markdownlintignore`. Commit:
  `docs(agents): Make AGENTS.md the single agent entry`.

---

### Task 10: `README.md`

- [ ] **Step 1:** Keep the existing sections; fix only what changed:
  - **How it works** table: drop rows for removed files; add `script/bootstrap-log.sh` (logs) and `test/`.
  - **Day to day**: the skills paragraph says the bootstrap restores skills in the background, with the log,
    result file, notification and `DOTS_SKILLS_FOREGROUND=1`; add "Logs: `~/.local/state/dots/logs/latest.log`".
  - **Playbooks**: `mise run -C assets` → `mise run test:specs` / `mise run -C test …`; the reinstall row links
    `docs/REINSTALL.md`.
  - **Configurations**: remove rows for configs deleted in Task 3 and for `amethyst`/`skhd` if deleted.
  - **Gotchas**: add "A bootstrap failed: read `~/.local/state/dots/logs/latest.log`".
  - **Repository layout**: the new tree (`test/`, `docs/`, no `assets/`).
  - Add **Docs**: one line per `docs/*.md` and `AGENTS.md`.
- [ ] **Step 2:** Commit: `docs(readme): Update for the close-out layout`.

---

### Task 11: `docs/` canonical set

For each doc: read every source in full, keep only statements true of dots today (§4 rules: no generic
tutorials, nothing from kodexb/electrobun, no `.mdc`, no gitlint, no tasks that do not exist — check each task
name with `mise tasks` / `mise -C test tasks`), then `g rm` the sources. Use `g mv` for the largest source of
each doc so history follows it.

- [ ] **Step 1: `docs/REINSTALL.md`** — `g mv assets/guides/REINSTALL_GUIDE.md docs/REINSTALL.md`. Fix row 29
  (`skills:restore` reads `config/agents/skill-lock.json`, now in the background). Add a "Bootstrap runbook"
  section from `$TMPDIR/runbook.md` (Task 2), trimmed to current commands. Update its references:
  `script/backup.ts` (header and the drive-README URL `…/blob/main/assets/guides/REINSTALL_GUIDE.md` →
  `…/blob/main/docs/REINSTALL.md`), `config/restic/backup.toml:3`, `config/restic/backup.schema.json:5`,
  `config/mise/conf.d/backup.toml:2`. Run `mise run -C test integration backup all` → pass.
- [ ] **Step 2: `docs/TESTING.md`** — `g mv assets/guides/TESTING_GUIDE.md docs/TESTING.md`, then cut it to: the
  gate (Task 9 §4 list), test layout (`test/features`, `test/integration/<domain>`, fixtures, stubs on PATH as the
  post-packages and skills specs do), how to run one domain or one spec, BDD + Gherkin rules from `BDD_GUIDE.md`
  and `BDD_GHERKIN_GUIDE.md` (Rule/Scenario shape, Screenplay actor, step vocabulary actually used in
  `test/features`), CST (`distros/*/container-structure-test.yml`), and the definition-of-done checklist from
  `DoD.md` (only items that map to a real command). Delete `test/features/README.md` after merging.
  Target: under 1,200 words.
- [ ] **Step 3: `docs/CONTRIBUTING.md`** — `g mv assets/guides/GIT_COMMITS_GUIDE.md docs/CONTRIBUTING.md`; merge
  the commit rules (types, capitalized description, enforced by `config/cog/cog.toml` through hk), branch and
  worktree practice (the SOPS wrapper), code style that applies to dots (bash/zsh: shellcheck, shfmt, `zsh -n`;
  TypeScript: Bun, no `any`; TOML: taplo), and mise task conventions from `MISE_GUIDE.md` (naming, inline
  `[tasks]`, `usage` args, root vs `test/`). Update `config/cog/cog.toml:3` if it links a guide.
  Target: under 1,000 words.
- [ ] **Step 4: `docs/DOCKER.md`** — `g mv assets/guides/DOCKER_GUIDE.md docs/DOCKER.md`; remove `.cursor`,
  `[tools]` and devcontainer mentions; add a **CI** section describing the three real workflows
  (`.github/workflows/preview.yml`: Brewfile parse, hadolint, image build + CST, size budget;
  `publish.yml`; `release.yml`: semantic-release) from reading them, not from `CI_GUIDE.md`.
- [ ] **Step 5: `docs/GLOSSARY.md`** — `g mv assets/guides/GLOSSARY.md docs/GLOSSARY.md`; drop removed terms
  (`xc-usage`, `xc-md`, `show_usage`, `gen` if gone, spec/skill-registry, Spec, Living documentation if BDD is
  described in TESTING); keep backup terms.
- [ ] **Step 6: Delete the rest.** `g rm -q assets/guides/*` (what is left: README, BDD_*, CI_GUIDE, CODESTYLE,
  DoD, GIT_GUIDE, MISE_GUIDE); `rmdir assets`.
- [ ] **Step 7: Per-app READMEs.** Rewrite `config/zsh/README.md` from the current files under `config/zsh/`
  (what each rc.d file does, how to add a function); prune `config/bin/README.md` to tools that exist in
  `config/bin` and tasks that exist (`ls config/bin`, `mise -C config/bin tasks`).
- [ ] **Step 8:** Commit: `docs: Merge the guides into one canonical set under docs/`.

---

### Task 12: Remaining references

- [ ] **Step 1:** `g grep -nE 'assets/|\.cursor|skills-lock|SKILLS\.(md|yml)|skill-registry|devcontainer|starship|xc-usage|xc-md|kodexb|electrobun|gitlint|\.mdc\b|graphify-out|_GUIDE\.md|DoD\.md' -- . ':!CHANGELOG.md' ':!docs/superpowers'`
  → fix every hit (config comments, READMEs, `.dockerignore`, workflows). `config/kodexb` itself is app data:
  if hits are only inside `config/kodexb/`, leave them and say so in the commit message.
- [ ] **Step 2:** Commit: `chore: Drop references to removed files`.

---

### Task 13: Verification

- [ ] **Step 1: Gate.** `mise run test:specs` → all pass; `hk check --all` → clean.
- [ ] **Step 2: Links.** Every relative Markdown link resolves:

```bash
g ls-files '*.md' | grep -v '^CHANGELOG.md$' | while IFS= read -r f; do
  grep -oE '\]\([^)#[:space:]]+' "$f" | sed 's/^](//' | grep -vE '^(https?:|mailto:)' | while IFS= read -r l; do
    [ -e "$(dirname "$f")/$l" ] || echo "$f -> $l"
  done
done
```

  Expected: no output.
- [ ] **Step 3: Stale terms.** Rerun Task 12 Step 1's grep → empty (or only `config/kodexb/` data).
- [ ] **Step 4: Image.** `mise run build --local --distro ubuntu --tag closeout`, then
  `mise run test --image dots:ubuntu-closeout --config distros/ubuntu/container-structure-test.yml` → 0 failures;
  `docker image ls dots:ubuntu-closeout` size ≤ the baseline's `ubuntu-*` size.
- [ ] **Step 5: Counts.** `g ls-files | wc -l` vs `$TMPDIR/closeout-files-before.txt`; `g diff --stat main | tail -1`.
- [ ] **Step 6:** Report to the owner: commits (`g log --oneline main..`), test results vs baseline, image size,
  file count delta, and anything left (e.g. kodexb hits).

### Task 14: Owner steps (not for the agent)

On the owner's go: push and open the PR. After merging, on this Mac: `mise bootstrap -E desktop` returns before
the skills finish and prints the skills log path; a notification appears when they are done;
`~/.local/state/dots/logs/latest.log` holds the run.
