# Review: zsh-word-split · 2026-11-13

**Verdict:** PASS

## Must fix

<!-- Blocking only: safety, anti-goals, a missing or broken RECIPE, a failed blog:check. Empty means none. -->

None. The previous block (the unproven quoting gotcha) is resolved: ⚠️ Gotchas now carries the `zsh -c` / `bash -c`
snippet for `"$list"`, and it reproduces here (`[a b c]` once in both shells).

## Cold read

- **The one point:** My AI agent writes bash-style loops, but on a Mac it runs them in my zsh, where an unquoted
  `$list` stays one word, so the loop runs once and still exits 0; one setting per tool hands the agents Homebrew's
  bash while my own terminal stays zsh.
- **Would I save it, and why:** Yes: the two exact settings (`CLAUDE_CODE_SHELL`,
  `chat.tools.terminal.terminalProfile.osx`) plus the one-line `${BASH_VERSION:-not bash}` check would otherwise cost
  me two docs sites and a bad afternoon.
- **Where I got lost:** Briefly at the Copilot bullet in 💡 But how? ("whose profile was zsh in my setup until I gave
  its tools a bash one"): cause and fix in one sentence. Nowhere else.

## Scores

| Check | Score | Note |
| --- | --- | --- |
| Cold read | 2 | One point found at once; would save it for the two settings and the check |
| Layout | 2 | All nine sections in order, each doing its job; snippets for every command, setting and output; DISCLAIMER above TL;DR, "Corrections…" and the AI disclosure at the end; the inline cover is gone. The hook line sits above TL;DR rather than in 🪲 The problem (tied to the deferred moment) |
| The hook | 1 | "One string to rule them all: my agent's for-loop found one item where I had three." First person, specific (one vs three), one wink that fits and now echoed by 💍 on the cover; the moment itself (what the loop was over, how it was noticed) is deferred by the author |
| Lived or proven | 2 | zsh keeps `$var` whole, `${=var}`, `SH_WORD_SPLIT`, arrays → [zsh FAQ 3.1](https://zsh.sourceforge.io/FAQ/zshfaq03.html#l18) and the 🪲 Symptoms snippet (reproduced); quoting doesn't help → the ⚠️ snippet (reproduced); `CLAUDE_CODE_SHELL` → [env-vars](https://code.claude.com/docs/en/env-vars) and `config/claude/settings.json` (line 4 on `main`); Copilot's setting → [Copilot settings](https://code.visualstudio.com/docs/copilot/reference/copilot-settings) and `config/vscode/settings.json` (line 810 on `main`); both asserted by `test/integration/bootstrap/agent-shell.spec.ts`; macOS bash 3.2 → `/bin/bash --version` (3.2.57 here); Homebrew bash 5.3.20 → the 🧪 output (matches here); PR #108 public, merged. Each fact once: the 3.2 fact repeats in 🤓 (Consider) |
| Information gain | 2 | Articles on zsh word splitting address people typing at a prompt; this one shows AI agents silently running bash idioms in the user's zsh (exit 0, wrong result) and gives the per-tool settings that move only the agents to bash |
| RECIPE self-test | 2 | Use it when, You need (with how to check `/bin/bash`), both settings with their files, In dots links including the test; both settings match `main`. Apple-silicon path only, as the author chose |
| STEPPS | 8/12 | Social currency 1 · Triggers 2 · Emotion 1 · Public 1 · Practical value 2 · Stories 1. Raw ≥ 6 and Practical value = 2 met; **neither Social currency nor Stories is 2: bar missed** (Consider, not a block; tied to the deferred moment) |
| Voice | 2 | hype words: none (`blog:check` 0 warnings; none found by hand) · mistake stated: yes ("It ran without errors" is not "it worked"; the `SH_WORD_SPLIT` and quoting limits) |
| LinkedIn | 2 | Hook 83 characters, stands alone; insight in one sentence (the zsh cause and the per-tool fix); about 347 characters with the arrow and 3 hashtags; link in the first comment; in-between post planned |
| Images | 1 | One image, the cover (2000 × 840): series look, `dots #0`, focused Ghostty window, 💍 wink matching the hook. Phone test at 400 px: title and hashtags pass; terminal lines (~6 px) and subtitle (~6 px) fail, accepted by the author as decorative |
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

1. **Goal 2 (accuracy):** the second gotcha, "`setopt SH_WORD_SPLIT` also fixes it — but for every script you run",
   overstates it: a zsh script started by its shebang doesn't read `~/.zshrc`, so the option reaches only the shells
   that read the file where it is set. Say e.g. "but for everything that reads your `~/.zshrc`, you included".
2. **Goal 2 (cold read):** split the Copilot bullet in 💡 But how? into the cause only ("Copilot chat runs its
   commands in a VS Code terminal; mine opened zsh, my login shell") and leave the bash profile to 🛠️ The fix,
   where it already is.
3. **Goal 1 (each fact once):** the 3.2 fact is in **You need** and again in 🤓 "Check which bash you get". Keep it
   in You need and cut the 🤓 bullet, or turn it into a limit the author actually hit.
4. **Goals 2, 5 (Stories bar, tone):** when, and if, the real moment is added, put it at the top of 🪲 The problem
   before `### Symptoms` and move the "One string…" line there; that lifts Stories to 2 and meets the STEPPS bar.
5. **Goal 5 (visuals):** when posting the LinkedIn cover, write alt text that carries the subtitle's point ("zsh
   doesn't split $vars, and agents write bash"), since that line doesn't survive phone width.

## Variables (the `vars:` comment)

hook type: confession · cover style: series, terminal window (Ghostty, focused), wink 💍 · images: 1 (cover only) ·
LinkedIn format: prose, ~347 characters, no image chosen · language: EN · day/time: <author> · tags: ai, zsh, bash,
productivity

`vars: hook=confession cover=series-terminal images=1-cover linkedin=prose lang=en day=<author> tags=ai,zsh,bash,productivity`

<!-- reviewed: 940bfa0783a80758 -->
