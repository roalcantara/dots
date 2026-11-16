# Blog cover safe area Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Covers survive LinkedIn's 1.91 : 1 crop and pass the phone test; `blog:cover` writes both previews.

**Architecture:** CSS changes in the cover template, one pure helper for the crop size, two `sips` calls in
`cover.ts`, and the docs.

**Tech Stack:** HTML/CSS, Bun + TypeScript, `bun test`, macOS `sips`.

**Spec:** [docs/superpowers/specs/2026-11-16-blog-cover-safe-area-design.md](../specs/2026-11-16-blog-cover-safe-area-design.md)

## Global Constraints

- Canvas 1000 × 420 (2000 × 840 rendered); content inside x 120–880; readable text ≥ 20 px; title 40 px.
- Previews go to `raw/` (never published): `00-cover-linkedin.png`, `00-cover-phone.png`.

## Review Focus

- A long title line (> ~18 characters) still overflows the left column: the content limits are documented, not
  checked; the LinkedIn preview is where the author sees it.

---

### Task 1: Template, previews and docs

**Files:** `docs/blog/tools/cover.html`, `.mise/tasks/blog/_lib.ts`, `.mise/tasks/blog/cover.ts`,
`test/integration/blog/blog.spec.ts`, `docs/blog/STYLE.md`, `docs/blog/templates/cover.json`,
`docs/blog/posts/2026-11-13-zsh-word-split/images/00-cover.png`

**Interfaces:** Produces `linkedinCropWidth(height: number): number` (`Math.round(height * 1.91)`).

- [ ] **Step 1: Failing tests** in `describe("coverHtml")`: `keeps readable text at 20 px or more and inside the
  safe area` (parse the template: `.sub`, `.h`, `.term`, `.app`, `.tag` sizes ≥ 20; `.bn` side padding ≥ 120) and
  `crops the cover to LinkedIn's card` (`linkedinCropWidth(840)` → `1604`).
- [ ] **Step 2: Run** `bun test test/integration/blog/blog.spec.ts` → the two FAIL.
- [ ] **Step 3: Implement** the template sizes, `linkedinCropWidth`, and the two `sips` previews in `cover.ts`.
- [ ] **Step 4: Run** the tests → PASS; `mise run blog:cover 2026-11-13-zsh-word-split`; look at the three images.
- [ ] **Step 5: Docs** (STYLE.md Cover row, phone test, Images rubric row; cover.json template limits); `hk check`.
- [ ] **Step 6: Commit** on `feat/blog-linkedin-formula`: `feat(blog): Keep the cover inside LinkedIn's crop and
  readable on a phone`.
