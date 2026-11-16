#!/usr/bin/env bun
//MISE description="Stamp a post's review.md with the fingerprint of what was reviewed (run by /blog:gate)"
//USAGE arg "[post]" help="Post folder (default: the current post branch)"
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { contentHash, pick, POSTS } from "./_lib";

const { post } = pick(process.argv[2]);
if (!post) throw new Error("which post? pass its folder, or run this on its feat/post-<slug> branch");
const dir = join(POSTS, post.dir);
const review = join(dir, "review.md");
if (!existsSync(review)) throw new Error(`no ${review}: run /blog:gate first`);
const stamp = `<!-- reviewed: ${contentHash(dir)} -->`;
const text = readFileSync(review, "utf8");
writeFileSync(review, /<!-- reviewed: [0-9a-f]+ -->/.test(text) ? text.replace(/<!-- reviewed: [0-9a-f]+ -->/, stamp) : `${text.trimEnd()}\n\n${stamp}\n`);
console.log(`${post.dir}: review stamped (${stamp})`);
