# Content series: setup and preflight post — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the series' home in `docs/blog/` (playbook, style, log, numbers, roadmap, templates, gate) and its
tooling (bun mise file tasks and a CI workflow on the Forem API), then publish one small real post end to end to
prove the flow before topic 1.

**Architecture:** Bun file tasks in `.mise/tasks/posts/` (`posts:check`, `posts:push`, `posts:stats`,
`posts:record`, `posts:todo`) share pure, tested functions in a non-executable `.mise/tasks/posts/_lib.ts`.
`.github/workflows/posts.yml` runs the same push task: a PR creates or updates a dev.to **draft**, the merge to
`main` publishes according to the front matter. Documents, templates and agent prompts live in `docs/blog/`.

**Tech Stack:** Bun (from the Brewfile; `bun:test`), mise file tasks (`//MISE`, `//USAGE` headers), Forem API v1
(`https://dev.to/api`, header `api-key`), GitHub Actions, `github:RayanBO/todo@0.2.9` (YAML storage), Python +
Pillow via `uv` for images, gopass.

**Spec:** `docs/superpowers/specs/2026-11-13-content-series-design.md`

## Global Constraints

- Work on branch `feat/content-series` in `~/.local/share/dots` (no worktree). Git through the SOPS wrapper:
  `g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }`. Stage named paths only.
- No push, PR, merge or publish without the author's explicit go in the moment. Steps marked **(author)** are theirs.
- Conventional Commits with a capitalised description; end with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- dev.to token: gopass `tokens/dev.to` locally, repo secret `DEVTO_TOKEN` in CI (both exist). It reaches code only
  as the `DEVTO_TOKEN` environment variable, never as an argument, never printed, never in a repo file.
- **Every tool from `config/homebrew/Brewfile` whenever possible.** Already there: bun, uv, gh, gopass, node,
  markdownlint-cli2. Exception: `todo` (RayanBO/todo) has no formula and the cargo name `todo-cli` is another crate,
  so it is pinned in its file task's `//MISE tools` header and named in a Brewfile comment.
- Language: English everywhere, the preflight post included.
- dev.to front matter: `title`, `published` (false until the author publishes), `description`, `tags` (max 4),
  `cover_image`, `id` (written by the tooling). Cover 1000 × 420.
- LinkedIn hook ≤ 210 characters; post 900–1,300 characters; the dev.to link in the first comment.
- Voice: "a colleague's notebook, made public"; zero hype words; at least one mistake or limit stated.
- Unblurred captures only in `docs/blog/<slug>/raw/` (git-ignored).
- Quality gate before declaring done: `mise run test:specs`, `hk check --all`.

## Review Focus

1. **A PR going live before the merge:** the PR job must send `published: false` whatever the front matter says.
   Pinned by an `articlePayload` test (Task 2).
2. **Duplicate articles:** a merge that lands before the PR job recorded the `id`, or a post published by hand (the
   Omarchy post), must update the existing article, found by title, not create a second one. Pinned by a
   `resolveArticleId` test (Task 2).
3. **Images that 404:** relative image links must point at the pushed ref on GitHub; publishing must come from
   `main`. Pinned by `rewriteImages` and `pushPreconditions` tests (Task 2).
4. **Pushing the wrong folder:** `templates`, `tools`, `prompts` or a path with `/` or `..` is never a post slug,
   though `docs/blog/templates/post.md` matches the workflow's path filter. Pinned by `assertSlug` tests (Task 2).
5. **Partial numbers and hook length:** a missing API field yields no row, not 0; a hook with "você" or an emoji is
   measured in visible characters (Tasks 1–2).

---

## File Structure

```text
.mise/tasks/posts/
├── _lib.ts            # pure functions (not a task: not executable)
├── check.ts           # posts:check <slug>
├── push.ts            # posts:push <slug> [--ref <ref>] [--draft]
├── stats.ts           # posts:stats
├── record.ts          # posts:record <slug> <platform> k=v…
└── todo               # posts:todo [args…] (bash; the todo CLI pinned in its #MISE tools header)
test/integration/posts/posts.spec.ts   # bun tests for _lib.ts
test/integration/posts/fixtures/       # good/ and bad/ post folders, articles-me.json
test/mise.toml                         # add "posts" to the `all` scope
.github/workflows/posts.yml            # drafts on PRs, publish on merge
config/agents/commands/wip/resume.md   # probe reads docs/blog/TODO.yaml
config/homebrew/Brewfile               # the todo comment
docs/blog/
├── README.md  PLAYBOOK.md  STYLE.md  LOG.md  stats.csv  hype-words.txt  TODO.yaml
├── prompts/   gate.md  next-pick.md
├── templates/ post.md  linkedin.md  community.md  review.md  log-entry.md
├── tools/     frame.py  header.py   # moved from omarchy-on-macos/tools
└── <slug>/    post.md  linkedin.md  community.md  review.md  images/  raw/ (ignored)
```

Each file task reads its arguments from mise's `usage_*` environment variables and falls back to `process.argv`, so
CI can run `bun .mise/tasks/posts/push.ts <slug> --ref <ref> --draft` without mise.

## Artifact shapes

**`stats.csv`** — header `date,slug,platform,metric,value,source`. `date` `YYYY-MM-DD`; `platform` ∈ `devto`,
`linkedin`, `reddit`, `github`; `metric` ∈ `views`, `reactions`, `comments`, `impressions`, `engagement_rate`,
`reposts`, `saves`, `profile_views`, `followers`, `upvote_ratio`, `removed`, `referrer_linkedin`, `referrer_reddit`,
`repo_views`, `repo_uniques`, `stars`; `source` ∈ `api`, `manual`; `slug` is `-` for account-wide numbers.

**`LOG.md` entry** (`templates/log-entry.md`):

```markdown
## <YYYY-MM-DD> · <slug> · <title>

- **Links:** dev.to · LinkedIn · community
- **Variables:** hook type (number | confession | opinion | question) · cover style · images (count, kind) ·
  LinkedIn format (image | carousel) · language · day/time · tags
- **Changed on purpose:** <the one variable, and the hypothesis>
- **Gate:** verdict · STEPPS <raw>/12 · information gain: <sentence>
- **Numbers:** 48 h: … · 7 d: … (detail in stats.csv)
- **Best comment:** …
- **Keep:** … · **Change:** …
```

**`review.md`** (`templates/review.md`), written by the gate:

```markdown
# Review: <slug> · <YYYY-MM-DD>

**Verdict:** PASS | BLOCKED

## Must fix     <!-- blocking only: safety, anti-goals, missing/broken RECIPE, failed posts:check -->
## Cold read    <!-- the one point · would I save it, why · where I got lost -->
## Scores       <!-- table: information gain · RECIPE self-test · STEPPS 6×(0–2) + raw · voice · hook ≤ 210 ·
                     images (phone test, one point, series look) · goals 1–5 (0–2 each) · language rules -->
## Consider     <!-- at most 7, most valuable first, each naming its goal; visual and tone ones explicit -->
## Variables    <!-- prefilled LOG.md variables line -->
```

**`TODO.yaml` tags:** `setup`, `preflight`, `topic-<n>`, `community`, `recal`, `in-between`. Actors: the author
(Human) and Claude (the type the CLI accepts for a non-human actor).

---

### Task 1: `posts:check`

**Files:**

- Create: `.mise/tasks/posts/_lib.ts`, `.mise/tasks/posts/check.ts`, `test/integration/posts/posts.spec.ts`,
  `test/integration/posts/fixtures/{good,bad}/{post,linkedin}.md`, `docs/blog/hype-words.txt`
- Modify: `test/mise.toml` (add `posts` to the `all` loop)

**Interfaces:**

- Produces (in `_lib.ts`):
  - `type FrontMatter = { title?: string; published?: boolean; description?: string; tags: string[]; cover_image?: string; id?: number; [k: string]: unknown }`
  - `parseFrontMatter(text: string): { fm: FrontMatter; body: string }`
  - `setFrontMatterId(text: string, id: number): string` — adds or replaces the `id:` line, every other byte unchanged
  - `type Finding = { level: "block" | "warn"; rule: string; message: string }`
  - `checkPost(dir: string, hypeWords: string[]): Finding[]`
  - `visibleLength(text: string): number` (graphemes, `Intl.Segmenter`)
  - `assertSlug(slug: string): string` — throws for `templates`, `tools`, `prompts`, empty, or containing `/`, `..`

- [ ] **Step 1: Write the failing tests:**
  - `parseFrontMatter` reads `tags: git, zsh, ai` and `tags: [a, b]` both to `string[]`, `published: false` to `false`.
  - `setFrontMatterId(text, 123)` adds `id: 123` after `title`; on a text with `id: 9` it replaces it; the body is
    byte-identical.
  - `checkPost(fixtures/good)` is `[]`. `checkPost(fixtures/bad)` blocks `tags-max-4`, `description-missing`,
    `recipe-missing` (no `**RECIPE**` line), `recipe-use-it-when`, `raw-image` (`](./raw/` or `](raw/`),
    `linkedin-missing`; warns `hype-word` ("game-changer"), `hook-over-210`, `gotchas-over-3`.
  - `visibleLength("você 👋🏽") === 6`.
  - `assertSlug("zsh-word-split")` returns it; `"templates"`, `"../x"`, `"a/b"` throw.

- [ ] **Step 2: Run to fail** — `mise run -C test integration posts all` → FAIL (module not found).

- [ ] **Step 3: Implement** in `_lib.ts`. `hype-words.txt`: `game-changer`, `game changer`, `10x`, `ultimate`,
  `must-have`, `revolutionary`, `supercharge`, `blazing fast`, `seamless`, `effortless`, `unlock`,
  `in today's fast-paced world`, `have you ever wondered` (case-insensitive phrase match). The hook is the first
  paragraph after `## Post` in `linkedin.md`.

- [ ] **Step 4: `check.ts`** — `#!/usr/bin/env bun`, `//MISE description="Check a post's shape, RECIPE and voice"`,
  `//USAGE arg "<slug>"`; prints findings, exits 1 on any block. `chmod +x`. `_lib.ts` stays non-executable.

- [ ] **Step 5: Run to pass** → PASS; add `posts` to `test/mise.toml`'s `all` loop; `mise run test:specs` → PASS;
  `mise run posts:check omarchy-on-macos` reports findings (it predates the RECIPE rule) without crashing.

- [ ] **Step 6: Commit** — `feat(posts): Check a post's shape, RECIPE and voice`.

### Task 2: `posts:push`, `posts:stats`, `posts:record`

**Files:**

- Modify: `.mise/tasks/posts/_lib.ts`, `test/integration/posts/posts.spec.ts`
- Create: `.mise/tasks/posts/{push,stats,record}.ts`, `test/integration/posts/fixtures/articles-me.json` (real shape,
  fake values), `docs/blog/stats.csv` (header only)

**Interfaces:**

- Consumes: `parseFrontMatter`, `setFrontMatterId`, `checkPost`, `assertSlug` (Task 1).
- Produces (in `_lib.ts`):
  - `rewriteImages(markdown: string, slug: string, ref: string): string` — relative `](images/x.png)` or
    `](./images/x.png)` → `](https://raw.githubusercontent.com/roalcantara/dots/<ref>/docs/blog/<slug>/images/x.png)`;
    absolute links untouched.
  - `articlePayload(fm: FrontMatter, body: string, o: { slug: string; ref: string; draft: boolean }): { article: { title: string; body_markdown: string; published: boolean; tags: string[]; description?: string; main_image?: string } }`
    — `published` is `false` when `o.draft`, else `fm.published === true`; `main_image` from `cover_image` through
    the same rewrite; front matter is not sent in `body_markdown`.
  - `type GitState = { branch: string; dirty: boolean; ahead: number; upstream: boolean }`
  - `pushPreconditions(state: GitState, draft: boolean): Finding[]` — blocks `dirty`, no `upstream`, `ahead > 0`;
    when `!draft`, also blocks unless `branch === "main"`.
  - `resolveArticleId(fm: FrontMatter, mine: { id: number; title: string }[]): number | undefined` — `fm.id` if set,
    else the id of an article with the same title, else `undefined`.
  - `type StatRow = { date: string; slug: string; platform: string; metric: string; value: number; source: "api" | "manual" }`
  - `rowsFromArticles(json: unknown, date: string, slugById: Map<number, string>): StatRow[]` — `views`
    (`page_views_count`), `reactions` (`public_reactions_count`), `comments` (`comments_count`); missing → no row.
  - `rowsFromTraffic(json: unknown, date: string): StatRow[]` — `repo_views`, `repo_uniques`, slug `-`.
  - `appendRows(csvPath: string, rows: StatRow[]): void` — append only; header written when the file is missing.
  - `parseRecordArgs(argv: string[], date: string): StatRow[]` — `<slug> <platform> metric=value…`, source
    `manual`; unknown platform or metric throws.

- [ ] **Step 1: Write the failing tests:**
  - `articlePayload(fm with published: true, …, {draft: true})` → `published: false`; with `draft: false` → `true`.
  - `rewriteImages("![a](images/x.png) ![b](https://e.com/y.png)", "s", "main")` rewrites only the first.
  - `pushPreconditions({branch:"feat/x",dirty:false,ahead:0,upstream:true}, false)` blocks `publish-from-main`;
    with `draft: true` → `[]`; `dirty: true` blocks either way.
  - `resolveArticleId({tags:[], title:"T"}, [{id: 7, title: "T"}]) === 7`; with `id: 3` → `3`; no match → `undefined`.
  - `rowsFromArticles` yields 3 rows for a complete article and 2 without `page_views_count`.
  - `appendRows` keeps existing lines byte-for-byte.
  - `parseRecordArgs(["zsh-word-split","linkedin","impressions=812","reactions=14"], d)` → 2 rows;
    `["x","myspace","views=1"]` throws.

- [ ] **Step 2: Run to fail**, **Step 3: implement**, **Step 4: run to pass** —
  `mise run -C test integration posts all`.

- [ ] **Step 5: `push.ts`** — `//MISE description="Push a post to dev.to (draft unless publishing from main)"`,
  `//USAGE arg "<slug>"`, `//USAGE flag "--ref <ref>"` (default: current branch), `//USAGE flag "--draft"`. Order:
  `assertSlug` → `checkPost` (stop on block) → `pushPreconditions` from `git` (skipped when `CI=true`; CI checks
  out a pushed ref) → `GET /api/articles/me/all?per_page=1000` → `resolveArticleId` → `PUT /api/articles/<id>` or
  `POST /api/articles` with `articlePayload` → when the id is new, write it with `setFrontMatterId` → print
  `<slug> <draft|published> <url>`. Token from `DEVTO_TOKEN`; locally the task header runs nothing else, so the
  `mise run` wrapper is: `DEVTO_TOKEN="$(gopass show -o tokens/dev.to)" mise run posts:push <slug>` documented in
  PLAYBOOK, and the script exits with "DEVTO_TOKEN is not set" when absent.

- [ ] **Step 6: `stats.ts` and `record.ts`** — `stats` reads `/api/articles/me/all`, maps ids to slugs from each
  `docs/blog/*/post.md`, tries `/api/analytics/referrers?article_id=<id>` (on 200 add `referrer_linkedin` for
  `linkedin.com`/`lnkd.in`, `referrer_reddit` for `reddit.com`; otherwise one note), adds `gh api
  repos/roalcantara/dots/traffic/views`, appends to `docs/blog/stats.csv`, prints a table. `record` appends
  `parseRecordArgs` rows. Both executable with `//MISE` / `//USAGE` headers.

- [ ] **Step 7: Live check (needs the token)** —
  `DEVTO_TOKEN="$(gopass show -o tokens/dev.to)" mise run posts:stats` appends the Omarchy rows to `stats.csv`.
  Then record the Omarchy post's id in its front matter with `setFrontMatterId` (found by title), so it can never be
  duplicated.

- [ ] **Step 8: Commit** — `feat(posts): Push to dev.to and record numbers through the Forem API`.

### Task 3: CI — drafts on PRs, publish on merge

**Files:**

- Create: `.github/workflows/posts.yml`

**Interfaces:**

- Consumes: `push.ts` (Task 2) run as `bun .mise/tasks/posts/push.ts <slug> --ref <ref> [--draft]`.

- [ ] **Step 1: Write the workflow:**
  - `on: pull_request` (types `opened`, `synchronize`, `reopened`; paths `docs/blog/*/post.md`,
    `docs/blog/*/images/**`) and `push` to `main` (same paths).
  - `concurrency: { group: posts-${{ github.ref }}, cancel-in-progress: false }`.
  - `permissions: { contents: write, pull-requests: write }`.
  - Skip when `github.event.pull_request.head.repo.full_name != github.repository` (forks have no secret).
  - Steps: checkout (`ref: ${{ github.head_ref }}` on PRs, `fetch-depth: 0`); `oven-sh/setup-bun@v2`; find slugs:
    `git diff --name-only <base>...HEAD -- 'docs/blog/*/post.md' 'docs/blog/*/images/**'` → unique folder names,
    excluding `templates`, `tools`, `prompts`; for each, run push with `DEVTO_TOKEN: ${{ secrets.DEVTO_TOKEN }}`,
    `--draft` and `--ref ${{ github.head_ref }}` on PRs, `--ref main` on `main`.
  - PRs only: if any `post.md` changed (an id was written), commit with the Actions bot and the default
    `GITHUB_TOKEN` (`chore(posts): Record dev.to ids`), push to the PR branch; comment each `<slug> <url>` on the PR
    with `gh pr comment` (update one comment marked `<!-- posts-bot -->` instead of adding new ones).
  - `main`: no commits.

- [ ] **Step 2: Verify** — `actionlint .github/workflows/posts.yml` if available, else `hk check --all`; YAML lint
  green.

- [ ] **Step 3: Commit** — `ci(posts): Draft posts on pull requests and publish them on merge`.

### Task 4: The series home: playbook, style, log, roadmap, templates

**Files:**

- Create: `docs/blog/{README,PLAYBOOK,STYLE,LOG}.md`, `docs/blog/TODO.yaml`, `docs/blog/templates/*.md`,
  `.mise/tasks/posts/todo`
- Modify: `config/agents/commands/wip/resume.md`, `config/homebrew/Brewfile` (comment only)

- [ ] **Step 1: `PLAYBOOK.md`** — the living version of the spec: Intent; Goals in order and tiebreaks; Audience
  and ownership; Formats; How a post moves (branch → `posts:check` → gate → PR = draft + preview → author review →
  set `published: true` → merge = publish → LinkedIn by hand → stats at 48 h / 7 d); Communities rules; Choosing the
  next topic; Success criteria and baseline; Tuning; Recalibration; Language; **Decisions log** (dated one-liners,
  seeded from the spec's "Decided by the author"). Exact values from the spec; the spec linked as origin.

- [ ] **Step 2: `STYLE.md`** — **Voice** (the spec's table, rules, title patterns, `hype-words.txt`); **Visual
  identity** (one series look: background `#0e121c → #181e2c`, accent `#33ccff → #00ff99`, ink `#f2f2f2`, SF Pro;
  cover 1000 × 420 with `dots · #<n>` top right, title bottom left, 2–4 key caps, a stylised window on the right;
  screenshots through `frame.py`; carousel 1080 × 1350, 4–6 slides; phone test at 400 px); **Rubric** (each check
  0–2, the bars STEPPS ≥ 6 with Practical value = 2 and Social currency or Stories = 2, the blocking items). Ends:
  "The look is a tuned variable, re-evaluated at each recalibration from the cover and image results in LOG.md."

- [ ] **Step 3: `README.md`** (what the series is; the recipes index table `# · Title · RECIPE in one line ·
  dev.to · dots files`; links), `LOG.md` (header and `## Baseline` from Task 2's Omarchy rows), templates (shapes
  above; `post.md` with `published: false`, the outline and RECIPE block; `linkedin.md` with `## Post`,
  `## First comment`, `## In-between post`; `community.md` with Where, Title, Flair, Body, Rules checked on).

- [ ] **Step 4: `posts:todo` and the roadmap** — `.mise/tasks/posts/todo` (bash, executable,
  `#MISE description="The series roadmap (todo CLI) in docs/blog"`, `#MISE tools={"github:RayanBO/todo"="0.2.9"}`,
  runs `cd "$MISE_PROJECT_ROOT/docs/blog" && todo "$@"`). Brewfile comment in the `npm`/`uv` area:
  `# todo (github.com/RayanBO/todo): no formula; cargo's todo-cli is another crate. Pinned in .mise/tasks/posts/todo.`
  Then `mise run posts:todo init --yaml`, add the actors, and one task per timeline row with tags and due dates
  (preflight today; Reddit runway 2026-11-17 → 2026-11-30; topics 1–8 on their Tuesdays with community and
  in-between posts; recalibrations). `mise run posts:todo list` shows them.

- [ ] **Step 5: `/wip:resume`** — in the probe, before the `TODO.md` branch, add a `docs/blog/TODO.yaml` branch
  printing at most 5 open tasks as `- <title> (<due>)` with `grep`/`awk` on the YAML the CLI wrote. Run the probe:
  the preflight task appears.

- [ ] **Step 6: Verify** — `markdownlint-cli2 "docs/blog/**/*.md"` → 0 issues; `hk check --all` green.

- [ ] **Step 7: Commit** — `docs(posts): Add the series playbook, style, log, roadmap and templates`.

### Task 5: Image tools for the series look

**Files:**

- Move: `docs/blog/omarchy-on-macos/tools/{frame,header}.py` → `docs/blog/tools/` (`g mv`)
- Modify: `docs/blog/tools/header.py`; Test: `test/integration/posts/posts.spec.ts`

**Interfaces:**

- Produces: `uv run --with pillow docs/blog/tools/header.py <out.png> --title "<t>" --series <n> --keys "a,b"` →
  1000 × 420 PNG in the STYLE.md palette; `frame.py` keeps its CLI.

- [ ] **Step 1: Failing test** — runs `header.py` into a temp file with `--title "Test" --series 0 --keys
  "zsh,bash"`, asserts the PNG is 1000 × 420 (IHDR bytes); skipped with a message when `uv` is missing.
- [ ] **Step 2: Run to fail**; **Step 3:** move the tools, add argparse (constants become defaults; series tag
  `dots · #<n>` top right); **Step 4: run to pass**. The published Omarchy cover stays untouched.
- [ ] **Step 5: Commit** — `feat(posts): Share the image tools and draw the series cover`.

### Task 6: Gate and next-pick prompts

**Files:**

- Create: `docs/blog/prompts/gate.md`, `docs/blog/prompts/next-pick.md`

- [ ] **Step 1: `gate.md`** — for a fresh agent with no other context: (1) `mise run posts:check <slug>`, blocks go
  to **Must fix**; (2) **cold read** of `post.md` and `linkedin.md` only, as a mid-level developer who doesn't know
  dots: the one point, would I save it and why, where I got lost; (3) read PLAYBOOK.md and STYLE.md, fill
  **Scores**; (4) **Must fix** only for safety (secret, key, token name, email, client or private repo name, in text
  or images), anti-goals (hype, spam, hate, takes aimed at people or tools), a missing or broken RECIPE, a failed
  check; (5) **Consider**: at most 7, most valuable first, each naming its goal, visual and tone ones explicit;
  (6) prefill **Variables**. Writes `docs/blog/<slug>/review.md` from the template; edits nothing else.
- [ ] **Step 2: `next-pick.md`** — reads PLAYBOOK.md "Choosing the next topic", `mise run posts:todo list`, the
  last three LOG.md entries; web search over the past 14 days per candidate; applies the spec's scoring and
  guardrails; outputs a `### Next pick · <date>` block (keep or swap, one line of reason, source link) for the author.
- [ ] **Step 3: Dry-run the gate** on `omarchy-on-macos` with a fresh agent → a complete `review.md`, verdict
  BLOCKED (no RECIPE). Fix any ambiguity it reveals; delete that `review.md`.
- [ ] **Step 4: Commit** — `docs(posts): Add the pre-release gate and next-topic prompts`.

### Task 7: Preflight post — draft and gate

Topic: **"My AI agent's for-loop ran once: zsh doesn't split `$vars`"**, slug `zsh-word-split`. Facts: commit
`15ebd18` (#108); `config/claude/settings.json` sets `CLAUDE_CODE_SHELL` to `/opt/homebrew/bin/bash`; Copilot chat
uses `chat.tools.terminal.terminalProfile.osx` / `.linux` in `config/vscode/settings.json`; the integrated terminal
stays on zsh.

**Files:** `docs/blog/zsh-word-split/{post.md,linkedin.md,review.md}`, `images/00-cover.png`,
`images/01-zsh-vs-bash.png`

- [ ] **Step 1: Verify the claim** — `zsh -c 'list="a b c"; for x in $list; do echo "[$x]"; done'` → `[a b c]`;
  the same in `bash` → three lines. Confirm both settings exist as stated.
- [ ] **Step 2: Draft `post.md`** with `technical-article-writer` (objective: personal branding / authority;
  audience: developers using AI coding agents on macOS; type: bug hunt; 400–600 words; thesis: "agents write bash,
  your login shell may be zsh, and zsh doesn't split unquoted variables"). RECIPE: use it when agent loops behave
  oddly on macOS; steps: `CLAUDE_CODE_SHELL`, the Copilot terminal profile, keep your interactive zsh; gotchas:
  `setopt SH_WORD_SPLIT` changes every script, quoting `"$list"` doesn't help. Tags `ai`, `zsh`, `bash`,
  `productivity`. 10 titles via `copywriting-hooks`, keep the most specific. `published: false`.
- [ ] **Step 3: Draft `linkedin.md`** with `linkedin-ghostwriting` (hook ≤ 210, recipe in 3 bullets, one honest
  lesson, a question; `## First comment` with the dev.to link placeholder).
- [ ] **Step 4: Images** — `header.py --title "<title>" --series 0 --keys "zsh,bash"`; one framed capture of a
  clean Ghostty window running Step 1's commands.
- [ ] **Step 5: Check and gate** — `mise run posts:check zsh-word-split` → no blocks; gate with a fresh agent →
  `review.md` PASS; apply what the author accepts.
- [ ] **Step 6: Commit** — `docs(posts): Draft the zsh word-splitting preflight post`.

### Task 8: Publish, measure, close the preflight

- [ ] **Step 1: Quality gate** — `mise run test:specs` and `hk check --all` green on the branch.
- [ ] **Step 2: Open the PR (author's go)** — push `feat/content-series`, open a PR (body ends with the Claude Code
  line). The workflow creates the draft, commits the id to the branch and comments the preview link. Check the
  preview: text, cover and images load.
- [ ] **Step 3: Author review (author)** — read the preview, LinkedIn text and `review.md`; edit freely (each push
  updates the same draft).
- [ ] **Step 4: Publish = merge (author)** — set `published: true` in `docs/blog/zsh-word-split/post.md`, commit,
  push; then merge. The `main` run updates the article with `main` image links and publishes it. Open the URL.
- [ ] **Step 5: LinkedIn (author)** — post `## Post`, then the first comment with the dev.to URL; stay for replies.
- [ ] **Step 6: Record** — on `main` (or a follow-up branch): a `LOG.md` entry from the template, the post in the
  `README.md` index, `mise run posts:todo status <id> --set done` for the preflight tasks.
- [ ] **Step 7: Measure at 48 h and 7 d** — `posts:stats`, and `mise run posts:record zsh-word-split linkedin
  impressions=… reactions=… comments=… reposts=…` from LinkedIn analytics; fill Numbers, Best comment, Keep/Change.
- [ ] **Step 8: Preflight retro** — what broke or slowed the flow, in `LOG.md`; small fixes now, the rest as
  `setup` tasks in `TODO.yaml`. Next: a separate plan for topic 1 (SOPS + age), starting with `prompts/next-pick.md`.
