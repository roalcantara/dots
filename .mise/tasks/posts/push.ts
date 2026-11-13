#!/usr/bin/env bun
//MISE description="Push a post to dev.to: a draft, or published when its front matter says so and it is on main"
//USAGE arg "<post>" help="Post folder under docs/blog/posts (YYYY-MM-DD-slug)"
//USAGE flag "--ref <ref>" help="Git ref the images are served from (default: the current branch)"
//USAGE flag "--draft" help="Always send a draft, whatever the front matter says (pull requests)"
import { readFileSync } from "node:fs";
import { join } from "node:path";
import {
  addComment, articlePayload, assertPost, checkPost, devto, gitState, myArticles, parseFrontMatter, POSTS,
  postOptions, postsFromTodo, pushAction, pushPreconditions, readTodo, resolveArticleId, SERIES,
} from "./_lib";

const fail = (lines: string[]): never => { for (const l of lines) console.error(l); process.exit(1); };
const opts = postOptions(process.argv.slice(2));
const post = assertPost(opts.post);
const ci = process.env.CI === "true";
const dir = join(POSTS, post);
const hype = readFileSync(join(SERIES, "hype-words.txt"), "utf8").split("\n").map((l) => l.trim()).filter(Boolean);

const blocks = checkPost(dir, hype).filter((f) => f.level === "block");
if (blocks.length) fail(blocks.map((f) => `BLOCK ${f.rule}: ${f.message}`));

const { fm, body } = parseFrontMatter(readFileSync(join(dir, "post.md"), "utf8"));
const draft = opts.draft || fm.published !== true;
const state = gitState();
if (!ci) {
  const pre = pushPreconditions(state, draft);
  if (pre.length) fail(pre.map((f) => `BLOCK ${f.rule}: ${f.message}`));
}
const ref = opts.ref || state.branch || fail(["BLOCK no-ref: detached HEAD; pass --ref <branch>"]);

const task = postsFromTodo(readTodo()).find((p) => p.dir === post);
const mine = (await myArticles()).map((a) => ({ id: a.id as number, title: a.title as string, published: a.published === true }));
const id = resolveArticleId(task?.devtoId, fm.title, mine);
const live = mine.find((a) => a.id === id)?.published === true;
if (id && pushAction({ draft, live }) === "skip") {
  console.log(`${post} live (updated from main on merge)`);
  process.exit(0);
}

const payload = articlePayload(fm, body, { slug: post, ref, draft, live });
const saved = (await devto(id ? `/articles/${id}` : "/articles", { method: id ? "PUT" : "POST", body: payload })) as {
  id: number; url: string;
};
if (task && task.devtoId !== saved.id) {
  // CI never writes the repo: a later local posts:push or posts:stats records the id (found by title meanwhile).
  if (ci) console.log(`note: ${post} has dev.to id ${saved.id}; posts:stats records it`);
  else {
    addComment(task.taskId, `devto.id: ${saved.id}`);
    addComment(task.taskId, `devto.url: ${saved.url}`);
  }
}
if (!task) console.log(`note: no post task points at docs/blog/posts/${post} (tag it "post", set its position)`);
console.log(`${post} ${payload.article.published ?? live ? "published" : "draft"} ${saved.url}`);
