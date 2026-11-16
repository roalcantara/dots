# Review: zsh-word-split · 2026-11-16

**Verdict:** PASS

## Must fix

<!-- Blocking only: safety, anti-goals, a missing or broken RECIPE, a failed blog:check. Empty means none. -->

None.

## Cold read

- **The one point:** On a Mac, AI agents like Claude Code run the bash-style code they write in my zsh, where an
  unquoted `$var` isn't split, so a loop quietly runs once; one setting per tool points the agents at Homebrew's bash
  and leaves my own terminal on zsh.
- **Would I save it, and why:** Yes: it's short, the two settings are copy-pasteable with their files named, and
  `echo "${BASH_VERSION:-not bash}"` is a check I'd reuse for any agent.
- **Where I got lost:** Nowhere for long. Small stumbles: "I had read that same line before. Twice is a pattern."
  (when was the first time?); in Why not, `"$list"` appears when the demo used `$v`, and the quoting claim has no
  snippet; the lesson "The fix came from the same agent (err.. Claude found `CLAUDE_CODE_SHELL`, actually)" reads
  like it contradicts itself.

## Scores

| Check | Score | Note |
| --- | --- | --- |
| Cold read | 2 | One point found in the opening; would save it for the settings and the check |
| Layout | 2 | Story layout in order: opening (who this hits: new Mac accounts + Claude Code, with Apple and Claude Code links; the demo snippet and one line on it), `## How I ran into it`, `## The fix: two settings` (`jsonc` snippets with comments naming the file, then the check and its output), `## Why not change zsh instead?`, `## What I (think I) learned`, dots links, `---`, Corrections → DISCLAIMER → AI disclosure. Code lines under 70 characters. Only `brew install bash` has no snippet of its own (Consider 7) |
| The hook | 2 | A real moment, first person (fresh Mac, 16 file types fed to `duti`, ran once, `unrecognized`.. and exit 0, the agent caught it); one wink, "One string to rule them all", echoed by 💍 on the cover; the opening says who this hits |
| Lived or proven | 1 | zsh default since Catalina → [Apple](https://support.apple.com/en-us/102360); Claude Code runs in your shell, `CLAUDE_CODE_SHELL` → [env-vars](https://code.claude.com/docs/en/env-vars) and `config/claude/settings.json` line 4; Copilot's terminal profile → `config/vscode/settings.json` line 810 (the Copilot docs link was dropped in the rewrite); zsh keeps `$v` whole by design → [zsh FAQ 3.1](https://zsh.sourceforge.io/FAQ/zshfaq03.html#l18) and the demo (reproduced here: `a b c` vs `a`/`b`/`c`); scripts don't read `~/.zshrc` → [zsh startup files](https://zsh.sourceforge.io/Doc/Release/Files.html); Homebrew bash 5.3.20 (matches here); PR #108 public and merged. Unlinked: "like most shell code online, is.. bash" (Consider 1), macOS `/bin/bash` is 3.2 (true here, 3.2.57) and "`"$list"` is one word in bash too" (true; both lost their snippet or neighbour in the rewrite; Consider 2). No `sources:` entry on the task. Each fact once |
| Information gain | 2 | Articles on zsh word splitting address people typing at a prompt; this one shows AI agents silently running bash idioms in the user's zsh (exit 0, wrong result) and gives the per-tool settings that move only the agents to bash |
| RECIPE self-test | 2 | `## The fix…` stands alone: install Homebrew bash, both settings with their file and key, the check and its expected output; settings match `main`. Apple-silicon path only, as the author chose earlier |
| STEPPS | 9/12 | Social currency 1 · Triggers 2 · Emotion 1 · Public 1 · Practical value 2 · Stories 2. All bars met (raw ≥ 6, Practical value = 2, Stories = 2): the lived moment lifted Stories from 1 |
| Voice | 2 | hype words: none (`blog:check` 0 warnings; none found by hand) · mistake stated: yes ("Exit 0 is not 'it worked'", "choices I made for me, not for them", the DISCLAIMER). The author's habits are there (two-dot beats, "**presto!**", ":(", the aside) without overdoing them |
| LinkedIn | 1 | Hook 132 characters, stands alone with specifics (16 file types, ran once, exit 0); 327 characters in all; link in the first comment; 3 hashtags. The insight half-teases: "One setting per tool fixes it" doesn't say what the setting is or why zsh does this (Consider 4) |
| Images | 1 | One image, the cover (2000 × 840): series look, `dots #0`, focused Ghostty window, 💍 wink tied to the hook, one point. Phone test at 400 px: pill and title pass; subtitle and hashtags (~7 px) and terminal lines (~6 px) fail. `raw/01-zsh-vs-bash.png` is not referenced |
| Goals 1–5 | 7/10 | 1 2 · 2 2 (the story of what went wrong is now real) · 3 1 (PR and settings linked; the test that asserts both settings was dropped) · 4 1 · 5 1 |
| Language | 2 | English throughout; no PT-BR text |
| Safety | ok | No secrets, token names, emails, clients or private repos; `CLAUDE_CODE_SHELL` is a setting, not a secret; `roalcantara/dots` is PUBLIC (`gh repo view`); the cover shows only the demo loop |
| AI disclosure | ok | "Drafted with AI help; every claim was checked by me, and the story is mine." |
| `blog:check` | ok | `2026-11-13-zsh-word-split: ok (0 warning(s))` |

Not scored against the post: the length (about 420 words against the 600–1,300 guideline, which is never a check),
the Intel bash path, and the moment's source (the 2026-11-07 session transcript, per the author).

## Consider

<!-- At most 7, most valuable first; each names the goal it serves; visual and tone suggestions explicit. -->

1. **Goal 2 (lived or proven):** in the opening, "like most shell code online, is.. bash" is the one general claim
   with no source. Cut "like most shell code online" ("And the shell code it writes is.. bash."): the story already
   proves the agent part. A strict gate could block this; it passes here because the clause is an aside.
2. **Goals 1–2 (proven, cold read):** the rewrite dropped the snippets behind two claims. In `## The fix…`, after
   "macOS's own `/bin/bash` is 3.2", add `$ /bin/bash --version` → `GNU bash, version 3.2.57(1)-release`. In
   `## Why not…`, show the quoting claim with the demo's own variable:
   `bash -c 'v="a b c"; for x in "$v"; do echo "$x"; done'` → `a b c`, and write `"$v"` instead of `"$list"`.
3. **Goal 2 (tone, cold read):** the lesson "**The fix came from the same agent** (err.. Claude found
   `CLAUDE_CODE_SHELL`, actually)" reads as a contradiction. Try "**The fix came from the agent that hit the bug**
   (err.. Claude found `CLAUDE_CODE_SHELL`, not me)". And in How I ran into it, say when "before" was ("in another
   session a few days earlier"), if that's what happened, so "Twice is a pattern" lands.
4. **Goals 4–5 (LinkedIn insight):** replace "One setting per tool fixes it." with the insight itself, e.g. "zsh
   doesn't split an unquoted $var; pointing the agents at bash (CLAUDE_CODE_SHELL for Claude Code) fixes it, and my
   terminal stays zsh." That keeps the post under 450 characters and stops it from teasing.
5. **Goal 3 (skills shown):** restore two links the old version had: the
   [Copilot settings](https://code.visualstudio.com/docs/copilot/reference/copilot-settings) page next to the
   Copilot snippet, and the test that asserts both settings (`test/integration/bootstrap/agent-shell.spec.ts`) in
   the closing's dots links.
6. **Goal 5 (visuals):** the cover's subtitle and terminal lines fail the phone test. Cut the terminal to three
   lines (`for x in $list; do echo "[$x]"; done`, `[a b c] ← once?!`, `# bash: [a] [b] [c]`) and raise their size,
   or enlarge the subtitle; when posting to LinkedIn, write alt text that carries the point ("zsh doesn't split
   $vars, and AI agents write bash").
7. **Goal 1 (RECIPE):** `brew install bash` sits inline in a sentence after both settings. Make it the first
   `console` snippet of `## The fix…`, so the fix reads in order: install, set, check.

## Variables (the `vars:` comment)

hook type: confession · cover style: series, terminal window (Ghostty, focused), wink 💍 · images: 1 (cover only) ·
LinkedIn format: prose, 327 characters, no image chosen · language: EN · day/time: <author> · tags: ai, zsh, bash,
productivity

`vars: hook=confession cover=series-terminal images=1-cover linkedin=prose lang=en day=<author> tags=ai,zsh,bash,productivity`

<!-- reviewed: 92e8d7e11850c67c -->
