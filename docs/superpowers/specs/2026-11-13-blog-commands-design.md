# Blog: one command per step — design

Third pass on the blog series ([first design](2026-11-13-content-series-design.md),
[DRY pass](2026-11-13-content-series-dry-design.md)). Asked by the author: turn every step of the QUICK REFERENCE in
`docs/blog/README.md` into a command, so running a post means calling commands instead of following a recipe.

## Intent

Mechanical steps become **mise tasks**; steps that need judgment or writing become **agent commands**. A status
task and a `/blog:next` command read a post's state and point at (or run) the next step, so the order lives in code,
tested once, instead of in the author's head.

## Goals

- Every QUICK REFERENCE step is one command; the README's QUICK REFERENCE becomes a short command list.
- One vocabulary: mise tasks `blog:*`, agent commands `/blog:*`.
- One copy of each prompt: the agent commands *are* the prompts (`docs/blog/prompts/` goes away).
- The stage of a post is computed by one tested function, used by `blog:status` and `/blog:next`.
- Agent commands can't do what the author keeps for themself (see **Enforcement**: `allowed-tools` only pre-approves;
  it doesn't block).

## Non-goals

- Posting to LinkedIn or Reddit (no API; the author posts by hand).
- Merging pull requests (merge = publish; the author's click).
- Commands for other repos: these are dots-only.
- Headless runs (`claude -p` inside mise tasks): considered and dropped (below).

## Anti-goals

- An agent command that pushes to `main`, merges, or publishes.
- A second copy of a rule that already lives in PLAYBOOK.md or STYLE.md (commands reference them with `@`).
- Invented stories in drafts: anything only the author knows stays a visible `<author: …>` marker.

## Decided by the author

- **Approach B:** one task or command per step, plus `blog:status` and `/blog:next`.
- **Boundary:**
  - Mise tasks may push the post's branch when the author runs them, because running the task is the request.
  - **Opening the PR is an agent command, `/blog:pr`,** so its title and body are written for you. It may push the
    post branch and run `gh pr create`. It may never merge.
  - Merging (which publishes) and the LinkedIn post stay the author's.
  - The other agent commands never push, open PRs or merge.
- **Location:** project-level commands in dots, `.agents/commands/blog/*.md` (`/blog:<name>`), not
  `~/.agents/commands` (which would show them in every project). Claude Code reads project commands only from
  `.claude/commands/`, so that path is a symlink to `../.agents/commands` (AGENTS.md: `.agents` over `.claude`).
- **Rename:** mise tasks `posts:*` → `blog:*` (`.mise/tasks/posts/` → `.mise/tasks/blog/`).
- Commands follow the `create-command` skill and the repo's command style: YAML front matter (`description`,
  `argument-hint`, `allowed-tools`), then `<task>`, `<context>`, `<workflow>`, `<checklist>`; `key=value` arguments
  plus free notes (`$ARGUMENTS`); `!` lines for live state; `@` references to PLAYBOOK, STYLE and templates.

## Approaches

| | What the author runs | Trade-off |
| --- | --- | --- |
| A. One command per step | each step's command, in order | clear and testable, but the order is still the author's to remember |
| **B. A + status and next (chosen)** | the same, plus `blog:status` / `/blog:next` | one entry point; the stage logic is written once and tested |
| C. Mise tasks running Claude headless | only mise tasks | fully scripted, but tied to one agent CLI and no conversation while drafting |

## The commands

`<post>` is the post folder (`YYYY-MM-DD-slug`); when omitted, commands use the post of the current branch
(`feat/post-<slug>` → the folder ending in `-<slug>`), else the next open topic.

### Mise tasks (`.mise/tasks/blog/`)

| Task | Does | Replaces |
| --- | --- | --- |
| `blog:status [post]` | Prints the post's stage, what's done, and the next command (all posts when none given) | reading the roadmap |
| `blog:new <slug> [--task <id>] [--date YYYY-MM-DD]` | Requires a clean tree; branches `feat/post-<slug>` from `main`; copies `templates/` into `posts/<date>-<slug>/` (with `images/`, `raw/`); sets the task's `post` tag and `position`. Default task: the next open `topic-<n>` task; default date: that task's due date | step 3 |
| `blog:cover <post> --title … [--highlight …] [--subtitle …] --keys …` | Runs `tools/header.py` into `images/00-cover.png`; series number from the task's `topic-<n>` tag (else 0) | step 5 (cover) |
| `blog:check <post>` | As today, plus: `<author: …>` markers warn | step 6 |
| `blog:publish <post>` | Blocks on any `<author: …>` marker or a gate verdict other than PASS; sets `published: true`; commits `docs(blog): Publish "<title>"`; pushes the post branch. The author then merges | step 9 |
| `blog:done <post> [--linkedin <url>] [--community <url>]` | Records the URLs, runs the stats, sets the task done, rewrites the README index | step 11 |
| `blog:stats`, `blog:record`, `blog:report`, `blog:todo`, `blog:push` | As today, renamed | steps 11–12, CI |

### Agent commands (`.agents/commands/blog/`)

| Command | Arguments | Does | Allowed beyond reading |
| --- | --- | --- | --- |
| `/blog:next` | notes | `!mise run -q blog:status`; runs the next step if it is a mise task other than `blog:publish`, else says which command to run and why | `mise run blog:status/new/cover/check/stats/report` |
| `/blog:pick` | `note=…` | The next-pick prompt (today `prompts/next-pick.md`): news, comments, readiness, guardrails; asks the author keep or swap; records `pick:` | `mise run blog:status/report/todo`, web search |
| `/blog:draft` | `[post] note=…` | Drafts `post.md` (`technical-article-writer`), `linkedin.md` (`linkedin-ghostwriting`), `community.md` from topic 2 (`reddit-posts`) from the playbook's topic row and its sources; a shot list; `<author: …>` where only the author knows | edit files in the post folder; `mise run blog:check/cover` |
| `/blog:gate` | `[post]` | Dispatches a fresh subagent with the gate prompt (today `prompts/gate.md`); writes `review.md`; records `gate:` and `vars:` | Agent tool; `mise run blog:check/todo` |
| `/blog:pr` | `[post] note=…` | Runs `blog:check`; writes a Conventional title (`docs(blog): Add "<title>"`) and a body (what the post is, its RECIPE line, the gate verdict, the author's checklist: preview, `<author:>` markers, `blog:publish`, merge, LinkedIn); pushes the post branch; `gh pr create` | `git push -u origin feat/post-*`, `gh pr create`, `gh pr view` — never `gh pr merge` |
| `/blog:share` | `[post] linkedin=<url> community=<url>` | Prints the LinkedIn post and first comment ready to paste (and copies the post with `pbcopy`); with URLs, runs `blog:done` | `pbcopy`, `mise run blog:done` |
| `/blog:retro` | `[post] note=…` | At 7 days: runs `blog:stats`, asks the author for the best comment, keep and change, records `log.*` comments and the LinkedIn numbers they read (`blog:record`) | `mise run blog:stats/record/todo` |

### Stages (`blog:status`)

A pure function `stageOf(facts) → { stage, next }` in `_lib.ts`, from facts the task gathers (the task's metadata,
the folder, `review.md`, the branch, `gh pr list --head`, the front matter). First match wins:

| Stage | When | Next |
| --- | --- | --- |
| `planned` | a topic task with no `position` | `/blog:pick`, then `blog:new` |
| `drafting` | folder exists; `blog:check` blocks, or `post.md` still has template placeholders | `/blog:draft`, `blog:check` |
| `gate` | check passes; no `review.md`, or it is older than `post.md` | `/blog:gate` |
| `blocked` | `review.md` verdict BLOCKED | fix, then `/blog:gate` |
| `pr` | review PASS; no open PR for the post branch | `/blog:pr` |
| `publish` | PR open; `published` not true, or `<author:>` markers left | resolve markers, `blog:publish`, then merge |
| `share` | published on dev.to (a `devto.url`); no `linkedin.url` | `/blog:share` |
| `measure` | shared; task not done, or fewer than 7 days since the due date | `blog:stats` at 48 h, `/blog:retro` at 7 days |
| `closed` | `log.keep` recorded | — |

## Enforcement (decided by the author)

`allowed-tools` only pre-approves the tools a command lists; it blocks nothing. The author chose **prompt +
`allowed-tools` only**: each command's instructions say what it must never do (merge, push to `main`, publish), and
its `allowed-tools` lists only what it needs, so anything else asks for permission in a normal session. No project
deny rules or hooks.

## Writes after the merge (decided by the author)

`blog:done`, `blog:stats`, `blog:record`, `/blog:retro` and `/blog:pick` write `TODO.yaml` (and the README index)
on whatever branch is checked out, usually `main`. They **commit locally with a Conventional message**
(`chore(blog): …`) **and stop**; the author pushes. Before the merge, `blog:new` commits the scaffold and `/blog:pr`
commits what's pending on the post branch.

## Builder's calls (settled from the builder check)

- **Which post:** an explicit `<post>` wins; else the current `feat/post-<slug>` branch; else, for the steps after
  the merge (`share`, `done`, `stats`, `retro`), the most recent post that isn't `closed`; only `pick` and `new` fall
  back to the next open topic. Ambiguous → ask.
- **Topic task:** exactly one `topic-<n>` tag and neither `in-between` nor `community`; the preflight is post #0.
  Separate measuring tasks (BnIE, 9ggB) stay the author's to close.
- **Stages, end states first** (replacing the order above): `closed` (`log.keep` recorded) → `measure` (task done,
  or PR merged and a `linkedin.url`) → `share` (PR merged, or published on `main`; `blog:stats` runs first when
  `devto.url` is missing) → `merge` (PR open, `published: true`, no markers: the author merges) → `publish` (PR
  open, not published or markers left) → `pr` (review PASS and fresh, no PR) → `blocked` → `gate` → `drafting` →
  `planned`. "Merged" comes from `gh pr list --head <branch> --state all`. A task Done with `published: true` (the
  Omarchy post, made before the tooling) is `measure` or `closed` whatever `check` says.
- **Fresh review:** `review.md` counts when its last commit time (`git log -1 --format=%ct`) is at or after
  `post.md`'s; an uncommitted file uses its mtime.
- **Placeholders:** any `<…>` in `post.md` or `linkedin.md` that is neither `<author: …>`, an HTML comment nor a
  known HTML tag blocks `check`; so `drafting` is "`check` blocks". `<author: …>` warns in `check` and blocks
  `blog:publish`.
- **`blog:new` copies** `post.md` and `linkedin.md`, and `community.md` for topic ≥ 2; never `review.md` (the gate
  writes it). It commits the scaffold on the new branch.
- **`blog:publish` reads** `review.md`'s verdict and requires it fresh (same function as the stages); a dirty tree
  blocks; it commits only `post.md`.
- **`/blog:next` runs** only argument-free steps (`status`, `check`, `report`, `stats`); for `new`, `cover` and the
  rest it prints the exact command and asks.
- **`/blog:pr` refuses** unless the stage is `pr`, quoting `blog:status`. It commits what's pending on the post
  branch, pushes through a small task `blog:push-branch` (which uses the SOPS git wrapper like `_lib.ts`, so the
  permission patterns stay simple), then runs `gh pr create`.
- **Rename reach:** test domain and fixture paths (`test/integration/blog/`, `hk.pkl`'s exclude), the workflow
  (`blog.yml`, name `Blog`, concurrency group `blog`, the task path, the `blog-bot` comment marker), AGENTS.md's
  test domain list; the repo has no branch protection to update.
- **Lint:** `.agents/commands/blog/*.md` are linted like other markdown; any rule their XML-style sections break is
  excluded for that folder only.

## Other changes

- `docs/blog/prompts/` is removed; its content moves into `/blog:pick` and `/blog:gate`.
- QUICK REFERENCE becomes the stage table's "Next" column as a short numbered list of commands.
- PLAYBOOK "How a post moves" points at the commands; the workflow, tests and docs follow the `blog:*` rename
  (test domain `blog`, workflow `blog.yml`, name `Blog`).
- `posts:check` gains the `<author: …>` rule (warn); `blog:publish` blocks on it.
- **Every doc and reference follows** (author's requirement): `docs/blog/` (README, PLAYBOOK, STYLE, templates),
  `README.md`, `AGENTS.md`, `hk.pkl`, `fnox.toml`, the Brewfile comment, `.gitignore`, the workflow, tests, and the
  content-series specs and plans; a repo-wide search for `posts:`, `.mise/tasks/posts`, `prompts/gate.md`,
  `prompts/next-pick.md` and `posts.yml` comes back empty except for history (commit messages, the decisions log).

## Constraints

- Every tool from the Brewfile (nothing new: mise, bun, gh, git, pbcopy are there or built in).
- The token through fnox; arguments through argv; metadata in `TODO.yaml` comments (DRY pass).
- `allowed-tools` lists the exact Bash patterns each command needs; reading and editing files stays allowed.

## Left to the builder

The exact wording of each command; the PR body template; how `blog:status` prints; whether `/blog:next` lists all
posts when none is in progress.
