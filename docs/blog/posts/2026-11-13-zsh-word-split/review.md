# Review: zsh-word-split · 2026-11-13

**Verdict:** BLOCKED

## Must fix

<!-- Blocking only: safety, anti-goals, a missing or broken RECIPE, a failed blog:check. Empty means none. -->

1. **An unproven claim (⚠️ Gotchas, first bullet):** "quoting (`"$list"`) doesn't help — it makes it one word in
   both shells" is a general claim about shell behaviour with no link, no repo file and no `sources:` entry on the
   task (the zsh FAQ 3.1 linked in 💡 But how? doesn't cover quoting). It is true (reproduced here: both
   `zsh -c` and `bash -c` print `[a b c]` once for `for x in "$list"`), so the fix is one snippet, in the post's own
   style:

   ```console
   $ bash -c 'list="a b c"; for x in "$list"; do echo "[$x]"; done'
   [a b c]
   ```

   or a link to the bash manual's
   [Word Splitting](https://www.gnu.org/software/bash/manual/html_node/Word-Splitting.html) section.

## Cold read

- **The one point:** On a Mac, my AI agent writes bash-style loops but runs them in my zsh, where an unquoted `$list`
  stays one word, so the loop runs once and still exits 0; one setting per tool moves the agents to Homebrew's bash
  and my own terminal stays zsh.
- **Would I save it, and why:** Yes: the two exact settings (`CLAUDE_CODE_SHELL`, Copilot's
  `chat.tools.terminal.terminalProfile.osx`) and the one-line `${BASH_VERSION:-not bash}` check are the kind of thing
  I'd otherwise dig out of two docs sites.
- **Where I got lost:** Briefly at the Copilot bullet in 💡 But how? ("whose profile was zsh in my setup until I gave
  its tools a bash one"): one sentence that mixes the cause with the fix. Nowhere else.

## Scores

| Check | Score | Note |
| --- | --- | --- |
| Cold read | 2 | One point found at once; would save it for the two settings and the check |
| Layout | 2 | All nine sections in order, each doing its job; snippets for every command, setting and output; DISCLAIMER above TL;DR, "Corrections…" and the AI disclosure at the end. The hook line sits in a quote above TL;DR; 🪲 The problem opens with the setup, not a moment (deferred by the author) |
| The hook | 1 | "One string to rule them all: my agent's for-loop found one item where I had three." First person, specific (one vs three), one wink that fits; the moment itself (what the loop was over, how it was noticed, what it cost) is not told, which the author has deferred |
| Lived or proven | 1 | zsh keeps `$var` whole → [zsh FAQ 3.1](https://zsh.sourceforge.io/FAQ/zshfaq03.html#l18) (checked; also covers `${=var}`, `SH_WORD_SPLIT`, arrays); `CLAUDE_CODE_SHELL` and "runs in your shell" → [env-vars](https://code.claude.com/docs/en/env-vars) (names it; auto-detection uses `$SHELL`) and `config/claude/settings.json`; Copilot's setting → [Copilot settings](https://code.visualstudio.com/docs/copilot/reference/copilot-settings) (names `chat.tools.terminal.terminalProfile.<platform>`) and `config/vscode/settings.json`; macOS bash 3.2 → `/bin/bash --version` (3.2.57 here); Homebrew bash 5.3.20 → the 🧪 output (matches here); the move → PR #108 (public, merged). **Unproven:** the quoting gotcha (Must fix). Each fact once: the 3.2 fact appears in You need and again in What I learned |
| Information gain | 2 | Articles on zsh word splitting address people typing at a prompt; this one shows AI agents silently running bash idioms in the user's zsh (exit 0, wrong result) and gives the per-tool settings that move only the agents to bash |
| RECIPE self-test | 2 | Use it when, You need, both settings with their files, In dots links; both settings match `main` (`config/claude/settings.json` line 4, `config/vscode/settings.json` line 810). The path assumes Apple silicon, as the author chose; the 🧪 check sits outside the TL;DR but is one line |
| STEPPS | 8/12 | Social currency 1 · Triggers 2 · Emotion 1 · Public 1 · Practical value 2 · Stories 1. Raw ≥ 6 and Practical value = 2 met; **neither Social currency nor Stories is 2: bar missed** (Consider, not a block; tied to the deferred moment) |
| Voice | 2 | hype words: none (`blog:check` 0 warnings; none found by hand) · mistake stated: yes ("It ran without errors" is not "it worked"; the `SH_WORD_SPLIT` limit) |
| LinkedIn | 2 | Hook 83 characters, stands alone, specific detail (one item vs three); insight in one sentence; about 347 characters with the arrow and 3 hashtags; link in the first comment; an in-between post planned |
| Images | 1 | One image, the cover (2000 × 840, rendered at 2×): series look, `dots #0` pill, focused Ghostty window, alt text present. Phone test: title and hashtags pass; at 400 px wide the terminal lines (~6 px) and the subtitle (~7 px) fail. The cover is also inlined under the DISCLAIMER, so dev.to shows it twice |
| Goals 1–5 | 6/10 | 1 2 · 2 1 (recipe strong, the story of what went wrong thin) · 3 1 (the repo's test isn't named) · 4 1 · 5 1 |
| Language | 2 | English throughout; no PT-BR text |
| Safety | ok | No secrets, token names, emails, clients or private repos; `CLAUDE_CODE_SHELL` is a setting, not a secret; `roalcantara/dots` is PUBLIC (`gh repo view`); PR #108 public and merged; the cover shows only the demo loop |
| AI disclosure | ok | "Drafted with AI help; every claim was checked by me, and the story is mine." |
| `blog:check` | ok | `2026-11-13-zsh-word-split: ok (0 warning(s))` |

Accepted by the author and not scored against the post: the cut `~/.bashrc` gotcha and Intel bash path, the length
(about 680 words against 800–1,300), and the deferred real moment.

## Consider

<!-- At most 7, most valuable first; each names the goal it serves; visual and tone suggestions explicit. -->

1. **Goal 3 (proof):** name the evidence the repo already has: PR #108 added
   [test/integration/bootstrap/agent-shell.spec.ts](https://github.com/roalcantara/dots/blob/main/test/integration/bootstrap/agent-shell.spec.ts),
   which asserts both settings. Add it to **In dots** or one line in 🧪 Check it works ("dots tests both settings").
2. **Goal 5 (visuals):** make the cover's terminal pass the phone test: keep three lines (the loop,
   `[a b c] ← once?!`, `# bash: [a] [b] [c]`) at a larger size in `cover.json`, and drop the inline cover under the
   DISCLAIMER, since dev.to already shows `cover_image` (each fact once).
3. **Goal 5 (tone):** one wink, echoed: the hook's wink is The Lord of the Rings ("One string to rule them all") but
   `cover.json`'s is 🪄 (a wand, Harry Potter). Use 💍 on the cover so the two line up, as STYLE.md's "The hook" asks.
4. **Goal 2 (accuracy):** the second gotcha, "`setopt SH_WORD_SPLIT` also fixes it — but for every script you run",
   overstates it: a zsh script started by its shebang doesn't read `~/.zshrc`. Say what it does reach, e.g. "but for
   everything that reads your `~/.zshrc`, you included", and the FAQ link already backs the rest.
5. **Goal 2 (cold read):** split the Copilot bullet in 💡 But how? into the cause only ("Copilot chat runs its
   commands in a VS Code terminal; mine opened zsh") and leave the bash profile to 🛠️ The fix, where it already is.
6. **Goal 1 (each fact once):** the 3.2 fact is in **You need** and again in 🤓 "Check which bash you get". Keep it in
   You need and turn the lesson into the limit it implies (e.g. "I nearly pointed the setting at `/bin/bash`" only
   if that happened; otherwise cut the bullet).
7. **Goals 2, 5 (Stories bar):** when, and if, the real moment is added, put it in 🪲 The problem before
   `### Symptoms` and move the "One string…" line there; that alone lifts Stories to 2 and meets the STEPPS bar.

## Variables (the `vars:` comment)

hook type: confession · cover style: series, terminal window (Ghostty, focused), wink 🪄 · images: 1 (cover only) ·
LinkedIn format: prose, ~347 characters, no image chosen · language: EN · day/time: <author> · tags: ai, zsh, bash,
productivity

`vars: hook=confession cover=series-terminal images=1-cover linkedin=prose lang=en day=<author> tags=ai,zsh,bash,productivity`

<!-- reviewed: e23968573ccf68d9 -->
