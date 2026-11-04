#!/usr/bin/env bun
// Audit and restore the global agent skills from config/agents/skill-lock.json.
// Usage: bun script/agent-skills.ts audit [--apply] | restore
import { cpSync, existsSync, lstatSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { dirname, join, relative, resolve } from "node:path";

/** The lock format this script understands; the skills CLI empties a lock with an older version on its next write. */
export const LOCK_VERSION = 3;
/** Below this share of locked skills matching their skillFolderHash, the hashing is wrong and the audit stops. */
export const MIN_MATCH_RATIO = 0.9;

export type LockEntry = {
  source: string;
  sourceType?: string;
  sourceUrl?: string;
  sourceBaseUrl?: string;
  skillPath?: string;
  skillFolderHash?: string;
};
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
  try {
    return Bun.spawnSync(cmd, { env, stdout: "inherit", stderr: "inherit" }).exitCode ?? 1;
  } catch (error) {
    // Bun throws when the executable is missing (e.g. `skills` not installed yet).
    console.error(`cannot run ${cmd[0]}: ${(error as Error).message}`);
    return 127;
  }
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
  // A wipe empties the lock; an uncommitted `skills remove` only shrinks it, so allow up to half.
  const count = Object.keys(skills ?? {}).length;
  if (count < committedCount / 2) {
    return `the lock has ${count} entries, less than half of the ${committedCount} committed at HEAD`;
  }
  return null;
}

/**
 * The given lock entries grouped by the source `skills add` takes, in lock order: sourceUrl, else source; for a
 * well-known entry, sourceBaseUrl (its sourceUrl is a versioned archive URL that `skills add` does not accept).
 */
export function groupBySource(lock: Lock, names: string[]): Map<string, string[]> {
  const groups = new Map<string, string[]>();
  for (const name of names) {
    const entry = lock.skills[name];
    if (!entry) continue;
    const source =
      entry.sourceType === "well-known" ? (entry.sourceBaseUrl ?? entry.source) : (entry.sourceUrl ?? entry.source);
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

const dotsState = () => join(process.env.XDG_STATE_HOME ?? join(homedir(), ".local/state"), "dots");

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

type SourceRun = { source: string; names: string[]; code: number; log: string };

/** One `skills add`, with its own state folder (the CLI writes its lock there) and its own log. */
async function addSource(source: string, names: string[], agents: string[], runDir: string, attempt = ""): Promise<SourceRun> {
  const slug = source.replace(/[^\w.-]+/g, "_");
  const state = join(runDir, "state", slug);
  mkdirSync(state, { recursive: true });
  const log = join(runDir, `${slug}${attempt}.log`);
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
  // A parallel run can lose a race the CLI does not guard against (a crash or a silent miss): retry those
  // sources once, one at a time, keeping the first attempt's log.
  if (jobs > 1) {
    for (const r of runs.filter((r) => r.names.some((n) => still.includes(n)))) {
      Object.assign(r, await addSource(r.source, r.names.filter((n) => still.includes(n)), agents, runDir, ".retry"));
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

if (import.meta.main) {
  const [command, ...args] = process.argv.slice(2);
  if (command === "audit") audit(args.includes("--apply"));
  else if (command === "restore") {
    // Both modes take the lock: restore() resets the shared run folder, so two runs must never overlap.
    const background = args.includes("--background");
    const pidFile = join(dotsState(), "skills-restore.pid");
    if (!acquireLock(pidFile)) {
      console.log(`skills:restore: already running (pid ${lockOwner(pidFile)})`);
      process.exit(background ? 0 : 1);
    }
    let outcome = { code: 1, result: "skills:restore crashed; see the log" };
    try {
      outcome = await restore();
    } finally {
      if (background) report(outcome.code, outcome.result);
      releaseLock(pidFile);
    }
    process.exit(outcome.code);
  }
  else {
    console.error("usage: bun script/agent-skills.ts audit [--apply] | restore [--background]");
    process.exit(2);
  }
}
