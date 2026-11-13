# Blog: voice, brevity, cover and a leaner playbook — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Implement `docs/superpowers/specs/2026-11-13-blog-voice-design.md`.

**Architecture:** Pure functions in `.mise/tasks/blog/_lib.ts` (tested in `test/integration/blog/blog.spec.ts`) for the
cover HTML, the new check rules, freshness and the publish gate; a cover template rendered by headless Chrome; docs,
commands and `TODO.yaml` data updated; the preflight post reworked.

**Spec:** `docs/superpowers/specs/2026-11-13-blog-voice-design.md`

## Global Constraints

- Branch `feat/content-series`; git through the SOPS wrapper; named paths only; Conventional Commits with the Claude
  co-author line; no push, PR, merge or publish.
- Gates: `mise run test:specs`, `hk check --all`, `markdownlint-cli2` on touched Markdown.

## Review Focus

1. A commit that only flips `published:` must not make a review stale; any other change to the reviewed files must.
2. A legacy post skips content rules but never safety or `raw/` images.
3. CI on `main` must refuse to publish a non-legacy post without a fresh PASS, and change nothing on dev.to then.
4. Cover HTML escapes every author string; markup can't inject tags.
5. No hook option reaches `post.md` without the author's pick.

---

### Task 1: Rules in `_lib.ts`

- [ ] Tests first: `legacy: true` skips `recipe-*`, `linkedin-missing`, `placeholder`, `author-marker`,
  `cover-missing` but still blocks `raw-image`; `linkedin-long` warns over 450 characters (the `## Post` section);
  `cover-missing` blocks a non-legacy post without `cover.json`; `parseComment` accepts `hook`, `recipe`, `sources`;
  `parseRecordArgs` accepts platform `series` and metrics `substantive_comments`, `sends`, `recipe_reuse`,
  `inbound`; `onlyPublishedChanged(diff)` is true for a diff touching only the `published:` line;
  `publishGate({legacy, review, fresh})` blocks a non-legacy post without a fresh PASS.
- [ ] Implement; `reviewIsFresh` watches `post.md`, `linkedin.md`, `community.md`, `cover.json`, `images/` and
  ignores commits for which `onlyPublishedChanged`; `push.ts` applies `publishGate` when publishing (CI included).
- [ ] `done.ts`: stop on a failing step without committing, list what was written, skip a URL comment already
  recorded.
- [ ] Commit `feat(blog): Legacy posts, cover and LinkedIn checks, a publish gate in CI`.

### Task 2: The cover

- [ ] Tests first: `coverHtml(spec, {series, tags})` puts both title lines, the highlight, the wink, the hashtags in
  the colour cycle, the window kind, name and focus; escapes `<`, `&`, `"` in every string; renders markup
  `{p}`, `{y:…}`, `{r:…}`, `{g:…}`, `{c:…}`, `{bar:N}`, `{bar:N:hl}`.
- [ ] `docs/blog/tools/cover.html` (from the approved asset); `blog:cover <post>` reads `cover.json`, fills the
  template, finds Chrome (app bundle, then PATH), renders 2× into `images/00-cover.png`.
- [ ] `tools/frame.py` restyled: Mocha base background, OmniWM title bar (traffic lights, app name) around the
  capture; `--app` names the window. Retire `tools/header.py` and its test.
- [ ] Commit `feat(blog): Render covers from the approved Catppuccin template`.

### Task 3: Commands, STYLE, PLAYBOOK, README, templates

- [ ] `/blog:draft`: hook options (3–5, each with its repo fact and what to confirm, the author picks; skipped →
  marker + `<!-- hook options -->`), lived-or-proven, the LinkedIn shape, writes `cover.json` and runs `blog:cover`.
  `/blog:gate`: unproven general claim = Must fix; the lived rule. `/blog:retro`: the new metrics and unknowns.
  `/blog:pick`: reads `hook:`/`recipe:`/`sources:` and theme tags.
- [ ] STYLE: the hook trait, lived-or-proven, LinkedIn shape and alt text, the new visual identity; templates
  (`linkedin.md`, a `cover.json`); README: "source" vs "canonical"; PLAYBOOK slimmed per the design; specs get the
  historical banner.
- [ ] Commit `docs(blog): One voice, lived or proven claims, short LinkedIn posts, a timeless playbook`.

### Task 4: Roadmap data

- [ ] Through the todo CLI: theme tags on topic tasks; `hook:`, `recipe:`, `sources:` comments from the old topics
  table; backlog topics as `topic-backlog` tasks with their data. Commit `chore(blog): Move topic data into the roadmap`.

### Task 5: The posts

- [ ] Omarchy: `legacy: true`. Preflight: cut the bashrc and Intel lines, qualify "agents write bash", LinkedIn in
  the new shape, `cover.json` + new cover, screenshot re-framed, hook options under an `<author: …>` marker.
- [ ] `blog:status`: Omarchy `measure`, preflight `drafting` (waiting on the author's hook). Gates green.
- [ ] Commit `docs(blog): Rework the preflight post and mark the Omarchy post legacy`.
