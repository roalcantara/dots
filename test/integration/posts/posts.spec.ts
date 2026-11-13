#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  appendRows,
  articlePayload,
  assertSlug,
  checkPost,
  parseFrontMatter,
  parseRecordArgs,
  postOptions,
  pushAction,
  pushPreconditions,
  resolveArticleId,
  rewriteImages,
  rowsFromArticles,
  rowsFromReferrers,
  rowsFromTraffic,
  setFrontMatterId,
  visibleLength,
} from "../../../mise-tasks/posts/_lib";

const REPO = join(import.meta.dir, "../../..");
const FIX = join(import.meta.dir, "fixtures");
const HYPE = readFileSync(join(REPO, "docs/posts/hype-words.txt"), "utf8")
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

describe("setFrontMatterId", () => {
  const text = "---\ntitle: T\npublished: false\n---\n\nbody: keep me\n";

  it("adds the id after the title and keeps the body", () => {
    const out = setFrontMatterId(text, 123);
    expect(out).toBe("---\ntitle: T\nid: 123\npublished: false\n---\n\nbody: keep me\n");
  });

  it("replaces an existing id", () => {
    expect(setFrontMatterId("---\ntitle: T\nid: 9\n---\nb\n", 10)).toBe("---\ntitle: T\nid: 10\n---\nb\n");
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
      "block:recipe-missing",
      "block:recipe-use-it-when",
      "block:raw-image",
      "block:linkedin-missing",
      "warn:hype-word",
      "warn:gotchas-over-3",
    ]) expect(got).toContain(r);
  });

  it("warns about a LinkedIn hook over 210 characters", () => {
    expect(rules("long-hook")).toEqual(["warn:hook-over-210"]);
  });
});

describe("visibleLength", () => {
  it("counts what a reader sees", () => {
    expect(visibleLength("você 👋🏽")).toBe(6);
    expect(visibleLength("a".repeat(210))).toBe(210);
  });
});

describe("assertSlug", () => {
  it("accepts a post folder name", () => {
    expect(assertSlug("zsh-word-split")).toBe("zsh-word-split");
  });

  it("rejects folders that are not posts and paths", () => {
    for (const s of ["templates", "tools", "prompts", "", "../x", "a/b"]) expect(() => assertSlug(s)).toThrow();
  });
});

describe("rewriteImages", () => {
  it("points relative images at the ref on GitHub and leaves absolute links alone", () => {
    const out = rewriteImages("![a](images/x.png) ![c](./images/z.png) ![b](https://e.com/y.png)", "s", "main");
    const base = "https://raw.githubusercontent.com/roalcantara/dots/main/docs/posts/s/images";
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
    expect(article.main_image).toBe("https://raw.githubusercontent.com/roalcantara/dots/main/docs/posts/s/images/c.png");
    expect(article.body_markdown).toContain("/main/docs/posts/s/images/x.png");
    expect(article).toMatchObject({ title: "T", description: "D", tags: ["ai"] });
  });

  it("never takes a live article offline", () => {
    const live = { slug: "s", ref: "feat/x", draft: true, live: true };
    expect("published" in articlePayload(fm, "b", live).article).toBe(false);
    expect("published" in articlePayload({ ...fm, published: false }, "b", { ...live, ref: "main", draft: false }).article)
      .toBe(false);
    expect(articlePayload(fm, "b", { ...live, ref: "main", draft: false }).article.published).toBe(true);
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
  it("prefers the recorded id, then the same title", () => {
    expect(resolveArticleId({ tags: [], title: "T" }, [{ id: 7, title: "T" }])).toBe(7);
    expect(resolveArticleId({ tags: [], title: "T", id: 3 }, [{ id: 7, title: "T" }])).toBe(3);
    expect(resolveArticleId({ tags: [], title: "New" }, [{ id: 7, title: "T" }])).toBeUndefined();
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

  it("appends without touching earlier lines", () => {
    const csv = join(mkdtempSync(join(tmpdir(), "posts-")), "stats.csv");
    const before = "date,slug,platform,metric,value,source\n2026-01-01,a,devto,views,1,api\n";
    writeFileSync(csv, before);
    appendRows(csv, [{ date: "2026-11-13", slug: "b", platform: "devto", metric: "views", value: 2, source: "api" }]);
    const after = readFileSync(csv, "utf8");
    expect(after.startsWith(before)).toBe(true);
    expect(after.slice(before.length)).toBe("2026-11-13,b,devto,views,2,api\n");
  });

  it("writes the header for a new file", () => {
    const csv = join(mkdtempSync(join(tmpdir(), "posts-")), "stats.csv");
    appendRows(csv, []);
    expect(readFileSync(csv, "utf8")).toBe("date,slug,platform,metric,value,source\n");
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

describe("header.py (series cover)", () => {
  const uv = Bun.which("uv");

  it.skipIf(!uv)("draws a 1000 × 420 PNG from a title, a series number and key caps", () => {
    const out = join(mkdtempSync(join(tmpdir(), "posts-")), "cover.png");
    const p = Bun.spawnSync(
      ["uv", "run", "--quiet", "--with", "pillow", join(REPO, "docs/posts/tools/header.py"), out,
        "--title", "Test", "--highlight", "cover", "--series", "0", "--keys", "zsh,bash"],
      { stdout: "pipe", stderr: "pipe" },
    );
    expect(p.stderr.toString()).toBe("");
    expect(p.exitCode).toBe(0);
    const png = readFileSync(out);
    expect(png.subarray(1, 4).toString()).toBe("PNG");
    expect([png.readUInt32BE(16), png.readUInt32BE(20)]).toEqual([1000, 420]);
  }, 60_000);
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
