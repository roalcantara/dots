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
