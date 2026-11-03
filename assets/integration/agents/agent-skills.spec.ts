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
