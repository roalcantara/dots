# Blog: voice, brevity, cover and a leaner playbook — design

> **Status:** historical design record. The current rules are in [`docs/blog/PLAYBOOK.md`](../../blog/PLAYBOOK.md) and
> [`docs/blog/STYLE.md`](../../blog/STYLE.md).

Fourth pass on the blog series, after the preflight post was drafted ([first design](2026-11-13-content-series-design.md),
[DRY](2026-11-13-content-series-dry-design.md), [commands](2026-11-13-blog-commands-design.md)). Asked by the author:
judge the posts through the `contagious` (STEPPS) lens and fix four notes, slim the playbook, and run an independent
audit. The audit was run with GPT-6.1 Terra (Gemini 4 failed on quota and connectivity); its findings are folded in.

## Intent

Posts should be unmistakably the author's: a small, true, geeky moment up front, nothing padded, nothing the author
hasn't lived or proven, a LinkedIn post short enough not to read as generated, and a cover people stop for. The
playbook keeps only what doesn't date; everything that changes lives in `TODO.yaml`.

## Goals

1. **A personal trait** (note 1): every post and LinkedIn post opens with a hook built from a real moment or a common
   pain, with at most one geeky wink.
2. **TL;DR and verified** (note 2): each fact once; no claim the author hasn't lived or a command in the repo doesn't
   prove.
3. **A short LinkedIn post** (note 3): a hook plus one insight, the takeaway for someone who never clicks.
4. **A vibrant cover** (note 4): the approved Charm-style template, rendered from HTML.
5. **A timeless playbook:** schedules, topics and per-topic data leave PLAYBOOK.md for `TODO.yaml`.
6. **The audit's findings** fixed (below).

## Non-goals

- Generated illustrations (the cover is a coded template).
- Rewriting the Omarchy post's text (it is published; it only gets the `legacy` flag).
- Changing the goal order, the publishing flow or the commands' boundaries.

## Anti-goals

- An invented anecdote, quote, number or experience, even to make a hook work.
- Humour that needs explaining, mocks people or tools, or crowds out the lesson.
- A LinkedIn post that teases without giving the insight.
- Two places holding the same rule or the same schedule.

## Decisions

### 1. The trait: the hook (STEPPS: Stories, Emotion, Social currency)

- **Every post opens with the hook:** a real moment from the author (what happened, how they noticed, what it cost)
  or a pain readers share, told in one to three sentences, first person.
- **One geeky wink, at most, per post**, from the author's interests: technology and gadgets, AI and machine
  learning, productivity hacks, comic books, Harry Potter, The Lord of the Rings and fantasy, cinema, science,
  science fiction. It frames the real moment ("I felt like Ron with a broken wand"); it never replaces it. The same
  wink can echo once more: the cover's emoji and the terminal's "← aside".
- The author's existing tics stay welcome (the DISCLAIMER, "**YOU HAVE BEEN WARNED!**", "**NO, SERIOUSLY!**").
- **`/blog:draft` suggests hooks; the author picks** (author's request). From the repo's evidence (the commits,
  fixes and notes behind the topic), it proposes **3–5 hook options** of different kinds: a relatable pain, a small
  confession, a "you won't believe" number from the repo, and one or two framed by a geeky wink from the author's
  interests. Each option says which repo fact it rests on and what the author must confirm ("did you notice it in a
  real run?"). It asks the author to pick one, edit it or write their own:
  - the picked or edited hook goes into the post (and, shortened, into the LinkedIn hook) as the author's own words;
  - if the author skips, the post keeps `<author: the moment — how you noticed, what it cost>` and the options are
    kept right below it as an HTML comment (`<!-- hook options: … -->`), so the next session can pick up from them.
  Options are suggestions, never facts: none goes into the post without the author's pick.
- STYLE.md's voice table changes "Light humour, rare" to "**One geeky wink per post, always tied to a real moment**".

### 2. Lived or proven (STEPPS: Practical value; trust)

- **Every claim is lived or proven:** the author did it, or a command, file or commit in the repo shows it, linked.
  Anything else is cut: no setups the author doesn't use (e.g. "on an Intel Mac…"), no "agents usually…" without
  evidence.
- **Each fact once:** a screenshot doesn't repeat a code block; the RECIPE doesn't repeat HOW IT WORKS.
- The gate treats an unproven claim as **Must fix** (new blocking item next to safety).
- STYLE gets a "Lived or proven" rule; `/blog:draft` and the gate prompt cite it.

### 3. LinkedIn: hook + one insight (STEPPS: Practical value, curiosity)

- **Shape:** the hook (≤ 210 characters, personal or geeky), then **one sentence with the insight** (what a reader
  keeps without clicking), then a pointer to the first comment. 250–450 characters; no bullet list; 1–3 hashtags.
- **First comment:** the dev.to link (`{devto.url}`), one line.
- The in-between post keeps the same shape.
- `blog:check` warns when the LinkedIn post is over 450 characters; the template, STYLE, PLAYBOOK and the
  `/blog:draft` instructions follow.

### 4. The cover (STEPPS: Public; recognisable in a feed)

Approved in the browser (style 4, "Charm playful" with OmniWM windows). Reference renders and sources:
[`assets/2026-11-13-cover-terminal.html`](assets/2026-11-13-cover-terminal.html) (+ `.png`),
[`assets/2026-11-13-cover-app.html`](assets/2026-11-13-cover-app.html),
[`assets/2026-11-13-cover-app-skeleton.png`](assets/2026-11-13-cover-app-skeleton.png).

- **Canvas:** 1000 × 420 CSS px, rendered at 2× (2000 × 840 PNG). Background Catppuccin Mocha base `#1e1e2e`, two
  soft circles (mauve `#cba6f7` at 18 %, teal `#94e2d5` at 16 %).
- **Left column** (flows, vertically centred): the series pill `dots #<n>` (pink `#f5c2e7` on base); **two explicit
  title lines**, SF Pro 700, 50 px, text `#cdd6f4`, the key phrase of line 2 on a pink highlight; a subtitle (19 px,
  `#a6adc8`) with **one emoji wink** and `$code` in yellow `#f9e2af`; **plain coloured hashtags** (SF Mono 700,
  19 px, no background), cycling mauve, green `#a6e3a1`, peach `#fab387`, sky `#89dceb`, from the post's tags.
- **Right: one OmniWM window**, chosen per post:
  - `terminal`: title bar with traffic lights and "Ghostty", body `#111116`, SF Mono 15.5 px, green `❯` prompt,
    3–5 lines (red for the surprising output, grey comments for the "← aside");
  - `app`: title bar with an app name (Zed, Notes…), body `#222226`, code lines and/or skeleton bars (grey
    `#3d3d43`, one highlight `#7f7150`);
  - `focused: true` adds the cyan `#62e6f0` border and glow.
- **Per-post input:** `docs/blog/posts/<post>/cover.json`:
  `{ "series": 0, "title": ["My AI agent's", "for-loop"], "highlight": "ran once", "subtitle": "…",
  "wink": "🪄", "window": { "kind": "terminal", "name": "Ghostty", "focused": true, "lines": [ … ] } }`; hashtags
  come from the front matter `tags`. Every string is HTML-escaped; line colours use a small markup
  (`{y:…}` yellow, `{r:…}` red, `{c:…}` comment, `{p}` prompt, `{bar:60}` skeleton bar, `{bar:46:hl}` highlight).
- **The whole series switches to this look** (author's decision): `tools/frame.py` frames screenshots on the Mocha
  base with the same OmniWM window chrome (title bar, traffic lights, app name), LinkedIn carousels use the same
  palette, and STYLE's visual identity is rewritten around it. The preflight post's screenshot is re-framed.
- **Renderer:** a template `docs/blog/tools/cover.html` filled by `blog:cover` and rendered by headless Chrome
  (`google-chrome`, already in the Brewfile) into `images/00-cover.png`. `tools/header.py` is retired (the Omarchy
  cover stays as published); `tools/frame.py` stays for screenshots. `blog:cover` stops with a clear message when
  Chrome is missing.

### 5. A timeless PLAYBOOK

- **Keeps:** intent and why; goals in order with tiebreaks; audience and ownership (**the repo is the source, dev.to
  the canonical public article**: README's "this folder is the original" is reworded); anti-goals; formats in brief;
  community rules (contribute first, 90/10, disclose); how the next topic is chosen; success criteria and how they
  are measured; tuning and recalibration rules; **the metadata schema** (its single home).
- **Points to, instead of repeating:** README's QUICK REFERENCE (the flow), STYLE (voice, look, rubric), the
  commands, `TODO.yaml` (what's next, when).
- **Moves to `TODO.yaml`:** the topics table becomes comments on each topic task, new schema keys `hook:`,
  `recipe:` and `sources:` (one comment each), read by `/blog:pick` and `/blog:draft`; the timeline is the tasks'
  due dates (already); communities per topic are the community tasks (already); the language test lives in the
  topic tasks' titles (already).
- **Removed:** the dated evidence section and the decisions log (the specs and git history are the record). Each spec
  gets a one-line status at the top: "Historical design record; the current rules are in docs/blog/PLAYBOOK.md".

### 6. Audit findings (GPT-6.1 Terra)

| # | Finding | Fix |
| --- | --- | --- |
| A1 | The preflight post claims the agent's bash reads `~/.bashrc`; `config/bash/bashrc` returns early for non-interactive shells | **Cut the claim now** (author's decision), cut the Intel path, qualify "agents write bash"; a later experiment by the author can bring it back as a lived detail |
| A2 | The merge would fail to update the Omarchy article: `checkPost` blocks it (no `linkedin.md`, no RECIPE) | Front matter `legacy: true` exempts a pre-tooling post from the content rules (RECIPE, LinkedIn, placeholders, markers), never from safety or `raw/` images; only the Omarchy post gets it |
| A3 | A push to `main` with `published: true` publishes without the gate | `blog.yml` on `main`: before publishing a non-legacy post, require `review.md` verdict PASS and fresh; otherwise fail the job without touching dev.to |
| A4 | A review only goes stale when `post.md` changes | `reviewIsFresh` also watches `linkedin.md`, `community.md`, `cover.json` and `images/` |
| A5 | Measurement is thinner than the success criteria | New metrics `substantive_comments`, `saves`, `sends`, `profile_views`, `followers`, `recipe_reuse`, `inbound`; `/blog:retro` asks for each (unknown is allowed and recorded as a `note:`); `blog:stats` records dev.to's `published_at` as a `note:` the first time |
| A6 | Rules duplicated and contradictory across docs | Covered by decision 5, plus the commands design's "markers warn" line corrected by its status banner |
| A7 | `blog:done` ignores failures of the steps it runs | Stop on a failing child step, with what was already recorded listed |
| A8 | No alt text guidance for LinkedIn images | STYLE and the LinkedIn template: write alt text for the image when posting |

## Constraints

Everything from the earlier designs holds: posts only through PR and merge; agent commands never push to `main`,
merge or publish; writes after the merge commit locally; tools from the Brewfile; the token through fnox; metadata
as `TODO.yaml` comments; one copy of each rule.

## Approaches

| Question | Considered | Chosen (by the author) |
| --- | --- | --- |
| Cover | A terminal, B mesh gradient, C Omarchy tiles; then six styles (OmniWM, ray.so, Vercel/Linear, Charm, Warp, glass) | **4 · Charm**, with OmniWM windows, plain coloured hashtags, two window kinds |
| Cover renderer | Pillow (`header.py`), HTML + headless Chrome, SVG + resvg | **HTML + headless Chrome** (Claude's call: matches the approved mockups exactly, emoji work, Chrome is in the Brewfile) |
| LinkedIn shape | hook + one insight, pure teaser, current length | **Hook + one insight** |
| Topic data | comments on topic tasks, drop them, a topics file | **Comments on topic tasks** |
| Audit | two models run by Claude, one, a handoff prompt | **Two models run by Claude** (only GPT ran) |

## Also in this pass

- The preflight post is reworked against all of the above: the hook (the author's real moment as an `<author: …>`
  marker until written), the verified-claims cut, the short LinkedIn post, a `cover.json` and the new cover, then
  `/blog:gate` again.
- `.superpowers/` is git-ignored (done).

## Builder's calls (settled from the builder check)

- **Freshness ignores the publish commit:** a commit whose only change to `post.md` is the `published:` line doesn't
  make a review stale, so `blog:publish` and any merge strategy keep a PASS valid (A3, A4). Re-rendering the cover or
  editing `cover.json` after the gate does make it stale, on purpose.
- **What "lived" means for the gate:** first-person statements the author wrote (typically in place of `<author: …>`
  markers) count as lived; general claims about tools or behaviour need a link to a file, command or commit, or a
  `sources:` comment on the task. The gate blocks only unlinked general claims; doubtful first-person ones go to
  Consider.
- **Backlog topics** become undated tasks tagged `topic-backlog`; every topic task also gets a theme tag
  (`theme-a` … `theme-d`). The four theme definitions and the alternation rule stay in PLAYBOOK (they don't date);
  the "Drivers" column is dropped (the gate scores STEPPS per post).
- **The cadence is a rule** (one topic every two weeks on Tuesdays, the community post Thursday–Saturday, the
  in-between post the Tuesday after): it stays in PLAYBOOK; the dated timeline table goes.
- **`cover.json`:** `/blog:draft` writes it; `blog:check` blocks a non-legacy post without it; the pill number comes
  from the task's `topic-<n>` tag (0 otherwise), and `series` in the JSON is only an override. `blog:cover` renders
  it (and `/blog:draft` runs it once).
- **A5 metrics:** add `substantive_comments`, `sends`, `recipe_reuse`, `inbound` to the metric list (`saves`,
  `profile_views`, `followers` exist); a new platform `series` holds account-wide manual counts (`recipe_reuse`,
  `inbound`); `substantive_comments` means a question, a correction or a shared setup, counted by hand per
  platform; an unknown value is recorded as `note: <date> <platform> <metric> unknown`.
- **Chrome:** macOS only (the Brewfile installs the cask only there, and SF fonts are macOS's). `blog:cover` looks
  for `/Applications/Google Chrome.app`, then `google-chrome`/`chromium` on PATH, else stops with a message. Tests
  check the filled HTML (escaping, markup, colours); rendering is checked by hand.
- **`blog:done` on failure:** no commit; it lists what was written; URL comments are skipped when the same value is
  already recorded, so a rerun is safe.

## Left to the builder

The exact wording of STYLE and PLAYBOOK; the colour-markup syntax details; how `blog:check` counts the LinkedIn
post's characters (the `## Post` section, hashtags included); the order of the work.
