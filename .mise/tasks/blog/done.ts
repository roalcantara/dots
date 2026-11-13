#!/usr/bin/env bun
//MISE description="Close a shared post: record its URLs and numbers, mark its task done, refresh the README index"
//USAGE arg "[post]" help="Post folder (default: the latest open post)"
//USAGE flag "--linkedin <url>" help="The LinkedIn post"
//USAGE flag "--community <url>" help="The community post"
import { join } from "node:path";
import { parseArgs } from "node:util";
import { addComment, commitLocal, pick, ROOT, todo } from "./_lib";

const { values, positionals } = parseArgs({
  args: process.argv.slice(2), allowPositionals: true,
  options: { linkedin: { type: "string" }, community: { type: "string" } },
});
const { post } = pick(positionals[0]);
if (!post) throw new Error("which post? pass its folder");
const written: string[] = [];
const record = (key: string, value?: string) => {
  if (!value || post.meta[key]?.includes(value)) return; // already recorded: a rerun is safe
  addComment(post.taskId, `${key}: ${value}`);
  written.push(`${key}: ${value}`);
};
const stop = (step: string): never => {
  console.error(`blog:done stopped at ${step}; nothing committed.${written.length ? ` Already written to TODO.yaml: ${written.join("; ")}` : ""}`);
  process.exit(1);
};
record("linkedin.url", values.linkedin);
record("community.url", values.community);
const bun = (script: string, ...args: string[]) =>
  Bun.spawnSync(["bun", join(import.meta.dir, script), ...args], { cwd: ROOT, stdout: "inherit", stderr: "inherit" }).exitCode === 0;
if (!bun("stats.ts", "--no-commit")) stop("blog:stats");
written.push("stats");
todo("status", post.taskId, "--set", "done");
written.push("task done");
if (!bun("report.ts", "--write")) stop("blog:report --write");
commitLocal(["docs/blog/TODO.yaml", "docs/blog/README.md"], `chore(blog): Close "${post.dir}"`);
