# Review: zsh-word-split · 2026-11-13

**Verdict:** PASS

## Must fix

<!-- Blocking only: safety, anti-goals, a missing or broken RECIPE, a failed blog:check. Empty means none. -->

None.

## Cold read

- **The one point:** On a Mac, my AI agents write bash-style loops but run them in my zsh, where an unquoted `$list`
  stays one word, so the loop runs once and exits 0; one setting per tool (`CLAUDE_CODE_SHELL`, Copilot's terminal
  profile) gives the agents Homebrew's bash and leaves my own terminal on zsh.
- **Would I save it, and why:** Yes: the TL;DR block now names both settings and where they live, and the
  `${BASH_VERSION:-not bash}` check is a one-liner I'd reuse for any agent.
- **Where I got lost:** Nowhere, really. Small stumbles: "My login shell is zsh." dangles at the end of the Copilot
  bullet in 💡 But how?, and in ⚠️ I couldn't tell whether `setopt SH_WORD_SPLIT` in `~/.zshrc` would fix the
  *agent's* commands or only my own prompt.

## Scores

| Check | Score | Note |
| --- | --- | --- |
| Cold read | 2 | One point found at once; would save it for the two settings and the check |
| Layout | 2 | DISCLAIMER, then all nine sections in order, each doing its job; snippets for every command, setting and output; "Corrections…" and the AI disclosure at the end. Only `### Keep zsh for yourself` has no snippet (Consider 2); the hook line sits above TL;DR, tied to the deferred moment |
| The hook | 1 | "One string to rule them all: my agent's for-loop found one item where I had three." First person, specific (one vs three), one LOTR wink echoed by 💍 on the cover; the moment itself (what the loop was over, how it was noticed) is deferred by the author |
| Lived or proven | 2 | zsh keeps `$var` whole, `${=var}`, `SH_WORD_SPLIT`, arrays → [zsh FAQ 3.1](https://zsh.sourceforge.io/FAQ/zshfaq03.html#l18) and the Symptoms snippet (reproduced here: `[a b c]` vs `[a] [b] [c]`; `${=list}` splits); quoting doesn't help → ⚠️ snippet (reproduced); `~/.zshrc` read by interactive shells only → [zsh startup files](https://zsh.sourceforge.io/Doc/Release/Files.html); `CLAUDE_CODE_SHELL` → [env-vars](https://code.claude.com/docs/en/env-vars) and `config/claude/settings.json` line 4; Copilot's profile → [Copilot settings](https://code.visualstudio.com/docs/copilot/reference/copilot-settings) and `config/vscode/settings.json` line 810; both asserted by `test/integration/bootstrap/agent-shell.spec.ts`; macOS bash 3.2 (3.2.57 here) and Homebrew bash 5.3.20 (matches 🧪 here); PR #108 public and merged. Each fact once, except the 3.2 fact (You need and 🤓) and "your shell is unchanged" (TL;DR, 🛠️, vs. table) |
| Information gain | 2 | Articles on zsh word splitting address people typing at a prompt; this one shows AI agents silently running bash idioms in the user's zsh (exit 0, wrong result) and gives the per-tool settings that move only the agents to bash |
| RECIPE self-test | 2 | Use it when, You need (Homebrew bash, not 3.2), both settings with their file and key, In dots links, the test; settings match `main`. The TL;DR's Copilot line drops the `"args": ["-l"]` the fix uses (Consider 5). Apple-silicon path only, as the author chose |
| STEPPS | 8/12 | Social currency 1 · Triggers 2 · Emotion 1 · Public 1 · Practical value 2 · Stories 1. Raw ≥ 6 and Practical value = 2 met; **neither Social currency nor Stories is 2: bar missed** (Consider, not a block; tied to the deferred moment) |
| Voice | 2 | hype words: none (`blog:check` 0 warnings; none found by hand) · mistake stated: yes ("It ran without errors" is not "it worked"; the quoting and `SH_WORD_SPLIT` limits; "I (think I) understood") |
| LinkedIn | 2 | Hook 82 characters, stands alone with a specific detail; insight in one sentence (zsh cause, per-tool fix, terminal stays zsh); 347 characters in all; link in the first comment |
| Images | 1 | One image, the cover (2000 × 840): series look, `dots #0`, focused Ghostty window, 💍 wink matching the hook, one point. Phone test at 400 px: title and hashtags pass; subtitle and terminal lines (~6 px) fail, accepted by the author as decorative |
| Goals 1–5 | 7/10 | 1 2 · 2 1 (recipe strong; the story of what went wrong is thin) · 3 2 (PR, settings and the test that asserts them linked) · 4 1 · 5 1 |
| Language | 2 | English throughout; no PT-BR text |
| Safety | ok | No secrets, token names, emails, clients or private repos; `CLAUDE_CODE_SHELL` is a setting, not a secret; `roalcantara/dots` is PUBLIC (`gh repo view`); the cover shows only the demo loop |
| AI disclosure | ok | "Drafted with AI help; every claim was checked by me, and the story is mine." |
| `blog:check` | ok | `2026-11-13-zsh-word-split: ok (0 warning(s))` |

Accepted by the author and not scored against the post: the cut `~/.bashrc` gotcha and Intel bash path, the length
(713 words against 800–1,300; goals 1–3 outrank goal 5), the deferred real moment, and the cover's small terminal
text.

## Consider

<!-- At most 7, most valuable first; each names the goal it serves; visual and tone suggestions explicit. -->

1. **Goal 2 (accuracy):** the second gotcha opens with "`setopt SH_WORD_SPLIT` also fixes it", but its own nested
   why says scripts never read `~/.zshrc`, so a reader can't tell whether it fixes the *agent's* commands at all.
   Say which case it fixes, e.g. "fixes it at your own prompt", unless the author has checked that the agent's shell
   picks the option up.
2. **Goal 1 (each fact once):** `### Keep zsh for yourself` is one bullet that repeats the TL;DR line and the vs.
   table's "Your shell: Unchanged", and it is the only `###` in 🛠️ with no snippet. Cut it, or fold "your
   interactive terminal doesn't change" into one sentence under `## 🛠️ The fix`.
3. **Goal 1 (each fact once):** the 3.2 fact is in **You need** and again in 🤓 "Check which bash you get". Keep it
   in You need and cut the 🤓 bullet, or replace it with a limit the author actually hit.
4. **Goal 2 (cold read):** in 💡 But how?, "My login shell is zsh." dangles after the Copilot link and repeats 🪲.
   Move it into the Claude Code bullet ("runs its commands in your shell, zsh for me, unless…") or cut it.
5. **Goals 1–2 (RECIPE):** the TL;DR's Copilot line gives only `path`; 🛠️ also sets `"args": ["-l"]`. Add an
   `args = ["-l"]` line to the TL;DR block (under 60 characters) so the RECIPE matches the real setting.
6. **Goals 2, 5 (Stories bar, tone):** if the real moment is added, put it at the top of 🪲 The problem before
   `### Symptoms` and move the "One string…" line there; that lifts Stories to 2 and meets the STEPPS bar. Until
   then, the 🤔 / 💡 / 😬 aside under Symptoms carries the emotion; its "💡 … (see 💡 But how?)" uses the emoji twice
   in one line: "It's a zsh feature, not a bug" is enough.
7. **Goal 5 (visuals):** when posting the LinkedIn cover, write alt text that carries the subtitle's point ("zsh
   doesn't split $vars, and agents write bash"), since that line doesn't survive phone width.

## Variables (the `vars:` comment)

hook type: confession · cover style: series, terminal window (Ghostty, focused), wink 💍 · images: 1 (cover only) ·
LinkedIn format: prose, 347 characters, no image chosen · language: EN · day/time: <author> · tags: ai, zsh, bash,
productivity

`vars: hook=confession cover=series-terminal images=1-cover linkedin=prose lang=en day=<author> tags=ai,zsh,bash,productivity`

<!-- reviewed: 5804c484c7b31b1d -->
