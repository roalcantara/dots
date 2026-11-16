#!/usr/bin/env bun
//MISE description="Render a post's cover (images/00-cover.png) from its cover.json in the series look (needs Chrome)"
//USAGE arg "[post]" help="Post folder (default: the current post branch)"
import { existsSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { type CoverSpec, coverHtml, parseFrontMatter, pick, POSTS, readTodo, SERIES, topicNumber } from "./_lib";

const { post } = pick(process.argv[2]);
if (!post) throw new Error("which post? pass its folder, or run this on its feat/post-<slug> branch");
const dir = join(POSTS, post.dir);
const specPath = join(dir, "cover.json");
if (!existsSync(specPath)) throw new Error(`no ${specPath}: /blog:draft writes it (see docs/blog/templates/cover.json)`);

const spec = JSON.parse(readFileSync(specPath, "utf8")) as CoverSpec;
const { fm } = parseFrontMatter(readFileSync(join(dir, "post.md"), "utf8"));
const task = readTodo().tasks.find((t) => t.id === post.taskId);
const html = coverHtml(readFileSync(join(SERIES, "tools", "cover.html"), "utf8"), spec, {
  series: task ? topicNumber(task) : 0,
  tags: fm.tags,
});

// macOS only: Chrome comes from the Brewfile's google-chrome cask (and the SF fonts from macOS).
const chrome = ["/Applications/Google Chrome.app/Contents/MacOS/Google Chrome", Bun.which("google-chrome"), Bun.which("chromium")]
  .find((p): p is string => Boolean(p && existsSync(p)));
if (!chrome) throw new Error("Chrome not found: brew install --cask google-chrome (covers render on macOS)");

const page = join(mkdtempSync(join(tmpdir(), "cover-")), "cover.html");
writeFileSync(page, html);
const out = join(dir, "images", "00-cover.png");
const r = Bun.spawnSync([
  chrome, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=2",
  "--window-size=1000,420", `--screenshot=${out}`, `file://${page}`,
], { stdout: "pipe", stderr: "pipe" });
if (r.exitCode !== 0 || !existsSync(out)) throw new Error(`Chrome failed to render the cover (exit ${r.exitCode})`);
console.log(`cover: ${out} (2000 × 840)`);
