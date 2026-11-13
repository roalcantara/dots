#!/usr/bin/env bun
//MISE description="Record dev.to numbers, referrers and repo traffic as stats comments in docs/blog/TODO.yaml (commits locally)"
//USAGE flag "--no-commit" help="Leave TODO.yaml uncommitted (used by blog:done)"
import {
  addComment, commitLocal, devto, formatStats, parseFrontMatter, POSTS, myArticles, postsFromTodo, readTodo, resolveArticleId, rowsFromArticles,
  rowsFromReferrers, rowsFromTraffic, seriesFromTodo, today, type StatRow,
} from "./_lib";

const date = today();
const todo = readTodo();
const mine = await myArticles();
const known = mine.map((a) => ({ id: a.id as number, title: a.title as string, body_markdown: a.body_markdown as string }));

for (const p of postsFromTodo(todo)) {
  const file = Bun.file(`${POSTS}/${p.dir}/post.md`);
  if (!(await file.exists())) {
    console.log(`note: ${p.dir}: no post.md, skipped`);
    continue;
  }
  const { fm } = parseFrontMatter(await file.text());
  const id = resolveArticleId(p.devtoId, p.dir, fm.title, known);
  if (!id) continue;
  if (!p.devtoId) {
    addComment(p.taskId, `devto.id: ${id}`);
    const url = mine.find((a) => a.id === id)?.url;
    if (url) addComment(p.taskId, `devto.url: ${url}`);
  }
  const rows: StatRow[] = rowsFromArticles(mine, date, new Map([[id, p.dir]]));
  try {
    rows.push(...rowsFromReferrers(await devto(`/analytics/referrers?article_id=${id}`), date, p.dir));
  } catch {
    console.log(`note: no referrer data for ${p.dir}`);
  }
  for (const line of formatStats(rows)) {
    addComment(p.taskId, `stats: ${line}`);
    console.log(`${p.dir}: ${line}`);
  }
}

const series = seriesFromTodo(todo);
const gh = Bun.spawnSync(["gh", "api", "repos/roalcantara/dots/traffic/views"], { stdout: "pipe", stderr: "pipe" });
if (!series.taskId) console.log('note: no task tagged "series"; repo traffic not recorded');
else if (gh.exitCode !== 0) console.log("note: no GitHub traffic (gh api failed)");
else {
  for (const line of formatStats(rowsFromTraffic(JSON.parse(gh.stdout.toString()), date))) {
    addComment(series.taskId, `stats: ${line}`);
    console.log(`series: ${line}`);
  }
}

if (!process.argv.includes("--no-commit")) commitLocal(["docs/blog/TODO.yaml"], `chore(blog): Record stats (${date})`);
