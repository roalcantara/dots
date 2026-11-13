#!/usr/bin/env bun
//MISE description="Where each post stands and the next command (one post when given)"
//USAGE arg "[post]" help="Post folder (YYYY-MM-DD-slug); default: every post, plus the next topic"
import { factsFor, isPost, nextTopicTask, pick, readTodo, stageOf } from "./_lib";

// Notes and URLs are not post folders: show every post, as with no argument.
const raw = process.argv[2];
const arg = raw && isPost(raw) ? raw : undefined;
const { post, posts } = pick(arg);
const show = arg ? (post ? [post] : []) : posts.sort((a, b) => a.dir.localeCompare(b.dir));
for (const p of show) {
  const { stage, next } = stageOf(factsFor(p));
  console.log(`${p.dir.padEnd(36)} ${stage.padEnd(9)} → ${next}`);
}
if (!arg) {
  const t = nextTopicTask(readTodo());
  if (t) console.log(`${`next topic (${t.id})`.padEnd(36)} planned   → /blog:pick, then mise run blog:new <slug> --task ${t.id}  # ${t.description}`);
}
if (arg && !post) console.log(`${arg}: no post task points at it (mise run blog:new …)`);
