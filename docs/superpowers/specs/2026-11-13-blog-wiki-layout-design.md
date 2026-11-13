# Blog: a wiki layout for posts — design

> **Status:** historical design record. The current rules are in [`docs/blog/PLAYBOOK.md`](../../blog/PLAYBOOK.md) and
> [`docs/blog/STYLE.md`](../../blog/STYLE.md).

Asked by the author: posts structured like a wiki page (nested topics, the same standard sections in every post,
one emoji per section so readers know where to look, code snippets wherever possible), for the preflight post and
every post after it, through the template and `/blog:draft`.

## Decisions

### 1. The layout (alternative A, "wiki page", chosen by the author)

Every dev.to post has these `##` sections, in this order, each led by its fixed emoji; `###` sub-topics inside them
carry no emoji:

| Section | Emoji | Holds |
| --- | --- | --- |
| TL;DR | ⚡ | The fix in two lines, then the RECIPE: **Use it when**, **You need**, the steps as one code block, **In dots** links |
| The problem | 🪲 | The hook (the author's moment), then `### Symptoms` |
| Why it happens | 🔍 | The mechanism, one `###` per cause |
| The fix | 🛠️ | One `###` per tool or step, each with its snippet |
| Check it works | 🧪 | A command and its expected output, as code |
| Gotchas | ⚠️ | One `###` per gotcha (at most 3) |
| Alternatives | ⚖️ | The "vs." table (may be skipped when there is no real alternative) |
| Lessons | 🧠 | What I (think I) learned: at least one mistake or limit |
| References | 📚 | Links |

The DISCLAIMER note stays above TL;DR; "Corrections and ideas are very welcome. :)" stays at the end.

### 2. Emoji: the author's voice, contained

Alternatives considered (accessibility guides advise against emoji in headings; emoji-led headings also read as a
sign of AI-generated text): a contents map only, emoji at the end of headings, no emoji, emoji at the start. The
author chose the middle ground that keeps their voice:

- emoji lead the **`##` section headings only**, one fixed emoji per section, the same in every post;
- **nowhere else** structural: no emoji on `###` headings, bullets or paragraphs; the one geeky wink and an
  occasional 💡 callout remain;
- the emoji were picked so their spoken names help a screen reader (🔍 magnifying glass, 🧪 test tube, ⚠️ warning,
  📚 books).

### 3. Code snippets wherever possible

Commands, settings, file excerpts and outputs go in fenced blocks with a language (`console`, `json`, `zsh`, `bash`,
`toml`…); the RECIPE's steps are one copy-pasteable block. Inline code only inside sentences.

### 4. AI disclosure (dev.to's guidelines)

dev.to requires disclosing AI assistance ([guidelines](https://dev.to/guidelines-for-ai-assisted-articles-on-dev)).
Every post ends with: "Drafted with AI help; every claim was checked by me, and the story is mine." `blog:check`
blocks a non-legacy post without a line mentioning AI help. The published Omarchy post stays as it is (author's
decision): as a `legacy` post it is exempt. Comments are never written by agents.

### 5. What follows

- `templates/post.md`, STYLE ("Post layout"), `/blog:draft`, the gate prompt (each section scored for being in place
  and doing its job) and `blog:check`: the RECIPE rule becomes "a `## ⚡ TL;DR` section with **Use it when**"; the
  section order is a warning, not a block; the disclosure is a block.
- The preflight post is rewritten into the layout, its `<author: …>` marker and hook options kept in `🪲 The problem`.

## Non-goals

- The LinkedIn and community posts keep their own shapes (short; native to the community; no section emoji).
- Collapsible `{% details %}` blocks (GitHub shows them as raw tags).

## Left to the builder

The exact wording of section intros; whether `blog:check` lists the missing sections in one finding or several.

## Revision (author)

After editing the preflight post, the author made their own section set the standard: 💡 **But how?** (why it
happens), 🥷🏼 **vs. <the usual way>** (alternatives) and 🤓 **What I (think I) learned** (lessons), with nested bullets
and `jsonc` snippets that name their file. Template, STYLE and checks follow.
