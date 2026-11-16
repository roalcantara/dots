# Review: secrets-sops-age · 2026-11-16

**Verdict:** PASS

## Must fix

<!-- Blocking only: safety, anti-goals, a missing or broken RECIPE, a failed blog:check. Empty means none. -->

None.

## Cold read

- **The one point:** I can keep secrets in git on purpose if a clean/smudge filter encrypts them with SOPS + age on
  commit and decrypts them on checkout, with the age key kept out of git; and here are the three ways that setup broke
  for the author (a new IV made files look modified, a fresh Mac cloned before the key and looked for it in the wrong
  place, a copied diff setting hung `git diff`).
- **Would I save it, and why:** Yes. The snippets are copy-paste sized, the "always modified" trick and the
  `textconv` warning are things I would otherwise learn the hard way, and the check at the end tells me when I am done.
- **Where I got lost:** Briefly at "My dotfiles commit theirs on purpose" (theirs = their own secrets, not the
  `.claude` file); after that, nowhere. The key paragraph now reads clearly: a git-ignored file in the repo folder,
  reached through a symlink.

## Scores

| Check | Score | Note |
| --- | --- | --- |
| Cold read | 2 | One point found at once; would save it for the snippets and the three gotchas |
| Information gain | 2 | Beyond the usual clean/smudge how-to, it shows how the setup breaks in real use (new IVs mark files modified, a fresh Mac clones before the key and macOS sops looks for the key elsewhere, `diff.command` hangs `git diff`) and the fix for each |
| RECIPE self-test | 2 | `.gitattributes`, `.sops.yaml`, filter and textconv config, key path, re-checkout and the check all have snippets matching the repo (verified: 9 filtered files, 14 `ENC[` values in `HEAD:config/.env`, `.sops.yaml` rule, `setup:git:filters`, `config/age/keys.txt` ignored by `.gitignore`, `~/.config/sops/age/keys.txt` resolving to it). Remaining gaps for a stranger: no `age-keygen` line, and the textconv script is described, not shown |
| Layout | 2 | Opening (news, demo snippet, one line) → How I ran into it → The fix (snippets, then the check) → Why not → What I (think I) learned → links, `---`, Corrections, DISCLAIMER, AI disclosure, in order. The opening implies rather than says who this hits |
| The hook | 2 | Real moment (fresh Mac of 2026-11-06, PR #102 / dbe14bc, merged that day), first person, one wink (Marauder's Map) that fits and echoes on the cover ("mischief managed", 🗺️) |
| Lived or proven | 2 | Leak count → dev.to explainer; IV / always modified → getsops/sops#1137; seven arguments → git's `GIT_EXTERNAL_DIFF` docs (new); textconv and never caching → gitattributes docs and the task's `sources:`; key location → `install`, `.gitignore`, `sources:`; fresh-Mac key path → PR #102 and the scripts; clean/smudge → Red Hat; alternatives → GitGuardian, git-agecrypt, the comparison; global ignore → `config/git/ignore`. "Ten months" is first-person lived. Each fact once |
| STEPPS | 8/12 | Social currency 2 · Triggers 1 · Emotion 1 · Public 1 · Practical value 2 · Stories 1. Bars met (raw ≥ 6, Practical value 2, Social currency 2) |
| Voice | 2 | hype words: none ("presto" is the author's habit) · mistake stated: yes (cloned before the key; a copied line hung `git diff` for ten months) |
| LinkedIn hook | 2 | Opening 163 characters, stands alone with a specific detail (fresh Mac, ciphertext, age key); about 228 characters without the URL; `{devto.url}` in the post; the title states the insight |
| Images | 2 | One image (cover). Phone test passes at 400 px (title and terminal readable, subtitle small but legible); LinkedIn crop keeps everything; one point (git holds ciphertext, disk holds plain text); series look, pill `dots #1` matches topic-1 |
| Goals 1–5 | 8/10 | 1 2 · 2 2 · 3 2 · 4 1 · 5 1 |
| Language | 2 | English throughout; no PT-BR text |
| Safety | ok | No secret, key or private name. The recipient is elided (`age1…`); `config/age/keys.txt`, `~/.config/sops/age/keys.txt` and `SOPS_AGE_KEY_FILE` are paths and sops' own variable, already public in the repo, not the name of a stored secret; `config/.env` is public (encrypted) in the repo; the password manager is unnamed. Repo `roalcantara/dots` is PUBLIC |
| `blog:check` | ok | 0 blocks, 0 warnings |

## Consider

1. **Show the textconv one-liner** (goal 2): as with the smudge script, one line makes the diff step reproducible
   without opening the repo: `sops --decrypt "$1" 2>/dev/null || cat "$1"`. Optionally add
   `age-keygen -o config/age/keys.txt` before the `.sops.yaml` step for a reader who has no key yet.
2. **Smooth the second sentence and name the reader** (goal 5, tone): "My dotfiles commit theirs on purpose" still
   trips a cold reader. Something like "If your repo holds secrets, you can commit them on purpose instead: mine has
   nine files…" also says who this hits, which the layout asks the opening to do.
3. **Date the news instead of "This month"** (goal 1): "In November 2026, researchers found…" keeps the opening true
   once the news is old (the playbook: the post must still make sense after the news is forgotten).
4. **Align the cover with the post** (visuals, goal 5): the terminal shows `git show HEAD:.env` and `cat .env`, the
   post `HEAD:config/.env`. Either is fine alone; matching them lets the cover read as the post's own check.
5. **Name the second symlink, or say "through symlinks"** (goal 2): `~/.config/sops/age/keys.txt` reaches
   `config/age/keys.txt` through two links (`~/.config/sops` → `config/sops`, then `config/sops/age` → `../age`). "a
   symlink" is close enough for the reader; a copier who makes one link by hand gets the same result, so this is
   optional.

## Variables (the `vars:` comment)

hook type: confession · cover style: series, terminal (Ghostty, focused), wink 🗺️ · images: 1 (cover only) · LinkedIn
format: link card, quote opening, no image · language: en · day/time: <author> · tags: git,security,devops,productivity

<!-- reviewed: b3ed36f1a57def1e -->
