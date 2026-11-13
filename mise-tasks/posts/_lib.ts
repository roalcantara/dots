// Shared code for the posts:* file tasks (docs/posts/PLAYBOOK.md). Not a task: this file is not executable.
import { existsSync, readFileSync } from "node:fs";
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
  for (const line of m[1].split("\n")) {
    const item = line.match(/^\s+-\s+(.*)$/);
    if (item && listKey) {
      (fm[listKey] as string[]).push(String(scalar(item[1])));
      continue;
    }
    const kv = line.match(/^([A-Za-z_][\w-]*):\s*(.*)$/);
    if (!kv) continue;
    const [, key, value] = kv;
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
  const lines = m[1].split("\n");
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
  const inline = lines[at].split(/\*\*Gotchas:\*\*/)[1].split(/\s+·\s+|;\s+/).filter((s) => s.trim()).length;
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
