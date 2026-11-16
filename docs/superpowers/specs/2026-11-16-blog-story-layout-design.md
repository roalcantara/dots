# Blog story layout (replaces the wiki layout)

**Status:** approved 2026-11-16 · supersedes [2026-11-13-blog-wiki-layout-design.md](2026-11-13-blog-wiki-layout-design.md)

## Intent

The wiki layout read like a form, and the preflight post's reason to exist wasn't clear. Fifteen variants were
rendered side by side (the variants page); the author picked **variant 15**: why it matters first, the real moment,
the fix under a linkable heading, in the author's own voice (asides, "..", "presto!", "NO, SERIOUSLY!", one wink).
It becomes the base for every post.

## Goals, non-goals, anti-goals

- **Goals:** the playbook's order holds. Goal 1 is served by `## The fix…` as a linkable heading (the RECIPE lives
  there); goal 2 by the lived story; goal 5 by the opening that says who is affected.
- **Non-goals:** a TL;DR block, emoji section headings, the **Use it when / You need / In dots** lines, a fixed
  word count (800–1,300 becomes a guideline, never a check).
- **Anti-goals (unchanged):** invented stories, hype, a RECIPE that needs the whole post.

## The layout

```text
<opening, no heading: who this hits and why, then the demo snippet and one line on it>
## How I ran into it…        the lived moment (STYLE: "The story is lived, never invented")
## The fix…                  one snippet per setting or step, then the check command and its output
## Why not …?                the alternatives and their catch (gotchas live here)
## What I (think I) learned  bold lessons; at least one mistake or limit
<the dots links, one line>
---
Corrections and ideas are very welcome. **NO, SERIOUSLY!** :)
> **DISCLAIMER** …          fixed text, the same in every post
Drafted with AI help; every claim was checked by me, and the story is mine.
```

## Approaches

1. **Split (picked):** the format change on `feat/content-series` (PR #111); the post on `feat/post-zsh-word-split`
   cut from it, following the README flow. Each PR has one job.
2. Everything on `feat/content-series`: one PR, but it mixes tooling and a post, and `blog:push-branch` refuses it.
3. Post first, format later: `blog:check` would block it.

**Check strictness: A (picked).** Headings matched by prefix, in order: `## How I ran into it`, `## The fix`,
`## Why not`, `## What I (think I) learned`. Block: no `## The fix` (the RECIPE), no AI line, the closing out of order
(Corrections → DISCLAIMER → AI line). Warn: other sections missing or out of order. B (only the fix and the closing)
was rejected: posts would stop looking alike.

## Changes

- **Docs:** STYLE.md ("Post layout", the DISCLAIMER and dev.to-conventions lines, the rubric's Layout row and its
  "Blocks when"), PLAYBOOK.md (Formats; the length is a guideline), `templates/post.md`, README's quick reference
  where it names the TL;DR.
- **Tooling:** `.mise/tasks/blog/_lib.ts` (sections, the fix block replacing `tldr-*`, the closing-order block; the
  gotchas count reads `## Why not`), the `wiki layout` tests and the `good/` fixtures, `/blog:draft` step 4,
  `/blog:gate`'s Layout row.
- **The post:** variant 15 with the DISCLAIMER moved to the closing; `linkedin.md` from 15's suggestion; the cover
  kept unless its text contradicts the post; `blog:check` and the gate pass before anything is pushed.

## Left to the builder

Exact wording of the check messages and the tests; whether the gotchas warning survives (`## Why not` holds prose,
so counting bullets may not fit; dropping it is fine).
