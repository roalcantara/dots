#!/usr/bin/env bun
//MISE description="Append dev.to and GitHub numbers for every post to docs/posts/stats.csv"
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { appendRows, devto, myArticles, parseFrontMatter, POSTS, SERIES, rowsFromArticles, rowsFromReferrers, rowsFromTraffic, type StatRow, today } from "./_lib";

const date = today();
const slugById = new Map<number, string>();
for (const slug of readdirSync(POSTS)) {
  const p = join(POSTS, slug, "post.md");
  if (!existsSync(p)) continue;
  const { fm } = parseFrontMatter(readFileSync(p, "utf8"));
  if (typeof fm.id === "number") slugById.set(fm.id, slug);
}

const rows: StatRow[] = rowsFromArticles(await myArticles(), date, slugById);
for (const [id, slug] of slugById) {
  try {
    const found = rowsFromReferrers(await devto(`/analytics/referrers?article_id=${id}`), date, slug);
    if (!found.length) console.log(`note: no referrer data for ${slug}`);
    rows.push(...found);
  } catch {
    console.log(`note: no referrer data for ${slug}`);
  }
}
const gh = Bun.spawnSync(["gh", "api", "repos/roalcantara/dots/traffic/views"], { stdout: "pipe", stderr: "pipe" });
if (gh.exitCode === 0) rows.push(...rowsFromTraffic(JSON.parse(gh.stdout.toString()), date));
else console.log("note: no GitHub traffic (gh api failed)");

appendRows(join(SERIES, "stats.csv"), rows);
for (const r of rows) console.log(`${r.slug.padEnd(24)} ${r.platform.padEnd(7)} ${r.metric.padEnd(18)} ${r.value}`);
console.log(`${rows.length} row(s) appended to docs/posts/stats.csv`);
