// Shared code for the posts:* file tasks (docs/posts/PLAYBOOK.md). Not a task: this file is not executable.
import { appendFileSync, existsSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

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
const NOT_POSTS = new Set(["templates", "tools", "prompts"]);

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

export function setFrontMatterId(text: string, id: number): string {
  const m = text.match(FENCE);
  if (!m) throw new Error("no front matter");
  const lines = (m[1] ?? "").split("\n");
  const at = lines.findIndex((l) => /^id:/.test(l));
  if (at >= 0) lines[at] = `id: ${id}`;
  else {
    const title = lines.findIndex((l) => /^title:/.test(l));
    lines.splice(title + 1, 0, `id: ${id}`);
  }
  return `---\n${lines.join("\n")}\n---\n${text.slice(m[0].length)}`;
}

export function visibleLength(text: string): number {
  return [...new Intl.Segmenter(undefined, { granularity: "grapheme" }).segment(text)].length;
}

export function assertSlug(slug: string): string {
  if (!slug || NOT_POSTS.has(slug) || slug.includes("/") || slug.includes("..")) {
    throw new Error(`not a post folder: "${slug}"`);
  }
  return slug;
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
const RAW = (ref: string, slug: string) => `https://raw.githubusercontent.com/${REPO}/${ref}/docs/posts/${slug}`;
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

// The recorded id wins; otherwise an article of mine with the same title (a post published by hand, or a merge that
// beat the PR job), so the push updates it instead of creating a duplicate.
export function resolveArticleId(fm: FrontMatter, mine: { id: number; title: string }[]): number | undefined {
  if (typeof fm.id === "number") return fm.id;
  return mine.find((a) => a.title === fm.title)?.id;
}

// ---- numbers ----------------------------------------------------------------------------------------------------

export const PLATFORMS = ["devto", "linkedin", "reddit", "github"] as const;
export const METRICS = [
  "views", "reactions", "comments", "impressions", "engagement_rate", "reposts", "saves", "profile_views",
  "followers", "upvote_ratio", "removed", "referrer_linkedin", "referrer_reddit", "repo_views", "repo_uniques",
  "stars",
] as const;
export type StatRow = { date: string; slug: string; platform: string; metric: string; value: number; source: "api" | "manual" };
const HEADER = "date,slug,platform,metric,value,source\n";

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

export function appendRows(csvPath: string, rows: StatRow[]): void {
  if (!existsSync(csvPath)) writeFileSync(csvPath, HEADER);
  const lines = rows.map((r) => `${r.date},${r.slug},${r.platform},${r.metric},${r.value},${r.source}\n`).join("");
  if (lines) appendFileSync(csvPath, lines);
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

// ---- shell side (used by the task files; not unit-tested) -----------------------------------------------------

export const ROOT = join(import.meta.dir, "../..");
export const POSTS = join(ROOT, "docs/posts");

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

// DEVTO_TOKEN from the environment (CI: the repo secret), else gopass. Never printed.
export function token(): string {
  const env = process.env.DEVTO_TOKEN?.trim();
  if (env) return env;
  const gp = run(["gopass", "show", "-o", "tokens/dev.to"]);
  if (gp.ok && gp.out) return gp.out;
  throw new Error("DEVTO_TOKEN is not set and gopass has no tokens/dev.to");
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
