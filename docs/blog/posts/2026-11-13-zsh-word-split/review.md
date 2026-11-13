# Review: zsh-word-split · 2026-11-13

**Verdict:** PASS

## Must fix

<!-- Blocking only: safety, anti-goals, a missing or broken RECIPE, a failed blog:check. Empty means none. -->

None.

## Cold read

- **The one point:** On a Mac, my AI agents write bash-style loops but run them in my zsh, where an unquoted `$list`
  stays one word, so the loop runs once and still "succeeds"; one setting per tool gives the agents Homebrew's bash
  and leaves my own terminal on zsh.
- **Would I save it, and why:** Yes: the two settings (`CLAUDE_CODE_SHELL`, Copilot's terminal profile) and the
  one-line `${BASH_VERSION:-not bash}` check are exactly what I'd otherwise hunt for across two docs sites.
- **Where I got lost:** In the TL;DR code block, "Copilot chat   terminal profile → /opt/homebrew/bin/bash" doesn't
  tell me which setting to change; I only found `chat.tools.terminal.terminalProfile.osx` in 🛠️ The fix. Briefly
  again at the Copilot bullet in 💡 But how?, which mixes the cause with the fix. Nowhere else.

## Scores

| Check | Score | Note |
| --- | --- | --- |
| Cold read | 2 | One point found at once; would save it for the two settings and the check |
| Layout | 2 | DISCLAIMER, then all nine sections in order, each doing its job; snippets for every command, setting and output; "Corrections…" and the AI disclosure at the end. The hook line sits above TL;DR rather than in 🪲 The problem (tied to the deferred moment) |
| The hook | 1 | "One string to rule them all: my agent's for-loop found one item where I had three." First person, specific (one vs three), one LOTR wink echoed by 💍 on the cover; the moment itself (what the loop was over, how it was noticed) is deferred by the author |
| Lived or proven | 2 | zsh keeps `$var` whole, `${=var}`, `SH_WORD_SPLIT`, arrays → [zsh FAQ 3.1](https://zsh.sourceforge.io/FAQ/zshfaq03.html#l18) and the Symptoms snippet (reproduced here: `[a b c]` vs `[a] [b] [c]`); quoting doesn't help → the ⚠️ snippet (reproduced); `CLAUDE_CODE_SHELL` → [env-vars](https://code.claude.com/docs/en/env-vars) and `config/claude/settings.json` line 4; Copilot's profile → [Copilot settings](https://code.visualstudio.com/docs/copilot/reference/copilot-settings) and `config/vscode/settings.json` line 810; both asserted by `test/integration/bootstrap/agent-shell.spec.ts`; macOS bash 3.2 → `/bin/bash --version` (3.2.57 here); Homebrew bash 5.3.20 → 🧪 output (matches here); PR #108 public and merged. Each fact once, except the 3.2 fact (You need and 🤓) |
| Information gain | 2 | Articles on zsh word splitting address people typing at a prompt; this one shows AI agents silently running bash idioms in the user's zsh (exit 0, wrong result) and gives the per-tool settings that move only the agents to bash |
| RECIPE self-test | 1 | Use it when, You need, In dots links and the test are there, and both settings match `main`; but the lighter TL;DR block no longer names Copilot's setting key or where `CLAUDE_CODE_SHELL` goes, so redoing it means opening a linked file or 🛠️ The fix. Followable, not a block (Consider 1). Apple-silicon path only, as the author chose |
| STEPPS | 8/12 | Social currency 1 · Triggers 2 · Emotion 1 · Public 1 · Practical value 2 · Stories 1. Raw ≥ 6 and Practical value = 2 met; **neither Social currency nor Stories is 2: bar missed** (Consider, not a block; tied to the deferred moment) |
| Voice | 2 | hype words: none (`blog:check` 0 warnings; none found by hand) · mistake stated: yes ("It ran without errors" is not "it worked"; the quoting and `SH_WORD_SPLIT` limits) |
| LinkedIn | 2 | Hook 83 characters, stands alone with a specific detail; insight in one sentence (zsh cause, per-tool fix, terminal stays zsh); 345 characters with the arrow and 3 hashtags; link in the first comment |
| Images | 1 | One image, the cover (2000 × 840): series look, `dots #0`, focused Ghostty window, 💍 wink matching the hook, one point. Phone test at 400 px: title and hashtags pass; terminal lines and subtitle (~6 px) fail, accepted by the author as decorative |
| Goals 1–5 | 7/10 | 1 2 · 2 1 (recipe strong; the story of what went wrong is thin) · 3 2 (PR, settings and the test that asserts them linked) · 4 1 · 5 1 |
| Language | 2 | English throughout; no PT-BR text |
| Safety | ok | No secrets, token names, emails, clients or private repos; `CLAUDE_CODE_SHELL` is a setting, not a secret; `roalcantara/dots` is PUBLIC (`gh repo view`); the cover shows only the demo loop |
| AI disclosure | ok | "Drafted with AI help; every claim was checked by me, and the story is mine." |
| `blog:check` | ok | `2026-11-13-zsh-word-split: ok (0 warning(s))` |

Accepted by the author and not scored against the post: the cut `~/.bashrc` gotcha and Intel bash path, the length
(about 700 words against 800–1,300; goals 1–3 outrank goal 5), the deferred real moment, and the cover's small
terminal text.

## Consider

<!-- At most 7, most valuable first; each names the goal it serves; visual and tone suggestions explicit. -->

1. **Goals 1–2 (RECIPE self-test):** make the TL;DR block name where each setting lives, still under 60
   characters a line, e.g. `Claude Code   settings.json env: CLAUDE_CODE_SHELL=…` and
   `Copilot chat  chat.tools.terminal.terminalProfile.osx` (path on the next line). Today the Copilot line says only
   "terminal profile", which a reader can't act on without scrolling.
2. **Goal 2 (accuracy):** the second gotcha, "`setopt SH_WORD_SPLIT` also fixes it, but for every script you run",
   overstates it: a zsh script started by its shebang doesn't read `~/.zshrc`, so the option reaches only the shells
   that read the file where it is set. Say e.g. "but for everything that reads your `~/.zshrc`, you included".
3. **Goal 2 (cold read):** split the Copilot bullet in 💡 But how? into the cause only ("Copilot chat runs its
   commands in a VS Code terminal; mine opened zsh, my login shell") and leave the bash profile to 🛠️ The fix,
   where it already is.
4. **Goal 1 (each fact once):** the 3.2 fact is in **You need** and again in 🤓 "Check which bash you get". Keep it
   in You need and cut the 🤓 bullet, or turn it into a limit the author actually hit.
5. **Goals 2, 5 (Stories bar, tone):** if the real moment is added, put it at the top of 🪲 The problem before
   `### Symptoms` and move the "One string…" line there; that lifts Stories to 2 and meets the STEPPS bar.
6. **Goal 5 (visuals):** when posting the LinkedIn cover, write alt text that carries the subtitle's point ("zsh
   doesn't split $vars, and agents write bash"), since that line doesn't survive phone width.

## Variables (the `vars:` comment)

hook type: confession · cover style: series, terminal window (Ghostty, focused), wink 💍 · images: 1 (cover only) ·
LinkedIn format: prose, 345 characters, no image chosen · language: EN · day/time: <author> · tags: ai, zsh, bash,
productivity

`vars: hook=confession cover=series-terminal images=1-cover linkedin=prose lang=en day=<author> tags=ai,zsh,bash,productivity`
