#!/usr/bin/env bun
//MISE description="Draw a post's cover (images/00-cover.png) in the series look"
//USAGE arg "<post>" help="Post folder (YYYY-MM-DD-slug)"
//USAGE flag "--title <title>" help="First title line"
//USAGE flag "--highlight <text>" help="Second title line, in the accent colour"
//USAGE flag "--subtitle <text>" help="Small line under the title"
//USAGE flag "--keys <keys>" help="Comma-separated key caps (fn draws the globe key)"
import { join } from "node:path";
import { parseArgs } from "node:util";
import { assertPost, POSTS, postsFromTodo, readTodo, ROOT, SERIES, topicNumber } from "./_lib";

const { values, positionals } = parseArgs({
  args: process.argv.slice(2), allowPositionals: true,
  options: { title: { type: "string" }, highlight: { type: "string" }, subtitle: { type: "string" }, keys: { type: "string" } },
});
const post = assertPost(positionals[0] ?? "");
if (!values.title || !values.keys) throw new Error("--title and --keys are required");
const todo = readTodo();
const taskId = postsFromTodo(todo).find((p) => p.dir === post)?.taskId;
const task = todo.tasks.find((t) => t.id === taskId);
const out = join(POSTS, post, "images", "00-cover.png");
const p = Bun.spawnSync([
  "uv", "run", "--quiet", "--with", "pillow", join(SERIES, "tools", "header.py"), out,
  "--title", values.title, "--highlight", values.highlight ?? "", "--subtitle", values.subtitle ?? "",
  "--keys", values.keys, "--series", String(task ? topicNumber(task) : 0),
], { cwd: ROOT, stdout: "inherit", stderr: "inherit" });
if (p.exitCode !== 0) process.exit(p.exitCode ?? 1);
console.log(`cover: ${out}`);
