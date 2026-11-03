<!-- markdownlint-disable -->
# Reproducible agent skills from a versioned lock — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task by task. Steps use checkbox (`- [ ]`) syntax for
> tracking. Tick each box in this file as you finish it.

**Goal:** Restore the global agent skills on any machine from `config/agents/skill-lock.json` in this repo,
keep the owner's commands in the repo, and stop syncing `~/.agents` through `dots-history`.

**Architecture:** One Bun script, `script/agent-skills.ts`, exports small pure helpers (unit-tested) and two
commands: `audit` (classify installed skills, optionally re-add confirmed ones so the `skills` CLI records
them) and `restore` (install every lock entry that is missing). Two mise tasks in the root `mise.toml` call
it. The CLI's own lock file moves into the repo and is linked back to both paths the CLI reads.

**Tech stack:** Bun 1.3.14 (TypeScript, `bun:test`), the `skills` CLI (`npm:skills`, lock format version 3),
`gh` (GitHub API), `git`, mise tasks and `[dotfiles]`.

**Design:** [design.md](./design.md). Read §2 (findings) and §4 (components) before starting.

---

## Ground rules for the executor

- Work in `~/Work/dots` on the branch `feat/agent-skills-lock` (it already exists and holds the spec). Check
  with `git branch --show-current`. Never commit to `main`.
- **Commits:** this Mac has no `hk` on PATH, so the git hooks fail. Commit with `HK=0 git commit ...`, and run
  the linters yourself before each commit:

  ```bash
  mise x hk@2.9.0 pkl@latest shellcheck@0.11.0 taplo@0.10.0 npm:markdownlint-cli@0.49.1 -- hk check
  ```

  Expected: every line starts with `✔`. If `taplo` fails, run `mise x taplo@0.10.0 -- taplo fmt <file>` and
  re-run the check.
- End every commit message with the line `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Set `export MISE_AUTO_INSTALL=0 MISE_EXEC_AUTO_INSTALL=0` in every shell you open: without it, mise on this
  Mac tries to install every global tool and fails.
- `git status` always shows untracked files under `config/flox/`. They are not yours: never `git add -A`; add
  files by path.
- **Stop and ask the owner** wherever a step says **STOP**. Do not continue past it on your own.
- Do not edit anything under `~/.agents` by hand. Only the `skills` CLI (through the tasks) and the steps in
  Tasks 6–8 touch it.

## File map

| File | Action | Responsibility |
| --- | --- | --- |
| `script/agent-skills.ts` | Create | Helpers plus the `audit` and `restore` commands |
| `assets/integration/agents/agent-skills.spec.ts` | Create | Unit tests for the helpers and the restore guard |
| `mise.toml` | Modify | Tasks `skills:audit` and `skills:restore` |
| `config/mise/config.toml` | Modify | Add the `npm:skills` tool; drop the `~/.agents` track entry; delete the `fix:skills` task |
| `config/mise/conf.d/dotfiles.toml` | Modify | Links for the lock (two paths) and the commands folder |
| `config/mise/conf.d/bootstrap.toml` | Modify | Call `skills:restore` from the `bootstrap` task |
| `config/agents/skill-lock.json` | Create (copy) | The global `skills` lock |
| `config/agents/commands/` | Create (move) | The owner's commands, from `~/.agents/commands` |
| `config/agents/review.csv` | Create (generated) | Skills whose source is not confirmed |
| `script/skills.csv` | Delete | Replaced by the audit |
| `README.md`, `assets/specs/mise-bootstrap/tasks-native.md` | Modify | Docs |

---

### Task 1: Pure helpers, test first

**Files:**
- Create: `assets/integration/agents/agent-skills.spec.ts`
- Create: `script/agent-skills.ts`

- [ ] **Step 1: Write the failing tests.** Create `assets/integration/agents/agent-skills.spec.ts` with exactly:

```ts
#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { mkdirSync, mkdtempSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  LOCK_VERSION,
  addCommand,
  findCandidates,
  groupBySource,
  lockProblem,
  matchCandidates,
  missingSkills,
  parseSkillsCsv,
  reviewCsv,
  treeHash,
  type Lock,
  type TreeEntry,
} from "../../../script/agent-skills";

const lock: Lock = {
  version: LOCK_VERSION,
  skills: {
    alpha: { source: "o/one", sourceUrl: "https://github.com/o/one.git", skillPath: "skills/alpha/SKILL.md", skillFolderHash: "a1" },
    beta: { source: "o/one", sourceUrl: "https://github.com/o/one.git", skillPath: "skills/beta/SKILL.md", skillFolderHash: "b1" },
    gamma: { source: "o/two", skillPath: "gamma/SKILL.md", skillFolderHash: "c1" },
  },
  lastSelectedAgents: ["codex", "cursor"],
};

function tempDir(): string {
  return mkdtempSync(join(tmpdir(), "agent-skills-spec-"));
}

describe("parseSkillsCsv", () => {
  it("maps each name to the owner/repo before the @", () => {
    const csv = "academic-cv-builder, paramchoudhary/resumeskills@academic-cv-builder, https://skills.sh/x\n" +
      "act-local-testing, thebushidocollective/han@act-local-testing, https://skills.sh/y\n";
    const m = parseSkillsCsv(csv);
    expect(m.get("academic-cv-builder")).toBe("paramchoudhary/resumeskills");
    expect(m.get("act-local-testing")).toBe("thebushidocollective/han");
  });

  it("skips blank and malformed lines", () => {
    expect(parseSkillsCsv("\nonly-a-name\nname, no-at-sign, url\n").size).toBe(0);
  });
});

describe("findCandidates", () => {
  const tree: TreeEntry[] = [
    { path: "skills", type: "tree", sha: "s0" },
    { path: "skills/alpha", type: "tree", sha: "t-alpha" },
    { path: "skills/alpha/SKILL.md", type: "blob", sha: "x" },
    { path: "docs/alpha", type: "tree", sha: "t-docs" },
    { path: "alpha-extra", type: "tree", sha: "t-extra" },
    { path: "alpha-extra/SKILL.md", type: "blob", sha: "y" },
  ];

  it("finds folders named exactly like the skill that hold a SKILL.md", () => {
    expect(findCandidates("alpha", tree).map((e) => e.sha)).toEqual(["t-alpha"]);
  });

  it("finds a top-level folder", () => {
    expect(findCandidates("alpha-extra", tree).map((e) => e.sha)).toEqual(["t-extra"]);
  });

  it("returns nothing when no folder matches", () => {
    expect(findCandidates("missing", tree)).toEqual([]);
  });
});

describe("matchCandidates", () => {
  const entry = (sha: string): TreeEntry => ({ path: `p/${sha}`, type: "tree", sha });

  it("is unknown without candidates", () => {
    expect(matchCandidates("h", [])).toEqual({ status: "unknown", candidateSource: "", upstreamHash: "" });
  });

  it("is confirmed when any candidate has the local hash", () => {
    const r = matchCandidates("h", [{ source: "o/a", entry: entry("z") }, { source: "o/b", entry: entry("h") }]);
    expect(r).toEqual({ status: "confirmed", candidateSource: "o/b", upstreamHash: "h" });
  });

  it("differs when candidates exist but none match, reporting the first", () => {
    const r = matchCandidates("h", [{ source: "o/a", entry: entry("z") }]);
    expect(r).toEqual({ status: "differs", candidateSource: "o/a", upstreamHash: "z" });
  });
});

describe("lockProblem", () => {
  it("accepts a version-3 lock with at least the committed count", () => {
    expect(lockProblem(lock, 3)).toBeNull();
  });

  it("rejects another version", () => {
    expect(lockProblem({ ...lock, version: 2 }, 0)).toContain("lock version 2");
  });

  it("rejects a lock with fewer entries than committed", () => {
    expect(lockProblem(lock, 4)).toContain("fewer than the 4 committed");
  });

  it("rejects something that is not a lock", () => {
    expect(lockProblem({ hello: 1 }, 0)).toContain("not a skills lock");
  });
});

describe("groupBySource", () => {
  it("groups names by sourceUrl, falling back to source", () => {
    const g = groupBySource(lock, ["alpha", "beta", "gamma", "not-in-lock"]);
    expect([...g.entries()]).toEqual([
      ["https://github.com/o/one.git", ["alpha", "beta"]],
      ["o/two", ["gamma"]],
    ]);
  });
});

describe("missingSkills", () => {
  it("lists lock entries with no folder; a link counts as present", () => {
    const dir = tempDir();
    try {
      mkdirSync(join(dir, "alpha"));
      symlinkSync("/nonexistent/target", join(dir, "beta"));
      expect(missingSkills(lock, dir)).toEqual(["gamma"]);
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
});

describe("reviewCsv", () => {
  it("keeps only differs, unknown and locked-differs rows, with a header", () => {
    const csv = reviewCsv([
      { name: "a", status: "confirmed", candidateSource: "o/a", localHash: "1", upstreamHash: "1" },
      { name: "b", status: "differs", candidateSource: "o/b", localHash: "2", upstreamHash: "3" },
      { name: "c", status: "unknown", candidateSource: "", localHash: "4", upstreamHash: "" },
      { name: "d", status: "locked-differs", candidateSource: "o/d", localHash: "5", upstreamHash: "6" },
      { name: "e", status: "custom", candidateSource: "", localHash: "", upstreamHash: "" },
    ]);
    expect(csv).toBe(
      "name,status,candidate_source,local_hash,upstream_hash\n" +
        "b,differs,o/b,2,3\n" +
        "c,unknown,,4,\n" +
        "d,locked-differs,o/d,5,6\n",
    );
  });
});

describe("addCommand", () => {
  it("builds a global, non-interactive skills add for several names and agents", () => {
    expect(addCommand("o/one", ["alpha", "beta"], ["codex", "cursor"])).toEqual([
      "skills", "add", "o/one", "-g", "-y", "-s", "alpha", "beta", "-a", "codex", "cursor",
    ]);
  });

  it("omits -a without agents", () => {
    expect(addCommand("o/one", ["alpha"], [])).toEqual(["skills", "add", "o/one", "-g", "-y", "-s", "alpha"]);
  });
});

describe("treeHash", () => {
  it("is the git tree id of the folder, ignoring node_modules and .git", () => {
    const dir = tempDir();
    try {
      mkdirSync(join(dir, "references"));
      mkdirSync(join(dir, "node_modules"));
      mkdirSync(join(dir, ".git"));
      writeFileSync(join(dir, "SKILL.md"), "---\nname: demo\ndescription: Demo skill\n---\n");
      writeFileSync(join(dir, "references", "a.md"), "ref\n");
      writeFileSync(join(dir, "node_modules", "x"), "x\n");
      writeFileSync(join(dir, ".git", "HEAD"), "ref: refs/heads/main\n");
      expect(treeHash(dir)).toBe("9d83f81b2da188bf5d113a7e48c2dd2404b18dd3");
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
});
```

- [ ] **Step 2: Run the tests and watch them fail.**

Run: `cd ~/Work/dots/assets && mise x bun@1.3.14 -- bun test integration/agents/`
Expected: FAIL, with an error like `Cannot find module '../../../script/agent-skills'`.

- [ ] **Step 3: Write the helpers.** Create `script/agent-skills.ts` with exactly this content (Task 2 adds the
  commands at the end):

```ts
#!/usr/bin/env bun
// Audit and restore the global agent skills from config/agents/skill-lock.json
// (assets/specs/agent-skills-lock/design.md). Usage: bun script/agent-skills.ts audit [--apply] | restore
import { cpSync, existsSync, lstatSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { dirname, join, relative, resolve } from "node:path";

/** The lock format this script understands; the skills CLI empties a lock with an older version on its next write. */
export const LOCK_VERSION = 3;
/** Below this share of locked skills matching their skillFolderHash, the hashing is wrong and the audit stops. */
export const MIN_MATCH_RATIO = 0.9;

export type LockEntry = { source: string; sourceUrl?: string; skillPath?: string; skillFolderHash?: string };
export type Lock = { version: number; skills: Record<string, LockEntry>; lastSelectedAgents?: string[] };
export type TreeEntry = { path: string; type: string; sha: string };
export type Status = "locked" | "locked-differs" | "confirmed" | "differs" | "unknown" | "custom";
export type Row = { name: string; status: Status; candidateSource: string; localHash: string; upstreamHash: string };

type Result = { code: number; out: string; err: string };

function run(cmd: string[], cwd?: string): Result {
  const r = Bun.spawnSync(cmd, { cwd, env: process.env, stdout: "pipe", stderr: "pipe" });
  return { code: r.exitCode ?? 1, out: r.stdout.toString(), err: r.stderr.toString() };
}

/** Runs a command with its output on this terminal; returns the exit code. */
function runLoud(cmd: string[], env: Record<string, string | undefined> = process.env): number {
  console.log(`$ ${cmd.join(" ")}`);
  return Bun.spawnSync(cmd, { env, stdout: "inherit", stderr: "inherit" }).exitCode ?? 1;
}

/** Git tree id of a folder's contents without .git and node_modules: what the lock's skillFolderHash records. */
export function treeHash(dir: string): string {
  const tmp = mkdtempSync(join(tmpdir(), "skill-hash-"));
  try {
    cpSync(dir, tmp, {
      recursive: true,
      filter: (src) => !relative(dir, src).split("/").some((part) => part === ".git" || part === "node_modules"),
    });
    for (const args of [["init", "-q"], ["add", "-A"], ["write-tree"]]) {
      const r = run(["git", ...args], tmp);
      if (r.code !== 0) throw new Error(`git ${args.join(" ")} failed in ${dir}: ${r.err}`);
      if (args[0] === "write-tree") return r.out.trim();
    }
    throw new Error("unreachable");
  } finally {
    rmSync(tmp, { recursive: true, force: true });
  }
}

/** name -> "owner/repo" from script/skills.csv lines like "name, owner/repo@name, url". */
export function parseSkillsCsv(text: string): Map<string, string> {
  const sources = new Map<string, string>();
  for (const line of text.split(/\r?\n/)) {
    const [name, ref] = line.split(",").map((part) => part.trim());
    if (!name || !ref || !ref.includes("@")) continue;
    sources.set(name, ref.slice(0, ref.lastIndexOf("@")));
  }
  return sources;
}

/** Folders in a repo tree named exactly `name` that hold a SKILL.md. */
export function findCandidates(name: string, tree: TreeEntry[]): TreeEntry[] {
  const blobs = new Set(tree.filter((e) => e.type === "blob").map((e) => e.path));
  return tree.filter(
    (e) => e.type === "tree" && (e.path === name || e.path.endsWith(`/${name}`)) && blobs.has(`${e.path}/SKILL.md`),
  );
}

/** Classifies an unlocked skill against the upstream folders found for it. */
export function matchCandidates(
  localHash: string,
  candidates: { source: string; entry: TreeEntry }[],
): Pick<Row, "status" | "candidateSource" | "upstreamHash"> {
  if (candidates.length === 0) return { status: "unknown", candidateSource: "", upstreamHash: "" };
  const hit = candidates.find((c) => c.entry.sha === localHash);
  if (hit) return { status: "confirmed", candidateSource: hit.source, upstreamHash: hit.entry.sha };
  return { status: "differs", candidateSource: candidates[0].source, upstreamHash: candidates[0].entry.sha };
}

/** Why a lock must not be restored, or null when it is safe. */
export function lockProblem(lock: unknown, committedCount: number): string | null {
  if (!lock || typeof lock !== "object" || !("skills" in lock)) return "the file is not a skills lock";
  const { version, skills } = lock as Lock;
  if (version !== LOCK_VERSION) {
    return `lock version ${version} is not ${LOCK_VERSION}; check the skills CLI before restoring`;
  }
  const count = Object.keys(skills ?? {}).length;
  if (count < committedCount) return `the lock has ${count} entries, fewer than the ${committedCount} committed at HEAD`;
  return null;
}

/** The given lock entries grouped by the source `skills add` takes (sourceUrl, else source), in lock order. */
export function groupBySource(lock: Lock, names: string[]): Map<string, string[]> {
  const groups = new Map<string, string[]>();
  for (const name of names) {
    const entry = lock.skills[name];
    if (!entry) continue;
    const source = entry.sourceUrl ?? entry.source;
    groups.set(source, [...(groups.get(source) ?? []), name]);
  }
  return groups;
}

function present(path: string): boolean {
  try {
    lstatSync(path);
    return true;
  } catch {
    return false;
  }
}

/** Lock entries with nothing at <skillsDir>/<name>; a folder or a link, even a broken one, counts as present. */
export function missingSkills(lock: Lock, skillsDir: string): string[] {
  return Object.keys(lock.skills).filter((name) => !present(join(skillsDir, name))).sort();
}

/** config/agents/review.csv: the rows whose source is not confirmed. */
export function reviewCsv(rows: Row[]): string {
  const keep = rows.filter((r) => r.status === "differs" || r.status === "unknown" || r.status === "locked-differs");
  const lines = keep.map((r) => [r.name, r.status, r.candidateSource, r.localHash, r.upstreamHash].join(","));
  return ["name,status,candidate_source,local_hash,upstream_hash", ...lines].join("\n") + "\n";
}

/** A global, non-interactive `skills add` for several skills of one source. */
export function addCommand(source: string, names: string[], agents: string[]): string[] {
  return ["skills", "add", source, "-g", "-y", "-s", ...names, ...(agents.length ? ["-a", ...agents] : [])];
}
```

- [ ] **Step 4: Run the tests and watch them pass.**

Run: `cd ~/Work/dots/assets && mise x bun@1.3.14 -- bun test integration/agents/`
Expected: PASS, `18 pass`, `0 fail`. If `treeHash` fails with a different id, do not change the expected
value: check that the filter skips `.git` and `node_modules`, then stop and ask the owner.

- [ ] **Step 5: Commit.**

```bash
cd ~/Work/dots
git add script/agent-skills.ts assets/integration/agents/agent-skills.spec.ts
HK=0 git commit -m "feat(skills): Add the agent skills lock helpers

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: The `audit` and `restore` commands

**Files:**
- Modify: `script/agent-skills.ts` (append at the end)
- Modify: `assets/integration/agents/agent-skills.spec.ts` (append at the end)

- [ ] **Step 1: Write the failing test for the restore guard.** Append to
  `assets/integration/agents/agent-skills.spec.ts`:

```ts
describe("restore command", () => {
  const script = join(import.meta.dir, "../../../script/agent-skills.ts");

  function restore(lockText: string) {
    const dir = tempDir();
    try {
      writeFileSync(join(dir, "lock.json"), lockText);
      mkdirSync(join(dir, "skills"));
      const r = Bun.spawnSync(["bun", script, "restore"], {
        env: { ...process.env, SKILL_LOCK: join(dir, "lock.json"), SKILLS_DIR: join(dir, "skills") },
        stdout: "pipe",
        stderr: "pipe",
      });
      return { code: r.exitCode, out: r.stdout.toString(), err: r.stderr.toString() };
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  }

  it("refuses a lock of another version", () => {
    const r = restore(JSON.stringify({ version: 2, skills: {} }));
    expect(r.code).toBe(1);
    expect(r.err).toContain("lock version 2");
  });

  it("does nothing when every locked skill is present", () => {
    const r = restore(JSON.stringify({ version: 3, skills: {} }));
    expect(r.code).toBe(0);
    expect(r.out).toContain("every locked skill is installed");
  });
});
```

- [ ] **Step 2: Run the tests and watch the two new ones fail.**

Run: `cd ~/Work/dots/assets && mise x bun@1.3.14 -- bun test integration/agents/`
Expected: the 18 earlier tests pass; the 2 `restore command` tests FAIL (the script has no `restore` yet,
so it exits 0 with no output).

- [ ] **Step 3: Append the commands** to the end of `script/agent-skills.ts`:

```ts
// ---- commands -------------------------------------------------------------------------------------------

const repoRoot = resolve(import.meta.dir, "..");
const repoLock = join(repoRoot, "config/agents/skill-lock.json");
const stateLock = join(process.env.XDG_STATE_HOME ?? join(homedir(), ".local/state"), "skills/.skill-lock.json");
const csvPath = join(repoRoot, "script/skills.csv");
const reviewPath = join(repoRoot, "config/agents/review.csv");

/** SKILL_LOCK, else the repo's lock once it exists, else the CLI's own (before the migration). */
function lockPath(): string {
  return process.env.SKILL_LOCK ?? (existsSync(repoLock) ? repoLock : stateLock);
}

function skillsDir(): string {
  return process.env.SKILLS_DIR ?? join(homedir(), ".agents/skills");
}

function readLock(path: string): Lock {
  return JSON.parse(readFileSync(path, "utf8")) as Lock;
}

const isGithubRepo = (source: string) => /^[\w.-]+\/[\w.-]+$/.test(source);

const trees = new Map<string, TreeEntry[]>();

/** A GitHub repo's full tree, fetched once per run; empty (with a warning) when it cannot be read. */
function fetchTree(source: string): TreeEntry[] {
  const cached = trees.get(source);
  if (cached) return cached;
  const r = run(["gh", "api", `repos/${source}/git/trees/HEAD?recursive=1`]);
  let tree: TreeEntry[] = [];
  if (r.code !== 0) {
    console.warn(`warning: cannot read ${source}: ${r.err.trim().split("\n")[0]}`);
  } else {
    const body = JSON.parse(r.out) as { tree: TreeEntry[]; truncated?: boolean };
    if (body.truncated) console.warn(`warning: ${source} is too large for one tree request; some folders are missed`);
    tree = body.tree;
  }
  trees.set(source, tree);
  return tree;
}

function audit(apply: boolean): void {
  const dir = skillsDir();
  const lock = readLock(lockPath());
  const csv = existsSync(csvPath) ? parseSkillsCsv(readFileSync(csvPath, "utf8")) : new Map<string, string>();
  const names = readdirSync(dir).filter((n) => !n.startsWith(".")).sort();
  const rows: Row[] = [];

  // 1. Self-check: the hashing must reproduce the lock's skillFolderHash for nearly every locked skill.
  let checked = 0;
  let matched = 0;
  for (const name of names) {
    const entry = lock.skills[name];
    if (!entry) continue;
    if (lstatSync(join(dir, name)).isSymbolicLink()) {
      rows.push({ name, status: "custom", candidateSource: "", localHash: "", upstreamHash: "" });
      continue;
    }
    const localHash = treeHash(join(dir, name));
    const same = !!entry.skillFolderHash && entry.skillFolderHash === localHash;
    checked++;
    if (same) matched++;
    rows.push({
      name,
      status: same ? "locked" : "locked-differs",
      candidateSource: entry.source,
      localHash,
      upstreamHash: entry.skillFolderHash ?? "",
    });
  }
  console.log(`self-check: ${matched}/${checked} locked skills match their skillFolderHash`);
  if (checked > 0 && matched / checked < MIN_MATCH_RATIO) {
    console.error("self-check failed: the hashing does not reproduce the lock; stopping");
    process.exit(1);
  }

  // 2. Unlocked skills: look for a folder of the same name, its CSV source first, then every known source.
  const sources = [...new Set([...Object.values(lock.skills).map((e) => e.source), ...csv.values()])].filter(isGithubRepo);
  for (const name of names) {
    if (lock.skills[name]) continue;
    const path = join(dir, name);
    if (lstatSync(path).isSymbolicLink()) {
      rows.push({ name, status: "custom", candidateSource: "", localHash: "", upstreamHash: "" });
      continue;
    }
    const localHash = treeHash(path);
    const first = csv.get(name);
    const order = first && isGithubRepo(first) ? [first, ...sources.filter((s) => s !== first)] : sources;
    const candidates: { source: string; entry: TreeEntry }[] = [];
    for (const source of order) {
      for (const entry of findCandidates(name, fetchTree(source))) candidates.push({ source, entry });
      if (candidates.some((c) => c.entry.sha === localHash)) break;
    }
    rows.push({ name, localHash, ...matchCandidates(localHash, candidates) });
    console.log(`${name}: ${rows[rows.length - 1].status}`);
  }

  // 3. Report.
  const counts = new Map<Status, number>();
  for (const r of rows) counts.set(r.status, (counts.get(r.status) ?? 0) + 1);
  console.log([...counts].map(([s, n]) => `${s} ${n}`).join(" · "));
  mkdirSync(dirname(reviewPath), { recursive: true });
  writeFileSync(reviewPath, reviewCsv(rows));
  console.log(`wrote ${relative(repoRoot, reviewPath)}`);

  // 4. --apply: re-add confirmed skills through the CLI, which records them in its lock.
  if (!apply) return;
  const bySource = new Map<string, string[]>();
  for (const r of rows.filter((row) => row.status === "confirmed")) {
    bySource.set(r.candidateSource, [...(bySource.get(r.candidateSource) ?? []), r.name]);
  }
  const failed = [...bySource].filter(([source, list]) => runLoud(addCommand(source, list, lock.lastSelectedAgents ?? [])) !== 0);
  if (failed.length) {
    console.error(`skills add failed for: ${failed.map(([s]) => s).join(", ")}`);
    process.exit(1);
  }
}

function restore(): void {
  const path = lockPath();
  const lock = readLock(path);
  const committed = run(["git", "show", "HEAD:config/agents/skill-lock.json"], repoRoot);
  const committedCount =
    !process.env.SKILL_LOCK && committed.code === 0 ? Object.keys((JSON.parse(committed.out) as Lock).skills ?? {}).length : 0;
  const problem = lockProblem(lock, committedCount);
  if (problem) {
    console.error(`skills:restore: ${problem}`);
    process.exit(1);
  }
  const missing = missingSkills(lock, skillsDir());
  if (missing.length === 0) {
    console.log("skills:restore: every locked skill is installed");
    return;
  }
  // A throwaway state folder, so the CLI writes its lock there and never rewrites the committed one.
  const state = mkdtempSync(join(tmpdir(), "skills-state-"));
  const env = { ...process.env, XDG_STATE_HOME: state };
  const failed: string[] = [];
  try {
    for (const [source, names] of groupBySource(lock, missing)) {
      if (runLoud(addCommand(source, names, lock.lastSelectedAgents ?? []), env) !== 0) failed.push(source);
    }
  } finally {
    rmSync(state, { recursive: true, force: true });
  }
  console.log(`skills:restore: ${missing.length} missing, ${failed.length} source(s) failed`);
  if (failed.length) {
    console.error(`failed: ${failed.join(", ")}`);
    process.exit(1);
  }
}

if (import.meta.main) {
  const [command, ...args] = process.argv.slice(2);
  if (command === "audit") audit(args.includes("--apply"));
  else if (command === "restore") restore();
  else {
    console.error("usage: bun script/agent-skills.ts audit [--apply] | restore");
    process.exit(2);
  }
}
```

- [ ] **Step 4: Run the tests and watch them all pass.**

Run: `cd ~/Work/dots/assets && mise x bun@1.3.14 -- bun test integration/agents/`
Expected: PASS, `20 pass`, `0 fail`.

- [ ] **Step 5: Commit.**

```bash
cd ~/Work/dots
git add script/agent-skills.ts assets/integration/agents/agent-skills.spec.ts
HK=0 git commit -m "feat(skills): Add the audit and restore commands

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: mise tasks and the `skills` CLI

**Files:**
- Modify: `mise.toml` (append at the end)
- Modify: `config/mise/config.toml` (the `[tools]` table, and the `fix:skills` task at the end)

- [ ] **Step 1: Append the tasks** to the end of `mise.toml`:

```toml

# Agent skills from config/agents/skill-lock.json (assets/specs/agent-skills-lock/design.md).
[tasks."skills:audit"]
description = "Classify installed agent skills against the lock and write config/agents/review.csv (-- --apply re-adds confirmed ones)"
tools = { bun = "1.3.14" }
run = "bun script/agent-skills.ts audit"

[tasks."skills:restore"]
description = "Install every skill in config/agents/skill-lock.json that is missing from ~/.agents/skills"
tools = { bun = "1.3.14" }
run = "bun script/agent-skills.ts restore"
```

  mise appends arguments given after `--` to a one-line `run`, so `mise run skills:audit -- --apply` runs
  `bun script/agent-skills.ts audit --apply`.

- [ ] **Step 2: Declare the `skills` CLI.** In `config/mise/config.toml`, find the line
  `"pipx:pynvim" = "latest"` in `[tools]` and add this line right after it:

```toml
"npm:skills" = "latest"                                          # Agent skills CLI (config/agents/skill-lock.json)
```

- [ ] **Step 3: Delete the `fix:skills` task.** It is the last section of `config/mise/config.toml`
  (from the line `[tasks."fix:skills"]` to the end of the file). Run:

```bash
cd ~/Work/dots
python3 - <<'EOF'
import pathlib
p = pathlib.Path("config/mise/config.toml"); s = p.read_text()
i = s.index('[tasks."fix:skills"]')
p.write_text(s[:i].rstrip() + "\n")
EOF
tail -3 config/mise/config.toml
grep -c 'fix:skills' config/mise/config.toml
```

  Expected: the last lines are the end of the `[tasks.backup]` task (`age -p -o omp-...` then `'''`), and the
  count is `0`.

- [ ] **Step 4: Check the tasks load.**

Run: `cd ~/Work/dots && mise tasks ls 2>/dev/null | grep -E '^skills:'`
Expected: two lines, `skills:audit` and `skills:restore`.

- [ ] **Step 5: Lint and commit.** Run the `hk check` command from the ground rules; then:

```bash
cd ~/Work/dots
git add mise.toml config/mise/config.toml
HK=0 git commit -m "feat(skills): Add the skills:audit and skills:restore tasks

Replaces fix:skills; declares npm:skills.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Run the audit (read-only)

**Files:**
- Create (generated): `config/agents/review.csv`

- [ ] **Step 1: Run it.** It reads `~/.local/state/skills/.skill-lock.json` (the repo lock does not exist yet)
  and makes about 70 `gh api` calls. It takes a few minutes.

```bash
cd ~/Work/dots && mise run skills:audit 2>&1 | tee "$TMPDIR/skills-audit.log" | tail -5
```

  Expected:
  - an early line `self-check: 169/187 locked skills match their skillFolderHash` (the numbers may differ
    slightly; the run stops if fewer than 90% match);
  - a counts line like `locked 169 · locked-differs 18 · custom 2 · confirmed … · differs … · unknown …`;
  - `wrote config/agents/review.csv`.

  If the self-check fails, **STOP** and report the log to the owner.

- [ ] **Step 2: Check the report.**

```bash
cd ~/Work/dots
head -3 config/agents/review.csv
cut -d, -f2 config/agents/review.csv | sort | uniq -c
```

  Expected: the header `name,status,candidate_source,local_hash,upstream_hash`, and counts for only
  `differs`, `locked-differs` and `unknown`.

- [ ] **Step 3: STOP.** Report to the owner: the counts line, and that `config/agents/review.csv` lists the
  skills to back up. Ask the owner to:
  1. back up the folders listed in `review.csv` (from `~/.agents/skills/<name>`), and
  2. approve running `--apply`, which re-adds the `confirmed` skills through the `skills` CLI (the content is
     identical; the CLI records them in its lock).

  Continue only after both are done.

---

### Task 5: Apply, then move the lock into the repo

**Files:**
- Create: `config/agents/skill-lock.json`
- Modify: `config/mise/conf.d/dotfiles.toml` (append at the end)

- [ ] **Step 1: Apply.**

```bash
cd ~/Work/dots && mise run skills:audit -- --apply 2>&1 | tee "$TMPDIR/skills-apply.log" | tail -5
python3 -c "import json,os;print(len(json.load(open(os.path.expanduser('~/.local/state/skills/.skill-lock.json')))['skills']))"
```

  Expected: one `$ skills add …` line per confirmed source, no `skills add failed` line, and the printed
  count equals 187 plus the `confirmed` count from Task 4.

- [ ] **Step 2: Copy the lock into the repo.**

```bash
cd ~/Work/dots
mkdir -p config/agents
cp ~/.local/state/skills/.skill-lock.json config/agents/skill-lock.json
python3 -c "import json;d=json.load(open('config/agents/skill-lock.json'));print(d['version'],len(d['skills']))"
```

  Expected: `3 <count from Step 1>`.

- [ ] **Step 3: Link both lock paths to it.** Append to `config/mise/conf.d/dotfiles.toml`:

```toml

# The skills CLI's global lock (assets/specs/agent-skills-lock/design.md). It reads the first path when
# XDG_STATE_HOME is set and the second otherwise (GUI apps, cron), so both point at one file.
"~/.local/state/skills/.skill-lock.json" = { source = "~/.local/share/dots/config/agents/skill-lock.json", relative = true }
"~/.agents/.skill-lock.json" = { source = "~/.local/share/dots/config/agents/skill-lock.json", relative = true }
```

- [ ] **Step 4: Replace the two real files with the links.** mise refuses to replace a real file, so move them
  aside first:

```bash
mkdir -p "$TMPDIR/old-skill-locks"
mv ~/.local/state/skills/.skill-lock.json "$TMPDIR/old-skill-locks/state.json"
mv ~/.agents/.skill-lock.json "$TMPDIR/old-skill-locks/agents.json"
mise dot apply ~/.local/state/skills/.skill-lock.json ~/.agents/.skill-lock.json 2>&1 | tail -3
ls -l ~/.local/state/skills/.skill-lock.json ~/.agents/.skill-lock.json
```

  Name the targets: a bare `mise dot apply` would also create every other pending link on this Mac.

  Expected: both are links (`->`) ending in `config/agents/skill-lock.json`. Note: `~/.local/share/dots` is
  the checkout these links resolve through; on this Mac it points at `~/Work/dots`
  (`readlink ~/.local/share/dots`).

- [ ] **Step 5: Check the CLI sees it.**

```bash
python3 -c "import json,os;print(len(json.load(open(os.path.expanduser('~/.local/state/skills/.skill-lock.json')))['skills']))"
```

  Expected: the same count as Step 2.

- [ ] **Step 6: Lint and commit.**

```bash
cd ~/Work/dots
git add config/agents/skill-lock.json config/agents/review.csv config/mise/conf.d/dotfiles.toml
HK=0 git commit -m "feat(skills): Keep the global skills lock in the repo

Both paths the skills CLI reads link to config/agents/skill-lock.json;
review.csv lists the skills whose source is not confirmed.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Move the commands into the repo

**Files:**
- Create: `config/agents/commands/` (moved from `~/.agents/commands`)
- Modify: `config/mise/conf.d/dotfiles.toml`

- [ ] **Step 1: Scan for secrets.** The repo is public.

```bash
grep -rniE 'ghp_|github_pat_|sk-[a-z0-9]{16}|AKIA[0-9A-Z]{16}|AGE-SECRET-KEY|BEGIN [A-Z ]*PRIVATE KEY|password *[:=]' ~/.agents/commands
```

  Expected: no output (checked on 2026-11-03: the only `token`/`secret` words are instructions not to write
  secrets). If anything prints, **STOP** and show it to the owner.

- [ ] **Step 2: Copy the folder into the repo.**

```bash
cd ~/Work/dots
cp -R ~/.agents/commands config/agents/commands
diff -r ~/.agents/commands config/agents/commands && echo same
```

  Expected: `same`.

- [ ] **Step 3: Link it.** Append to `config/mise/conf.d/dotfiles.toml`:

```toml
# The owner's agent commands.
"~/.agents/commands" = { source = "~/.local/share/dots/config/agents/commands", relative = true }
```

- [ ] **Step 4: Replace the real folder with the link.**

```bash
mv ~/.agents/commands "$TMPDIR/old-agents-commands"
mise dot apply ~/.agents/commands 2>&1 | tail -3
ls -l ~/.agents/commands
ls ~/.agents/commands
```

  Expected: a link ending in `config/agents/commands`, listing `done.md fd kb setup superset wip`.

- [ ] **Step 5: Lint and commit.**

```bash
cd ~/Work/dots
git add config/agents/commands config/mise/conf.d/dotfiles.toml
HK=0 git commit -m "feat(agents): Keep the agent commands in the repo

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Stop tracking `~/.agents`; restore from bootstrap

**Files:**
- Modify: `config/mise/config.toml` (the `[dotfiles]` table)
- Modify: `config/mise/conf.d/bootstrap.toml` (the `bootstrap` task)
- Delete: `script/skills.csv`

- [ ] **Step 1: Drop the track entry.** In `config/mise/config.toml`, delete these lines exactly (they follow
  the `"~/.config/gopass"` entry):

```toml
# Agent commands are the owner's own; skills come from many sources with no manifest (`.skill-lock.json` lists
# one), so the folder itself is the record; encrypted because some skills ship token-named files mise would
# otherwise omit. The two links point into local checkouts.
"~/.agents" = { mode = "track", encrypt = true, exclude = [
  "skills/cua-driver",
  "skills/recon",
] }
```

  Check: `grep -c '"~/.agents"' config/mise/config.toml` prints `0`.

- [ ] **Step 2: Call the restore from bootstrap.** In `config/mise/conf.d/bootstrap.toml`, find these two
  lines in the `bootstrap` task:

```bash
# devcontainer: minimal, so no Neovim providers or plugins.
case ",${MISE_ENV:-}," in *,devcontainer,*) exit 0 ;; esac
```

  and replace them with:

```bash
# devcontainer: minimal, so no agent skills, Neovim providers or plugins.
case ",${MISE_ENV:-}," in *,devcontainer,*) exit 0 ;; esac

# Agent skills from config/agents/skill-lock.json; installs only the missing ones.
mise run -C "$dots" skills:restore || warn "skills:restore"
```

- [ ] **Step 3: Delete the old CSV.**

```bash
cd ~/Work/dots && git rm -q script/skills.csv
```

- [ ] **Step 4: Check the config and the history.**

```bash
cd ~/Work/dots
for f in config/mise/config.toml config/mise/conf.d/bootstrap.toml config/mise/conf.d/dotfiles.toml; do
  python3 -c "import tomllib;tomllib.load(open('$f','rb'))" && echo "ok $f"
done
mise dot status 2>&1 | sed -n '/Tracking/,/checkpoints/p'
```

  Expected: three `ok` lines; `Tracking` shows 3 entries (`~/.config/ssh`, `~/.config/gnupg`,
  `~/.config/gopass`), far fewer files than the 4,000+ before.

- [ ] **Step 5: Check the restore is a no-op here.**

```bash
cd ~/Work/dots && mise run skills:restore && git status --short config/agents
```

  Expected: `skills:restore: every locked skill is installed`, and no changes under `config/agents`.

- [ ] **Step 6: Lint and commit.**

```bash
cd ~/Work/dots
git add config/mise/config.toml config/mise/conf.d/bootstrap.toml script/skills.csv
HK=0 git commit -m "feat(skills): Restore skills from the lock instead of the history

~/.agents is no longer tracked in dots-history; the bootstrap task runs
skills:restore. script/skills.csv is replaced by skills:audit.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 7: Save and push the history**, so other machines stop restoring `~/.agents` from it:

```bash
mise dot save 2>&1 | tail -1
GIT_TERMINAL_PROMPT=0 timeout 120 mise dot sync 2>&1 | tail -2
mise dot status 2>&1 | grep 'Last published'
```

  Expected: `Last published` shows today. If `mise dot sync` prints nothing and `Last published` is old, run
  it once more (a failed earlier push makes the next one wait).

---

### Task 8: Docs

**Files:**
- Modify: `README.md` (the "Testing `install` in a container" section)
- Modify: `assets/specs/mise-bootstrap/tasks-native.md` (the `## Findings` list, at the end)

- [ ] **Step 1: README.** In `README.md`, find this paragraph at the end of the container playbook:

```markdown
The container restores the history but never pushes to it. Mac changes reach it only after `mise dot save` and
`mise dot sync` on the Mac.
```

  and add right after it:

```markdown

The `devcontainer` profile skips agent skills. To test their restore, run `mise run -C ~/.local/share/dots
skills:restore` in the container's shell after step 4: it installs every skill in
`config/agents/skill-lock.json`, and a second run prints `every locked skill is installed`.

Agent skills come from `config/agents/skill-lock.json`, the `skills` CLI's own lock (both paths it reads link
there), so `skills add` and `skills update` show up as git diffs. `mise run skills:audit` lists installed skills
whose source is not confirmed in `config/agents/review.csv`.
```

- [ ] **Step 2: tasks-native.md.** Append this line to the end of `assets/specs/mise-bootstrap/tasks-native.md`:

```markdown
- Follow-up (2026-11-03): `~/.agents` is no longer tracked in `dots-history`. Skills restore from `config/agents/skill-lock.json` (`skills:restore`, run by `tasks.bootstrap`); commands live in `config/agents/commands`. See `assets/specs/agent-skills-lock/`.
```

- [ ] **Step 3: Lint and commit.**

```bash
cd ~/Work/dots
git add README.md assets/specs/mise-bootstrap/tasks-native.md
HK=0 git commit -m "docs: Describe the agent skills lock and its restore

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: Verify in a fresh container

- [ ] **Step 1: Push the branch** (the container clones it):

```bash
cd ~/Work/dots && git push -u origin feat/agent-skills-lock
```

- [ ] **Step 2: Prepare the secrets folder and the script** (the README playbook, steps 1–3, with this branch):

```bash
t="$(mktemp -d)"
(umask 077; grep '^AGE-SECRET-KEY' ~/.config/age/keys.txt > "$t/age"; gh auth token > "$t/gh")
git -C ~/Work/dots show feat/agent-skills-lock:install > "$t/install"
cat > "$t/run.sh" <<'SCRIPT'
set -u
export DOTS_AGE_KEY="$(cat /run/s/age)" GH_TOKEN="$(cat /run/s/gh)"
export DOTS_PROFILE=devcontainer DOTS_BRANCH=feat/agent-skills-lock
bash /run/s/install </dev/null > /tmp/install.log 2>&1; echo "install exit=$?"
export PATH="$HOME/.local/share/mise/shims:$PATH"
cd ~/.local/share/dots
mise run skills:restore > /tmp/restore.log 2>&1; echo "restore exit=$?"; tail -2 /tmp/restore.log
# The base image has no python3; count with Bun, which the task already installed.
mise x bun@1.3.14 -- bun -e 'const fs = require("fs"); const names = Object.keys(require("./config/agents/skill-lock.json").skills); console.log("locked", names.length, "installed", names.filter((n) => fs.existsSync(`${process.env.HOME}/.agents/skills/${n}`)).length)'
mise run skills:restore 2>&1 | tail -1
git status --short config/agents; echo "status-done"
ls -l ~/.agents/commands | head -1
SCRIPT
echo "$t"
```

- [ ] **Step 3: Run it.** It takes several minutes (about 60 repo clones).

```bash
docker run --rm -v "$t:/run/s:ro" -u vscode -w /home/vscode mcr.microsoft.com/devcontainers/base:ubuntu bash /run/s/run.sh
```

  Expected, in order:
  - `install exit=0`
  - `restore exit=0`, with the line `skills:restore: N missing, 0 source(s) failed`
  - `locked N installed N` (both numbers equal)
  - `skills:restore: every locked skill is installed`
  - nothing between the second restore and `status-done` (the committed lock is unchanged)
  - a link line for `~/.agents/commands`

  If any source fails, record the failing sources from `/tmp/restore.log` in the PR description; do not change
  the lock to hide them.

- [ ] **Step 4: Delete the secrets copy.**

```bash
rm -rf "$t"
```

---

### Task 10: Pull request

- [ ] **Step 1: Open it.**

```bash
cd ~/Work/dots
gh pr create --base main --head feat/agent-skills-lock --title "feat(skills): Restore agent skills from a versioned lock" --body "$(cat <<'EOF'
Stops syncing `~/.agents` (635 skill folders, about 58 MB) through `dots-history`. Design and plan:
`assets/specs/agent-skills-lock/`.

- `config/agents/skill-lock.json` is the `skills` CLI's global lock. Both paths the CLI reads link to it, so
  `skills add` and `skills update` show up as git diffs.
- `mise run skills:restore` installs every missing lock entry; `tasks.bootstrap` runs it (not in `devcontainer`).
  It refuses a lock of another format version, or one with fewer entries than `HEAD`.
- `mise run skills:audit` classifies installed skills by git tree id and writes `config/agents/review.csv`
  (sources not confirmed, or skills edited here).
- The owner's commands move to `config/agents/commands`.

Verified in a fresh `devcontainer` container: <fill in the Task 9 numbers: locked N, installed N, failures>.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

  Replace the `<fill in …>` text with the real numbers from Task 9 before running the command.

- [ ] **Step 2: Report** the PR link and the Task 4 counts to the owner.
