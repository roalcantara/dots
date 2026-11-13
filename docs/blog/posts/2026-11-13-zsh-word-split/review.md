# Review: zsh-word-split · 2026-11-13

**Verdict:** PASS

## Must fix

<!-- Blocking only: safety, anti-goals, a missing or broken RECIPE, a failed blog:check. Empty means none. -->

None.

## Cold read

- **The one point:** On a Mac, my coding agent writes bash-style loops but runs them in my zsh, where an unquoted
  `$list` stays one word, so the loop runs once without an error; point each agent at Homebrew's bash and keep zsh
  for myself.
- **Would I save it, and why:** Yes: the two exact settings (`CLAUDE_CODE_SHELL` and Copilot's
  `chat.tools.terminal.terminalProfile.osx`) and the one-line `${BASH_VERSION:-not bash}` check are things I'd
  otherwise dig out of docs.
- **Where I got lost:** Briefly at the Copilot bullet in 💡 But how? ("whose profile was zsh in my setup until I gave
  its tools a bash one"): one long sentence that mixes the cause and the fix. Then I wondered, after switching, whether
  the agent's bash still finds my tools (mise, Homebrew); the post doesn't say.

## Scores

| Check | Score | Note |
| --- | --- | --- |
| Layout | 2 | All nine sections in order, each doing its job; snippets for every command, setting and output; DISCLAIMER above TL;DR, "Corrections…" and the AI disclosure at the end. The hook sits in a quote above TL;DR rather than in 🪲 The problem, which opens with the mechanism instead |
| The hook | 1 | "One string to rule them all: my agent's for-loop found one item where I had three." First person, one wink that fits, a specific number; but the moment is thin: what the loop was over, how it was noticed and what it cost are not said |
| Lived or proven | 1 | Claims and their proof: zsh not splitting `$var` → zsh FAQ 3.1 (checked, and reproduced locally); `CLAUDE_CODE_SHELL` → Claude Code settings page (that page doesn't name it; the env-vars reference does) and `config/claude/settings.json`; Copilot's terminal profile → VS Code terminal profiles page (doesn't name `chat.tools.terminal.terminalProfile.*`) and `config/vscode/settings.json`; macOS `/bin/bash` is 3.2 → `/bin/bash --version` (3.2.57 here); quoting makes one word in both shells → shown nowhere, reproduced locally. All proven through the repo or a command; two links point at the wrong page. The FAQ link appears twice in a row in Symptoms and But how? |
| Information gain | 2 | Articles on zsh word splitting address humans typing; this one shows AI agents silently running bash idioms in the user's zsh (exit 0, wrong result) and gives the per-tool settings that move only the agents to bash |
| RECIPE self-test | 1 | Both settings are exact and match `main`; the check is runnable. Limits: the path assumes Apple silicon (`/usr/local/bin/bash` on Intel), and nothing says the agent's bash doesn't read `~/.zshrc`, so tools activated there (mise) may be missing; PR #108 had to touch `config/bash/bashrc` and `config/.profile` for that |
| STEPPS | 8/12 | Social currency 1 · Triggers 2 · Emotion 1 · Public 1 · Practical value 2 · Stories 1. Raw ≥ 6 and Practical value = 2 met; **neither Social currency nor Stories is 2: bar missed** |
| Voice | 2 | hype words: none (`blog:check` 0 warnings, none found by hand) · mistake stated: yes ("It ran without errors" is not "it worked"; `SH_WORD_SPLIT` as a limit) |
| LinkedIn | 2 | Hook 82 characters, stands alone, specific (one item vs three); the insight in one sentence (zsh doesn't split, one setting per tool, terminal stays zsh); about 309 characters before hashtags, ~340 with them; 3 hashtags; link in the first comment |
| Images | 1 | One image (the cover, 2000 × 840 at 2×): series look, `dots #0` pill, focused Ghostty window, alt text present. Phone test: title and hashtags pass; the terminal lines and the subtitle fall to ~6–7 px at 400 px wide. The cover also appears inline under the DISCLAIMER, so dev.to shows it twice |
| Goals 1–5 | 6/10 | 1 2 · 2 1 · 3 1 · 4 1 · 5 1 |
| Language | 2 | English throughout; no PT-BR text |
| Safety | ok | No secrets, token names, emails, clients or private repos; `CLAUDE_CODE_SHELL` is a setting, not a secret; `roalcantara/dots` is public (`gh repo view`: PUBLIC); PR #108 is public and merged |
| AI disclosure | ok | "Drafted with AI help; every claim was checked by me, and the story is mine." |
| `blog:check` | ok | `2026-11-13-zsh-word-split: ok (0 warning(s))` |

## Consider

<!-- At most 7, most valuable first; each names the goal it serves; visual and tone suggestions explicit. -->

1. **Goals 2, 5 (Stories bar):** give 🪲 The problem its moment: what the loop iterated over, how you noticed (exit 0,
   a confident summary, then the wrong result) and what it cost, in two or three first-person sentences, and move the
   "One string to rule them all" line there (the layout puts the hook in The problem). This lifts Stories to 2 and
   meets the STEPPS bar; only the author knows the facts.
2. **Goal 1 (RECIPE):** add a gotcha: the agent's bash doesn't read `~/.zshrc`, so tools activated there (mise,
   Homebrew's PATH) can vanish; say which file it reads (`bash -l` → `~/.bash_profile`) and add
   [config/bash/bashrc](https://github.com/roalcantara/dots/blob/main/config/bash/bashrc) to **In dots**. In
   **You need**, add the Intel path (`$(brew --prefix)/bin/bash`, `/usr/local/bin/bash`). Both were applied after the
   first review and dropped in the wiki-layout rewrite (2266a78).
3. **Goal 3 (proof):** point the links at the pages that name the settings: `CLAUDE_CODE_SHELL` →
   [Claude Code environment variables](https://code.claude.com/docs/en/env-vars), which also says auto-detection
   uses your `$SHELL`, the exact mechanism of 💡 But how?; Copilot's setting → the
   [Copilot settings reference](https://code.visualstudio.com/docs/copilot/reference/copilot-settings). Keep the zsh
   FAQ link once (drop the "feature" link in Symptoms or the second one in But how?).
4. **Goal 3:** name the evidence: PR #108 added `test/integration/bootstrap/agent-shell.spec.ts`; one line in
   **In dots** or 🧪 Check it works ("dots tests this") shows the repo checks itself.
5. **Goal 5 (visuals):** make the cover's terminal pass the phone test: three lines (the loop, `[a b c] ← once?!`,
   `# bash: [a] [b] [c]`) at a larger size, and drop the inline cover image under the DISCLAIMER, since dev.to already
   shows `cover_image` (each fact once).
6. **Goal 5 (tone):** one wink, echoed: the post's wink is The Lord of the Rings ("One string to rule them all"), but
   `cover.json`'s wink is 🪄 (a wand). Use 💍 on the cover so the two line up, as STYLE.md's "The hook" asks.
7. **Goals 2, 4:** the post is about 700 words (code included) against 800–1,300; items 1 and 2 bring it there
   without padding. Also split the Copilot bullet in But how? into cause ("Copilot runs commands in a VS Code
   terminal; mine defaulted to zsh") and leave the fix to 🛠️ The fix.

## Variables (the `vars:` comment)

hook type: confession · cover style: series, terminal window (Ghostty, focused), wink 🪄 · images: 1 (cover only) ·
LinkedIn format: prose, ~309 characters, no image chosen · language: EN · day/time: <author> · tags: ai, zsh, bash,
productivity

`vars: hook=confession cover=series-terminal images=1-cover linkedin=prose lang=en day=<author> tags=ai,zsh,bash,productivity`

<!-- reviewed: 8ac0817a35773c4e -->
