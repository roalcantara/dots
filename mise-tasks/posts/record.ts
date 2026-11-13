#!/usr/bin/env bun
//MISE description="Record numbers read by hand: posts:record <slug|-> <linkedin|reddit|…> metric=value…"
import { join } from "node:path";
import { appendRows, parseRecordArgs, POSTS, today } from "./_lib";

const rows = parseRecordArgs(process.argv.slice(2), today());
appendRows(join(POSTS, "stats.csv"), rows);
console.log(`${rows.length} row(s) appended to docs/posts/stats.csv`);
