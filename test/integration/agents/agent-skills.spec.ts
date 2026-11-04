#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  DEFAULT_JOBS,
  LOCK_VERSION,
  acquireLock,
  addCommand,
  findCandidates,
  groupBySource,
  jobsFromEnv,
  lockOwner,
  lockProblem,
  matchCandidates,
  missingSkills,
  notifyCommand,
  parseSkillsCsv,
  releaseLock,
  reviewCsv,
  runPool,
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

  it("accepts a lock a little smaller than committed (an uncommitted skills remove)", () => {
    expect(lockProblem(lock, 4)).toBeNull();
  });

  it("rejects a lock with less than half the committed entries (a wipe)", () => {
    expect(lockProblem(lock, 7)).toContain("less than half of the 7 committed");
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

describe("groupBySource for well-known entries", () => {
  it("uses sourceBaseUrl, not the archive sourceUrl", () => {
    const wk: Lock = {
      version: LOCK_VERSION,
      skills: {
        triage: {
          source: "clawhub.ai",
          sourceType: "well-known",
          sourceUrl: "https://example.site/api/v1/agent-skills/x/triage/archive?version=1.0.0",
          sourceBaseUrl: "https://clawhub.ai/x/skills/triage",
        },
      },
    };
    expect([...groupBySource(wk, ["triage"]).keys()]).toEqual(["https://clawhub.ai/x/skills/triage"]);
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
});
