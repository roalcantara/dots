# Blog playbook

The rules of the dots blog that don't change from post to post. What's next and when lives in
[`TODO.yaml`](TODO.yaml) (`mise run blog:status`, `mise run blog:todo -- dashboard`); how a post moves, step by step,
is the QUICK REFERENCE in [`README.md`](README.md); how posts sound and look is [`STYLE.md`](STYLE.md). The designs
that led here are in `docs/superpowers/specs/` (historical records). Changes to this file happen at recalibrations.

## Intent

Turn what dots already solves into a series of posts, each a story and a **RECIPE** (a TL;DR the author and readers
come back to): a dev.to article, a short LinkedIn post that points to it, and, from topic 2, one community post. The
aim is to show know-how and lessons learned, not to chase clicks; engagement follows usefulness and honesty.

## Goals, in priority order

The order means **higher wins when two goals conflict**, not "lower matters less". Goals 1–3 are what the content
*is*; goals 4–5 are how far it *reaches*, and reach multiplies whatever is there.

| # | Goal | What it means | Serves first | One sign it works |
| --- | --- | --- | --- | --- |
| 1 | **Knowledge base** | Everything lives in dots: `docs/blog/` and the recipes index, owned and permanent | Future author | The author links a recipe to answer someone instead of re-explaining |
| 2 | **Lessons learned, as recipes** | Each post is one recipe plus the story of what went wrong | Author, then peers | The author can redo the thing from the RECIPE alone, months later |
| 3 | **Showing tech skills** | The working repo, tests and decisions are the evidence, not claims | Peers, hiring managers, clients | Comments ask how something works; profile views from posts |
| 4 | **Personal brand and presence** | Showing up steadily on LinkedIn, dev.to and communities | The network | Followers and inbound messages, month over month |
| 5 | **Engaging, contagious content** | Hooks, images, STEPPS: how 1–4 travel | Strangers | Saves, reposts, referred visitors |

**Tiebreaks:**

- A catchier title that overstates the result loses to an accurate one (2 over 5).
- A dull but necessary RECIPE step stays (1 over 5).
- A post with no lesson, only a nice screenshot, becomes an in-between LinkedIn post, not a recipe (2 over 4).
- Late but correct beats on schedule but sloppy (3 over 4).

**Audience order** mirrors the goals: future author → peer developers → hiring managers and clients. It settles how
much to explain: enough for a peer who has not used the tool, no more.

**Ownership:** the repo is the **source** (it holds every post, its files and its numbers); dev.to is the **canonical
public article**; LinkedIn and communities point to dev.to.

## Anti-goals

- Any secret, key, token name, email, client or private repo name visible in text or screenshots. This matters
  most for the secrets and backup topics.
- Posts that read as ads or hype ("10x your setup!").
- Spam in any form: the same post in several communities, bare links, posting and leaving, reposting a topic that
  sank, undisclosed self-promotion.
- Hate, rage bait, or takes aimed at other people or tools to provoke. Comparisons stay factual ("vs." tables).
- A RECIPE that cannot be followed without reading the whole post.
- Dropping the honest "what I (think I) learned" part to make a post look more polished.
- An invented anecdote, quote, number or experience, even to make a hook work.
- A LinkedIn post that teases without giving the insight.

## Cadence and themes

- **One topic every two weeks, on Tuesdays** (author's time zone, working-week morning): the dev.to article and the
  LinkedIn post the same day; the community post Thursday–Saturday; a lighter LinkedIn-only post the Tuesday after.
  December holidays are skipped. The dates are the tasks' due dates.
- **Four themes**, alternated so neighbouring posts differ (a task's `theme-a` … `theme-d` tag): **A** a machine you
  can rebuild; **B** a repo that checks itself; **C** working with AI agents; **D** desktop and terminal.
- Topics that apply to almost anyone come first; dots-specific tools come last or not at all. dots is the example,
  never the headline.

## Formats

- **dev.to article** (800–1,300 words): the wiki layout (⚡ TL;DR with the RECIPE first, then 🪲 the problem with
  the hook, 🔍 why, 🛠️ the fix, 🧪 check, ⚠️ gotchas, ⚖️ alternatives, 🧠 lessons, 📚 references) and the AI
  disclosure; [STYLE.md](STYLE.md), "Post layout", and [`templates/post.md`](templates/post.md).
- **LinkedIn post:** the hook plus one insight, 250–450 characters, the link in the first comment
  ([STYLE.md](STYLE.md), [`templates/linkedin.md`](templates/linkedin.md)).
- **Community post:** the story and the RECIPE written for one community, disclosed as the author's
  ([`templates/community.md`](templates/community.md)).
- **Cover and images:** the series look ([STYLE.md](STYLE.md), "Visual identity"); `cover.json` per post.

## Language

**English everywhere by default**; LinkedIn's own feed translation covers part of the Portuguese-speaking network.
PT-BR is tested on the LinkedIn post of the topics whose task title says "LinkedIn in PT-BR". At a recalibration,
switch the default to PT-BR LinkedIn posts if they get at least 1.5× the engagement while international viewers stay
at 15 % or more; to one bilingual post (EN, then PT) if PT-BR wins but international viewers drop below 15 %;
otherwise keep English. A few posts on a small account are directional only; comment quality and inbound messages
weigh as much as counts. dev.to stays English: one RECIPE per topic.

**Rules for any PT-BR text:**

- Translate only from the final English version; never edit the PT copy on its own.
- Keep in English: code, commands, flags, paths, tool names, error messages, Conventional Commit types, "RECIPE".
- Keep the loanwords Brazilian developers use (commit, deploy, backup, hook, secrets, dotfiles, pipeline).
- Same voice: first person, "você", the honest mistakes kept; rewrite the hook naturally, not word for word.
- Hashtags: 2–3 English tool or topic tags, at most one PT/BR tag.
- A short EN↔PT glossary in `docs/blog/GLOSSARY.pt.md` keeps the reviews consistent.

## Choosing the next topic

The schedule is the default, not a contract. At the start of each cycle (the Tuesday before publishing), an agent
re-evaluates the next pick against the current context, and the author approves the result.

**Inputs:** the scheduled topic; the other open topics and the backlog (`topic-backlog` tasks), with their `hook:`,
`recipe:` and `sources:` comments and theme tags; the latest metadata of the past posts (`mise run blog:report`)
(questions from comments, what worked); and a news check: a web search over the past two weeks for each candidate's
subject (for example "secrets leaked GitHub", "restic", "Conventional Commits", "AI coding agents"), plus the
release notes of the tools involved.

**Scoring:** each candidate gets the scheduled order as its base, then:

- **Timeliness:** a recent, credible, widely discussed event that the topic genuinely helps with (a large secrets
  leak on GitHub → the SOPS + age post; a major release of a tool in the series → that tool's post).
- **Demand:** a question asked in comments by two or more people.
- **Readiness:** the drafts, images and facts can be ready by Tuesday without cutting the quality gate.

**Guardrails:**

- **The news is the hook, not the subject:** one or two sentences, with a link to a credible source, then the
  RECIPE as planned. The post must still make sense after the news is forgotten (goals 1–2 outrank goal 5).
- **No newsjacking of harm to people:** no tragedies, layoffs or personal blame. Write about the problem class, not
  the victim ("secrets leak from public repos every day"), never mocking a company or person.
- **Only the next topic moves,** and only one slot forward; the theme alternation may break once in a row, not
  twice. The displaced topic takes the next slot.
- **No pick for news alone:** a timely topic that fails the information-gain gate or isn't ready waits; an
  in-between LinkedIn post can react to the news instead.
- **The author decides.** The agent proposes: keep or swap, with one line of reason and the source. The decision
  becomes a `pick:` comment on the topic's task.

## Communities

Reddit first; a tool's own forum or GitHub Discussions where the topic belongs to one tool. The rule is
**contribute first, link second**:

- **Runway:** before the first community post, two weeks of comments and answers in the target subreddits, no own
  links (the roadmap's "Reddit runway" task).
- **90/10:** at most one in six of the author's posts or comments in a community links to their own work.
- **One community per topic.** Read its sidebar rules and recent top posts first, use the required flair and title
  format. Never the same post in two communities.
- **Disclose:** "I wrote this up on dev.to".
- **Stay 2 hours** after posting to answer; thank corrections.
- **Never repost** a topic that sank; record it as a `note:` on the topic's task instead.

Which community a topic goes to is the title of its `community` task in `TODO.yaml`; the subreddit's rules are
checked again before each post.

## Success criteria

Three layers, from the skills `contagious` (STEPPS), `content-strategy` and `linkedin-profile-optimizer`, mapped to
the goals.

### 1. Before publishing (quality gate, per post)

- **Information gain** (goals 2–3): the one-sentence "what this adds" exists and is true.
- **RECIPE self-test** (goals 1–2): the author could redo the thing from the RECIPE alone, six months from now.
- **Cold read** (goals 2, 5): a fresh agent, playing a mid-level developer who doesn't know dots, answers three
  questions: What is the one point? Would I save this, and why? Where did I get lost? Fix what it trips on.
- **STEPPS score** (goal 5; each driver 0 absent, 1 weak, 2 strong; raw 0–12): at least **6**, with
  **Practical value = 2** and **one of Social currency or Stories = 2**.
- **Voice check:** zero hype words; at least one mistake or limit stated.
- **Hook test:** the first 210 characters of the LinkedIn post make sense alone and contain a specific detail.
- **Phone test** for every image; **safety** check by the author.

### 2. After publishing (per post, at 48 hours and 7 days)

**Baseline.** Numbers only need to be honest, not impressive: every comparison is with the series' own past, never
with other creators.

- dev.to: the numbers already recorded on the posts' and the series task (`mise run blog:report`).
- LinkedIn: no API is available for personal posts, so the baseline is the **median of the first two series
  posts**; targets apply from the third.

Signals:

| Signal | Where | Goal |
| --- | --- | --- |
| Impressions; impressions per follower | LinkedIn | 4–5 |
| Engagement rate = (reactions + comments + reposts) ÷ impressions | LinkedIn | 5 |
| Comments with substance (`substantive_comments`: a question, a setup, a correction), counted by hand | All | 2–3 (worth more than reactions) |
| Saves, reposts and sends | LinkedIn | 2, 5 |
| Views, reactions, comments | dev.to | 3–4 |
| Visitors referred from linkedin.com and reddit.com | dev.to referrers | 4 (do the copies send readers to the original?) |
| Upvote ratio, comments with substance, removals | Reddit | 4–5 |
| Repo views and stars | GitHub traffic | 3 |

Starting targets, from the third post, reset at each recalibration: per topic, at least the baseline's LinkedIn
impressions, an engagement rate at or above the baseline, and at least 3 comments with substance across all
platforms. A number that can't be read is recorded as `note: <date> <platform> <metric> unknown`, never guessed.

### 3. Over the series (monthly)

Recorded on the series task (`mise run blog:record series series recipe_reuse=… inbound=…`, and LinkedIn's
`followers`/`profile_views`):

- Recipes reused (`recipe_reuse`): times the author linked a RECIPE to answer someone (goal 1, the clearest sign).
- Inbound conversations (`inbound`): messages or comments that ask for help, invite a talk, or mention work (goals 3–4).
- Followers and profile views month over month (goal 4).

## Tuning each element

With one post a fortnight, nothing here is statistically sound: **change one thing at a time, and write it down**.
Each post's task records its variables (`vars:`), the hypothesis for the one that changed (`note:`), and the numbers
(`stats:`).

| Element | Variables recorded | Measured by | Rule |
| --- | --- | --- | --- |
| Title / hook | type (number, confession, opinion, question), length | LinkedIn impressions per follower; dev.to views in 48 h | A type that wins twice becomes the default |
| Cover | window kind (terminal, app), the wink | dev.to views relative to the tag's usual | Keep the series look; tune the window and wink |
| Screenshots | count, kind (terminal, desktop, diagram) | LinkedIn saves; "how did you…" comments | Fewer, clearer images if saves don't move |
| LinkedIn copy | length, bullets vs prose, image vs carousel | Engagement rate; dev.to referrers from linkedin.com | Keep what sends readers, not only reactions |
| Day and time | weekday, hour (author's time zone), and the time zone of most viewers | Impressions in the first 2 hours and at 48 h; LinkedIn viewer locations | Tuesday morning to start; reviewed at every recalibration, and tried against one alternative (e.g. Thursday, or a later hour if most viewers are abroad) for two topics before switching |
| Hook and wink | the hook's kind (moment, pain, confession, number), the wink's universe | Comments with substance vs reactions; corrections | Corrections are good: they mean people read closely |
| Tags | the 4 dev.to tags | dev.to views | Drop a tag that never brings views |
| Community | subreddit, title format, link placement | Upvote ratio, referrers from reddit.com, removals | See recalibration rules |

## Recalibration

- **Per post (10 minutes, at the 7-day mark):** comments on the post's task: links, `vars:`, `gate:`, the numbers,
  `log.best-comment:`, `log.keep:` and `log.change:`.
- **When a post underperforms the baseline by half or more,** diagnose in this order: hook → image/format →
  publishing time → topic. The topic is the last suspect.
- **Rules that change the backlog:**
  - A question asked in comments by two or more people becomes a topic or an in-between post.
  - A format or hook type that beats the others twice becomes the default.
  - A topic whose information-gain sentence turns weak moves down or merges into the gotchas post.
  - A moderator removal: re-read that community's rules and recent posts before posting there again; two removals
    in one community drop it.
  - A community that beats LinkedIn on comments with substance twice gets the topic's first post next time.
- **Recalibration 1 (after topic 4):** reset the targets from real numbers, review the language choice and the
  publishing day and time, reorder topics 5–8, decide whether the in-between posts are worth their time.
- **Recalibration 2 (after topic 8):** order the backlog; keep the cadence, step up to weekly, slow down, or end
  the series. Write the decision in the log.

## Metadata in TODO.yaml

Every fact about a post lives in [`TODO.yaml`](TODO.yaml), on the post's task: the task is tagged `post`, its
`position` is the post's folder (`docs/blog/posts/<YYYY-MM-DD>-<slug>`), its status and due date are the post's.
Facts are comments on that task, one `key: value` each, appended (never edited) with
`mise run blog:todo -- add --comment "<key>: <value>" --task-id <id>` or by the tasks. A task tagged `series` holds
account-wide numbers. The todo CLI drops any field it doesn't know, which is why nothing else is stored there.
The post's files (`post.md`, `linkedin.md`, `community.md`, `cover.json`, `review.md`, `images/`) are found by
convention in its folder. A post published before the tooling carries `legacy: true` in its front matter: it skips
the content checks and the publish gate, never the safety ones; no new post uses it. `mise run blog:report` prints everything and flags any comment outside the schema.

| Key | Value | Written by |
| --- | --- | --- |
| `devto.id`, `devto.url` | the article id and URL | `blog:push` and `blog:stats` (when it finds one by title) |
| `linkedin.url`, `community.url` | a URL | the author |
| `stats` | `<YYYY-MM-DD> <platform> <metric>=<n> [<metric>=<n>…] (<api\|manual>)` | `blog:stats`, `blog:record` |
| `gate` | `<YYYY-MM-DD> <PASS\|BLOCKED> stepps=<n>/12` | the gate run |
| `vars` | `hook=… cover=… images=… linkedin=… lang=… day=… tags=…` | the author / the gate |
| `log.keep`, `log.change`, `log.best-comment` | text | the author at 7 days |
| `pick` | `<YYYY-MM-DD> keep\|swap <reason> <source>` | `/blog:pick`, after the author decides |
| `hook`, `recipe`, `sources` | the topic's angle, its RECIPE in one line, the repo files and links it rests on | the roadmap (topic tasks), `/blog:draft` |
| `note` | free text: a hypothesis, a follow-up, an unknown metric (`<date> <platform> <metric> unknown`) | anyone |
| `decision` | `<YYYY-MM-DD> <text>` | recalibrations (series or recal tasks) |

Locally, `mise run blog:push <post>` sends a draft from a pushed branch (or publishes from `main`); the token comes
from `DEVTO_TOKEN` in CI, or through fnox (`fnox.toml`: gopass `tokens/dev.to`) locally.
