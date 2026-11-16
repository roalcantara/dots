# Blog style

How the posts sound and look, and how the gate scores them: what a writer or reviewer keeps open. The goals behind
it are in [PLAYBOOK.md](PLAYBOOK.md). Voice, look and rubric are tuned at each recalibration from the results in
[`TODO.yaml`](TODO.yaml) (`mise run blog:report`).

## Voice

**A colleague's notebook, made public.** Same voice everywhere; only the length changes.

| The voice is | It is not |
| --- | --- |
| First person, specific, with numbers from the repo ("606,863 files, 541 GiB") | "We", vague, adjectives ("huge") |
| Honest about mistakes ("it took 54 fixes") | Polished success stories |
| Calmly confident: "this works for me, here's why" | Hype ("game-changer", "10x") or modesty that hides the point |
| Opinionated with reasons, fair to alternatives | Takes aimed at other tools or people |
| **One geeky wink per post, always tied to a real moment** | Jokes that need explaining, memes, rage bait |

### The hook

Every post tells **a real moment** (what happened to the author, how they noticed, what it cost) under
`## How I ran into it`, and every LinkedIn post opens with it, in one to three sentences, first person. The post
itself opens with who this hits and why, so a stranger knows in three sentences whether to read on. At most **one geeky wink** frames
it, from the author's interests: technology and gadgets, AI and machine learning, productivity hacks, comic books,
Harry Potter, The Lord of the Rings and fantasy, cinema, science, science fiction. The wink frames the moment ("I
felt like Ron with a broken wand"); it never replaces it. It may echo once more: the cover's emoji and the terminal's
"← aside". The author's own tics are welcome: the DISCLAIMER, "**YOU HAVE BEEN WARNED!**", "**NO, SERIOUSLY!**".

**The story is lived, never invented.** Before drafting, `/blog:draft` looks for the moment in the session
transcripts, the PR and the commits. If none turns up, the post opens with the symptom instead (the Symptoms snippet
becomes the hook), and the gate scores the hook on the symptom rather than blocking.

`/blog:draft` suggests 3–5 hook options from that evidence; the author picks, edits or writes their own. Until then
the post carries `<author: the moment …>` (and the options in a `<!-- hook options -->` comment below it).

### Lived or proven

- **Every claim is lived or proven.** Lived: a first-person statement the author wrote. Proven: a general claim
  about a tool or behaviour, linked to a file, command or commit in the repo, or to a source recorded as a
  `sources:` comment on the task. Anything else is cut: no setups the author doesn't use, no "agents usually…".
- **Each fact once.** A screenshot doesn't repeat a code block; the opening doesn't repeat `## The fix`.

### Writing rules

- Plain words, short sentences, one idea per paragraph, one claim per bullet; at least one mistake or limit stated.
- No hype words: [`hype-words.txt`](hype-words.txt) is the list `blog:check` and the gate use. Hype is about the
  author's own work; honest praise for someone else's tool is fine.
- dev.to conventions: the story layout below, an occasional 💡 callout or "vs." table where it earns its place, and
  the closing (Corrections, the DISCLAIMER, the AI disclosure) at the end.
- **Titles:** draft 10, keep the most specific (a number, a confession, an opinion with a reason). **The title states
  the insight** (the cause, in one line): the LinkedIn link card shows it, so the LinkedIn post doesn't repeat it.
  dots is the example, never the headline.
- **Tags** (max 4): the large ones that fit first (`git`, `devops`, `productivity`, `terminal`, `ai`, `docker`,
  `security`, `macos`); `dotfiles` only as the fourth, if at all. They are also the cover's hashtags.
- **LinkedIn** (decided 2026-11-16, from the author's own draft): the lived moment, quoted when there is a line worth
  quoting (≤ 210 characters), one short beat on why it mattered, a plain pointer ("Here is how I fixed it:") and the
  dev.to URL (`{devto.url}`) in the post. LinkedIn turns the URL into a card with the cover and the title, and the
  title carries the insight, so the post doesn't repeat it: no first comment, no image to upload. 1–3 topic
  hashtags on their own line at the end. About 80–250 characters, not counting the URL; no bullet list.

  ```text
  "My loop didn't split the list, a zsh word-splitting quirk." - my AI agent said..
  More than once!

  Here is how I fixed it:
  {devto.url}

  #AI #zsh #macOS
  ```

## Post layout

Every dev.to post tells one story and ends in its fix (the **story layout**, picked from fifteen rendered variants on
2026-11-16; [template](templates/post.md)). Headings are plain `##` sections, matched by how they start, so each post
finishes them in its own words ("## The fix: two settings", "## Why not change zsh instead?").

| Part | Holds |
| --- | --- |
| Opening (no heading) | Who this hits and why, in about three sentences, with links that prove it; the demo snippet and one line on it |
| `## How I ran into it…` | The lived moment: what happened, how it was noticed, what it cost (see "The hook") |
| `## The fix…` | The RECIPE: one snippet per setting or step (`jsonc` with a comment naming the file), then the check command and its output |
| `## Why not …?` | The alternatives and their catch; the gotchas live here (skip it when there is no real alternative) |
| `## What I (think I) learned` | Bold lessons, one line each, at least one mistake or limit |
| Closing | The dots links in one line, `---`, then "Corrections and ideas are very welcome. **NO, SERIOUSLY!** :)", the DISCLAIMER, the AI disclosure |

- **The fix is findable alone:** a reader who lands on `## The fix…` from a link can follow it without the rest
  (the RECIPE self-test).
- **The closing is fixed and in this order,** the same in every post, so it never interrupts the reading:
  Corrections → `> **DISCLAIMER**` → "Drafted with AI help; every claim was checked by me, and the story is mine."
  (dev.to requires the disclosure). Comments are never written by agents.
- **Code snippets wherever possible:** commands, settings, excerpts and outputs in fenced blocks with a language
  (`console`, `json`, `zsh`, `bash`, `toml`…); inline code only inside sentences. **Code lines stay under about 70
  characters**, so they don't scroll sideways on dev.to.
- **No emoji as structure** (headings, bullets); the one geeky wink and an occasional 💡 callout remain.
- **Length is a guideline** (about 600–1,300 words), never a check: a post is as long as its story and its fix.
- Prose may wrap in the repo: `blog:push` joins wrapped lines, because dev.to turns every newline into a line break.
- **The author's habits are the style:** asides in parentheses ("(err.. Claude found it, actually)"), two-dot beats
  ("..and exited 0"), "And **presto!**", a ":(" where it stings, "**NO, SERIOUSLY!**", bold lessons.

## Visual identity

**One series look** (approved 2026-11-13): Catppuccin Mocha, a Charm-style layout, OmniWM windows. Reference:
[the design](../superpowers/specs/2026-11-13-blog-voice-design.md) and its renders in
[`specs/assets/`](../superpowers/specs/assets).

| Element | Value |
| --- | --- |
| Base | `#1e1e2e`, two soft circles: mauve `#cba6f7` (18 %) top right, teal `#94e2d5` (16 %) bottom |
| Text | `#cdd6f4`; secondary `#a6adc8`; code `#f9e2af` |
| Accents | pink `#f5c2e7` (series pill, title highlight); hashtags cycle mauve `#cba6f7`, green `#a6e3a1`, peach `#fab387`, sky `#89dceb` |
| Font | SF Pro (700 for titles); code in SF Mono |
| Windows | OmniWM style: title bar `#2a2a2f` with traffic lights and the app's name; terminal body `#111116`, app body `#222226`; skeleton bars `#3d3d43`, one highlight bar `#7f7150`; **focused** windows get a cyan `#62e6f0` border and glow |
| Cover | 1000 × 420 (rendered at 2×): pill `dots #<n>`, two title lines with the key phrase on pink, a subtitle with one emoji wink, plain coloured hashtags, one window (`terminal` or `app`). From `cover.json` by `mise run blog:cover` ([template](tools/cover.html)) |
| Screenshots | a clean capture, cropped to the point, sensitive regions blurred, framed by `tools/frame.py --app <name> [--focus]` in the same window style on the same base |
| Carousel (LinkedIn, optional) | 1080 × 1350, 4–6 slides, one point per slide, same palette and windows |
| Diagrams | Mermaid when a picture shows a mechanism; never decoration |

Every image passes the **phone test** (scaled to 400 px wide, the text it's there to show is still readable,
roughly 8 px or taller) and makes **one point**. The pill number is the topic's (`topic-<n>`); the preflight and
posts outside the numbered topics use `#0`.

## Rubric

The gate (`/blog:gate`) fills this in `review.md`. Each check scores **0** (absent or wrong), **1** (present, weak) or
**2** (strong, deliberate).

| Check | What earns a 2 | Blocks when |
| --- | --- | --- |
| The hook | The opening says who this hits; a real moment, first person, at most one wink that fits | — |
| Lived or proven | Every claim lived or linked; each fact once | A general claim with no link or source |
| Information gain | One true sentence on what this adds that the usual articles don't | — |
| Layout | The story layout's sections in order, each doing its job; snippets for every command and setting; the closing in order | No `## The fix…`; the closing out of order |
| RECIPE self-test | The author could redo it from `## The fix…` alone, months later | The RECIPE can't be followed |
| Cold read | A mid-level developer names the one point and would save it | — |
| STEPPS (six drivers) | Social currency, Triggers, Emotion, Public, Practical value, Stories, each 0–2 | — |
| Voice | Zero hype words; a mistake or limit stated | Hype, takes aimed at people or tools, hate |
| LinkedIn | A lived opening ≤ 210 characters; the dev.to URL in the post; ≤ 250 characters without it; the post's title states the insight | No dev.to link in the post |
| Images | Phone test, one point each, the series look, alt text | Anything sensitive is visible |
| Goals 1–5 | Knowledge base, lesson as a recipe, skills shown, presence, contagious (0–2 each) | — |
| Language | English default; PT-BR text follows the playbook's rules | — |
| Safety | No secret, key, token name, email, client or private repo name | Any of them, in text or images |
| AI disclosure | The closing line says AI helped and the author checked every claim | Missing |
| `blog:check` | No blocks | Any block |

**Bars:** STEPPS raw ≥ 6 of 12, with Practical value = 2 and one of Social currency or Stories = 2. Under a bar a
post gets **Consider** items, not a block; only the "Blocks when" column blocks.
