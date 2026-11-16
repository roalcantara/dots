# Review: zsh-word-split · 2026-11-16

**Verdict:** PASS

## Must fix

<!-- Blocking only: safety, anti-goals, a missing or broken RECIPE, a failed blog:check. Empty means none. -->

None.

## Cold read

- **The one point:** On a Mac the shell is zsh, AI agents like Claude Code run their bash-style code in it, and zsh
  doesn't split an unquoted `$var`, so a loop silently runs once; point the agents (not me) at Homebrew's bash with
  one setting per tool.
- **Would I save it, and why:** Yes: the two settings name their files and keys, the `bash -c` / `zsh -c` pair is a
  demo I can paste, and `echo "${BASH_VERSION:-not bash}"` is a check I'd reuse for any agent.
- **Where I got lost:** Nowhere for long. Two small stumbles remain: "I had read that same line before. Twice is a
  pattern." (when was the first time?), and the lesson "**The fix came from the same agent** (err.. Claude found
  `CLAUDE_CODE_SHELL`, actually)" reads like the aside contradicts the bold part.

## Scores

| Check | Score | Note |
| --- | --- | --- |
| Cold read | 2 | One point found in the opening; would save it for the settings and the check |
| Layout | 2 | Story layout in order: opening (who this hits: new Mac accounts + Claude Code, with Apple and Claude Code links; the demo snippet and one line on it), `## How I ran into it`, `## The fix: two settings` (`jsonc` snippets with comments naming the file, the `/bin/bash --version` proof, then the check and its output), `## Why not change zsh instead?` (alternatives and their catch, the quoting gotcha with its snippet), `## What I (think I) learned` (bold lessons, a mistake stated), dots links, `---`, Corrections → DISCLAIMER → AI disclosure. Code lines under 70 characters. Only `brew install bash` lives inline in a sentence (Consider 5) |
| The hook | 2 | A real moment, first person (fresh Mac, 16 file types fed to `duti`, ran once, `unrecognized`.. and exit 0, the agent caught it), lived per the 2026-11-07 session transcript; one wink, "One string to rule them all", echoed by 💍 on the cover; the opening says who this hits in three sentences |
| Lived or proven | 2 | zsh default since Catalina → [Apple](https://support.apple.com/en-us/102360); Claude Code runs in your shell, `CLAUDE_CODE_SHELL` → [env-vars](https://code.claude.com/docs/en/env-vars) (checked: documented there) and `config/claude/settings.json` line 4; Copilot's terminal profile → `config/vscode/settings.json` line 810 (linked in the closing); zsh keeps `$v` whole by design → [zsh FAQ 3.1](https://zsh.sourceforge.io/FAQ/zshfaq03.html#l18) and the demo (reproduced: `a`/`b`/`c` vs `a b c`); scripts don't read `~/.zshrc` → [zsh startup files](https://zsh.sourceforge.io/Doc/Release/Files.html); macOS `/bin/bash` is 3.2 → snippet (reproduced: 3.2.57); `"$v"` is one word in bash → snippet (reproduced: `a b c`); Homebrew bash 5.3.20 (matches here); PR #108 public and merged. "The shell code it writes is.. bash" is backed by the lived story now that "like most shell code online" is gone. The one soft spot: "Copilot chat runs commands in a VS Code terminal" rests on the setting, not on Copilot's docs (Consider 4). All links return 200. Each fact once |
| Information gain | 2 | Articles on zsh word splitting address people typing at a prompt; this one shows AI agents silently running bash idioms in the user's zsh (exit 0, wrong result) and gives the per-tool settings that move only the agents to bash |
| RECIPE self-test | 2 | `## The fix…` stands alone: both settings with their file and key, Homebrew bash and why not `/bin/bash`, the check and its expected output; settings match `main`. Apple-silicon path only, as the author chose |
| STEPPS | 9/12 | Social currency 1 · Triggers 2 · Emotion 1 · Public 1 · Practical value 2 · Stories 2. All bars met (raw ≥ 6, Practical value = 2, Stories = 2) |
| Voice | 2 | hype words: none (`blog:check` 0 warnings; none found by hand) · mistake stated: yes ("Exit 0 is not 'it worked'", "choices I made for me, not for them", the DISCLAIMER). The author's habits are there (two-dot beats, "**presto!**", ":(", the asides) without overdoing them |
| LinkedIn hook | 1 | Hook 132 characters, stands alone with specifics (16 file types, ran once, exit 0); about 330 characters in all, in range; link in the first comment; 3 hashtags. The insight still half-teases: "One setting per tool fixes it" doesn't say what the setting does (Consider 2) |
| Images | 1 | One image, the cover (2000 × 840): series look, `dots #0`, focused Ghostty window, 💍 wink tied to the hook, one point; the new title matches the post's. Phone test at 400 px: pill and title pass; subtitle and hashtags (~7 px) and terminal lines (~6 px) fail. The terminal uses `$list` while the post uses `$v`. `raw/01-zsh-vs-bash.png` is not referenced |
| Goals 1–5 | 7/10 | 1 2 · 2 2 · 3 1 (PR and settings linked; the test that asserts both settings is not) · 4 1 · 5 1 |
| Language | 2 | English throughout; no PT-BR text |
| Safety | ok | No secrets, token names, emails, clients or private repos; `CLAUDE_CODE_SHELL` is a setting, not a secret; `roalcantara/dots` is PUBLIC (`gh repo view`); the cover shows only the demo loop |
| AI disclosure | ok | "Drafted with AI help; every claim was checked by me, and the story is mine." |
| `blog:check` | ok | `2026-11-13-zsh-word-split: ok (0 warning(s))` |

Not scored against the post: the length (about 480 words against the 600–1,300 guideline, which is never a check)
and the Intel bash path.

## Consider

<!-- At most 7, most valuable first; each names the goal it serves; visual and tone suggestions explicit. -->

1. **Goal 2 (tone, cold read):** the lesson "**The fix came from the same agent** (err.. Claude found
   `CLAUDE_CODE_SHELL`, actually)" reads as a contradiction. Try "**The fix came from the agent that hit the bug**
   (err.. Claude found `CLAUDE_CODE_SHELL`, not me)". In How I ran into it, say when "before" was ("in another
   session a few days earlier"), if that's what happened, so "Twice is a pattern" lands.
2. **Goals 4–5 (LinkedIn insight):** replace "One setting per tool fixes it." with the insight itself, e.g. "zsh
   doesn't split an unquoted $var; one setting per tool (CLAUDE_CODE_SHELL for Claude Code) gives the agents bash,
   and my terminal stays zsh." That keeps the post under 450 characters and stops it from teasing.
3. **Goal 5 (visuals):** the cover's subtitle, hashtags and terminal lines fail the phone test. Cut the terminal to
   three lines and raise their size, or enlarge the subtitle; use `$v` in the terminal to match the post's demo.
   When posting to LinkedIn, write alt text that carries the point ("zsh doesn't split $vars, and AI agents write
   bash").
4. **Goal 3 (proven, skills shown):** next to the Copilot snippet, link the
   [Copilot settings](https://code.visualstudio.com/docs/copilot/reference/copilot-settings) page, so "Copilot chat
   runs commands in a VS Code terminal" has a source of its own.
5. **Goal 1 (RECIPE):** `brew install bash` sits inline after both settings. Make it the first `console` snippet of
   `## The fix…`, so the fix reads in order: install, set, check.
6. **Goal 3 (skills shown):** add the test that asserts both settings
   (`test/integration/bootstrap/agent-shell.spec.ts`) to the closing's dots links: it shows the fix is guarded, not
   only written.

## Variables (the `vars:` comment)

hook type: number (contrast + "16 file types… ran once", LinkedIn) · cover style: series, terminal window (Ghostty,
focused), wink 💍 · images: 1 (cover only) · LinkedIn format: prose, about 330 characters, no image chosen ·
language: EN · day/time: <author> · tags: ai, zsh, bash, productivity

`vars: hook=number cover=series-terminal images=1-cover linkedin=prose lang=en day=<author> tags=ai,zsh,bash,productivity`

<!-- reviewed: 618e37dfb3c164f4 -->
