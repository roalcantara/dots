#!/usr/bin/env bun
//MISE description="Check a post's shape, RECIPE and voice (docs/posts/articles/<post>)"
//USAGE arg "<post>" help="Post folder under docs/posts/articles (YYYY-MM-DD-slug)"
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { assertPost, checkPost } from "./_lib";

const root = join(import.meta.dir, "../..");
const slug = assertPost(process.argv[2] ?? "");
const hype = readFileSync(join(root, "docs/posts/hype-words.txt"), "utf8").split("\n").map((l) => l.trim()).filter(Boolean);
const findings = checkPost(join(root, "docs/posts/articles", slug), hype);
for (const f of findings) console.log(`${f.level === "block" ? "BLOCK" : "warn "} ${f.rule}: ${f.message}`);
const blocks = findings.filter((f) => f.level === "block").length;
console.log(blocks ? `${slug}: ${blocks} blocking finding(s)` : `${slug}: ok (${findings.length} warning(s))`);
process.exit(blocks ? 1 : 0);
