#!/usr/bin/env bun
//MISE description="Mark a post published (front matter), commit and push its branch; then you merge the PR"
//USAGE arg "[post]" help="Post folder (default: the current post branch)"
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import {
  authorMarkers, changedAt, commitLocal, gitState, parseFrontMatter, pick, POSTS, publishBlockers, pushBranch,
  reviewFresh, reviewVerdict, setPublished,
} from "./_lib";

const { post } = pick(process.argv[2]);
if (!post) throw new Error("which post? pass its folder, or run this on its feat/post-<slug> branch");
const dir = join(POSTS, post.dir);
const read = (f: string) => { try { return readFileSync(join(dir, f), "utf8"); } catch { return ""; } };
const blockers = publishBlockers({
  review: reviewVerdict(read("review.md")),
  reviewFresh: reviewFresh(changedAt(join(dir, "review.md")), changedAt(join(dir, "post.md"))),
  markers: authorMarkers(read("post.md") + read("linkedin.md")).length,
  dirty: gitState().dirty,
});
if (blockers.length) {
  for (const b of blockers) console.error(`BLOCK ${b.rule}: ${b.message}`);
  process.exit(1);
}
const text = read("post.md");
writeFileSync(join(dir, "post.md"), setPublished(text));
commitLocal([`docs/blog/posts/${post.dir}/post.md`], `docs(blog): Publish "${parseFrontMatter(text).fm.title}"`);
console.log(`pushed ${pushBranch()}. Next: merge the pull request (that publishes it), then /blog:share`);
