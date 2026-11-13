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
if (values.linkedin) addComment(post.taskId, `linkedin.url: ${values.linkedin}`);
if (values.community) addComment(post.taskId, `community.url: ${values.community}`);
const bun = (script: string, ...args: string[]) =>
  Bun.spawnSync(["bun", join(import.meta.dir, script), ...args], { cwd: ROOT, stdout: "inherit", stderr: "inherit" });
bun("stats.ts", "--no-commit");
todo("status", post.taskId, "--set", "done");
bun("report.ts", "--write");
commitLocal(["docs/blog/TODO.yaml", "docs/blog/README.md"], `chore(blog): Close "${post.dir}"`);
