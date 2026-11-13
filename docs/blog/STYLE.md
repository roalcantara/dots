# Content series style

How the posts sound and look, and how the gate scores them. The rules come from the
[playbook](PLAYBOOK.md); this file is what a writer or reviewer keeps open. Voice, look and rubric are tuned
variables: each recalibration re-evaluates them from the results recorded in [`TODO.yaml`](TODO.yaml) (`mise run blog:report`) and records the change in the
playbook's Decisions log.

## Voice

**A colleague's notebook, made public.** The voice is the same everywhere; only the length changes. On LinkedIn it
is the notebook's front page.

| The voice is | It is not |
| --- | --- |
| First person, specific, with numbers ("606,863 files, 541 GiB") | "We", vague, adjectives ("huge") |
| Honest about mistakes ("it took 54 fixes") | Polished success stories |
| Calmly confident: "this works for me, here's why" | Hype ("game-changer", "10x") or modesty that hides the point |
| Opinionated with reasons, fair to alternatives | Takes aimed at other tools or people |
| Light humour, rare (the Omarchy post's ":(" and "NO, SERIOUSLY" are the ceiling) | Memes, rage bait |

- Plain words, short sentences, one idea per paragraph, one claim per bullet.
- At least one mistake or limit stated in every post.
- No hype words: [`hype-words.txt`](hype-words.txt) is the list `blog:check` and the gate use; add to it when a new
  one slips through. Hype is about the author's own work ("my game-changing setup"); honest praise for someone
  else's tool ("Omarchy is a joy to drive") is fine.
- dev.to conventions: a DISCLAIMER note, bold ALL-CAPS section labels, 💡 callouts, "vs." tables, references at the
  end, "Corrections and ideas are very welcome. :)".
- **Titles:** draft 10, keep the most specific. Patterns that work on dev.to: a number ("5 things…"), a confession
  ("It took 54 fixes to…"), an opinion with a reason. dots is the example, never the headline.
- **Tags** (max 4): the large ones that fit first (`git`, `devops`, `productivity`, `terminal`, `ai`, `docker`,
  `security`, `macos`); `dotfiles` only as the fourth, if at all.
- **LinkedIn:** hook ≤ 210 characters with a specific detail; the recipe in 3 bullets; one honest lesson; a question
  that invites people's own setups; 3 hashtags; the dev.to link in the first comment.

## Visual identity

**One series look**, so readers recognise a post in the feed before reading it.

| Element | Value |
| --- | --- |
| Background | vertical gradient `#0e121c` → `#181e2c` |
| Accent | gradient `#33ccff` → `#00ff99` (the focus outline of the fn layer); amber `#ffb000` for a single highlight |
| Ink | `#f2f2f2` text, `#9aa4b2` secondary |
| Font | SF Pro (system); code in SF Mono |
| Cover (dev.to and LinkedIn) | 1000 × 420: series tag `dots · #<n>` top right; title on the left (first line ink, second line accent green), a subtitle, 2–4 key caps under it; a stylised terminal or window on the right with the accent outline. Made with `tools/header.py`. |
| Screenshots | a clean Ghostty window, cropped to the point, sensitive regions blurred, framed by `tools/frame.py` (rounded corners, shadow, the background gradient) |
| Carousel (LinkedIn, optional) | 1080 × 1350, 4–6 slides, one point per slide, same palette; the RECIPE is the usual content |
| Diagrams | Mermaid in the post when a picture shows a mechanism; never decoration |

Every image passes the **phone test** and makes **one point**. Phone test: scaled to 400 px wide, every piece of
text the image is there to show is still readable (roughly 8 px or taller at that width); decorative text may blur.
The series tag is `dots · #<n>` with the topic number; the preflight and any post outside the numbered topics use
`#0`.

## Rubric

The gate ([`prompts/gate.md`](prompts/gate.md)) fills this in `review.md`. Each check scores **0** (absent or
wrong), **1** (present, weak) or **2** (strong, deliberate).

| Check | What earns a 2 | Blocks when |
| --- | --- | --- |
| Information gain | One true sentence on what this adds that the top existing articles don't | — |
| RECIPE self-test | The author could redo it from the RECIPE alone, months later | The RECIPE is missing or can't be followed |
| Cold read | A mid-level developer names the one point and would save it | — |
| STEPPS (six drivers) | Social currency, Triggers, Emotion, Public, Practical value, Stories, each 0–2 | — |
| Voice | Zero hype words; a mistake or limit stated; first person, specific | Hype, takes aimed at people or tools, hate |
| LinkedIn hook | ≤ 210 characters, makes sense alone, a specific detail | — |
| Images | Phone test, one point each, the series look, nothing sensitive | Anything sensitive is visible |
| Goal 1, knowledge base | A RECIPE worth linking to; the dots files linked | — |
| Goal 2, lesson as a recipe | A real mistake or surprise, and what changed because of it | — |
| Goal 3, skills shown | The working repo, tests or numbers prove it; no unproven claims | — |
| Goal 4, presence | A LinkedIn post and a community angle that stand on their own | — |
| Goal 5, contagious | A hook and an image someone would forward; STEPPS bars met | — |
| Language | English default; PT-BR text follows the playbook's rules | — |
| Safety | No secret, key, token name, email, client or private repo name | Any of them, in text or images |
| `blog:check` | No blocks | Any block |

**Bars:** STEPPS raw ≥ 6 of 12, with Practical value = 2 and one of Social currency or Stories = 2. A post under a
bar gets **Consider** items, not a block; only the "Blocks when" column blocks (the gate is mixed: blocking for
safety and anti-goals, advisory for the rest).
