#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import {
  assertSlug,
  checkPost,
  parseFrontMatter,
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
