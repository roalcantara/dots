#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { appendFileSync, cpSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  articlePayload,
  authorMarkers,
  assertPost,
  checkPost,
  contentHash,
  coverHtml,
  type Facts,
  formatStats,
  isTopicTask,
  nextTopicTask,
  postBranch,
  parseComment,
  parseFrontMatter,
  parseRecordArgs,
  parseStats,
  placeholders,
  publishBlockers,
  postOptions,
  postsFromTodo,
  resolvePost,
  publishGate,
  pushAction,
  pushPreconditions,
  resolveArticleId,
  reviewStamp,
  reviewVerdict,
  rewriteImages,
  rowsFromArticles,
  rowsFromReferrers,
  rowsFromTraffic,
  scaffoldFiles,
  setPublished,
  stageOf,
  type Todo,
  topicNumber,
  visibleLength,
} from "../../../.mise/tasks/blog/_lib";

const REPO = join(import.meta.dir, "../../..");
const FIX = join(import.meta.dir, "fixtures");
const HYPE = readFileSync(join(REPO, "docs/blog/hype-words.txt"), "utf8")
  .split("\n")
  .map((l) => l.trim())
  .filter(Boolean);
const rules = (dir: string) => checkPost(join(FIX, dir), HYPE).map((f) => `${f.level}:${f.rule}`);

describe("parseFrontMatter", () => {
  it("reads comma and list tags, booleans and the body", () => {
    const a = parseFrontMatter("---\ntitle: T\npublished: false\ntags: git, zsh, ai\n---\nbody\n");
    expect(a.fm.tags).toEqual(["git", "zsh", "ai"]);
    expect(a.fm.published).toBe(false);
    expect(a.fm.title).toBe("T");
    expect(a.body).toBe("body\n");
    expect(parseFrontMatter("---\ntags: [a, b]\nid: 42\n---\n").fm).toMatchObject({ tags: ["a", "b"], id: 42 });
  });

  it("returns empty tags and the whole text without front matter", () => {
    expect(parseFrontMatter("no front matter\n")).toEqual({ fm: { tags: [] }, body: "no front matter\n" });
  });
});

describe("checkPost", () => {
  it("accepts a complete post", () => {
    expect(rules("good")).toEqual([]);
  });

  it("blocks a broken post and warns about its voice", () => {
    const got = rules("bad");
    for (const r of [
      "block:tags-max-4",
      "block:description-missing",
      "block:tldr-missing",
      "block:ai-disclosure",
      "block:raw-image",
      "block:linkedin-missing",
      "warn:hype-word",
      "warn:sections",
      "warn:gotchas-over-3",
    ]) expect(got).toContain(r);
  });

  it("warns about a LinkedIn hook over 210 characters", () => {
    expect(rules("long-hook")).toEqual(["warn:hook-over-210"]);
  });

  it("blocks <author: …> markers", () => {
    const dir = join(mkdtempSync(join(tmpdir(), "post-")), "good");
    cpSync(join(FIX, "good"), dir, { recursive: true });
    appendFileSync(join(dir, "post.md"), "\n<author: how I noticed the loop ran once>\n");
    expect(checkPost(dir, HYPE).map((f) => `${f.level}:${f.rule}`)).toContain("block:author-marker");
  });
});

describe("visibleLength", () => {
  it("counts what a reader sees", () => {
    expect(visibleLength("você 👋🏽")).toBe(6);
    expect(visibleLength("a".repeat(210))).toBe(210);
  });
});

describe("assertPost", () => {
  it("accepts a dated post folder", () => {
    expect(assertPost("2026-11-13-zsh-word-split")).toBe("2026-11-13-zsh-word-split");
  });

  it("rejects anything else", () => {
    for (const s of ["zsh-word-split", "templates", "2026-13-01-x", "2026-11-13-", "2026-11-13-A", "", "../x", "2026-11-13-a/b"]) {
      expect(() => assertPost(s)).toThrow();
    }
  });
});

describe("rewriteImages", () => {
  it("points relative images at the ref on GitHub and leaves absolute links alone", () => {
    const out = rewriteImages("![a](images/x.png) ![c](./images/z.png) ![b](https://e.com/y.png)", "2026-11-13-s", "main");
    const base = "https://raw.githubusercontent.com/roalcantara/dots/main/docs/blog/posts/2026-11-13-s/images";
    expect(out).toBe(`![a](${base}/x.png) ![c](${base}/z.png) ![b](https://e.com/y.png)`);
  });
});

describe("articlePayload", () => {
  const fm = { title: "T", published: true, description: "D", tags: ["ai"], cover_image: "./images/c.png" };

  it("always sends a draft for a pull request", () => {
    expect(articlePayload(fm, "b", { slug: "s", ref: "feat/x", draft: true }).article.published).toBe(false);
  });

  it("follows the front matter otherwise, with the cover and images from the ref", () => {
    const { article } = articlePayload(fm, "![a](images/x.png)", { slug: "s", ref: "main", draft: false });
    expect(article.published).toBe(true);
    expect(article.main_image).toBe("https://raw.githubusercontent.com/roalcantara/dots/main/docs/blog/posts/s/images/c.png");
    expect(article.body_markdown).toContain("/main/docs/blog/posts/s/images/x.png");
    expect(article).toMatchObject({ title: "T", description: "D", tags: ["ai"] });
  });

  it("never takes a live article offline", () => {
    const live = { slug: "s", ref: "feat/x", draft: true, live: true };
    expect("published" in articlePayload(fm, "b", live).article).toBe(false);
    expect("published" in articlePayload({ ...fm, published: false }, "b", { ...live, ref: "main", draft: false }).article)
      .toBe(false);
    expect(articlePayload(fm, "b", { ...live, ref: "main", draft: false }).article.published).toBe(true);
  });

  it("marks the body with the post's folder, so a renamed post still finds its article", () => {
    const { article } = articlePayload(fm, "b", { slug: "2026-11-13-p", ref: "main", draft: true });
    expect(article.body_markdown.endsWith("\n\n<!-- dots:2026-11-13-p -->\n")).toBe(true);
  });

  it("is a draft when the front matter says nothing", () => {
    expect(articlePayload({ title: "T", tags: [] }, "b", { slug: "s", ref: "main", draft: false }).article.published).toBe(false);
  });
});

describe("pushPreconditions", () => {
  const clean = { branch: "feat/x", dirty: false, ahead: 0, upstream: true };
  const r = (s: typeof clean, draft: boolean) => pushPreconditions(s, draft).map((f) => f.rule);

  it("publishes only from main", () => {
    expect(r(clean, false)).toEqual(["publish-from-main"]);
    expect(r({ ...clean, branch: "main" }, false)).toEqual([]);
  });

  it("allows a draft from a pushed branch", () => {
    expect(r(clean, true)).toEqual([]);
  });

  it("needs a clean, pushed tree either way", () => {
    expect(r({ ...clean, dirty: true }, true)).toContain("dirty");
    expect(r({ ...clean, ahead: 2 }, true)).toContain("unpushed");
    expect(r({ ...clean, upstream: false }, true)).toContain("no-upstream");
  });
});

describe("pushAction", () => {
  it("leaves a live article alone on a pull request; the merge updates it", () => {
    expect(pushAction({ draft: true, live: true })).toBe("skip");
    expect(pushAction({ draft: true, live: false })).toBe("send");
    expect(pushAction({ draft: false, live: true })).toBe("send");
  });
});

describe("resolveArticleId", () => {
  const mine = [
    { id: 7, title: "T", body_markdown: "x" },
    { id: 9, title: "Old title", body_markdown: "body\n\n<!-- dots:2026-11-13-p -->\n" },
  ];

  it("prefers the recorded id, then the post's marker, then the same title", () => {
    expect(resolveArticleId(3, "2026-11-13-p", "T", mine)).toBe(3);
    expect(resolveArticleId(undefined, "2026-11-13-p", "Renamed", mine)).toBe(9);
    expect(resolveArticleId(undefined, "2026-01-01-q", "T", mine)).toBe(7);
    expect(resolveArticleId(undefined, "2026-01-01-q", "New", mine)).toBeUndefined();
  });
});

describe("stats rows", () => {
  const articles = JSON.parse(readFileSync(join(FIX, "articles-me.json"), "utf8"));
  const slugs = new Map([[101, "good"], [102, "no-views"]]);

  it("records what the API returns and never invents a zero", () => {
    const rows = rowsFromArticles(articles, "2026-11-13", slugs);
    expect(rows.filter((x) => x.slug === "good").map((x) => `${x.metric}=${x.value}`)).toEqual([
      "views=120",
      "reactions=7",
      "comments=2",
    ]);
    expect(rows.filter((x) => x.slug === "no-views").map((x) => x.metric)).toEqual(["reactions", "comments"]);
    expect(rows.every((x) => x.platform === "devto" && x.source === "api")).toBe(true);
  });

  it("reads referrers only when dev.to returns them", () => {
    const refs = { domains: [{ domain: "www.linkedin.com", count: 4 }, { domain: "lnkd.in", count: 1 }, { domain: "old.reddit.com", count: 2 }, { domain: "google.com", count: 9 }] };
    expect(rowsFromReferrers(refs, "2026-11-13", "s").map((x) => `${x.metric}=${x.value}`))
      .toEqual(["referrer_linkedin=5", "referrer_reddit=2"]);
    expect(rowsFromReferrers({}, "2026-11-13", "s")).toEqual([]);
    expect(rowsFromReferrers(null, "2026-11-13", "s")).toEqual([]);
  });

  it("reads repo traffic as account-wide rows", () => {
    expect(rowsFromTraffic({ count: 40, uniques: 9 }, "2026-11-13").map((x) => `${x.slug} ${x.metric}=${x.value}`))
      .toEqual(["- repo_views=40", "- repo_uniques=9"]);
  });

});

describe("parseRecordArgs", () => {
  it("turns metric=value pairs into manual rows", () => {
    const rows = parseRecordArgs(["zsh-word-split", "linkedin", "impressions=812", "reactions=14"], "2026-11-15");
    expect(rows).toEqual([
      { date: "2026-11-15", slug: "zsh-word-split", platform: "linkedin", metric: "impressions", value: 812, source: "manual" },
      { date: "2026-11-15", slug: "zsh-word-split", platform: "linkedin", metric: "reactions", value: 14, source: "manual" },
    ]);
  });

  it("rejects unknown platforms, metrics and values", () => {
    expect(() => parseRecordArgs(["x", "myspace", "views=1"], "d")).toThrow();
    expect(() => parseRecordArgs(["x", "linkedin", "likes=1"], "d")).toThrow();
    expect(() => parseRecordArgs(["x", "linkedin", "impressions=lots"], "d")).toThrow();
  });
});


describe("postOptions", () => {
  it("reads the post, --ref and --draft from argv", () => {
    expect(postOptions(["2026-11-13-x", "--ref", "main", "--draft"])).toEqual({ post: "2026-11-13-x", ref: "main", draft: true });
    expect(postOptions(["--ref=main", "2026-11-13-x"])).toEqual({ post: "2026-11-13-x", ref: "main", draft: false });
    expect(postOptions(["2026-11-13-x"])).toEqual({ post: "2026-11-13-x", ref: undefined, draft: false });
  });

  it("rejects unknown flags and a missing post", () => {
    expect(() => postOptions(["2026-11-13-x", "--publish"])).toThrow();
    expect(() => postOptions([])).toThrow();
  });
});

describe("TODO.yaml metadata", () => {
  const todo = Bun.YAML.parse(readFileSync(join(FIX, "TODO.yaml"), "utf8")) as Todo;

  it("reads a comment as key: value, only for known keys", () => {
    expect(parseComment("devto.id: 5")).toEqual({ key: "devto.id", value: "5" });
    expect(parseComment("log.best-comment: a: b")).toEqual({ key: "log.best-comment", value: "a: b" });
    expect(parseComment("great post, loved it")).toBeUndefined();
    expect(parseComment("colour: blue")).toBeUndefined();
  });

  it("reads and writes stats lines", () => {
    const rows = parseStats("2026-11-13 devto views=30 reactions=0 (api)", "p");
    expect(rows).toEqual([
      { date: "2026-11-13", slug: "p", platform: "devto", metric: "views", value: 30, source: "api" },
      { date: "2026-11-13", slug: "p", platform: "devto", metric: "reactions", value: 0, source: "api" },
    ]);
    expect(formatStats(rows!)).toEqual(["2026-11-13 devto views=30 reactions=0 (api)"]);
    for (const bad of ["2026-11-13 myspace views=1 (api)", "2026-11-13 devto likes=1 (api)", "devto views=1 (api)", "2026-11-13 devto (api)"]) {
      expect(parseStats(bad, "p")).toBeUndefined();
    }
  });

  it("groups stats by date, platform and source", () => {
    const rows = parseStats("2026-11-13 devto views=30 (api)", "p")!.concat(parseStats("2026-11-13 github stars=2 (api)", "-")!);
    expect(formatStats(rows)).toEqual(["2026-11-13 devto views=30 (api)", "2026-11-13 github stars=2 (api)"]);
  });

  it("finds the post tasks and their metadata", () => {
    const posts = postsFromTodo(todo);
    expect(posts.map((p) => p.dir)).toEqual(["2026-11-12-omarchy-on-macos"]);
    const [p] = posts;
    expect(p).toMatchObject({ taskId: "P1", status: "Done", due: "2026-11-12", devtoId: 5021431 });
    expect(p!.stats.map((r) => `${r.date} ${r.metric}=${r.value}`)).toEqual([
      "2026-11-13 views=30", "2026-11-13 reactions=0", "2026-11-13 referrer_linkedin=10", "2026-11-14 views=41",
    ]);
    expect(p!.invalid).toEqual(["great post, loved it"]);
  });

  it("keeps a comment the task's own list lost (a merge that kept one side), and survives no comments at all", () => {
    const merged = { ...todo, tasks: todo.tasks.map((t) => (t.id === "P1" ? { ...t, comments: ["c1"] } : t)) };
    expect(postsFromTodo(merged)[0]!.stats.length).toBe(4);
    expect(postsFromTodo({ tasks: todo.tasks } as Todo)[0]!.stats).toEqual([]);
  });
});

describe("stageOf", () => {
  const base: Facts = {
    hasFolder: true, checkBlocks: false, review: undefined, reviewFresh: false, pr: undefined, published: false,
    markers: 0, devtoUrl: false, linkedinUrl: false, taskDone: false, logKeep: false,
  };
  const stage = (f: Partial<Facts>) => stageOf({ ...base, ...f }).stage;

  it("walks a post from plan to close", () => {
    expect(stage({ hasFolder: false })).toBe("planned");
    expect(stage({ checkBlocks: true })).toBe("drafting");
    expect(stage({})).toBe("gate");
    expect(stage({ review: "PASS", reviewFresh: false })).toBe("gate");
    expect(stage({ review: "BLOCKED", reviewFresh: true })).toBe("blocked");
    expect(stage({ review: "PASS", reviewFresh: true })).toBe("pr");
    expect(stage({ review: "PASS", reviewFresh: true, pr: "open" })).toBe("publish");
    expect(stage({ review: "PASS", reviewFresh: true, pr: "open", published: true, markers: 1 })).toBe("publish");
    expect(stage({ review: "PASS", reviewFresh: true, pr: "open", published: true })).toBe("merge");
    expect(stage({ review: "PASS", reviewFresh: true, pr: "merged", published: true })).toBe("share");
    expect(stage({ pr: "merged", published: true, linkedinUrl: true })).toBe("measure");
    expect(stage({ pr: "merged", published: true, linkedinUrl: true, logKeep: true })).toBe("closed");
  });

  it("says so when the pull request state is unknown (gh failed)", () => {
    expect(stage({ review: "PASS", reviewFresh: true, pr: "unknown" })).toBe("unknown");
    expect(stage({ pr: "unknown", taskDone: true })).toBe("measure");
  });

  it("never sends a merged post back to the pull request step", () => {
    expect(stage({ review: "PASS", reviewFresh: true, pr: "merged" })).toBe("share");
  });

  it("treats a post published before the tooling as measured, whatever check says", () => {
    expect(stage({ checkBlocks: true, published: true, taskDone: true })).toBe("measure");
  });

  it("asks for stats before sharing when the dev.to URL is missing", () => {
    expect(stageOf({ ...base, pr: "merged", published: true }).next).toContain("blog:stats");
    expect(stageOf({ ...base, pr: "merged", published: true, devtoUrl: true }).next).toContain("/blog:share");
  });
});

describe("post helpers", () => {
  const task = (tags: string[]) => ({ id: "x", status: "Todo", description: "d", tags });

  it("knows a topic task from in-between, community and preflight tasks", () => {
    expect(isTopicTask(task(["topic-3"]))).toBe(true);
    expect(isTopicTask(task(["topic-3", "in-between"]))).toBe(false);
    expect(isTopicTask(task(["topic-3", "community"]))).toBe(false);
    expect(isTopicTask(task(["preflight", "post"]))).toBe(false);
    expect(topicNumber(task(["topic-3", "post"]))).toBe(3);
    expect(topicNumber(task(["preflight", "post"]))).toBe(0);
  });

  it("finds template placeholders, not markers, comments, tags or code", () => {
    const text = "<one line> <author: how I noticed> <!-- dots:x --> <img src=a> <https://e.com> `<post>`\n```\n<x>\n```\n";
    expect(placeholders(text)).toEqual(["<one line>"]);
    expect(authorMarkers(text)).toEqual(["<author: how I noticed>"]);
  });

  it("doesn't read comparisons in prose as placeholders", () => {
    expect(placeholders("when x < y holds,\nand later a > b, the loop runs")).toEqual([]);
    expect(placeholders("a <b\n\nc> d")).toEqual([]);
  });

  it("finds markers and placeholders wrapped onto two lines", () => {
    expect(authorMarkers("a <author: how you noticed the\nloop ran once> b")).toHaveLength(1);
    expect(placeholders("<Next week: the RECIPE as a\ncarousel>")).toHaveLength(1);
  });

  it("reads a filled-in verdict, not the template's", () => {
    expect(reviewVerdict("**Verdict:** PASS\n")).toBe("PASS");
    expect(reviewVerdict("**Verdict:** BLOCKED (published)\n")).toBe("BLOCKED");
    expect(reviewVerdict("**Verdict:** PASS | BLOCKED\n")).toBeUndefined();
  });

  it("copies the community post only from topic 2", () => {
    expect(scaffoldFiles(1)).toEqual(["post.md", "linkedin.md"]);
    expect(scaffoldFiles(2)).toEqual(["post.md", "linkedin.md", "community.md"]);
  });

  it("blocks publishing on a stale or blocked review, author markers or a dirty tree", () => {
    const r = (f: Parameters<typeof publishBlockers>[0]) => publishBlockers(f).map((x) => x.rule);
    expect(r({ review: "PASS", reviewFresh: true, markers: 0, dirty: false })).toEqual([]);
    expect(r({ review: "PASS", reviewFresh: false, markers: 0, dirty: false })).toEqual(["review-stale"]);
    expect(r({ review: "BLOCKED", reviewFresh: true, markers: 2, dirty: true })).toEqual(["review-not-pass", "author-markers", "dirty"]);
  });

  it("picks the post: argument, branch, then the latest one still open after the merge", () => {
    const posts = ["2026-11-12-a", "2026-11-13-b", "2026-11-24-c"].map((dir) => ({ dir }));
    const stages = new Map([["2026-11-12-a", "closed"], ["2026-11-13-b", "measure"], ["2026-11-24-c", "planned"]]);
    expect(resolvePost({ arg: "2026-11-12-a", posts, stages })).toBe("2026-11-12-a");
    expect(resolvePost({ branch: "feat/post-c", posts, stages })).toBe("2026-11-24-c");
    expect(resolvePost({ branch: "main", posts, stages })).toBe("2026-11-13-b");
    expect(resolvePost({ arg: "linkedin=https://x", branch: "main", posts, stages })).toBe("2026-11-13-b");
    expect(resolvePost({ branch: "feat/post-c", posts: [...posts, { dir: "2026-11-30-b-c" }], stages })).toBe("2026-11-24-c");
  });
});

describe("task helpers", () => {
  it("publishes through the front matter only", () => {
    const text = "---\ntitle: T\npublished: false\n---\n\npublished: false stays in the body\n";
    expect(setPublished(text)).toBe("---\ntitle: T\npublished: true\n---\n\npublished: false stays in the body\n");
    expect(setPublished("---\ntitle: T\n---\nb\n")).toBe("---\ntitle: T\npublished: true\n---\nb\n");
  });

  it("names a post's branch from its slug", () => {
    expect(postBranch("2026-11-24-sops-age")).toBe("feat/post-sops-age");
  });

  it("finds the next open topic without a folder", () => {
    const t = (id: string, tags: string[], due: string, position?: string, status = "Todo") => ({ id, status, description: id, tags, due, position });
    const todo = { comments: [], tasks: [
      t("a", ["topic-1", "post"], "2026-11-17T09:00:00", "docs/blog/posts/x"),
      t("b", ["topic-2", "in-between"], "2026-11-20T09:00:00"),
      t("c", ["topic-3"], "2026-12-01T09:00:00"),
      t("d", ["topic-2"], "2026-11-24T09:00:00"),
      t("e", ["topic-4"], "2026-11-10T09:00:00", undefined, "Done"),
    ] } as Todo;
    expect(nextTopicTask(todo)?.id).toBe("d");
  });
});

describe("voice pass rules", () => {
  const copyGood = () => {
    const dir = mkdtempSync(join(tmpdir(), "post-"));
    cpSync(join(FIX, "good"), dir, { recursive: true });
    return dir;
  };
  const rulesIn = (dir: string) => checkPost(dir, HYPE).map((f) => `${f.level}:${f.rule}`);

  it("lets a legacy post skip the content rules, never the raw-image rule", () => {
    const dir = mkdtempSync(join(tmpdir(), "post-"));
    writeFileSync(join(dir, "post.md"), "---\ntitle: Old\ndescription: d\ntags: a\nlegacy: true\n---\n<one line> ![x](./raw/a.png)\n");
    expect(rulesIn(dir)).toEqual(["block:raw-image"]);
  });

  it("blocks a new post without cover.json", () => {
    const dir = copyGood();
    rmSync(join(dir, "cover.json"));
    expect(rulesIn(dir)).toEqual(["block:cover-missing"]);
  });

  it("warns when the LinkedIn post is longer than 450 characters", () => {
    const dir = copyGood();
    writeFileSync(join(dir, "linkedin.md"), `## Post\n\nShort hook.\n\n${"word ".repeat(100)}\n\n## First comment\n\n{devto.url}\n`);
    expect(rulesIn(dir)).toEqual(["warn:linkedin-long"]);
  });

  it("accepts the topic keys and the new metrics", () => {
    for (const k of ["hook", "recipe", "sources"]) expect(parseComment(`${k}: x`)?.key).toBe(k);
    expect(parseRecordArgs(["series", "series", "recipe_reuse=2", "inbound=1"], "d").length).toBe(2);
    expect(parseRecordArgs(["p", "linkedin", "substantive_comments=3", "sends=4"], "d").length).toBe(2);
  });

  it("refuses to publish a new post without a fresh PASS", () => {
    const r = (f: Parameters<typeof publishGate>[0]) => publishGate(f).map((x) => x.rule);
    expect(r({ legacy: false, review: "PASS", fresh: true })).toEqual([]);
    expect(r({ legacy: false, review: "PASS", fresh: false })).toEqual(["review-stale"]);
    expect(r({ legacy: false, review: undefined, fresh: false })).toEqual(["review-not-pass"]);
    expect(r({ legacy: true, review: undefined, fresh: false })).toEqual([]);
  });
});

describe("coverHtml", () => {
  const tpl = readFileSync(join(REPO, "docs/blog/tools/cover.html"), "utf8");
  const spec = {
    title: ["My AI agent's", "for-loop"], highlight: "ran once", subtitle: "zsh doesn't split {y:$vars} {wink} and agents write bash",
    wink: "🪄", window: { kind: "terminal" as const, focused: true, lines: ["{p} for x in {y:$list}; do", "{r:[a b c]} {c:← once?!}", "{bar:60}", "{bar:40:hl}"] },
  };

  it("fills the series, both title lines, the highlight, the wink and the hashtags in their colours", () => {
    const html = coverHtml(tpl, spec, { series: 0, tags: ["zsh", "bash", "ai", "productivity", "macos"] });
    expect(html).toContain("dots #0");
    expect(html).toContain("My AI agent&#39;s<br>for-loop <span class=\"hl\">ran once</span>");
    expect(html).toContain("🪄");
    expect(html).toContain('<span class="h h1">#zsh</span><span class="h h2">#bash</span><span class="h h3">#ai</span><span class="h h4">#productivity</span><span class="h h1">#macos</span>');
  });

  it("draws the window: kind, name, focus, prompt, colours and bars", () => {
    const html = coverHtml(tpl, spec, { series: 0, tags: [] });
    expect(html).toContain('<div class="win focus">');
    expect(html).toContain('<span class="name">Ghostty</span>');
    expect(html).toContain('<span class="pr">❯</span> for x in <span class="y">$list</span>; do');
    expect(html).toContain('<div class="sk" style="width:60%"></div>');
    expect(coverHtml(tpl, { ...spec, window: { kind: "terminal", lines: ["  echo"] } }, { series: 0, tags: [] }))
      .toContain("<div>&nbsp;&nbsp;echo</div>");
    expect(html).toContain('<div class="sk hlbar" style="width:40%"></div>');
    const app = coverHtml(tpl, { ...spec, window: { kind: "app", name: "Notes", lines: ["{bar:50}"] } }, { series: 3, tags: [] });
    expect(app).toContain('<div class="win">');
    expect(app).toContain('<div class="app">');
    expect(app).toContain('<span class="name">Notes</span>');
  });

  it("escapes every author string, markup included", () => {
    const html = coverHtml(tpl, { ...spec, title: ["<script>", "a & b"], subtitle: "{y:<img src=x>}" }, { series: 1, tags: ['"><b>'] });
    expect(html).not.toContain("<script>");
    expect(html).not.toContain("<img src=x>");
    expect(html).toContain("&lt;script&gt;");
    expect(html).toContain("a &amp; b");
    expect(html).toContain("#&quot;&gt;&lt;b&gt;");
  });
});

describe("review fingerprint", () => {
  const copyGood = () => {
    const dir = mkdtempSync(join(tmpdir(), "post-"));
    cpSync(join(FIX, "good"), dir, { recursive: true });
    return dir;
  };

  it("ignores the published line and nothing else", () => {
    const dir = copyGood();
    const before = contentHash(dir);
    const post = readFileSync(join(dir, "post.md"), "utf8");
    writeFileSync(join(dir, "post.md"), post.replace("published: false", "published: true"));
    expect(contentHash(dir)).toBe(before);
    writeFileSync(join(dir, "post.md"), post.replace("A good post", "A good post!"));
    expect(contentHash(dir)).not.toBe(before);
  });

  it("changes when an image changes, appears or goes, and when a reviewed file is deleted", () => {
    const dir = copyGood();
    const a = contentHash(dir);
    cpSync(join(FIX, "good", "post.md"), join(dir, "images-x"));
    expect(contentHash(dir)).toBe(a);
    const { mkdirSync } = require("node:fs");
    mkdirSync(join(dir, "images"), { recursive: true });
    writeFileSync(join(dir, "images", "c.png"), "one");
    const b = contentHash(dir);
    expect(b).not.toBe(a);
    writeFileSync(join(dir, "images", "c.png"), "two");
    expect(contentHash(dir)).not.toBe(b);
    rmSync(join(dir, "cover.json"));
    expect(contentHash(dir)).not.toBe(b);
  });

  it("reads the stamp the gate writes into review.md", () => {
    expect(reviewStamp("**Verdict:** PASS\n\n<!-- reviewed: abc123 -->\n")).toBe("abc123");
    expect(reviewStamp("no stamp")).toBeUndefined();
  });
});

describe("leaks and escapes", () => {
  const rulesIn = (dir: string) => checkPost(dir, HYPE).map((f) => `${f.level}:${f.rule}`);

  it("blocks leftover hook options and unfilled cover placeholders", () => {
    const dir = mkdtempSync(join(tmpdir(), "post-"));
    cpSync(join(FIX, "good"), dir, { recursive: true });
    appendFileSync(join(dir, "post.md"), "\n<!-- hook options:\n1. a\n-->\n");
    writeFileSync(join(dir, "cover.json"), JSON.stringify({ title: ["<first title line>", "b"], highlight: "c", subtitle: "d", window: { kind: "app", lines: [] } }));
    expect(rulesIn(dir)).toEqual(["block:hook-options", "block:cover-placeholder"]);
  });

  it("escapes the series number too", () => {
    const tpl = readFileSync(join(REPO, "docs/blog/tools/cover.html"), "utf8");
    const html = coverHtml(tpl, { series: "<img src=x>" as unknown as number, title: ["a", "b"], highlight: "c", subtitle: "d", window: { kind: "app", lines: [] } }, { series: 0, tags: [] });
    expect(html).not.toContain("<img src=x>");
  });
});

describe("wiki layout", () => {
  const rulesIn = (dir: string) => checkPost(dir, HYPE).map((f) => `${f.level}:${f.rule}`);
  const withPost = (edit: (text: string) => string) => {
    const dir = mkdtempSync(join(tmpdir(), "post-"));
    cpSync(join(FIX, "good"), dir, { recursive: true });
    writeFileSync(join(dir, "post.md"), edit(readFileSync(join(dir, "post.md"), "utf8")));
    return dir;
  };

  it("finds Use it when only inside the TL;DR section", () => {
    const dir = withPost((t) => t.replace("> **Use it when:** an agent's loop runs once.\n", "").replace("## 🧠 Lessons", "## 🧠 Lessons\n\n> **Use it when:** later"));
    expect(rulesIn(dir)).toEqual(["block:tldr-use-it-when"]);
  });

  it("warns about sections out of order, and allows skipping Alternatives", () => {
    expect(rulesIn(withPost((t) => t))).toEqual([]);
    const swapped = withPost((t) => t.replace("## 🔍 Why it happens", "## 🔍 WHY").replace("## 🛠️ The fix", "## 🔍 Why it happens\n\n## 🛠️ The fix").replace("## 🔍 WHY\n\n", ""));
    expect(rulesIn(withPost((t) => t.replace("## 🧪 Check it works\n\n", "")))).toEqual(["warn:sections"]);
    expect(rulesIn(swapped)).toEqual([]);
  });

  it("blocks a post without the AI disclosure", () => {
    expect(rulesIn(withPost((t) => t.replace("Drafted with AI help; every claim was checked by me, and the story is mine.", "")))).toEqual(["block:ai-disclosure"]);
  });

  it("exempts a legacy post from the layout and the disclosure", () => {
    const dir = mkdtempSync(join(tmpdir(), "post-"));
    writeFileSync(join(dir, "post.md"), "---\ntitle: Old\ndescription: d\ntags: a\nlegacy: true\n---\n**OVERVIEW**\n");
    expect(rulesIn(dir)).toEqual([]);
  });
});
