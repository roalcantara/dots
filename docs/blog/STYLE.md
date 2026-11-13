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

Every post, and every LinkedIn post, opens with **a real moment** (what happened to the author, how they noticed,
what it cost) or a pain readers share, in one to three sentences, first person. At most **one geeky wink** frames
it, from the author's interests: technology and gadgets, AI and machine learning, productivity hacks, comic books,
Harry Potter, The Lord of the Rings and fantasy, cinema, science, science fiction. The wink frames the moment ("I
felt like Ron with a broken wand"); it never replaces it. It may echo once more: the cover's emoji and the terminal's
"← aside". The author's own tics are welcome: the DISCLAIMER, "**YOU HAVE BEEN WARNED!**", "**NO, SERIOUSLY!**".

`/blog:draft` suggests 3–5 hook options from the repo's evidence; the author picks, edits or writes their own. Until
then the post carries `<author: the moment …>` (and the options in a `<!-- hook options -->` comment below it).

### Lived or proven

- **Every claim is lived or proven.** Lived: a first-person statement the author wrote. Proven: a general claim
  about a tool or behaviour, linked to a file, command or commit in the repo, or to a source recorded as a
  `sources:` comment on the task. Anything else is cut: no setups the author doesn't use, no "agents usually…".
- **Each fact once.** A screenshot doesn't repeat a code block; the TL;DR doesn't repeat 🛠️ The fix in prose.

### Writing rules

- Plain words, short sentences, one idea per paragraph, one claim per bullet; at least one mistake or limit stated.
- No hype words: [`hype-words.txt`](hype-words.txt) is the list `blog:check` and the gate use. Hype is about the
  author's own work; honest praise for someone else's tool is fine.
- dev.to conventions: the DISCLAIMER note, the wiki layout below, 💡 callouts, "vs." tables, "Corrections and ideas
  are very welcome. :)" and the AI disclosure at the end.
- **Titles:** draft 10, keep the most specific (a number, a confession, an opinion with a reason). dots is the
  example, never the headline.
- **Tags** (max 4): the large ones that fit first (`git`, `devops`, `productivity`, `terminal`, `ai`, `docker`,
  `security`, `macos`); `dotfiles` only as the fourth, if at all. They are also the cover's hashtags.
- **LinkedIn:** the hook (≤ 210 characters), then **one sentence with the insight** (what a reader keeps without
  clicking), then "→ first comment". 250–450 characters, no bullet list, 1–3 hashtags. The first comment is one
  line with the dev.to link (`{devto.url}`). **Write alt text** for the image when posting.

## Post layout

Every dev.to post reads like a wiki page: the same `##` sections, in this order, each led by its emoji; `###`
sub-topics inside them, without emoji ([template](templates/post.md)).

| Section | Holds |
| --- | --- |
| ⚡ TL;DR | The fix in two lines, then the RECIPE as plain bullets (**Use it when**, **You need**), the steps as one short code block, **In dots** links |
| 🪲 The problem | The hook (the author's moment), then `### Symptoms` |
| 💡 But how? | Why it happens: the mechanism as nested bullets, each proven by a snippet or a link |
| 🛠️ The fix | One `###` per tool or step, each with its snippet |
| 🧪 Check it works | A command and its expected output |
| ⚠️ Gotchas | At most three, as bullets with a nested why |
| 🥷🏼 vs. \<the usual way\> | The comparison table (skip it when there is no real alternative) |
| 🤓 What I (think I) learned | Bold lessons with a nested why, at least one mistake or limit |
| 📚 References | Links |

- **Emoji lead the `##` section headings only**, the same one for each section in every post; nowhere else as
  structure (no emoji on `###`, bullets or paragraphs). The one geeky wink and an occasional 💡 callout remain.
- **Code snippets wherever possible:** commands, settings, excerpts and outputs in fenced blocks with a language
  (`console`, `json`, `zsh`, `bash`, `toml`…); inline code only inside sentences. **Code lines stay under about 70
  characters** (60 in the TL;DR), so they don't scroll sideways on dev.to.
- Prose may wrap in the repo: `blog:push` joins wrapped lines, because dev.to turns every newline into a line break.
- **AI disclosure** (dev.to requires it): the post ends with "Drafted with AI help; every claim was checked by me,
  and the story is mine." Comments are never written by agents.
- **The author's habits are the style:** nested bullets for every point, `jsonc` snippets with a comment naming the
  file, short emoji-led lines for asides (🤔, 💡, 😬). The section set above is the author's own.
- The DISCLAIMER note stays above TL;DR; "Corrections and ideas are very welcome. :)" stays at the end.

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
| The hook | A real moment, first person, at most one wink that fits | — |
| Lived or proven | Every claim lived or linked; each fact once | A general claim with no link or source |
| Information gain | One true sentence on what this adds that the usual articles don't | — |
| Layout | All sections in order, each doing its job; snippets for every command and setting | No `## ⚡ TL;DR` with **Use it when** |
| RECIPE self-test | The author could redo it from the TL;DR alone, months later | The RECIPE can't be followed |
| Cold read | A mid-level developer names the one point and would save it | — |
| STEPPS (six drivers) | Social currency, Triggers, Emotion, Public, Practical value, Stories, each 0–2 | — |
| Voice | Zero hype words; a mistake or limit stated | Hype, takes aimed at people or tools, hate |
| LinkedIn | Hook ≤ 210 characters; the insight in one sentence; 250–450 characters in all | — |
| Images | Phone test, one point each, the series look, alt text | Anything sensitive is visible |
| Goals 1–5 | Knowledge base, lesson as a recipe, skills shown, presence, contagious (0–2 each) | — |
| Language | English default; PT-BR text follows the playbook's rules | — |
| Safety | No secret, key, token name, email, client or private repo name | Any of them, in text or images |
| AI disclosure | The closing line says AI helped and the author checked every claim | Missing |
| `blog:check` | No blocks | Any block |

**Bars:** STEPPS raw ≥ 6 of 12, with Practical value = 2 and one of Social currency or Stories = 2. Under a bar a
post gets **Consider** items, not a block; only the "Blocks when" column blocks.
