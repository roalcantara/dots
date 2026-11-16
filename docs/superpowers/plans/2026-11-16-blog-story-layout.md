# Blog story layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the wiki layout with the story layout (variant 15) in the checks, docs and commands, then ship the
preflight post in it.

**Architecture:** `blog:check` (`.mise/tasks/blog/_lib.ts`) enforces the new section prefixes and the closing order;
the docs and commands describe the same shape; the post moves to its own `feat/post-zsh-word-split` branch.

**Tech Stack:** Bun + TypeScript (mise tasks, `bun test`), Markdown, the existing `blog:*` tasks.

**Spec:** [docs/superpowers/specs/2026-11-16-blog-story-layout-design.md](../specs/2026-11-16-blog-story-layout-design.md)

## Global Constraints

- Sections, matched by prefix, in order: `## How I ran into it`, `## The fix`, `## Why not`,
  `## What I (think I) learned`. `## Why not` is optional (skip it when there is no real alternative).
- The closing, in order: `Corrections and ideas are very welcome.` → `> **DISCLAIMER**` → `Drafted with AI help; every
  claim was checked by me, and the story is mine.`
- Blocks: no `## The fix` (`fix-missing`); the closing missing a part or out of order, or a DISCLAIMER above the last
  `## ` heading (`closing-order`). Warnings: other sections missing or out of order (`sections`).
- No TL;DR, no **Use it when / You need / In dots**, no emoji on headings; 800–1,300 words is a guideline, never checked.
- Legacy posts (`legacy: true`) keep skipping content rules.
- Nothing is pushed before the author approves the post preview (Task 3).

## Review Focus

- A post that keeps the old DISCLAIMER on top *and* adds one at the bottom: expect `block:closing-order` (Task 1 test).
- Headings with post-specific endings (`## The fix: two settings`, `## Why not change zsh instead?`): expect no
  findings (Task 1, the `good` fixture).
- The Omarchy legacy post: `mise run blog:check 2026-11-12-omarchy-on-macos` still prints no blocks (Task 1, Step 4).
- A heading inside a fenced code block: out of scope, accepted as is (sectionBody ignores fences today).
- `bad` still reports its voice and gotcha warnings after the rename (Task 1 test).

---

### Task 1: `blog:check` enforces the story layout

**Files:**
- Modify: `.mise/tasks/blog/_lib.ts:75-133` (gotchaCount, SECTIONS, OPTIONAL, the `tldr-*` blocks)
- Modify: `test/integration/blog/blog.spec.ts:69-99, 568-598`
- Modify: `test/integration/blog/fixtures/good/post.md`, `fixtures/long-hook/post.md`, `fixtures/bad/post.md`

**Interfaces:**
- Produces: `SECTIONS = ["## How I ran into it", "## The fix", "## Why not", "## What I (think I) learned"]`;
  `OPTIONAL = new Set(["## Why not"])`; rules `block:fix-missing`, `block:closing-order`; `gotchaCount` reads
  `## Why not`. `sectionBody` and `sectionsOrder` keep their signatures.

- [ ] **Step 1: Rewrite the fixtures.** `good/post.md` and `long-hook/post.md` (same body): front matter unchanged;
  an opening paragraph; `## How I ran into it…`, `## The fix: two settings` (with one ```json snippet),
  `## Why not change zsh instead?` (two `-` bullets), `## What I (think I) learned`; then `---`,
  `Corrections and ideas are very welcome. **NO, SERIOUSLY!** :)`, `> **DISCLAIMER** Not a tutorial.`, the AI line.
  `bad/post.md`: rename `## ⚠️ Gotchas` to `## Why not just quote it?` (keep its four `###`).
- [ ] **Step 2: Write the failing tests.** In `checkPost`: replace `"block:tldr-missing"` with `"block:fix-missing"`
  and add `"block:closing-order"` to the `bad` list. Rename `describe("wiki layout")` to `describe("story layout")`
  and replace its first two tests with:
  - `blocks a post without The fix`: remove the `## The fix: two settings` line →
    `["block:fix-missing", "warn:sections"]`.
  - `warns about sections out of order, and allows skipping Why not`: move `## How I ran into it…` with its text
    below The fix → `["warn:sections"]`; delete the `## Why not…` section → `[]`.
  - `blocks the closing out of order`: swap the Corrections and DISCLAIMER lines → `["block:closing-order"]`; also
    insert `> **DISCLAIMER** Not a tutorial.` above the first `##` (keeping the bottom one) → `["block:closing-order"]`.
  Keep the AI-disclosure and legacy tests as they are.
- [ ] **Step 3: Run** `bun test test/integration/blog/blog.spec.ts`. Expected: the new tests FAIL (`tldr-missing`
  still reported, no `fix-missing`/`closing-order`).
- [ ] **Step 4: Implement in `_lib.ts`.** New SECTIONS/OPTIONAL as above (comment points to STYLE.md "Post layout").
  Replace the two `tldr-*` blocks with `fix-missing` ("no `## The fix` section (the RECIPE lives there)"). Add
  `closing-order` when the AI line is present: the Corrections line, the last `**DISCLAIMER**` and the AI line must
  all exist, in that order, and no `**DISCLAIMER**` may sit above the last `## ` heading. Message: "the closing must be
  Corrections → DISCLAIMER → AI line, after the last section". `gotchaCount` reads `## Why not`.
- [ ] **Step 5: Run** `bun test test/integration/blog/blog.spec.ts` → all PASS; then
  `mise run blog:check 2026-11-12-omarchy-on-macos` → no BLOCK lines.
- [ ] **Step 6: Commit** on `feat/content-series`:
  `feat(blog): Check the story layout instead of the wiki layout` (the four files above).

### Task 2: Docs and commands describe the story layout

**Files:**
- Modify: `docs/blog/STYLE.md` (the uncommitted "story is lived" rule; "Writing rules" dev.to-conventions line;
  "Post layout" table and bullets; rubric Layout row and its "Blocks when")
- Modify: `docs/blog/PLAYBOOK.md` (Intent's "a TL;DR the author and readers come back to" → the fix under
  `## The fix`; Formats: the story layout, "800–1,300 words as a guideline"; anti-goal wording unchanged)
- Modify: `docs/blog/templates/post.md` (the spec's layout, with `<…>` placeholders; no body cover image, since
  dev.to shows `cover_image` already)
- Modify: `docs/blog/README.md:3-4` ("ends in a RECIPE, a TL;DR…" → "ends in the fix")
- Modify: `.agents/commands/blog/draft.md` step 4 (story layout; length a guideline), `.agents/commands/blog/gate.md`
  Layout row (the four sections by prefix, the closing order)
- Modify: `docs/superpowers/specs/2026-11-13-blog-wiki-layout-design.md` (first line: "Superseded by
  2026-11-16-blog-story-layout-design.md")
- Add: this plan and the spec

- [ ] **Step 1:** Make the edits above. The layout table in STYLE.md has one row per part: Opening (who this hits and
  why, the demo snippet), How I ran into it, The fix (one snippet per setting, the check and its output), Why not
  (alternatives and their catch), What I (think I) learned (bold lessons, a mistake or limit), Closing (dots links,
  Corrections, DISCLAIMER, AI line). Voice bullets keep the author's tics (asides, "..", "presto!", "NO, SERIOUSLY!",
  one wink).
- [ ] **Step 2: Verify** `grep -rnE 'TL;DR|Use it when|wiki layout' docs/blog .agents/commands/blog` → only historical
  mentions (none in STYLE, PLAYBOOK, template, README, draft, gate). `hk check` on the changed files passes.
- [ ] **Step 3: Commit** on `feat/content-series`: `docs(blog): Describe the story layout and adopt it in the commands`.

### Task 3: The post in the story layout, validated locally

**Files:**
- Branch: `git switch -c feat/post-zsh-word-split` from `feat/content-series`
- Modify: `docs/blog/posts/2026-11-13-zsh-word-split/post.md`, `linkedin.md`, `cover.json`, `images/00-cover.png`,
  `review.md`

- [ ] **Step 1: `post.md`** = variant 15's Markdown (the variants page, Markdown view) with the DISCLAIMER moved
  between the Corrections line and the AI line. Front matter: `title: "Your AI agent writes bash. Your Mac runs zsh."`,
  description "Since Catalina, a new Mac's shell is zsh, and Claude Code runs its commands in it. One unquoted $var
  later, an agent's loop over 16 file types ran once and exited 0.", tags unchanged, `cover_image` unchanged.
- [ ] **Step 2: `linkedin.md`** `## Post` = 15's LinkedIn text (320 characters, hook 132), hashtags `#AI #zsh #macOS`;
  `## First comment` = `{devto.url}`; drop the stale "In-between post" note.
- [ ] **Step 3: Cover.** `cover.json` title lines and highlight from the new title (e.g. `["Your AI agent", "writes
  bash. Your Mac"]`, highlight `runs zsh`); keep the subtitle's 💍 wink and the terminal lines. Run
  `mise run blog:cover 2026-11-13-zsh-word-split`, look at the image once (phone test).
- [ ] **Step 4: Validate.** `mise run blog:check 2026-11-13-zsh-word-split` → no BLOCK; then `/blog:gate` (fresh
  agent, writes `review.md`) → PASS, STEPPS raw ≥ 6.
- [ ] **Step 5: Preview.** Republish the variants page with a "Final" entry rendering `post.md` and `linkedin.md` as
  committed-to-be; ask the author to approve. **Stop here until they do.**

### Task 4: Commit, push, draft, references

- [ ] **Step 1: Commit** on `feat/post-zsh-word-split`: `docs(blog): Rewrite the preflight post in the story layout`
  (the post folder).
- [ ] **Step 2: Push** `feat/content-series` (`git push`, updates PR #111), then `/blog:pr` for the post (PR base
  `feat/content-series` until #111 merges; pass `--base` if the command assumes `main`).
- [ ] **Step 3: Draft.** `mise run blog:push 2026-11-13-zsh-word-split` → a dev.to draft; open its preview once and
  compare with the local preview (cover loads, code blocks, closing).
- [ ] **Step 4: References.** `mise run blog:report --write` (README index picks up the new title); commit
  `docs(blog): Index the preflight post's new title` and push.
- [ ] **Step 5: Report** the numbered next moves (merge order #111 → post PR → `blog:publish`; `/blog:share`; 48 h
  stats; whether `/blog:draft` should search session transcripts for the moment).
