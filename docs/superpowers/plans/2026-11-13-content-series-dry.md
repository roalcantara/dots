# Content series: DRY the structure — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** fnox for the token, argv instead of `usage_*` variables, `docs/blog/posts/<YYYY-MM-DD>-<slug>/`
folders, and every post's metadata as comments on its `TODO.yaml` task.

**Architecture:** `_lib.ts` gains a `TODO.yaml` reader (`Bun.YAML`), the comment schema (parse/format), and a todo
CLI writer; tasks parse argv with `parseArgs`; `posts:report` regenerates the README index.

**Spec:** `docs/superpowers/specs/2026-11-13-content-series-dry-design.md`

## Global Constraints

Same as `2026-11-13-content-series-preflight.md` (branch `feat/content-series`, SOPS git wrapper, named paths,
Conventional Commits, no push without the author). Quality gate: `mise run test:specs`, `hk check --all`.

## Review Focus

1. A published post moved to `posts/` must keep working: its next push from main serves images from the new path.
2. A malformed comment must be reported, not crash a report or vanish.
3. `assertPost` must accept only `YYYY-MM-DD-<slug>` folder names.
4. CI must never write to the repo.
5. The token never appears in argv or output (fnox `get` output is captured, never printed).

---

### Task 1: fnox and argv

- [ ] Tests: `postOptions(["2026-11-13-x","--ref","main","--draft"])` → `{ post, ref: "main", draft: true }`;
  `postOptions(["--ref=main","2026-11-13-x"])` → same ref; unknown flag throws.
- [ ] `fnox.toml` (references only); `token()` → `DEVTO_TOKEN` env, else `fnox get DEVTO_TOKEN`; tasks parse argv
  with `parseArgs`; no `usage_*` reads. Verify `mise run posts:stats` resolves the token through fnox.
- [ ] Commit `refactor(posts): Read the token through fnox and arguments from argv`.

### Task 2: Chronological folders

- [ ] Tests: `assertPost("2026-11-13-zsh-word-split")` passes; `"zsh-word-split"`, `"templates"`, `"2026-13-01-x"`,
  `"../x"` throw; `rewriteImages(…, "2026-11-13-x", "main")` → `…/docs/blog/posts/2026-11-13-x/images/…`.
- [ ] `g mv` the two posts to `posts/2026-11-12-omarchy-on-macos` and `posts/2026-11-13-zsh-word-split` (their
  `raw/` moved by hand); `.gitignore` → `docs/blog/posts/*/raw/`; the workflow's paths and folder cut; docs.
- [ ] Commit `refactor(posts): Keep posts in dated folders under docs/blog/posts`.

### Task 3: Metadata in TODO.yaml

- [ ] Tests: `parseComment("devto.id: 5")` → `{ key: "devto.id", value: "5" }`; `parseStats("2026-11-13 devto
  views=30 reactions=0 (api)")` → 2 rows; malformed → `undefined` and listed by `invalidComments`;
  `formatStats(rows)` round-trips; `postsFromTodo(yaml)` maps a task with tag `post` and a `position` to
  `{ dir, taskId, title, status, due, meta }`.
- [ ] `posts:push` reads/writes `devto.id` comments (no front matter id); `posts:stats` records rows and missing
  ids; `posts:record` writes `stats … (manual)`; the workflow drops its write-back step; `posts:report` prints and
  rewrites the README index. Migrate: baseline and repo traffic → series task; Omarchy and preflight post tasks with
  positions and `devto.id`; remove `stats.csv`, `LOG.md`, the front matter `id:` lines.
- [ ] PLAYBOOK (flow, schema, decisions log), STYLE/gate/next-pick/templates references updated.
- [ ] Commit `refactor(posts): Keep every post's metadata in TODO.yaml`.
