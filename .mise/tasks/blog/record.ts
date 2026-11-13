#!/usr/bin/env bun
//MISE description="Record numbers read by hand as a stats comment: blog:record <post|series> <platform> metric=value…"
//USAGE arg "<target>" help="A post folder (YYYY-MM-DD-slug) or 'series'"
//USAGE arg "<platform>" help="linkedin, reddit, devto or github"
//USAGE arg "<pairs>..." help="metric=value pairs"
import { addComment, formatStats, parseRecordArgs, postsFromTodo, readTodo, seriesFromTodo, today } from "./_lib";

const [target = "", ...rest] = process.argv.slice(2);
const todo = readTodo();
const taskId = target === "series" ? seriesFromTodo(todo).taskId : postsFromTodo(todo).find((p) => p.dir === target)?.taskId;
if (!taskId) throw new Error(`no task for "${target}": a post task (tag post, position = its folder) or the series task`);
for (const line of formatStats(parseRecordArgs([target, ...rest], today()))) {
  addComment(taskId, `stats: ${line}`);
  console.log(`${target}: ${line}`);
}
