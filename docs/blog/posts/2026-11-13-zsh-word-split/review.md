# Review: zsh-word-split · 2026-11-13

**Verdict:** PASS

## Must fix

<!-- Blocking only: safety, anti-goals, a missing or broken RECIPE, a failed blog:check. Empty means none. -->

None.

## Cold read

- **The one point:** On macOS my coding agent writes bash but runs it in my zsh, and zsh doesn't split `$list`, so
  `for x in $list` runs once without any error; point the agent at Homebrew's bash and keep zsh for myself.
- **Would I save it, and why:** Yes: the two exact settings (`CLAUDE_CODE_SHELL` and Copilot's terminal profile) are
  things I'd otherwise have to dig out of docs, and "exit 0 isn't success" is a check I'd want to remember.
- **Where I got lost:** The RECIPE's "globs that don't match": the post never says what zsh does differently with
  globs. And the third gotcha ("make sure the agent's bash loads your tools") doesn't tell me how.

## Scores

| Check | Score | Note |
| --- | --- | --- |
| Cold read | 2 | One point found at once; would save it for the two settings |
| Information gain | 2 | Articles on zsh word splitting address humans typing; this one shows AI agents silently running bash idioms in the user's zsh, and gives the per-tool settings that move only the agents to Homebrew bash |
| RECIPE self-test | 2 | Both settings are exact and match `config/claude/settings.json` and `config/vscode/settings.json` on `main`; weak spots: the bash path assumes Apple silicon, and "loads your tools" has no how |
| STEPPS | 8/12 | Social currency 1 · Triggers 2 · Emotion 1 · Public 1 · Practical value 2 · Stories 1 — raw ≥ 6 and Practical value = 2 met; **neither Social currency nor Stories is 2: bar missed** |
| Voice | 2 | hype words: none · mistake stated: yes (quoting as the first fix; exit 0 taken as success) |
| LinkedIn hook | 2 | 121 characters for the first sentence block ("My AI agent's for-loop ran once. No error, exit 0, a confident summary. The bug wasn't in the agent: it was in my shell."); stands alone, specific (exit 0, ran once) |
| Images | 1 | Cover: series look, `dots · #0`, 1000 × 420, title readable at 400 px; subtitle small (~6 px) but secondary. Screenshot: one point, framed in the series look, but 1728 px wide with the right third empty, so the code shrinks to ~7 px at 400 px (under the bar); it also repeats the console block right above it |
| Goals 1–5 | 7/10 | 1 2 · 2 2 · 3 1 · 4 1 · 5 1 |
| Language | 2 | English throughout; no PT-BR text |
| Safety | ok | No secrets, token names, emails, clients; `CLAUDE_CODE_SHELL` is a setting, not a secret; `roalcantara/dots` is public (`gh repo view`), PR #108 is public and merged |
| `blog:check` | ok | `zsh-word-split: ok (0 warning(s))` |

## Consider

1. **Goals 2, 5 (Stories bar):** make the OVERVIEW story concrete. Name what the loop was over and what it should have
   done (for example "a loop over the skill names in my lock file"), how you noticed, and what it would have cost.
   One or two specific sentences lift Stories to 2 and meet the STEPPS bar.
2. **Goals 2, 3:** add the **HOW IT WORKS** section the format asks for; the post is 581 words against 800–1,300.
   Three short paragraphs fit: why an agent's command ends up in zsh (it spawns your login shell), why zsh does this
   (`SH_WORD_SPLIT` off; arrays are the zsh way), and what the PR changed.
3. **Goal 1:** the RECIPE's "Use it when" promises "globs that don't match", which the post never explains. Either
   add one line on it (zsh's `nomatch` error where bash passes the pattern through) or cut it from the line.
4. **Goal 1:** make the third gotcha followable: say which file the agent's bash reads (e.g. `bash -l` reads
   `~/.bash_profile`) and add [config/bash/bashrc](https://github.com/roalcantara/dots/blob/main/config/bash/bashrc)
   to **In dots**, since it is where mise gets activated. Also note the Intel path in **You need**:
   `$(brew --prefix)/bin/bash` (`/usr/local/bin/bash` on Intel Macs).
5. **Goal 5 (visuals):** crop `01-zsh-vs-bash.png` to the text (about 1,200 px wide) or re-render it with a larger
   font so the code passes the phone test. Since it duplicates the console block above it, consider using it as the
   LinkedIn image and keeping only the text block in the post, or moving it to replace the block.
6. **Goals 2, 5 (tone):** the LinkedIn hook says "The bug wasn't in the agent: it was in my shell", while the post
   rightly calls it "a zsh feature, not a bug". Align them, e.g. "The agent wasn't wrong: it ran bash in my zsh."
   The LinkedIn post is also 821 characters, under the 900–1,300 target: room for the one-line story from item 1.
7. **Goal 3:** check the "2007" date: bash 3.2 was released in 2006 (Apple ships 3.2.57, a 2014 patch). Say "bash
   3.2, from 2006" (post and LinkedIn) so a correction in the comments is about something more interesting.

## Variables

hook type: confession · cover style: generated (`tools/header.py`, text with a stylised window) · images: 2 (cover,
1 framed terminal) · LinkedIn format: prose + 3 arrow bullets, image not yet chosen · language: EN · day/time:
<author> · tags: ai, zsh, bash, productivity

## Applied after the review

- Applied by Claude (2026-11-13): Consider 2 (HOW IT WORKS), 3 (dropped "globs that don't match"), 4 (`~/.bashrc`
  gotcha, `config/bash/bashrc` link, Intel path), 5 (image cropped to the text), 6 (LinkedIn tone aligned, length
  raised), 7 (bash 3.2 is from 2006).
- Left for the author: Consider 1, the concrete story of how the bug was noticed (only the author knows it).
