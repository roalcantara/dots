# Review: secrets-sops-age · 2026-11-16

**Verdict:** PASS

## Must fix

<!-- Blocking only: safety, anti-goals, a missing or broken RECIPE, a failed blog:check. Empty means none. -->

None.

## Cold read

- **The one point:** I can commit my secrets to git safely if a clean/smudge filter encrypts them with SOPS + age on
  the way in and decrypts them on the way out, with the age key kept out of git; and here are the three ways that
  setup bit the author (a new IV on every run, a fresh Mac with no key or the wrong key path, a diff setting that hung).
- **Would I save it, and why:** Yes. The config snippets are copy-paste sized, the "always modified" trick and the
  `textconv` (not `diff.command`) setting are things I would otherwise find the hard way, and the check commands
  tell me when I am done.
- **Where I got lost:** Barely, in the second sentence: "My dotfiles commit theirs on purpose" made me read twice
  (theirs = the `.claude` settings file? no: their own secrets). After that, nowhere.

## Scores

| Check | Score | Note |
| --- | --- | --- |
| Cold read | 2 | One point found at once; would save it for the snippets and the gotchas |
| Information gain | 2 | Beyond the usual clean/smudge how-to, it shows how the setup breaks in real use (new IVs mark files modified, a fresh Mac clones before the key and macOS sops looks for the key elsewhere, `diff.command` hangs `git diff`) and the fix for each |
| RECIPE self-test | 2 | `.gitattributes`, `.sops.yaml`, the filter and diff config, the key path, the re-checkout and the check all have snippets that match the repo (verified: 9 filtered files, 14 `ENC[` values in `HEAD:config/.env`, `script/textconv.sops.sh`, `setup:git:filters`). Gaps a stranger would hit: no `age-keygen` line, and the textconv script itself is not shown |
| Layout | 2 | Opening (news, demo snippet, one line) → How I ran into it → The fix (snippets, then the check) → Why not → What I (think I) learned → links, `---`, Corrections, DISCLAIMER, AI disclosure, in order. The opening implies rather than says who this hits |
| The hook | 2 | Real moment (fresh Mac of 2026-11-06, PR #102), first person, one wink (Marauder's Map) that fits and echoes on the cover ("mischief managed", 🗺️) |
| Lived or proven | 2 | Leak number → dev.to explainer; IV / always-modified → getsops/sops#1137; `textconv` and never caching it → git docs; fresh-Mac key path → PR #102 and the scripts; `required true`, clean/smudge → Red Hat article; alternatives → GitGuardian, git-agecrypt, the comparison. Weakest: "git calls a diff command with seven arguments" has no link of its own (true, documented under `GIT_EXTERNAL_DIFF` in git(1)). Each fact once |
| STEPPS | 8/12 | Social currency 2 · Triggers 1 · Emotion 1 · Public 1 · Practical value 2 · Stories 1. Bars met (raw ≥ 6, Practical value 2, Social currency 2) |
| Voice | 2 | hype words: none ("presto" is the author's habit) · mistake stated: yes (cloned before the key; a copied line hung `git diff` for ten months) |
| LinkedIn hook | 2 | Opening 164 characters, stands alone with a specific detail (fresh Mac, ciphertext, age key); about 220 characters without the URL; `{devto.url}` in the post; the title states the insight |
| Images | 2 | One image (cover). Phone test passes at 400 px (title and terminal readable, subtitle small but legible); LinkedIn crop keeps everything; one point (git holds ciphertext, disk holds plain text); series look, pill `dots #1` matches topic 1 |
| Goals 1–5 | 8/10 | 1 2 · 2 2 · 3 2 · 4 1 · 5 1 |
| Language | 2 | English throughout; no PT-BR text |
| Safety | ok | No secret, key or private name. The public recipient is elided (`age1…`); `~/.config/sops/age/keys.txt` and `SOPS_AGE_KEY_FILE` are sops' own documented defaults, not the name of a stored secret; `config/.env` is already public in the repo; the password manager is unnamed. Repo `roalcantara/dots` is PUBLIC |
| `blog:check` | ok | 0 blocks, 0 warnings |

## Consider

1. **Fix the front-matter description's count** (goal 2): it says "Two things broke it, and both have a fix", but the
   post now shows three (the always-modified status, the fresh Mac, the hanging `git diff`). Say "Three things broke
   it" or drop the count; dev.to shows this line under the title.
2. **Say where the key really lives** (goal 2): "The key lives outside the repo" and "`install` … writes
   `~/.config/sops/age/keys.txt`" are true through two symlinks, but `install` writes `config/age/keys.txt` inside the
   dots working tree, kept out of git by `config/.gitignore`. Either "outside git (an ignored path)" or one line on
   the symlink, so a reader who copies the layout knows the ignore rule is what protects it.
3. **Link the "seven arguments" claim** (goal 1): add the git(1) `GIT_EXTERNAL_DIFF` link (or the fix commit / its
   spec) to the last lesson, and update the task's `sources:` comment, which still lists only the two filter scripts,
   to include `script/textconv.sops.sh` and the external links the post rests on.
4. **Show the textconv one-liner** (goal 2): as with the smudge script, one line makes the diff step reproducible
   without opening the repo: `sops --decrypt "$1" 2>/dev/null || cat "$1"`. Optionally add `age-keygen -o …` before
   the `.sops.yaml` step for a reader with no key yet.
5. **Smooth the second sentence and name the reader** (goal 5, tone): "My dotfiles commit theirs on purpose" trips a
   cold reader. Something like "If your repo holds secrets, you can commit them on purpose instead: mine has nine
   files…" also says who this hits, which the layout asks the opening to do.
6. **Date the news instead of "This month"** (goal 1): "In November 2026, researchers found…" keeps the opening true
   once the news is old (the playbook's "the post must still make sense after the news is forgotten").
7. **Align the cover with the post** (visuals, goal 5): the terminal shows `git show HEAD:.env`, the post
   `HEAD:config/.env`; and the LinkedIn post could add one beat on what it cost ("…and `Failed to get the data key`
   on every file") so the moment carries its pain, not only the wink.

## Variables (the `vars:` comment)

hook type: confession · cover style: series, terminal (Ghostty), wink 🗺️ · images: 1 (cover only) · LinkedIn format:
link card, quote opening, no image · language: en · day/time: <author> · tags: git,security,devops,productivity

<!-- reviewed: b7f2a9a089260869 -->
