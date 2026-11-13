#!/usr/bin/env bun
//MISE description="Push a post to dev.to: a draft, or published when its front matter says so and it is on main"
//USAGE arg "<slug>" help="Post folder under docs/posts"
//USAGE flag "--ref <ref>" help="Git ref the images are served from (default: the current branch)"
//USAGE flag "--draft" help="Always send a draft, whatever the front matter says (pull requests)"
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import {
  articlePayload, assertSlug, checkPost, devto, gitState, myArticles, parseFrontMatter, POSTS, pushPreconditions,
  resolveArticleId, setFrontMatterId,
} from "./_lib";

const argv = process.argv.slice(2);
const flag = (name: string) => argv.includes(`--${name}`);
const opt = (name: string) => { const i = argv.indexOf(`--${name}`); return i >= 0 ? argv[i + 1] : undefined; };

const slug = assertSlug(process.env.usage_slug ?? argv.find((a, i) => !a.startsWith("--") && argv[i - 1] !== "--ref") ?? "");
const dir = join(POSTS, slug);
const hype = readFileSync(join(POSTS, "hype-words.txt"), "utf8").split("\n").map((l) => l.trim()).filter(Boolean);
const fail = (lines: string[]) => { for (const l of lines) console.error(l); process.exit(1); };

const blocks = checkPost(dir, hype).filter((f) => f.level === "block");
if (blocks.length) fail(blocks.map((f) => `BLOCK ${f.rule}: ${f.message}`));

const path = join(dir, "post.md");
const text = readFileSync(path, "utf8");
const { fm, body } = parseFrontMatter(text);
const draft = process.env.usage_draft === "true" || flag("draft") || fm.published !== true;

const state = gitState();
if (process.env.CI !== "true") {
  const pre = pushPreconditions(state, draft);
  if (pre.length) fail(pre.map((f) => `BLOCK ${f.rule}: ${f.message}`));
}
const ref = process.env.usage_ref ?? opt("ref") ?? state.branch;

const mine = (await myArticles()).map((a) => ({ id: a.id as number, title: a.title as string }));
const id = resolveArticleId(fm, mine);
const payload = articlePayload(fm, body, { slug, ref, draft });
const saved = (await devto(id ? `/articles/${id}` : "/articles", { method: id ? "PUT" : "POST", body: payload })) as {
  id: number; url: string;
};
if (fm.id !== saved.id) writeFileSync(path, setFrontMatterId(text, saved.id));
console.log(`${slug} ${payload.article.published ? "published" : "draft"} ${saved.url}`);
