// Shared code for the posts:* file tasks (docs/posts/PLAYBOOK.md). Not a task: this file is not executable.
import { existsSync, readFileSync } from "node:fs";
import { basename, join } from "node:path";
import { parseArgs } from "node:util";

export type FrontMatter = {
  title?: string;
  published?: boolean;
  description?: string;
  tags: string[];
  cover_image?: string;
  id?: number;
  [k: string]: unknown;
};
export type Finding = { level: "block" | "warn"; rule: string; message: string };

const FENCE = /^---\n([\s\S]*?)\n---\n?/;

const scalar = (raw: string): unknown => {
  const v = raw.trim().replace(/^(["'])(.*)\1$/, "$2");
  if (v === "true" || v === "false") return v === "true";
  if (/^\d+$/.test(v)) return Number(v);
  return v;
};
const list = (raw: string): string[] =>
  raw.replace(/^\[|\]$/g, "").split(",").map((s) => s.trim().replace(/^(["'])(.*)\1$/, "$2")).filter(Boolean);

export function parseFrontMatter(text: string): { fm: FrontMatter; body: string } {
  const m = text.match(FENCE);
  if (!m) return { fm: { tags: [] }, body: text };
  const fm: FrontMatter = { tags: [] };
  let listKey = "";
  for (const line of (m[1] ?? "").split("\n")) {
    const item = line.match(/^\s+-\s+(.*)$/);
    if (item && listKey) {
      (fm[listKey] as string[]).push(String(scalar(item[1] ?? "")));
      continue;
    }
    const kv = line.match(/^([A-Za-z_][\w-]*):\s*(.*)$/);
    if (!kv) continue;
    const key = kv[1] ?? "";
    const value = kv[2] ?? "";
    listKey = "";
    if (key === "tags") fm.tags = list(value);
    else if (value === "") {
      fm[key] = [];
      listKey = key;
    } else fm[key] = scalar(value);
  }
  return { fm, body: text.slice(m[0].length) };
}

export function visibleLength(text: string): number {
  return [...new Intl.Segmenter(undefined, { granularity: "grapheme" }).segment(text)].length;
}

// A post is a folder docs/posts/articles/<YYYY-MM-DD>-<slug>, the date being its (planned) publish date.
const POST = /^(\d{4})-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])-[a-z0-9]+(?:-[a-z0-9]+)*$/;
export function assertPost(post: string): string {
  if (!POST.test(post)) throw new Error(`not a post folder (YYYY-MM-DD-slug): "${post}"`);
  return post;
}

// The first paragraph after "## Post" in linkedin.md: what shows before "see more".
export function linkedinHook(text: string): string {
  const after = text.split(/^## Post\s*$/m)[1] ?? "";
  return after.trim().split(/\n\s*\n/)[0]?.trim() ?? "";
}

const gotchaCount = (body: string): number => {
  const lines = body.split("\n");
  const at = lines.findIndex((l) => /\*\*Gotchas:\*\*/.test(l));
  if (at < 0) return 0;
  const inline = (lines[at]?.split(/\*\*Gotchas:\*\*/)[1] ?? "").split(/\s+·\s+|;\s+/).filter((s) => s.trim()).length;
  let bullets = 0;
  for (const l of lines.slice(at + 1)) {
    if (!/^\s*[-*]\s+/.test(l)) break;
    bullets++;
  }
  return inline + bullets;
};

export function checkPost(dir: string, hypeWords: string[]): Finding[] {
  const out: Finding[] = [];
  const block = (rule: string, message: string) => out.push({ level: "block", rule, message });
  const warn = (rule: string, message: string) => out.push({ level: "warn", rule, message });

  const postPath = join(dir, "post.md");
  if (!existsSync(postPath)) {
    block("post-missing", `${postPath} does not exist`);
    return out;
  }
  const text = readFileSync(postPath, "utf8");
  const { fm, body } = parseFrontMatter(text);
  if (!fm.title) block("title-missing", "front matter has no title");
  if (!fm.description) block("description-missing", "front matter has no description");
  if (fm.tags.length > 4) block("tags-max-4", `dev.to takes at most 4 tags, found ${fm.tags.length}`);
  if (!/^\*\*RECIPE\*\*\s*$/m.test(body)) block("recipe-missing", "no **RECIPE** block");
  if (!/\*\*Use it when:\*\*/.test(body)) block("recipe-use-it-when", "the RECIPE has no **Use it when:** line");
  if (/\]\(\.?\/?raw\//.test(text)) block("raw-image", "an image points at raw/ (unblurred captures)");
  if (!existsSync(join(dir, "linkedin.md"))) block("linkedin-missing", "no linkedin.md next to post.md");

  const lower = body.toLowerCase();
  for (const word of hypeWords) {
    if (lower.includes(word.toLowerCase())) warn("hype-word", `hype word: "${word}"`);
  }
  const gotchas = gotchaCount(body);
  if (gotchas > 3) warn("gotchas-over-3", `${gotchas} gotchas; keep at most 3`);

  const li = join(dir, "linkedin.md");
  if (existsSync(li)) {
    const hook = linkedinHook(readFileSync(li, "utf8"));
    const n = visibleLength(hook);
    if (n > 210) warn("hook-over-210", `LinkedIn hook is ${n} characters; at most 210 show before "see more"`);
  }
  return out;
}

// ---- push -------------------------------------------------------------------------------------------------------

export const REPO = "roalcantara/dots";
const RAW = (ref: string, post: string) => `https://raw.githubusercontent.com/${REPO}/${ref}/docs/posts/articles/${post}`;
const relative = (url: string) => !/^[a-z][a-z0-9+.-]*:/i.test(url) && !url.startsWith("/") && !url.startsWith("#");
const resolve = (url: string, slug: string, ref: string) => `${RAW(ref, slug)}/${url.replace(/^\.\//, "")}`;

// Relative image links work in the repo; dev.to needs absolute ones, served from the pushed ref on GitHub.
export function rewriteImages(markdown: string, slug: string, ref: string): string {
  return markdown.replace(/(!\[[^\]]*\]\()([^)\s]+)(\))/g, (all, open, url, close) =>
    relative(url) ? `${open}${resolve(url, slug, ref)}${close}` : all,
  );
}

export type Article = {
  title: string;
  body_markdown: string;
  published?: boolean;
  tags: string[];
  description?: string;
  main_image?: string;
};

// A pull request always sends a draft; only the front matter of what reached main can publish. The tooling never
// takes a live article offline: for one that is already published, `published` is sent only to keep it true
// (unpublishing is done by hand on dev.to).
export function articlePayload(
  fm: FrontMatter,
  body: string,
  o: { slug: string; ref: string; draft: boolean; live?: boolean },
): { article: Article } {
  const article: Article = {
    title: fm.title ?? "",
    body_markdown: rewriteImages(body, o.slug, o.ref),
    tags: fm.tags,
  };
  const published = o.draft ? false : fm.published === true;
  if (published || !o.live) article.published = published;
  if (fm.description) article.description = fm.description;
  if (fm.cover_image) {
    article.main_image = relative(fm.cover_image) ? resolve(fm.cover_image, o.slug, o.ref) : fm.cover_image;
  }
  return { article };
}

export type GitState = { branch: string; dirty: boolean; ahead: number; upstream: boolean };

export function pushPreconditions(state: GitState, draft: boolean): Finding[] {
  const out: Finding[] = [];
  const block = (rule: string, message: string) => out.push({ level: "block", rule, message });
  if (state.dirty) block("dirty", "commit or stash your changes first: dev.to reads the images from GitHub");
  if (!state.upstream) block("no-upstream", `push ${state.branch} first: dev.to reads the images from GitHub`);
  else if (state.ahead > 0) block("unpushed", `${state.ahead} commit(s) not pushed yet`);
  if (!draft && state.branch !== "main") block("publish-from-main", "publish only from main (merge the PR)");
  return out;
}

// A pull request never touches a live article: its text would change in public before the merge. The merge's run
// updates it from main.
export function pushAction(o: { draft: boolean; live: boolean }): "skip" | "send" {
  return o.draft && o.live ? "skip" : "send";
}

// The recorded id (a devto.id comment) wins; otherwise an article of mine with the same title (a post published by
// hand, or one created by a run whose id isn't recorded yet), so a push updates it instead of creating a duplicate.
export function resolveArticleId(
  recorded: number | undefined,
  title: string | undefined,
  mine: { id: number; title: string }[],
): number | undefined {
  if (typeof recorded === "number") return recorded;
  return mine.find((a) => a.title === title)?.id;
}

// ---- numbers ----------------------------------------------------------------------------------------------------

export const PLATFORMS = ["devto", "linkedin", "reddit", "github"] as const;
export const METRICS = [
  "views", "reactions", "comments", "impressions", "engagement_rate", "reposts", "saves", "profile_views",
  "followers", "upvote_ratio", "removed", "referrer_linkedin", "referrer_reddit", "repo_views", "repo_uniques",
  "stars",
] as const;
export type StatRow = { date: string; slug: string; platform: string; metric: string; value: number; source: "api" | "manual" };

const num = (v: unknown): number | undefined => (typeof v === "number" && Number.isFinite(v) ? v : undefined);

export function rowsFromArticles(json: unknown, date: string, slugById: Map<number, string>): StatRow[] {
  if (!Array.isArray(json)) return [];
  const rows: StatRow[] = [];
  for (const a of json as Record<string, unknown>[]) {
    const slug = slugById.get(a.id as number);
    if (!slug) continue;
    for (const [metric, field] of [["views", "page_views_count"], ["reactions", "public_reactions_count"], ["comments", "comments_count"]] as const) {
      const value = num(a[field]);
      if (value !== undefined) rows.push({ date, slug, platform: "devto", metric, value, source: "api" });
    }
  }
  return rows;
}

// Visitors to one article from LinkedIn and Reddit; no rows when dev.to returns no referrer list.
export function rowsFromReferrers(json: unknown, date: string, slug: string): StatRow[] {
  const domains = (json as { domains?: unknown } | null)?.domains;
  if (!Array.isArray(domains)) return [];
  const sum = (re: RegExp) =>
    (domains as { domain?: unknown; count?: unknown }[])
      .filter((d) => typeof d.domain === "string" && re.test(d.domain))
      .reduce((n, d) => n + (num(d.count) ?? 0), 0);
  return [
    { date, slug, platform: "devto", metric: "referrer_linkedin", value: sum(/(^|\.)(linkedin\.com|lnkd\.in)$/), source: "api" },
    { date, slug, platform: "devto", metric: "referrer_reddit", value: sum(/(^|\.)reddit\.com$/), source: "api" },
  ];
}

export function rowsFromTraffic(json: unknown, date: string): StatRow[] {
  const t = (json ?? {}) as Record<string, unknown>;
  const rows: StatRow[] = [];
  for (const [metric, field] of [["repo_views", "count"], ["repo_uniques", "uniques"]] as const) {
    const value = num(t[field]);
    if (value !== undefined) rows.push({ date, slug: "-", platform: "github", metric, value, source: "api" });
  }
  return rows;
}

export function parseRecordArgs(argv: string[], date: string): StatRow[] {
  const [slug = "", platform = "", ...pairs] = argv;
  if (!slug) throw new Error("usage: record <slug|-> <platform> metric=value…");
  if (!(PLATFORMS as readonly string[]).includes(platform)) throw new Error(`unknown platform "${platform}" (${PLATFORMS.join(", ")})`);
  if (!pairs.length) throw new Error("give at least one metric=value");
  return pairs.map((pair) => {
    const [metric = "", raw] = pair.split("=");
    if (!(METRICS as readonly string[]).includes(metric)) throw new Error(`unknown metric "${metric}" (${METRICS.join(", ")})`);
    const value = Number(raw);
    if (raw === undefined || raw === "" || !Number.isFinite(value)) throw new Error(`not a number: ${pair}`);
    return { date, slug, platform, metric, value, source: "manual" as const };
  });
}

// ---- metadata in TODO.yaml ---------------------------------------------------------------------------------
// Each post has one task tagged `post` whose `position` is its folder; facts about it are comments on that task,
// one `key: value` each (schema: docs/posts/PLAYBOOK.md, "Metadata in TODO.yaml"). The todo CLI keeps comments and
// drops unknown fields, so nothing else is stored in the file.

export const KEYS = [
  "devto.id", "devto.url", "linkedin.url", "community.url", "stats", "gate", "vars", "log.keep", "log.change",
  "log.best-comment", "pick", "decision", "note",
] as const;
export type Comment = { id: string; text: string; task_id: string };
export type TodoTask = {
  id: string; status: string; description: string; due?: string | null; tags?: string[]; position?: string | null;
  comments?: string[];
};
export type Todo = { tasks: TodoTask[]; comments: Comment[] };
export type Post = {
  dir: string; taskId: string; label: string; status: string; due?: string; devtoId?: number;
  meta: Record<string, string[]>; stats: StatRow[]; invalid: string[];
};

export function parseComment(text: string): { key: string; value: string } | undefined {
  const m = text.match(/^([a-z][a-z.-]*):\s+(.+)$/s);
  if (!m || !(KEYS as readonly string[]).includes(m[1] ?? "")) return undefined;
  return { key: m[1] ?? "", value: (m[2] ?? "").trim() };
}

// "<YYYY-MM-DD> <platform> <metric>=<n> [<metric>=<n>…] (<api|manual>)"
export function parseStats(value: string, slug: string): StatRow[] | undefined {
  const m = value.match(/^(\d{4}-\d{2}-\d{2}) ([a-z]+) ((?:[a-z_]+=-?[\d.]+ ?)+)\((api|manual)\)$/);
  if (!m) return undefined;
  const [, date = "", platform = "", pairs = "", source = "api"] = m;
  if (!(PLATFORMS as readonly string[]).includes(platform)) return undefined;
  const rows: StatRow[] = [];
  for (const pair of pairs.trim().split(/\s+/)) {
    const [metric = "", raw = ""] = pair.split("=");
    const value = Number(raw);
    if (!(METRICS as readonly string[]).includes(metric) || !Number.isFinite(value)) return undefined;
    rows.push({ date, slug, platform, metric, value, source: source as "api" | "manual" });
  }
  return rows;
}

export function formatStats(rows: StatRow[]): string[] {
  const groups = new Map<string, string[]>();
  for (const r of rows) {
    const k = `${r.date} ${r.platform}\u0000${r.source}`;
    groups.set(k, [...(groups.get(k) ?? []), `${r.metric}=${r.value}`]);
  }
  return [...groups].map(([k, pairs]) => {
    const [head, source] = k.split("\u0000");
    return `${head} ${pairs.join(" ")} (${source})`;
  });
}

const day = (v: unknown): string | undefined => (v ? String(v instanceof Date ? v.toISOString() : v).slice(0, 10) : undefined);

function metaOf(todo: Todo, task: TodoTask, slug: string) {
  const byId = new Map(todo.comments.map((c) => [c.id, c]));
  const meta: Record<string, string[]> = {};
  const stats: StatRow[] = [];
  const invalid: string[] = [];
  for (const id of task.comments ?? []) {
    const text = byId.get(id)?.text ?? "";
    const kv = parseComment(text);
    const rows = kv?.key === "stats" ? parseStats(kv.value, slug) : undefined;
    if (!kv || (kv.key === "stats" && !rows)) invalid.push(text);
    else if (rows) stats.push(...rows);
    else (meta[kv.key] ??= []).push(kv.value);
  }
  return { meta, stats, invalid };
}

export function postsFromTodo(todo: Todo): Post[] {
  return todo.tasks
    .filter((t) => t.tags?.includes("post") && t.position)
    .map((t) => {
      const dir = basename(String(t.position));
      const { meta, stats, invalid } = metaOf(todo, t, dir);
      const id = Number(meta["devto.id"]?.at(-1));
      return {
        dir, taskId: t.id, label: t.description, status: t.status, due: day(t.due),
        devtoId: Number.isInteger(id) && id > 0 ? id : undefined, meta, stats, invalid,
      };
    });
}

export function seriesFromTodo(todo: Todo): { taskId?: string; stats: StatRow[]; invalid: string[] } {
  const t = todo.tasks.find((x) => x.tags?.includes("series"));
  return t ? { taskId: t.id, ...metaOf(todo, t, "-") } : { stats: [], invalid: [] };
}

// ---- shell side (used by the task files; not unit-tested) -----------------------------------------------------

export const ROOT = join(import.meta.dir, "../..");
export const SERIES = join(ROOT, "docs/posts");
export const POSTS = join(SERIES, "articles");

const run = (cmd: string[]): { ok: boolean; out: string } => {
  const p = Bun.spawnSync(cmd, { cwd: ROOT, stdout: "pipe", stderr: "pipe" });
  return { ok: p.exitCode === 0, out: p.stdout.toString().trim() };
};
const git = (...args: string[]) => run(["git", "-c", "filter.sops.clean=cat", "-c", "filter.sops.smudge=cat", ...args]);

export function gitState(): GitState {
  const upstream = git("rev-parse", "--abbrev-ref", "@{u}").ok;
  return {
    branch: git("branch", "--show-current").out,
    dirty: git("status", "--porcelain").out !== "",
    upstream,
    ahead: upstream ? Number(git("rev-list", "--count", "@{u}..HEAD").out || 0) : 0,
  };
}

// DEVTO_TOKEN from the environment (CI: the repo secret), else fnox (fnox.toml: gopass tokens/dev.to). Never printed.
export function token(): string {
  const env = process.env.DEVTO_TOKEN?.trim();
  if (env) return env;
  const fx = run(["fnox", "get", "DEVTO_TOKEN"]);
  if (fx.ok && fx.out) return fx.out;
  throw new Error("DEVTO_TOKEN is not set and `fnox get DEVTO_TOKEN` resolved nothing (see fnox.toml)");
}

// argv of posts:push (mise passes the arguments its #USAGE spec validated; CI runs the same command line).
export function postOptions(argv: string[]): { post: string; ref: string | undefined; draft: boolean } {
  const { values, positionals } = parseArgs({
    args: argv,
    options: { ref: { type: "string" }, draft: { type: "boolean", default: false } },
    allowPositionals: true,
    strict: true,
  });
  const post = positionals[0];
  if (!post || positionals.length > 1) throw new Error("usage: push <post> [--ref <ref>] [--draft]");
  return { post, ref: values.ref, draft: values.draft ?? false };
}

export async function devto(path: string, init: { method?: string; body?: unknown } = {}): Promise<unknown> {
  const res = await fetch(`https://dev.to/api${path}`, {
    method: init.method ?? "GET",
    headers: { "api-key": token(), accept: "application/vnd.forem.api-v1+json", "content-type": "application/json" },
    body: init.body === undefined ? undefined : JSON.stringify(init.body),
  });
  if (!res.ok) throw new Error(`dev.to ${init.method ?? "GET"} ${path}: ${res.status} ${(await res.text()).slice(0, 300)}`);
  return res.json();
}

export const myArticles = async (): Promise<Record<string, unknown>[]> =>
  (await devto("/articles/me/all?per_page=1000")) as Record<string, unknown>[];

export const today = (): string => new Date().toLocaleDateString("sv-SE");

export const TODO = join(ROOT, "docs/posts/TODO.yaml");
export const readTodo = (): Todo => Bun.YAML.parse(readFileSync(TODO, "utf8")) as Todo;

// Append a comment through the todo CLI (the file's owner), never by editing TODO.yaml.
export function addComment(taskId: string, text: string): void {
  const p = Bun.spawnSync(["mise", "run", "-q", "posts:todo", "--", "add", "--comment", text, "--task-id", taskId], {
    cwd: ROOT, stdout: "pipe", stderr: "pipe",
  });
  if (p.exitCode !== 0) throw new Error(`todo add --comment failed: ${p.stderr.toString().trim()}`);
}
