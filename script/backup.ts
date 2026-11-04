#!/usr/bin/env bun
// Manifest-driven restic backups and the reinstall audit.
// Usage: docs/REINSTALL.md.
import { existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from "node:fs";
import { hostname, tmpdir } from "node:os";
import { join } from "node:path";

export type Exclude = { pattern: string; why: string };
export type Manifest = {
  repository: { root: string; path: string; password_command?: string };
  backup: { paths: string[]; tags: string[]; exclude_caches: boolean };
  retention: { daily: number; weekly: number; monthly: number };
  exclude: Exclude[];
};
export type Ctx = { home: string; host: string; root: string };
export type RepoState = { name: string; dirty: number; unpushed: number; stashes: number; remotes: number };
export type Facts = {
  date: string; host: string; user: string; macos: string; filevault: string; timeMachine: string;
  repos: RepoState[]; nonGit: { name: string; size: string }[]; brewCheck: string; untrustedTaps: string[];
  appsNotCasks: string[]; largest: { path: string; size: string }[]; notes: string[];
};
export type RestoreOpts = { snapshot: string; fromHome: string; target: string; includes: string[]; dryRun: boolean };
export type RestoreFlags = { includes: string[]; snapshot: string; fromHome?: string; target?: string; dryRun: boolean };

type Table = Record<string, unknown>;
const table = (v: unknown): Table => (v && typeof v === "object" && !Array.isArray(v) ? (v as Table) : {});
const strings = (v: unknown): string[] => (Array.isArray(v) ? v.filter((x): x is string => typeof x === "string") : []);
const int = (v: unknown): number => (typeof v === "number" && Number.isInteger(v) && v >= 0 ? v : 0);

export function parseManifest(text: string): Manifest {
  const raw = table(Bun.TOML.parse(text));
  const repo = table(raw.repository), backup = table(raw.backup), retention = table(raw.retention);
  const need = (ok: boolean, key: string) => {
    if (!ok) throw new Error(`manifest: missing or invalid ${key}`);
  };
  need(typeof repo.path === "string" && repo.path !== "", "repository.path");
  need(strings(backup.paths).length > 0, "backup.paths");
  const exclude = (Array.isArray(raw.exclude) ? raw.exclude : []).map((e, i) => {
    const t = table(e);
    need(typeof t.pattern === "string" && t.pattern !== "", `exclude[${i}].pattern`);
    need(typeof t.why === "string" && t.why !== "", `exclude[${i}].why`);
    return { pattern: t.pattern as string, why: t.why as string };
  });
  return {
    repository: {
      root: typeof repo.root === "string" ? repo.root : "/Volumes/backups",
      path: repo.path as string,
      password_command: typeof repo.password_command === "string" ? repo.password_command : undefined,
    },
    backup: { paths: strings(backup.paths), tags: strings(backup.tags), exclude_caches: backup.exclude_caches === true },
    retention: { daily: int(retention.daily), weekly: int(retention.weekly), monthly: int(retention.monthly) },
    exclude,
  };
}

export function expand(s: string, ctx: Pick<Ctx, "home" | "host">): string {
  const homed = s === "~" ? ctx.home : s.startsWith("~/") ? ctx.home + s.slice(1) : s;
  return homed.replaceAll("{host}", ctx.host);
}

export const repoPath = (m: Manifest, ctx: Ctx): string => join(ctx.root, expand(m.repository.path, ctx));

export const excludeLines = (m: Manifest, ctx: Ctx): string =>
  m.exclude.map((e) => `${expand(e.pattern, ctx)}\n`).join("");

const PASSWORD_VARS = ["RESTIC_PASSWORD", "RESTIC_PASSWORD_FILE", "RESTIC_PASSWORD_COMMAND"];

// `in`, not truthiness: RESTIC_PASSWORD_COMMAND= (empty) means "prompt me", used when gopass is not restored yet.
export function passwordEnv(m: Manifest, env: Record<string, string | undefined>): Record<string, string> {
  if (PASSWORD_VARS.some((v) => v in env)) return {};
  return m.repository.password_command ? { RESTIC_PASSWORD_COMMAND: m.repository.password_command } : {};
}

export const backupArgs = (m: Manifest, ctx: Ctx, excludeFile: string): string[] => [
  "backup",
  ...m.backup.paths.map((p) => expand(p, ctx)),
  "--exclude-file", excludeFile,
  ...(m.backup.exclude_caches ? ["--exclude-caches"] : []),
  ...m.backup.tags.flatMap((t) => ["--tag", expand(t, ctx)]),
];

export function forgetArgs(m: Manifest): string[] {
  const keep = (["daily", "weekly", "monthly"] as const)
    .filter((k) => m.retention[k] > 0)
    .flatMap((k) => [`--keep-${k}`, String(m.retention[k])]);
  if (keep.length === 0) throw new Error("retention: every keep is 0; refusing to forget");
  return ["forget", ...keep, "--prune"];
}

export const restoreArgs = (o: RestoreOpts): string[] => [
  "restore", `${o.snapshot}:${o.fromHome}`, "--target", o.target,
  ...o.includes.flatMap((p) => ["--include", `/${p.replace(/^~\//, "").replace(/^\/+/, "")}`]),
  ...(o.dryRun ? ["--dry-run", "--verbose"] : []),
];

export function classifyRepo(s: RepoState): string[] {
  const risks: string[] = [];
  if (s.remotes === 0) risks.push("no remote");
  if (s.dirty) risks.push(`${s.dirty} uncommitted`);
  if (s.unpushed) risks.push(`${s.unpushed} unpushed`);
  if (s.stashes) risks.push(`${s.stashes} stashed`);
  return risks;
}

export function appsNotFromCasks(apps: string[], caskJson: string): string[] {
  const provided = new Set<string>();
  for (const cask of strictArray(table(safeJson(caskJson)).casks)) {
    for (const artifact of strictArray(table(cask).artifacts)) {
      for (const app of strictArray(table(artifact).app)) {
        if (typeof app === "string") provided.add(app);
        else if (typeof table(app).target === "string") provided.add(table(app).target as string);
      }
    }
  }
  return apps.filter((a) => !provided.has(a));
}
function strictArray(v: unknown): unknown[] {
  return Array.isArray(v) ? v : [];
}
function safeJson(s: string): unknown {
  try {
    return JSON.parse(s);
  } catch {
    return {};
  }
}

const CHECKLIST = [
  "Age key and restic password are in the password manager (they are the only secrets dots cannot restore)",
  "2FA recovery codes and app licence keys are in the password manager",
  "Every repository above is pushed, or its risk is accepted (the restic snapshot holds it)",
  "Browser sync is on, or bookmarks and profiles are exported",
  "`mise run backup` finished, `restic check` passed, and a test restore worked",
];

export function renderManifest(f: Facts): string {
  const risky = f.repos.map((r) => [r.name, classifyRepo(r)] as const).filter(([, r]) => r.length);
  const lines = [
    `# Reinstall audit: ${f.host}, ${f.date}`, "",
    `macOS ${f.macos}, user \`${f.user}\`. Restore on the new machine with:`, "",
    "```sh", `DOTS_BACKUP_HOST=${f.host} mise run backup:restore -- --from-home /Users/${f.user} --include Work --dry-run`, "```", "",
    "## Risks", "",
    ...risky.map(([n, r]) => `- ${n}: ${r.join(", ")}`),
    ...f.nonGit.map((d) => `- ~/Work/${d.name}: not a git repository (${d.size}); only the snapshot holds it`),
    ...f.untrustedTaps.map((t) => `- untrusted tap ${t}: run \`brew trust ${t}\` after the reinstall`),
    ...(f.appsNotCasks.length ? [`- ${f.appsNotCasks.length} app(s) not in the Brewfile: see apps.txt`] : []),
    ...(f.filevault.includes("Off") ? ["- FileVault is off: turn it on in Setup Assistant"] : []),
    ...(risky.length || f.nonGit.length ? [] : ["- none in ~/Work"]),
    "", "## Repositories", "", "| Repo | Risks |", "| --- | --- |",
    ...f.repos.map((r) => `| ${r.name} | ${classifyRepo(r).join(", ") || "clean"} |`),
    "", "## System", "", `- FileVault: ${f.filevault}`, `- Time Machine: ${f.timeMachine}`,
    "", "## Packages", "", "```text", f.brewCheck.trim(), "```",
    "", "## Apps not provided by a cask", "", ...(f.appsNotCasks.length ? f.appsNotCasks.map((a) => `- ${a}`) : ["- none"]),
    "", "## Largest folders in ~", "", ...f.largest.map((l) => `- ${l.size}\t${l.path}`),
    ...(f.notes.length ? ["", "## Notes", "", ...f.notes.map((n) => `- ${n}`)] : []),
    "", "## Before you wipe", "", ...CHECKLIST.map((c) => `- [ ] ${c}`), "",
  ];
  return lines.join("\n");
}

// ---------- side effects ----------

type Run = { code: number; out: string };
function run(cmd: string[], opts: { cwd?: string; env?: Record<string, string>; timeoutMs?: number } = {}): Run {
  if (!Bun.which(cmd[0] as string)) return { code: 127, out: "" };
  const p = Bun.spawnSync(cmd, {
    cwd: opts.cwd, env: { ...process.env, ...opts.env }, timeout: opts.timeoutMs ?? 120_000, stdout: "pipe", stderr: "pipe",
  });
  return { code: p.exitCode ?? 1, out: `${p.stdout.toString()}${p.stderr.toString()}` };
}
const count = (s: string): number => s.split("\n").filter((l) => l.trim()).length;

function die(msg: string, code = 1): never {
  console.error(`backup: ${msg}`);
  process.exit(code);
}

function context(m: Manifest): Ctx {
  const home = process.env.HOME ?? die("HOME is not set");
  const scutil = process.platform === "darwin" ? run(["scutil", "--get", "LocalHostName"]) : { code: 1, out: "" };
  const host = process.env.DOTS_BACKUP_HOST || (scutil.code === 0 ? scutil.out.trim() : hostname().split(".")[0] ?? "host");
  return { home, host, root: process.env.DOTS_BACKUP_ROOT || m.repository.root };
}

function loadManifest(): Manifest {
  const file = process.env.DOTS_BACKUP_MANIFEST || join(import.meta.dir, "../config/restic/backup.toml");
  if (!existsSync(file)) die(`manifest not found: ${file}`);
  if (Bun.which("taplo")) {
    const check = run(["taplo", "check", file]);
    if (check.code !== 0) die(`manifest fails its schema (taplo check ${file}):\n${check.out}`);
  }
  try {
    return parseManifest(readFileSync(file, "utf8"));
  } catch (e) {
    return die((e as Error).message);
  }
}

function requireRoot(root: string): void {
  if (!existsSync(root) || !statSync(root).isDirectory()) die(`backup root not found: ${root} (mount the drive or set DOTS_BACKUP_ROOT)`);
}

function restic(args: string[], repo: string, env: Record<string, string>): number {
  if (!Bun.which("restic")) die("restic not found: brew install restic");
  const p = Bun.spawnSync(["restic", "--repo", repo, ...args], { env: { ...process.env, ...env }, stdio: ["inherit", "inherit", "inherit"] });
  return p.exitCode ?? 1;
}

function requireRepo(repo: string): void {
  if (!existsSync(join(repo, "config"))) die(`no repository at ${repo}: run mise run backup:init (or set DOTS_BACKUP_HOST to the old host)`);
}

const DRIVE_README = `# Backups

| Folder | Holds |
| --- | --- |
| machines/<host>/restic | restic repository (encrypted); password: gopass backups/restic, and the password manager |
| machines/<host>/exports/YYYY-MM-DD | reinstall audits (MANIFEST.md) and one-off copies (legacy/) |
| media | files that are not machine backups |
| archive | retired machines, moved whole from machines/ |

Restore (after the dots install): DOTS_BACKUP_HOST=<host> mise run backup:restore -- --include Work --dry-run
Without dots: restic --repo machines/<host>/restic restore latest:/Users/<user> --target ~ --include /Work
Guide: https://github.com/roalcantara/dots/blob/main/docs/REINSTALL.md
`;

function init(m: Manifest, ctx: Ctx): void {
  requireRoot(ctx.root);
  const repo = repoPath(m, ctx);
  if (existsSync(join(repo, "config"))) {
    console.log(`backup: ${repo} is already a repository`);
    return;
  }
  const env = passwordEnv(m, process.env);
  if (env.RESTIC_PASSWORD_COMMAND && run(["sh", "-c", env.RESTIC_PASSWORD_COMMAND]).code !== 0) {
    die(`password command failed: ${env.RESTIC_PASSWORD_COMMAND}\ncreate it: gopass generate backups/restic 32 (then copy it to your password manager)`);
  }
  mkdirSync(repo, { recursive: true });
  const code = restic(["init"], repo, env);
  if (code !== 0) process.exit(code);
  mkdirSync(join(ctx.root, "machines", ctx.host, "exports"), { recursive: true });
  const readme = join(ctx.root, "README.md");
  if (!existsSync(readme)) writeFileSync(readme, DRIVE_README);
}

function backup(m: Manifest, ctx: Ctx): void {
  requireRoot(ctx.root);
  const repo = repoPath(m, ctx);
  requireRepo(repo);
  const env = passwordEnv(m, process.env);
  const dir = mkdtempSync(join(tmpdir(), "dots-backup-"));
  const excludeFile = join(dir, "excludes.txt");
  writeFileSync(excludeFile, excludeLines(m, ctx));
  try {
    const code = restic(backupArgs(m, ctx, excludeFile), repo, env);
    if (code === 3) console.error("backup: some files could not be read (exit 3). Grant your terminal Full Disk Access, or exclude them.");
    else if (code !== 0) process.exit(code);
    const check = restic(["check"], repo, env);
    process.exit(check || code);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

export function parseRestoreFlags(args: string[]): RestoreFlags {
  const o = { includes: [] as string[], snapshot: "latest", fromHome: undefined as string | undefined, target: undefined as string | undefined, dryRun: false };
  for (let i = 0; i < args.length; i++) {
    const a = args[i], v = args[i + 1];
    if (a === "--dry-run") o.dryRun = true;
    else if (a === "--include" && v) (o.includes.push(v), i++);
    else if (a === "--snapshot" && v) ((o.snapshot = v), i++);
    else if (a === "--from-home" && v) ((o.fromHome = v), i++);
    else if (a === "--target" && v) ((o.target = v), i++);
    else throw new Error(`unknown or incomplete flag: ${a}`);
  }
  return o;
}

function snapshotHome(repo: string, snapshot: string, env: Record<string, string>): string | undefined {
  const p = Bun.spawnSync(["restic", "--repo", repo, "snapshots", "--json", snapshot], { env: { ...process.env, ...env }, stdout: "pipe", stderr: "inherit" });
  const list = strictArray(safeJson(p.stdout.toString()));
  // A snapshot of the manifest default (paths = ["~"]) has exactly one path: the old home.
  const paths = strings(table(list[list.length - 1]).paths);
  return paths.length === 1 ? paths[0] : undefined;
}

function restore(m: Manifest, ctx: Ctx, args: string[]): void {
  let flags: RestoreFlags;
  try {
    flags = parseRestoreFlags(args);
  } catch (e) {
    return die((e as Error).message, 2);
  }
  if (flags.includes.length === 0) die("restore needs at least one --include <path relative to the old home>, e.g. --include Work", 2);
  requireRoot(ctx.root);
  const repo = repoPath(m, ctx);
  requireRepo(repo);
  const env = passwordEnv(m, process.env);
  const fromHome = flags.fromHome ?? snapshotHome(repo, flags.snapshot, env) ?? die("cannot tell the snapshot's home folder: pass --from-home /Users/<old user>", 2);
  process.exit(restic(restoreArgs({ snapshot: flags.snapshot, fromHome, target: flags.target ?? ctx.home, includes: flags.includes, dryRun: flags.dryRun }), repo, env));
}

function forget(m: Manifest, ctx: Ctx): void {
  requireRoot(ctx.root);
  const repo = repoPath(m, ctx);
  requireRepo(repo);
  let args: string[];
  try {
    args = forgetArgs(m);
  } catch (e) {
    return die((e as Error).message);
  }
  process.exit(restic(args, repo, passwordEnv(m, process.env)));
}

function collectFacts(ctx: Ctx, date: string): { facts: Facts; files: Record<string, string> } {
  const notes: string[] = [];
  const work = join(ctx.home, "Work");
  const repos: RepoState[] = [];
  const nonGit: { name: string; size: string }[] = [];
  const size = (p: string) => (run(["du", "-sh", p], { timeoutMs: 60_000 }).out.split("\t")[0] || "?").trim();
  if (existsSync(work)) {
    for (const name of readdirSync(work).sort()) {
      const dir = join(work, name);
      if (!statSync(dir).isDirectory()) continue;
      if (run(["git", "-C", dir, "rev-parse", "--git-dir"]).code !== 0) {
        nonGit.push({ name, size: size(dir) });
        continue;
      }
      const git = (...a: string[]) => run(["git", "-C", dir, ...a]).out;
      // A linked worktree has a .git file; it shares branches and stashes with its main checkout.
      const worktree = statSync(join(dir, ".git"), { throwIfNoEntry: false })?.isFile() === true;
      repos.push({
        name: worktree ? `${name} (worktree)` : name, dirty: count(git("status", "--porcelain")), unpushed: count(git("log", "--branches", "--not", "--remotes", "--oneline")),
        stashes: count(git("stash", "list")), remotes: count(git("remote")),
      });
    }
  } else notes.push(`${work} not found; repositories not audited`);

  const brewfile = join(import.meta.dir, "../config/homebrew/Brewfile");
  const brewEnv = { HOMEBREW_NO_AUTO_UPDATE: "1" };
  const has = (t: string) => {
    if (Bun.which(t)) return true;
    notes.push(`${t} not installed`);
    return false;
  };
  const files: Record<string, string> = {};
  let brewCheck = "brew not installed", caskJson = "{}";
  const untrustedTaps: string[] = [];
  if (has("brew")) {
    brewCheck = run(["brew", "bundle", "check", "--verbose", "--file", brewfile], { env: brewEnv }).out;
    const cleanup = run(["brew", "bundle", "cleanup", "--file", brewfile], { env: brewEnv }).out;
    for (const t of cleanup.matchAll(/untrusted tap (\S+?)\.?$/gm)) untrustedTaps.push(t[1] as string);
    files["brew-bundle-check.txt"] = brewCheck;
    files["brew-bundle-cleanup.txt"] = cleanup;
    files["brew-leaves.txt"] = run(["brew", "leaves"], { env: brewEnv }).out;
    files["brew-casks.txt"] = run(["brew", "list", "--cask"], { env: brewEnv }).out;
    caskJson = run(["brew", "info", "--cask", "--installed", "--json=v2"], { env: brewEnv }).out;
  }
  const apps = existsSync("/Applications") ? readdirSync("/Applications").filter((a) => a.endsWith(".app")).sort() : [];
  files["apps.txt"] = `${apps.join("\n")}\n`;
  if (has("mas")) files["mas.txt"] = run(["mas", "list"]).out;

  const largest = readdirSync(ctx.home)
    .filter((n) => n !== "Library" && statSync(join(ctx.home, n), { throwIfNoEntry: false })?.isDirectory())
    .map((n) => ({ path: n, kb: Number(run(["du", "-sk", join(ctx.home, n)], { timeoutMs: 60_000 }).out.split("\t")[0]) || 0 }))
    .sort((a, b) => b.kb - a.kb)
    .slice(0, 15)
    .map(({ path, kb }) => ({ path, size: kb >= 1048576 ? `${(kb / 1048576).toFixed(1)}G` : `${Math.round(kb / 1024)}M` }));

  const tsv = ["repo\tdirty\tunpushed\tstashes\tremotes", ...repos.map((r) => `${r.name}\t${r.dirty}\t${r.unpushed}\t${r.stashes}\t${r.remotes}`)];
  files["repos.tsv"] = `${tsv.join("\n")}\n`;
  const facts: Facts = {
    date, host: ctx.host, user: ctx.home.split("/").pop() ?? "", macos: run(["sw_vers", "-productVersion"]).out.trim() || process.platform,
    filevault: run(["fdesetup", "status"]).out.trim() || "unknown", timeMachine: run(["tmutil", "destinationinfo"]).out.trim().split("\n")[0] || "unknown",
    repos, nonGit, brewCheck, untrustedTaps, appsNotCasks: appsNotFromCasks(apps, caskJson), largest, notes,
  };
  return { facts, files };
}

function audit(m: Manifest, ctx: Ctx, args: string[]): void {
  const date = new Date().toISOString().slice(0, 10);
  const toStdout = args.includes("--stdout");
  if (!toStdout) requireRoot(ctx.root);
  const { facts, files } = collectFacts(ctx, date);
  const md = renderManifest(facts);
  if (toStdout) {
    console.log(md);
    return;
  }
  const dir = join(ctx.root, "machines", ctx.host, "exports", date);
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, "MANIFEST.md"), md);
  for (const [name, body] of Object.entries(files)) writeFileSync(join(dir, name), body);
  const risks = md.split("## Repositories")[0]?.split("\n").filter((l) => l.startsWith("- ") && !l.includes("none in")).length ?? 0;
  console.log(`backup: audit written to ${dir} (${risks} risk(s); open MANIFEST.md)`);
}

const USAGE = "usage: bun script/backup.ts audit [--stdout] | init | backup | snapshots | restore --include P… [--snapshot ID] [--from-home DIR] [--target DIR] [--dry-run] | forget";

if (import.meta.main) {
  const [command, ...args] = process.argv.slice(2);
  if (!command || command === "-h" || command === "--help") die(USAGE, command ? 0 : 2);
  const m = loadManifest();
  const ctx = context(m);
  switch (command) {
    case "audit": audit(m, ctx, args); break;
    case "init": init(m, ctx); break;
    case "backup": backup(m, ctx); break;
    case "snapshots": requireRoot(ctx.root); requireRepo(repoPath(m, ctx)); process.exit(restic(["snapshots"], repoPath(m, ctx), passwordEnv(m, process.env)));
    case "restore": restore(m, ctx, args); break;
    case "forget": forget(m, ctx); break;
    default: die(USAGE, 2);
  }
}
