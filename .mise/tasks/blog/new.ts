#!/usr/bin/env bun
//MISE description="Start a post: branch feat/post-<slug>, copy the templates, point its roadmap task at the folder"
//USAGE arg "<slug>" help="lowercase-words-with-hyphens"
//USAGE flag "--task <id>" help="Roadmap task (default: the next open topic)"
//USAGE flag "--date <date>" help="Publish date YYYY-MM-DD (default: the task's due date)"
import { copyFileSync, mkdirSync } from "node:fs";
import { join } from "node:path";
import { parseArgs } from "node:util";
import {
  assertPost, commitLocal, git, gitState, nextTopicTask, POSTS, readTodo, scaffoldFiles, SERIES, today, todo, topicNumber,
} from "./_lib";

const { values, positionals } = parseArgs({
  args: process.argv.slice(2), allowPositionals: true,
  options: { task: { type: "string" }, date: { type: "string" } },
});
const slug = positionals[0] ?? "";
const t = readTodo();
const task = values.task ? t.tasks.find((x) => x.id === values.task) : nextTopicTask(t);
if (!task) throw new Error(values.task ? `no task ${values.task}` : "no open topic task; pass --task <id>");
const date = values.date ?? (task.due ? String(task.due).slice(0, 10) : today());
const post = assertPost(`${date}-${slug}`);
if (gitState().dirty) throw new Error("commit or stash your changes first");

const branch = `feat/post-${slug}`;
if (!git("switch", "-c", branch, "main").ok) throw new Error(`could not create ${branch} from main`);
const dir = join(POSTS, post);
for (const sub of ["images", "raw"]) mkdirSync(join(dir, sub), { recursive: true });
for (const f of scaffoldFiles(topicNumber(task))) copyFileSync(join(SERIES, "templates", f), join(dir, f));
todo("update", task.id, "--tag", [...new Set([...(task.tags ?? []), "post"])].join(","), "--position", `docs/blog/posts/${post}`);
commitLocal([`docs/blog/posts/${post}`, "docs/blog/TODO.yaml"], `docs(blog): Start "${post}"`);
console.log(`${post} on ${branch} (task ${task.id}: ${task.description}). Next: /blog:draft`);
