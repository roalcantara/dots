#!/usr/bin/env bun
//MISE description="Render a post's cover (images/00-cover.png) from its cover.json in the series look (needs Chrome)"
//USAGE arg "[post]" help="Post folder (default: the current post branch)"
import { existsSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { type CoverSpec, coverHtml, linkedinCropWidth, parseFrontMatter, pick, POSTS, readTodo, SERIES, topicNumber } from "./_lib";

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

// Two previews for the author, in raw/ (never published): what LinkedIn's link card keeps (the center at 1.91 : 1)
// and the phone test (400 px wide). sips ships with macOS, like the Chrome and SF fonts the cover needs.
const raw = join(dir, "raw");
mkdirSync(raw, { recursive: true });
const linkedin = join(raw, "00-cover-linkedin.png");
const phone = join(raw, "00-cover-phone.png");
for (const args of [["-c", "840", String(linkedinCropWidth(840)), out, "--out", linkedin], ["-Z", "400", out, "--out", phone]]) {
  const s = Bun.spawnSync(["sips", ...args], { stdout: "pipe", stderr: "pipe" });
  if (s.exitCode !== 0) throw new Error(`sips failed: ${s.stderr.toString().trim()}`);
}
console.log(`look before posting: ${linkedin} (LinkedIn's card) · ${phone} (phone test)`);
