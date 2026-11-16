#!/usr/bin/env bun
//MISE description="Check a post's shape, RECIPE and voice (docs/blog/posts/<post>)"
//USAGE arg "<post>" help="Post folder under docs/blog/posts (YYYY-MM-DD-slug)"
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { assertPost, checkPost, POSTS, SERIES } from "./_lib";

const slug = assertPost(process.argv[2] ?? "");
const hype = readFileSync(join(SERIES, "hype-words.txt"), "utf8").split("\n").map((l) => l.trim()).filter(Boolean);
const findings = checkPost(join(POSTS, slug), hype);
for (const f of findings) console.log(`${f.level === "block" ? "BLOCK" : "warn "} ${f.rule}: ${f.message}`);
const blocks = findings.filter((f) => f.level === "block").length;
console.log(blocks ? `${slug}: ${blocks} blocking finding(s)` : `${slug}: ok (${findings.length} warning(s))`);
process.exit(blocks ? 1 : 0);
