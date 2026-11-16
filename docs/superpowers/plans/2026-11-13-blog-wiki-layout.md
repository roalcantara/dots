# Blog: a wiki layout for posts — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Implement `docs/superpowers/specs/2026-11-13-blog-wiki-layout-design.md`.

**Spec:** `docs/superpowers/specs/2026-11-13-blog-wiki-layout-design.md`

## Global Constraints

Branch `feat/content-series`; SOPS git wrapper; named paths; Conventional Commits with the Claude co-author line;
no push. Gates: `mise run test:specs`, `hk check --all`, markdownlint. The Omarchy post is not touched.

## Review Focus

1. A legacy post is exempt from the layout and disclosure rules; safety rules still apply.
2. The TL;DR rule finds `**Use it when:**` only inside the `## ⚡ TL;DR` section.
3. Gotchas are counted as `###` headings inside `## ⚠️ Gotchas`.

---

### Task 1: Checks

- [ ] Tests first: `checkPost` blocks `tldr-missing` (no `## ⚡ TL;DR`), `tldr-use-it-when` (no `**Use it when:**`
  inside it), `ai-disclosure` (no line saying AI helped); warns `sections` (a required section missing or out of
  order; Alternatives optional) and `gotchas-over-3` (more than three `###` under `## ⚠️ Gotchas`); the fixtures
  follow the new layout; a legacy post skips all of these.
- [ ] Implement in `_lib.ts` (`SECTIONS` constant, shared with the template and docs). Commit
  `feat(blog): Check the wiki layout and the AI disclosure`.

### Task 2: Template, STYLE, commands

- [ ] `templates/post.md` in the layout; STYLE "Post layout" (sections, emoji rule, snippets, disclosure) and rubric;
  `/blog:draft` and the gate prompt follow; PLAYBOOK's formats line. Commit
  `docs(blog): Write posts in the wiki layout`.

### Task 3: The preflight post

- [ ] Rewrite `2026-11-13-zsh-word-split/post.md` in the layout (same lived-or-proven content, snippets for every
  command and setting, the hook marker and options under `🪲 The problem`, the disclosure line). `blog:check` shows
  only the author-marker and hook-options blocks. Commit `docs(blog): Rewrite the preflight post in the wiki layout`.
