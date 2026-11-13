#!/usr/bin/env bun
//MISE description="Report every post's metadata from docs/posts/TODO.yaml; --write regenerates the README index"
//USAGE flag "--write" help="Rewrite the index table in docs/posts/README.md"
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { parseArgs } from "node:util";
import { parseFrontMatter, POSTS, postsFromTodo, readTodo, SERIES, seriesFromTodo, type StatRow } from "./_lib";

const { values } = parseArgs({ args: process.argv.slice(2), options: { write: { type: "boolean", default: false } } });
const todo = readTodo();
const posts = postsFromTodo(todo).sort((a, b) => a.dir.localeCompare(b.dir));
const latest = (rows: StatRow[]) => {
  const last = new Map<string, StatRow>();
  for (const r of rows) last.set(`${r.platform} ${r.metric}`, r);
  return [...last.values()].map((r) => `${r.platform}.${r.metric}=${r.value} (${r.date})`).join(" · ");
};

let problems = 0;
for (const p of posts) {
  const file = join(POSTS, p.dir, "post.md");
  const fm = existsSync(file) ? parseFrontMatter(readFileSync(file, "utf8")).fm : undefined;
  console.log(`\n## ${p.dir} · ${p.status}${fm?.title ? ` · ${fm.title}` : ""}`);
  if (!fm) console.log(`  ! no post.md at ${file}`);
  for (const [k, v] of Object.entries(p.meta)) console.log(`  ${k}: ${v.join(" | ")}`);
  if (p.stats.length) console.log(`  latest: ${latest(p.stats)}`);
  for (const bad of p.invalid) console.log(`  ! not in the schema: ${bad}`);
  problems += p.invalid.length + (fm ? 0 : 1);
}
const series = seriesFromTodo(todo);
if (series.stats.length) console.log(`\n## series\n  latest: ${latest(series.stats)}`);
for (const bad of series.invalid) console.log(`  ! not in the schema: ${bad}`);
problems += series.invalid.length;

if (values.write) {
  const readme = join(SERIES, "README.md");
  const text = readFileSync(readme, "utf8");
  const rows = posts.map((p) => {
    const fm = parseFrontMatter(readFileSync(join(POSTS, p.dir, "post.md"), "utf8")).fm;
    const link = (key: string, label: string) => (p.meta[key]?.at(-1) ? `[${label}](${p.meta[key]!.at(-1)})` : "—");
    return `| ${p.dir.slice(0, 10)} | [${fm.title}](articles/${p.dir}/post.md) | ${fm.description ?? ""} | ${link("devto.url", "dev.to")} | ${link("linkedin.url", "LinkedIn")} |`;
  });
  const table = ["| Date | Post | What it is | dev.to | LinkedIn |", "| --- | --- | --- | --- | --- |", ...rows].join("\n");
  const next = text.replace(/<!-- index:start -->[\s\S]*<!-- index:end -->/, `<!-- index:start -->\n${table}\n<!-- index:end -->`);
  if (next === text && !text.includes("<!-- index:start -->")) throw new Error("README.md has no <!-- index:start --> marker");
  writeFileSync(readme, next);
  console.log(`\nREADME.md index: ${rows.length} post(s)`);
}
if (problems) console.log(`\n${problems} problem(s) above`);
