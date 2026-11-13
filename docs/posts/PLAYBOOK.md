# Content series playbook

The living rules of the series. It starts as the design in [the spec](../superpowers/specs/2026-11-13-content-series-design.md) (the record of how it was decided)
and changes only at recalibrations, with each change written in the **Decisions log** at the end. Voice and
visuals live in [`STYLE.md`](STYLE.md). [`TODO.yaml`](TODO.yaml) holds the roadmap **and every post's metadata**
(see **Metadata in TODO.yaml**): `mise run posts:report` prints it, `mise run posts:todo -- dashboard` shows the board.

## How a post moves

1. **Pick:** run [`prompts/next-pick.md`](prompts/next-pick.md) the Tuesday before; the author approves keep or
   swap; the decision becomes a `pick:` comment on the topic's task.
2. **Branch:** `feat/post-<slug>`; copy [`templates/`](templates/) into `docs/posts/articles/<YYYY-MM-DD>-<slug>/`,
   the date being the planned publish date (never renamed once published: it is in the image URLs).
3. **Draft:** `post.md` (skill `technical-article-writer`), `linkedin.md` (`linkedin-ghostwriting`), `community.md`
   (`reddit-posts`), images with [`tools/`](tools/) (unblurred captures in `raw/`, never committed).
4. **Check:** `mise run posts:check <post>` until there are no blocks.
5. **Gate:** a fresh agent runs [`prompts/gate.md`](prompts/gate.md) and writes `review.md`; fix every **Must fix**,
   take the **Consider** items you agree with.
6. **Draft on dev.to:** open a PR. The `Posts` workflow pushes a dev.to draft (images from the branch) and comments
   the preview link; every push updates the same draft. CI never writes the repo: the article is found by title
   until a local `posts:push` or `posts:stats` records its `devto.id:`.
7. **Publish:** set `published: true`, push, merge. The run on `main` publishes the article with images from `main`.
8. **LinkedIn (by hand):** the post, then the first comment with the dev.to link; stay for replies. Community post a
   few days later.
9. **Record:** on the post's task, `linkedin.url:` (and `community.url:`), `gate:` and `vars:` comments
   (`mise run posts:todo -- add --comment "<key>: <value>" --task-id <id>`); the task done
   (`mise run posts:todo -- status <id> --set done`); `mise run posts:report --write` refreshes the README index.
10. **Measure:** at 48 h and 7 days, `mise run posts:stats` (dev.to, referrers, repo traffic) and
    `mise run posts:record <post> linkedin impressions=… reactions=… comments=… reposts=…` (read by hand); at 7 days
    the `log.*` comments.

The tooling never takes a live article offline: to unpublish, do it by hand on dev.to.

## Metadata in TODO.yaml

Every fact about a post lives in [`TODO.yaml`](TODO.yaml), on the post's task: the task is tagged `post`, its
`position` is the post's folder (`docs/posts/articles/<YYYY-MM-DD>-<slug>`), its status and due date are the post's.
Facts are comments on that task, one `key: value` each, appended (never edited) with
`mise run posts:todo -- add --comment "<key>: <value>" --task-id <id>` or by the tasks. A task tagged `series` holds
account-wide numbers. The todo CLI drops any field it doesn't know, which is why nothing else is stored there.
The post's files (`post.md`, `linkedin.md`, `community.md`, `review.md`, `images/`) are found by convention in its
folder. `mise run posts:report` prints everything and flags any comment outside the schema.

| Key | Value | Written by |
| --- | --- | --- |
| `devto.id` | the article id | `posts:push` (when it creates one), `posts:stats` (when it finds one by title) |
| `devto.url`, `linkedin.url`, `community.url` | a URL | `posts:push` / the author |
| `stats` | `<YYYY-MM-DD> <platform> <metric>=<n> [<metric>=<n>…] (<api\|manual>)` | `posts:stats`, `posts:record` |
| `gate` | `<YYYY-MM-DD> <PASS\|BLOCKED> stepps=<n>/12` | the gate run |
| `vars` | `hook=… cover=… images=… linkedin=… lang=… day=… tags=…` | the author / the gate |
| `log.keep`, `log.change`, `log.best-comment` | text | the author at 7 days |
| `pick` | `<YYYY-MM-DD> keep\|swap <reason> <source>` | the next-pick run, after the author decides |
| `decision` | `<YYYY-MM-DD> <text>` | recalibrations (series or recal tasks) |

Locally, `mise run posts:push <post>` sends a draft from a pushed branch (or publishes from `main`); the token comes
from `DEVTO_TOKEN` or gopass `tokens/dev.to`.

## Intent

Turn what this repo already solves into a regular series: for each topic, a **dev.to post** (detailed, not a
tutorial), a **LinkedIn post** that stands on its own and points to it, and, from topic 2, one **community post**.
The Omarchy-ish post ([dev.to](https://dev.to/roalcantara/omarchy-ish-macos-tiling-an-fn-layer-and-raycast-3fd8)) is
the model; its LinkedIn reception was positive.

The why: **show know-how and lessons learned, not chase clicks.** Every dev.to post carries a **RECIPE**, a TL;DR
the author (and readers) can come back to and point at. Together, the recipes become a public "TLDR knowledge base"
of how things are done in dots.

## Goals, in priority order

The order means **higher wins when two goals conflict**, not "lower matters less". Goals 1–3 are what the content
*is*; goals 4–5 are how far it *reaches*, and reach multiplies whatever is there.

| # | Goal | What it means | Serves first | One sign it works |
| --- | --- | --- | --- | --- |
| 1 | **Knowledge base** | Everything lives in dots: `docs/posts/` and the recipes index, owned and permanent | Future author | The author links a recipe to answer someone instead of re-explaining |
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

**Ownership:** the repo is the original. dev.to, LinkedIn and communities are copies that point back to it.

## Delivery goals

- One topic per fortnight, published as a pair (dev.to + LinkedIn), with a lighter LinkedIn-only post in the week
  between: about one LinkedIn post a week.
- Each topic can be adopted without adopting dots. The most widely applicable topics come first; dots-specific
  tools (`xcg`, `gitx`, `yb`) come last or not at all.
- **dots is the example, never the headline.** Titles lead with the problem (git, secrets, AI agents, backups);
  dots appears in the body as the working proof.
- Each dev.to post has a RECIPE block that works on its own. A recipes index in the repo (`docs/posts/README.md`)
  links every RECIPE.
- From topic 2, each topic gets **one community post**, written natively for that community, never as spam.
- dev.to publishing (drafts on PRs, publishing on merge) and dev.to numbers are automated from the repo; LinkedIn and Reddit are posted and measured by
  hand.
- Each post is checked before publishing, measured after, and the series is adjusted on a fixed rhythm.

## Non-goals

- Full tutorials or install guides. Whoever wants every step follows the links into dots.
- Growth tactics: engagement pods, hashtag stuffing, a cadence the author cannot keep, comment bait.
- Covering every folder in `config/`. The topic list is a backlog, not a commitment.
- LinkedIn profile work. It helps (see **Notes for the author**), but is out of scope here.
- Curated lists and directories (awesome-dotfiles and similar). Kept for later.
- Automating LinkedIn or Reddit posting or analytics (LinkedIn's member post analytics needs an approved Community
  Management API app; schedulers such as Postiz or Buffer add a service and need the LinkedIn login).

## Anti-goals

- Any secret, key, token name, email, client or private repo name visible in text or screenshots. This matters
  most for the secrets and backup topics.
- Posts that read as ads or hype ("10x your setup!").
- Spam in any form: the same post in several communities, bare links, posting and leaving, reposting a topic that
  sank, undisclosed self-promotion.
- Hate, rage bait, or takes aimed at other people or tools to provoke. Comparisons stay factual ("vs." tables).
- A RECIPE that cannot be followed without reading the whole post.
- Dropping the honest "what I (think I) learned" part to make a post look more polished.

## Constraints

- The author writes and publishes. Claude drafts posts, captures and frames images, and keeps the log; nothing is
  published or committed without the author.
- dots is public (github.com/roalcantara/dots). Links point to files on `main` or to PRs.
- dev.to front matter: `title`, `published: false` until the author publishes, `description`, `tags` (max 4),
  `cover_image`. Cover 1000 × 420.
- LinkedIn: about 210 characters show before "see more"; posts with outside links tend to get less reach, so the
  dev.to link goes in the first comment.
- Images go through the existing pipeline: unblurred captures in `docs/posts/articles/<post>/raw/` (git-ignored), framed
  output in `images/`.

## Language

**English everywhere by default; LinkedIn's own feed translation covers part of the Portuguese-speaking network.**
Chosen by the author from an independent evaluation (2026-11-13). Inputs: the author writes technical posts most
comfortably in English; the LinkedIn network is mixed, probably mostly Brazilian; opportunities from both Brazil and
abroad matter; acceptable extra effort is "Claude translates, the author reviews".

Ranked options considered:

1. **English everywhere** (chosen): one RECIPE per topic (goals 1–2), one consistent signal abroad (goal 3), no
   extra effort. LinkedIn auto-translates feed posts for some members whose interface is in Portuguese.
2. **English, with the LinkedIn post in PT-BR:** best if the network is mostly Brazilian; weaker international
   signal; 10–15 minutes of review per post.
3. **One bilingual LinkedIn post (EN, then PT):** dense; only one language gets the hook. Fallback.
4. **Separate EN and PT LinkedIn posts:** doubles posting, splits engagement. Rejected.

Dropped: PT-BR dev.to copies or TabNews (two versions of every RECIPE work against goal 1); r/brdev (self-promotion
needs moderator approval). A single native PT post for the strongest topic stays possible later; dev.to's
`canonical_url` would keep it from competing with the original.

**Test in topics 1–4:** topics 1 and 3 get the LinkedIn post in English, topics 2 and 4 in PT-BR (option 2); the
in-between posts alternate. At 7 days, record impressions, engagement, comments, profile views, and the viewers'
location and job titles from LinkedIn analytics. At recalibration 1:

| If | Then |
| --- | --- |
| PT-BR gets ≥ 1.5× the engagement and international viewers stay ≥ 15% | Switch to option 2 |
| PT-BR wins on engagement but international viewers drop below 15% | Switch to option 3 |
| Otherwise | Stay on option 1 |

Four posts on a small account are directional only; comment quality and inbound messages weigh as much as counts.
No primary data was found on whether LinkedIn reduces reach by post language.

**Rules for any PT-BR text:**

- Translate only from the final English version; never edit the PT copy on its own.
- Keep in English: code, commands, flags, paths, tool names, error messages, Conventional Commit types, "RECIPE".
- Keep the loanwords Brazilian developers use (commit, deploy, backup, hook, secrets, dotfiles, pipeline).
- Same voice: first person, "você", the honest mistakes kept; rewrite the hook naturally, not word for word.
- Hashtags: 2–3 English tool or topic tags, at most one PT/BR tag.
- A short EN↔PT glossary in `docs/posts/GLOSSARY.pt.md` keeps the reviews consistent.

## The formats

### dev.to post

800–1,300 words.

```text
front matter (published: false)
> DISCLAIMER  — not a tutorial; it lives in dots; grain of salt
cover image
**OVERVIEW**            — the problem, as a small story (why I needed this)
**RECIPE**              — the TL;DR (format below); the part people bookmark
**HOW IT WORKS**        — the pieces, a picture or two, the one diagram if needed
**vs. <the usual way>** — a small table: what most people do, what I do, the trade-off
**WHAT I (THINK I) LEARNED** — 3–5 bullets, each a lesson, at least one mistake
**REFERENCES**          — tools, the dots files and PRs
"Corrections and ideas are very welcome. :)"
```

The RECIPE block, modelled on tldr pages:

```markdown
**RECIPE**

> **Use it when:** <one line>
> **You need:** <tools, one line>

1. <step> — `command or file`
2. <step> — `command or file`
3. <step> — `command or file`

⚠️ **Gotchas:** <one line each, at most 3>
📁 **In dots:** [file](link) · [file](link)
```

**Titles and tags.** Draft 10 titles, keep the most specific. Patterns that work on dev.to: a number ("5 things…"),
a confession ("It took 54 fixes to…"), an opinion with a reason. Tags (max 4): lead with the large tags that fit
(`git`, `devops`, `productivity`, `terminal`, `ai`, `docker`, `security`, `macos`); `dotfiles` only as the fourth,
if at all.

### LinkedIn post

Useful without clicking. 900–1,300 characters.

```text
Hook (≤ 210 chars): a number, a surprise or a small confession from the topic.
2–4 short lines: the problem and the decision.
The recipe in 3 bullets (→ …).
One honest lesson ("What I got wrong: …").
A question that invites people's own setups ("How do you …?").
Image: the cover, one framed screenshot, or a 4–6 slide carousel of the RECIPE (PDF).
3 hashtags. dev.to link in the first comment, posted right after.
```

The in-between LinkedIn-only post takes one piece of the same topic (a gotcha, a before/after number, the RECIPE as
a carousel) and links back to the dev.to post in the first comment.

### Community post

The story and the RECIPE written natively for one community, in plain markdown, with the dev.to link at the end
("I wrote this up here") or in a comment where links in posts are frowned on. Rules in **Communities**.

## Choosing the next topic

The schedule is the default, not a contract. At the start of each cycle (the Tuesday before publishing), an agent
re-evaluates the next pick against the current context, and the author approves the result.

**Inputs:** the scheduled topic; the ready topics in the schedule and the backlog; the latest metadata of the past posts (`mise run posts:report`)
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

- **Runway:** the author's Reddit account (u/roalcantara) has some history. From 2026-11-17 to 2026-11-30, comment
  and answer in the target subreddits only, no own links. Community posts start with topic 2.
- **90/10:** at most one in six of the author's posts or comments in a community links to their own work.
- **One community per topic.** Read its sidebar rules and recent top posts first, use the required flair and title
  format. Never the same post in two communities.
- **Disclose:** "I wrote this up on dev.to".
- **Stay 2 hours** after posting to answer; thank corrections.
- **Never repost** a topic that sank; record it in the log instead.

| Topic | First choice | Alternatives |
| --- | --- | --- |
| Omarchy-ish macOS (published) | r/unixporn (strict screenshot format) | r/macos, yabai GitHub Discussions |
| 1. SOPS + age secrets | r/devops (later, if a slot opens) | r/git |
| 2. Commit conventions | r/git | r/programming |
| 3. Back up a list | r/selfhosted | r/DataHoarder, restic forum |
| 4. hk hooks | r/commandline | hk GitHub Discussions |
| 5. Bootstrap, 54 fixes | r/dotfiles | r/commandline |
| 6. Spec → plan → agents | r/ClaudeAI | r/ExperiencedDevs; Hacker News once, if the post is strong |
| 7. mise profiles | r/commandline | mise GitHub Discussions |
| 8. Docker images with CST | r/docker | r/devops |

Subreddit names and rules are checked before each post; the table is a starting point. Each community post is
drafted with the `reddit-posts` skill and kept in the topic's `community.md`.

## Topics

Four themes; neighbouring posts come from different themes. Each topic must pass the **information-gain gate**
before drafting: one sentence on what it adds that the top existing articles don't (usually the decision, the
mistakes and the real numbers). If that sentence cannot be written, the topic moves down or merges.

| Theme | Topics |
| --- | --- |
| **A. A machine you can rebuild** | mise bootstrap end to end · mise profiles · one Brewfile · macOS settings as code · back up a list · secrets with SOPS + age |
| **B. A repo that checks itself** | commit conventions · hk hooks · testing dotfiles (BDD) · Docker images verified by CST |
| **C. Working with AI agents** | superpowers: spec → plan → worktree · agent skills in a lock file · "my agents ran zsh and lied to me" |
| **D. Desktop and terminal** | Omarchy-ish (published) · zsh startup, measured · later: the fzf tools |

### Scheduled (topics 1–8)

| # | Topic | Hook from the repo | RECIPE in one line | Drivers | Sources |
| --- | --- | --- | --- | --- | --- |
| 1 | **Secrets in git with SOPS + age** (A) | Secrets live in the repo, encrypted on commit, decrypted on checkout | git clean/smudge filters + `.gitattributes` + an age key outside the repo | Practical value, social currency | `script/{clean,smudge}.sops.sh`, `.sops.yaml`, `.gitattributes`, `docs/CONTRIBUTING.md` |
| 2 | **Commit conventions that write your release notes** (B) | Every commit in dots follows one format, and the changelog writes itself | Conventional Commits + a capitalised description + a commit-msg check + semantic-release | Practical value | `docs/CONTRIBUTING.md`, `.github/workflows/release.yml`, `CHANGELOG.md`, the locale fix in `hk` |
| 3 | **Back up a list, not your home folder** (A) | A full-home run read 606,863 files, 541 GiB, mostly VMs | restic + an allowlist manifest; rebuildable things come back from dots, Homebrew and lock files | Emotion (surprise), practical value | `docs/REINSTALL.md`, `script/backup.ts` |
| 4 | **One linter config for pre-commit and CI with hk** (B) | Eight linters, one file, the same checks locally and in CI | `hk.pkl` steps, `hk check --all`, hooks installed by the bootstrap | Practical value | `hk.pkl`, `config/hk/`, `docs/TESTING.md` |
| 5 | **It took 54 fixes to make my bootstrap boring** (A) | One command from a clean Mac or Linux box to a working machine | `install` → `mise bootstrap`; core group must pass, the rest warns; logs in `~/.local/state/dots/` | Stories, emotion | `install`, `config/mise/conf.d/bootstrap.toml`, README, `git log --grep 'fix(install)'` |
| 6 | **Spec → plan → agents on a personal repo** (C) | 14 design specs, 336 pinned agent skills, every change through a worktree | brainstorm → spec → plan with checkboxes → agent implements in a worktree → quality gate | Social currency, stories | `AGENTS.md`, `docs/superpowers/`, `config/agents/skill-lock.json` |
| 7 | **mise profiles: one repo, four kinds of machine** (A) | Desktop vs container, macOS vs Linux, from the same config | mise env profiles, `miserc.local.toml` written by `install`, per-profile tools | Practical value | `config/mise/`, README "Gotchas" |
| 8 | **Test your Docker images like code (CST)** (B) | The dev images are built and checked by Container Structure Tests in CI | multi-stage Dockerfile + CST manifest + `mise run build/test` + GitHub Actions | Practical value, social currency | `distros/`, `docs/DOCKER.md`, `.github/workflows/` |

### Backlog (ordered at recalibration 2)

- One Brewfile for macOS and Linux (A): `config/homebrew/Brewfile`.
- macOS settings as code (A): `config/mise/conf.d/macos.toml`, `docs/MACOS.md`.
- Testing dotfiles with BDD (B): `docs/TESTING.md`, `test/`.
- Agent skills pinned in a lock file (C): `config/agents/skill-lock.json`, `script/agent-skills.ts`.
- "My agents ran zsh and lied to me" (C): the silent one-pass loop and the switch to bash; also a strong in-between
  post for topic 6.
- Zsh startup, measured (D): `script/zsh-verify.sh`.
- The gotchas list (all): README "Gotchas" and the fix commits above.
- The fzf tools (`xcg`, `gitx fza`) (D).

## Timeline

One topic every two weeks, Tuesdays (author's time zone, working-week morning). The community post goes out
Thursday–Saturday of the same week; the in-between LinkedIn post the Tuesday after. December holidays are skipped.

| Week of | Pair (dev.to + LinkedIn) | Community post | In-between LinkedIn post |
| --- | --- | --- | --- |
| 2026-11-17 | 1. Secrets with SOPS + age | — Reddit runway: comment only | the RECIPE as a carousel |
| 2026-12-01 | 2. Commit conventions | r/git | the locale bug in the commit linter |
| 2026-12-15 | — light: year-end "what I automated" | Omarchy-ish → r/unixporn | holiday break |
| 2027-01-05 | 3. Back up a list | r/selfhosted | the 606,863 files number |
| 2027-01-19 | 4. hk hooks | r/commandline | one config, eight linters, shown |
| 2027-02-02 | 5. Bootstrap, 54 fixes | r/dotfiles | **recalibration 1 is due before this** |
| 2027-02-16 | 6. Spec → plan → agents | r/ClaudeAI | "my agents ran zsh and lied to me" |
| 2027-03-02 | 7. mise profiles | r/commandline | the `miserc.local.toml` gotcha |
| 2027-03-16 | 8. Docker images with CST | r/docker | **recalibration 2: order the backlog** |

Per topic, work starts the Tuesday before publishing: next-pick check (see **Choosing the next topic**) → plan →
draft and images → cold read → author review → publish. Before topic 1, a one-off setup: the stats task, the devto-cli wiring, the shared image tools, and
the baseline recorded as comments on the Omarchy post task and the series task.

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

- dev.to: the Omarchy post's numbers, read by `mise run posts:stats` during setup (no manual step).
- LinkedIn: no API is available for personal posts. The baseline is the **median of topics 1 and 2**; until then,
  targets are not applied. If the author has the Omarchy post's LinkedIn numbers, or LinkedIn's analytics export
  for it, they are recorded as context, not as a target.

Signals:

| Signal | Where | Goal |
| --- | --- | --- |
| Impressions; impressions per follower | LinkedIn | 4–5 |
| Engagement rate = (reactions + comments + reposts) ÷ impressions | LinkedIn | 5 |
| Comments with substance (a question, a setup, a correction) | All | 2–3 (worth more than reactions) |
| Saves and reposts | LinkedIn | 2, 5 |
| Views, reactions, comments | dev.to | 3–4 |
| Visitors referred from linkedin.com and reddit.com | dev.to referrers | 4 (do the copies send readers to the original?) |
| Upvote ratio, comments with substance, removals | Reddit | 4–5 |
| Repo views and stars | GitHub traffic | 3 |

Starting targets, from topic 3, reset at recalibration 1: per topic, at least the baseline's LinkedIn impressions,
an engagement rate at or above the baseline, and at least 3 comments with substance across all platforms.

### 3. Over the series (monthly)

- Recipes reused: times the author linked a RECIPE to answer someone (goal 1, the clearest sign).
- Inbound conversations: messages or comments that ask for help, invite a talk, or mention work (goals 3–4).
- Followers and profile views month over month (goal 4).

## Tuning each element

With one post a fortnight, nothing here is statistically sound: **change one thing at a time, and write it down**.
Each post's task records its variables (`vars:`), the hypothesis for the one that changed (`note:`), and the numbers
(`stats:`).

| Element | Variables recorded | Measured by | Rule |
| --- | --- | --- | --- |
| Title / hook | type (number, confession, opinion, question), length | LinkedIn impressions per follower; dev.to views in 48 h | A type that wins twice becomes the default |
| Cover / banner | style (generated, screenshot, text-only) | dev.to views relative to the tag's usual | Alternate until one wins twice |
| Screenshots | count, kind (terminal, desktop, diagram) | LinkedIn saves; "how did you…" comments | Fewer, clearer images if saves don't move |
| LinkedIn copy | length, bullets vs prose, image vs carousel | Engagement rate; dev.to referrers from linkedin.com | Keep what sends readers, not only reactions |
| Day and time | weekday, hour (author's time zone), and the time zone of most viewers | Impressions in the first 2 hours and at 48 h; LinkedIn viewer locations | Tuesday morning to start; reviewed at every recalibration, and tried against one alternative (e.g. Thursday, or a later hour if most viewers are abroad) for two topics before switching |
| Tone | voice-check result, humour yes/no | Comments with substance vs reactions; corrections | Corrections are good: they mean people read closely |
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

## Automation and skills

| Step | How | Notes |
| --- | --- | --- |
| Draft the dev.to post | `technical-article-writer` (installed) | Its intake and title steps fit; its objective is "personal branding / authority", and the spec's voice overrides its defaults |
| Draft the LinkedIn post | `samber/cc-skills@linkedin-ghostwriting` (installed 2026-11-13) | Quantified, results-first posts; 5.8K installs, audits pass |
| Hooks, titles, closing line | `copywriting-hooks`, `copywriting-cta` (installed 2026-11-13) | Used by `technical-article-writer`; the CTA stays "corrections welcome", no signup asks |
| Draft the community post | `reddit-posts` (installed) | 90/10, flair, subreddit format |
| Check shareability | `contagious` (installed) | STEPPS score in the log |
| Cold read | A fresh agent playing a mid-level developer | See **Success criteria** |
| Publish to dev.to | The Forem API directly, from bun file tasks in `mise-tasks/posts/`, run locally (`mise run posts:push`) and by `.github/workflows/posts.yml` | A PR that touches a `post.md` creates or updates a **draft** (images from the PR branch), comments the preview link; the merge to `main` updates the article with images from `main` and the front matter's `published` value. **Merging a PR with `published: true` is the author's publish button.** |
| dev.to numbers | `mise run posts:stats`: Forem API (`/api/articles/me/all`, `/api/analytics/referrers?article_id=` when available) | Token from gopass `tokens/dev.to` locally and the `DEVTO_TOKEN` repo secret in CI, never in the repo; recorded as `stats:` comments on the posts' tasks in `TODO.yaml` |
| LinkedIn and Reddit numbers | By hand at 48 h and 7 days, about 2 minutes per post | `mise run posts:record <post> linkedin impressions=… …` |
| Repo traffic | `gh api repos/roalcantara/dots/traffic/views` in the same stats task | |

The okou `devto` skill was considered and dropped: publish-only, its own tooling, 60 installs, a Snyk warning.
devto-cli and the `sinedied/publish-devto` Action were considered and dropped: the Action publishes whatever the
front matter says (a PR with `published: true` would go live before the merge), devto-cli was last released in
July 2024, and the direct API needs no extra tool. Prior art for draft-on-PR, publish-on-merge:
[shihanng's workflow](https://dev.to/shihanng/publishing-dev-articles-from-github-3jc2).

## Evidence behind the choices (2026-11-13)

- **The author's dev.to baseline is low:** the Omarchy post has 0 reactions, 0 comments; the best earlier post
  ("Tidy Up Your VSCode Explorer with File Nesting", a one-minute single tip) has 7 reactions.
- **The `#dotfiles` tag is nearly empty on dev.to:** its top posts of the past year have 0–5 reactions. Large tags
  do far better: `#git` (top post 263 reactions, 113 comments), `#devops`, `#productivity`, `#terminal`.
- **What wins there:** numbered practical lists ("Five Git Config Settings Every Dev Needs", 48 reactions,
  27 comments), confessions of failure ("How I Almost Deleted My Entire Project", 112 / 45), clear opinions
  ("Don't Write Markdown Files for Your Coding Agent. Write Scripts.", 60 / 48).
- **The git history holds the stories:** 54 `fix(install)` commits behind the bootstrap; agents that ran
  `for x in $list` in zsh and silently looped once; a `mise.toml` that would have been trusted silently; a commit
  linter that missed lowercase subjects in other locales; a bootstrap that now warns instead of aborting; CI
  workflows that needed their own concurrency groups.

Source: dev.to public API (`/api/articles?tag=<t>&top=365`, `?username=roalcantara`) and `git log` on 2026-11-13.

## Decisions log

Newest last. Each recalibration adds its decisions here; the spec is never edited for them.

### 2026-11-13 · decided by the author

- The goal order and tiebreaks, the voice, the audience order, ownership.
- Topics: mise bootstrap, commit conventions, hk, CST/Docker, mise profiles and superpowers added; four themes.
- Tuning per element, with one change at a time and the cold read.
- LinkedIn and Reddit: posted and measured by hand; no scheduler, no API application.
- Reddit presence, never spam or hate; the community rules above.
- awesome-dotfiles and similar lists: later.
- Installing skills: allowed once agreed.
- Language: English by default, PT-BR tested on LinkedIn in topics 2 and 4 (the agent's recommendation).
- Re-evaluating the next topic against current context (news, comments), with the news as a brief hook only.
- Skills installed: `linkedin-ghostwriting`, `copywriting-hooks`, `copywriting-cta`.
- Start on 2026-11-17; publishing day and time are reviewed at each recalibration.
- Baseline: dev.to read by the stats task; LinkedIn from the series' own first two posts.
- Tooling: bun file tasks instead of a script; every tool from the Brewfile whenever possible; the token in gopass
  at `tokens/dev.to` and as the `DEVTO_TOKEN` repo secret; drafts on PRs, publishing on merge.

### 2026-11-13 · proposed by Claude, accepted with the spec

- Fortnightly pairs plus one in-between LinkedIn post, Tuesdays, starting 2026-11-17, December holidays skipped.
- The order of topics 1–8 and the theme alternation; the rest ordered at recalibration 2.
- The RECIPE format (tldr-style) near the top of the dev.to post; the dev.to link in LinkedIn's first comment.
- Tag strategy: large tags first, `dotfiles` at most fourth.
- STEPPS ≥ 6 with Practical value = 2 as the pre-publish bar; LinkedIn targets applied from topic 3.
- A two-week Reddit runway; the Omarchy post to r/unixporn in the December light week.
- The Forem API from bun file tasks (`mise-tasks/posts/`) and a CI workflow: drafts on PRs, publish on merge.
- A `posts:stats` task for dev.to numbers, referrers and repo traffic.
- Moving the image tools to `docs/posts/tools/`; `README.md` and `LOG.md` in `docs/posts/`.

### 2026-11-13 · during setup

- The backlog item "my agents ran zsh and lied to me" became the **preflight post** (`2026-11-13-zsh-word-split`), published
  before topic 1 to prove the flow end to end. Topic 6's in-between post is now "336 agent skills in a lock file".
- Publishing runs on the Forem API from bun file tasks (`mise-tasks/posts/`) and the `Posts` workflow: drafts on
  pull requests, publishing on merge. devto-cli is not used.
- The roadmap is `TODO.yaml` (todo CLI, YAML), read by `/wip:resume`. `todo` is pinned in its mise task: it has no
  Homebrew formula, and cargo's `todo-cli` is another crate.

### 2026-11-13 · DRY pass ([design](../superpowers/specs/2026-11-13-content-series-dry-design.md))

- The dev.to token resolves through fnox (`fnox.toml`: gopass `tokens/dev.to`, first line); CI uses the repo secret.
- Tasks parse their arguments from argv (`parseArgs`), not mise's `usage_*` variables.
- Posts live in `docs/posts/articles/<YYYY-MM-DD>-<slug>/`; the folder name is the post's id.
- Every post's metadata is comments on its task in `TODO.yaml`; `stats.csv`, `LOG.md` and the front matter `id:` are
  gone, and CI no longer commits to the repo. `posts:report` replaces the log and writes the README index.
