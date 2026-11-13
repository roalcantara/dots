# Blog: one command per step — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Every QUICK REFERENCE step becomes a `blog:*` mise task or a `/blog:*` agent command, with a tested stage
function behind `blog:status` and `/blog:next`, and every doc and reference updated.

**Architecture:** `.mise/tasks/blog/` (renamed from `posts/`) gains `status`, `new`, `cover`, `publish`, `done`,
`push-branch`, sharing pure functions in `_lib.ts` (`stageOf`, `resolvePost`, `isTopicTask`, `placeholders`,
`reviewFresh`, `scaffoldFiles`, `publishBlockers`). Agent commands live in `.agents/commands/blog/`, read by Claude
Code through a `.claude/commands` → `../.agents/commands` symlink. `docs/blog/prompts/` folds into the commands.

**Tech Stack:** Bun (`bun:test`), mise file tasks, the todo CLI, gh, git (SOPS wrapper), Markdown commands.

**Spec:** `docs/superpowers/specs/2026-11-13-blog-commands-design.md`

## Global Constraints

- Branch `feat/content-series`, main checkout; git through `g()`; named paths only; Conventional Commits with the
  Claude co-author line.
- Agent commands never merge, push to `main` or publish (prompt + `allowed-tools`, the author's choice).
- Writes after the merge commit locally (`chore(blog): …`) and stop; the author pushes.
- Every doc and reference follows the rename; a final search finds no `posts:`, `.mise/tasks/blog`,
  `prompts/gate.md`, `prompts/next-pick.md` or `blog.yml` outside history.
- Gates: `mise run test:specs`, `hk check --all`, actionlint on the workflow.

## Review Focus

1. A merged post must not fall back to `pr` (end states first).
2. The Omarchy post (Done, published, no `linkedin.md`) is `measure` or `closed`, never `drafting`.
3. On `main` with no `<post>`, post-merge commands pick the latest non-closed post, never the next unstarted topic.
4. `blog:publish` refuses a stale or BLOCKED review and any `<author: …>` marker.
5. `/blog:pr` refuses unless the stage is `pr`.

---

### Task 1: Rename `posts` → `blog`

- [ ] `g mv .mise/tasks/posts .mise/tasks/blog`, `g mv test/integration/posts test/integration/blog`,
  `g mv .github/workflows/posts.yml .github/workflows/blog.yml` (name `Blog`, concurrency `blog`, task path,
  `<!-- blog-bot -->`); `test/mise.toml` domain `blog`; `hk.pkl` fixture exclude; every `posts:<task>` in code and
  docs → `blog:<task>`; task descriptions.
- [ ] Verify: `mise tasks ls | grep blog:` lists the six existing tasks; `mise run -C test integration blog all`
  passes; actionlint clean.
- [ ] Commit `refactor(blog): Rename the posts tasks, tests and workflow to blog`.

### Task 2: Stages and helpers (pure, tested)

Interfaces (in `_lib.ts`):

- `isTopicTask(t: TodoTask): boolean` — exactly one `topic-<n>` tag, no `in-between`/`community`.
- `topicNumber(t: TodoTask): number` — n, or 0 (preflight and posts without a topic tag).
- `placeholders(text: string): string[]` — `<…>` that is not `<author: …>`, an HTML comment or a known tag.
- `authorMarkers(text: string): string[]` — `<author: …>` occurrences.
- `reviewFresh(reviewTime?: number, postTime?: number): boolean`.
- `type Facts = { task?: TodoTask; hasFolder; checkBlocks; review?: "PASS" | "BLOCKED"; reviewFresh; pr?: "open" | "merged"; published; markers: number; devtoUrl; linkedinUrl; taskDone; logKeep }`
- `stageOf(f: Facts): { stage: Stage; next: string }` — the spec's end-states-first order.
- `resolvePost(o: { arg?: string; branch?: string; posts: Post[]; stages: Map<string, Stage>; phase: "plan" | "after" | "any" }): string | undefined`.
- `scaffoldFiles(topic: number): string[]` — `post.md`, `linkedin.md`, plus `community.md` when topic ≥ 2.
- `publishBlockers(f: { review?: string; reviewFresh: boolean; markers: number; dirty: boolean }): Finding[]`.

- [ ] Tests first: one per stage row (including merged → not `pr`; Omarchy-shaped facts → `measure`/`closed`;
  published + PR open → `merge`); `isTopicTask` on in-between/community/preflight tasks; `placeholders` ignores
  `<!-- … -->`, `<img>`, `<author: x>`; `resolvePost` on `main` after the merge picks the latest non-closed post;
  `scaffoldFiles(1)` has no `community.md`; `publishBlockers` for stale, BLOCKED, markers, dirty.
- [ ] Implement; `checkPost` blocks `placeholder` and warns `author-marker`.
- [ ] Commit `feat(blog): Compute a post's stage and its next step`.

### Task 3: The new mise tasks

- [ ] `blog:status [post]` (facts from TODO.yaml, files, `git log -1 --format=%ct`, `gh pr list --head <branch>
  --state all --json state`; prints stage and next; all posts when none); `blog:new <slug> [--task] [--date]`
  (clean tree, `git switch -c feat/post-<slug> main`, `scaffoldFiles`, `images/`, `raw/`, task tag + position,
  commit `docs(blog): Start "<slug>"`); `blog:cover <post> --title [--highlight] [--subtitle] --keys` (series from
  `topicNumber`); `blog:publish <post>` (`publishBlockers`, `published: true`, commit `post.md`, `blog:push-branch`);
  `blog:done <post> [--linkedin] [--community]` (url comments, stats, task done, README index, commit
  `chore(blog): …`, no push); `blog:push-branch` (pushes the current `feat/post-*` branch through the SOPS wrapper;
  refuses `main`). `blog:stats`/`blog:record` commit their TODO.yaml changes locally.
- [ ] Live checks: `blog:status` shows Omarchy `measure` and the preflight `pr`; `blog:new --help`, a dry
  `blog:cover` into a temp file.
- [ ] Commit `feat(blog): Add status, new, cover, publish, done and push-branch tasks`.

### Task 4: Agent commands

- [ ] `.agents/commands/blog/{next,pick,draft,gate,pr,share,retro}.md` in the house style (front matter with
  `description`, `argument-hint`, `allowed-tools`; `<task>`, `<context>` with `!mise run -q blog:status …` and `@`
  references to PLAYBOOK/STYLE/templates, `<workflow>`, `<checklist>`); bodies of `pick` and `gate` from
  `docs/blog/prompts/*` (then remove the folder); `.claude/commands` → `../.agents/commands` symlink.
- [ ] Verify: the symlink resolves; markdownlint clean (exclusions only for this folder if needed).
- [ ] Commit `feat(blog): Add the /blog agent commands`.

### Task 5: Docs and references

- [ ] `docs/blog/README.md` QUICK REFERENCE → the command list; PLAYBOOK "How a post moves" and "Choosing the next
  topic" → commands; STYLE/templates references; `README.md` and `AGENTS.md` (layout, test domains, docs list,
  `.agents/commands`); content-series specs and plans; decisions log entry.
- [ ] Repo-wide search per Global Constraints is empty outside history; gates green.
- [ ] Commit `docs(blog): Point the docs at the blog commands`.
