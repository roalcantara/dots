#!/usr/bin/env bun
//MISE description="Record dev.to numbers, referrers and repo traffic as stats comments in docs/posts/TODO.yaml"
import {
  addComment, devto, formatStats, parseFrontMatter, POSTS, myArticles, postsFromTodo, readTodo, resolveArticleId, rowsFromArticles,
  rowsFromReferrers, rowsFromTraffic, seriesFromTodo, today, type StatRow,
} from "./_lib";

const date = today();
const todo = readTodo();
const mine = await myArticles();
const titles = mine.map((a) => ({ id: a.id as number, title: a.title as string }));

for (const p of postsFromTodo(todo)) {
  const { fm } = parseFrontMatter(await Bun.file(`${POSTS}/${p.dir}/post.md`).text());
  const title = fm.title;
  const id = resolveArticleId(p.devtoId, title, titles);
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
