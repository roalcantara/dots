#!/usr/bin/env bun
//MISE description="Push a post to dev.to: a draft, or published when its front matter says so and it is on main"
//USAGE arg "<post>" help="Post folder under docs/posts/articles (YYYY-MM-DD-slug)"
//USAGE flag "--ref <ref>" help="Git ref the images are served from (default: the current branch)"
//USAGE flag "--draft" help="Always send a draft, whatever the front matter says (pull requests)"
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import {
  articlePayload, assertPost, checkPost, devto, gitState, myArticles, parseFrontMatter, POSTS, SERIES, postOptions, pushAction, pushPreconditions,
  resolveArticleId, setFrontMatterId,
} from "./_lib";

const opts = postOptions(process.argv.slice(2));
const slug = assertPost(opts.post);
const dir = join(POSTS, slug);
const hype = readFileSync(join(SERIES, "hype-words.txt"), "utf8").split("\n").map((l) => l.trim()).filter(Boolean);
const fail = (lines: string[]) => { for (const l of lines) console.error(l); process.exit(1); };

const blocks = checkPost(dir, hype).filter((f) => f.level === "block");
if (blocks.length) fail(blocks.map((f) => `BLOCK ${f.rule}: ${f.message}`));

const path = join(dir, "post.md");
const text = readFileSync(path, "utf8");
const { fm, body } = parseFrontMatter(text);
const draft = opts.draft || fm.published !== true;

const state = gitState();
if (process.env.CI !== "true") {
  const pre = pushPreconditions(state, draft);
  if (pre.length) fail(pre.map((f) => `BLOCK ${f.rule}: ${f.message}`));
}
const ref = opts.ref || state.branch;
if (!ref) fail(["BLOCK no-ref: detached HEAD; pass --ref <branch>"]);

const mine = (await myArticles()).map((a) => ({ id: a.id as number, title: a.title as string, published: a.published === true }));
const id = resolveArticleId(fm, mine);
const live = mine.find((a) => a.id === id)?.published === true;
if (id && pushAction({ draft, live }) === "skip") {
  console.log(`${slug} live https://dev.to/api/articles/${id} (published: updated from main on merge)`);
  process.exit(0);
}
const payload = articlePayload(fm, body, { slug, ref, draft, live });
const saved = (await devto(id ? `/articles/${id}` : "/articles", { method: id ? "PUT" : "POST", body: payload })) as {
  id: number; url: string;
};
if (fm.id !== saved.id) writeFileSync(path, setFrontMatterId(text, saved.id));
console.log(`${slug} ${payload.article.published ?? live ? "published" : "draft"} ${saved.url}`);
