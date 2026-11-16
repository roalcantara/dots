# Review: secrets-sops-age · 2026-11-16

**Verdict:** PASS

## Must fix

<!-- Blocking only: safety, anti-goals, a missing or broken RECIPE, a failed blog:check. Empty means none. -->

None.

## Cold read

- **The one point:** I can commit my secrets on purpose if a git clean/smudge filter runs them through SOPS + age, so
  git only ever stores ciphertext and my disk holds plain text, with the age key kept out of git; and the author shows
  the three ways it broke (a new IV every run made files look modified, a fresh Mac cloned before the key and looked
  for it in another folder, a copied diff setting hung `git diff`) and the fix for each.
- **Would I save it, and why:** Yes. Each step is a small snippet I can paste, the "always modified" trick and the
  "never cache textconv" warning are things I'd otherwise learn the hard way, and the closing check tells me when
  I'm done. The diff image right under "How I ran into it" made the idea click before I read the fix.
- **Where I got lost:** Still briefly at "My dotfiles commit theirs on purpose" (theirs = their own secrets, not the
  `.claude` file); after that, nowhere.

## Scores

| Check | Score | Note |
| --- | --- | --- |
| Cold read | 2 | One point found at once; would save it for the snippets and the three gotchas |
| Information gain | 2 | Beyond the usual clean/smudge how-to, it shows how the setup breaks in real use (new IVs mark files modified, a fresh Mac clones before the key and macOS sops looks for the key elsewhere, `diff.command` hangs `git diff`) and the fix for each |
| RECIPE self-test | 2 | `.gitattributes`, `.sops.yaml`, filter and textconv config, key path, re-checkout and the check all have snippets matching the repo (re-verified: `check-attr` → `sops`, 9 filtered files, 14 `ENC[AES256_GCM` values in `HEAD:config/.env`). Remaining gaps for a stranger: no `age-keygen` line, and the textconv script is described, not shown |
| Layout | 2 | Opening (news, demo snippet, one line) → How I ran into it (wink card on top, then the moment) → The fix (snippets, then the check) → Why not → What I (think I) learned → links, `---`, Corrections, DISCLAIMER, AI disclosure, in order. All code lines ≤ 70 characters. The opening still implies rather than says who this hits |
| The hook | 2 | Real moment (fresh Mac, PR #102 / dbe14bc), first person, with a cost (`Failed to get the data key`, ":("). The wink now lives only in the card; the article's text has no pop-culture line (no Marauder / mischief / solemnly / map left in `post.md`) |
| Lived or proven | 2 | Leak count → dev.to explainer; IV / always modified → getsops/sops#1137; seven arguments → git's `GIT_EXTERNAL_DIFF` docs; textconv and never caching → gitattributes docs and the task's `sources:`; key location → `install`, `.gitignore`; fresh-Mac key path → PR #102 and the scripts; clean/smudge → Red Hat; alternatives → GitGuardian, git-agecrypt, the comparison; global ignore → `config/git/ignore`. "Ten months" is first-person lived. The one repeated fact is "git holds ciphertext, my disk holds plain text" (opening line, wink card, cover): see Consider 2 |
| STEPPS | 8/12 | Social currency 2 · Triggers 1 · Emotion 1 · Public 1 · Practical value 2 · Stories 1. Bars met (raw ≥ 6, Practical value 2, Social currency 2). The card gives Public a shareable object, but LinkedIn uses the link card, so it stays 1 for now |
| Voice | 2 | hype words: none ("presto" is the author's habit) · mistake stated: yes (cloned before the key; a copied line hung `git diff` for ten months) |
| LinkedIn hook | 2 | Opening 163 characters; 230 characters without the URL; `{devto.url}` in the post; the title states the insight. The quote opening is the author's choice (noted by the author); it is a wink, not the lived moment, but the second sentence carries the moment (fresh Mac, ciphertext, age key) |
| Images | 2 | Two images. **Wink card:** real command (`diff -u <(git show HEAD:config/.env) config/.env`), real shape of its output (`/dev/fd/63`, one encrypted value against its plain one, a non-secret key unchanged, the 6 `sops_` metadata lines trimmed as a grey comment — `HEAD:config/.env` has 6), dummy key and value (`APP_SECRET` and `DEBUG` are not in the real file; dummy values are allowed); teaches without the text (git holds ciphertext, the disk plain, non-secret values stay readable); alt text present. Phone test: terminal lines legible at 400 px, the subtitle and footer are at the limit. **Cover:** passes the phone test and the LinkedIn crop (nothing cut), subtitle keeps only the 🗺️ wink, pill `dots #1`, series look |
| Goals 1–5 | 8/10 | 1 2 · 2 2 · 3 2 · 4 1 · 5 1 |
| Language | 2 | English throughout; no PT-BR text |
| Safety | ok | No secret, key or private name. The card's `APP_SECRET="mischief-managed"` is a dummy, not a stored secret's name (absent from `config/.env`); the ciphertext is truncated (`9xQ…`); the recipient is elided (`age1…`); `config/age/keys.txt`, `~/.config/sops/age/keys.txt` and `SOPS_AGE_KEY_FILE` are paths and sops' own variable, already public in the repo; the password manager is unnamed. Repo `roalcantara/dots` is PUBLIC |
| `blog:check` | ok | 0 blocks, 0 warnings |

## Consider

1. **Smooth the second sentence and name the reader** (goal 5, tone): "My dotfiles commit theirs on purpose" still
   trips a cold reader, and the layout asks the opening to say who this hits. Something like "If your repo holds
   secrets, you can commit them on purpose instead: my dotfiles do, nine files run through a git filter…".
2. **Make the cover say something the card doesn't** (visuals, goal 5): the opening line, the wink card and the cover
   all show "ciphertext in git, plain on disk". The card now owns that point; the cover's window could show the
   setup instead (`git check-attr filter -- config/.env` → `filter: sops`, or the `git status --short` clean check),
   and its subtitle drop the second "encrypted on commit", which repeats the title.
3. **Show the textconv one-liner** (goal 2): as with the smudge script, one line makes the diff step reproducible
   without opening the repo (`sops --decrypt "$1" 2>/dev/null || cat "$1"`). Optionally add
   `age-keygen -o config/age/keys.txt` before the `.sops.yaml` step for a reader who has no key yet.
4. **Bridge the card to the moment** (visuals, tone, goal 2): the card shows the end state (disk plain), the text
   right under it starts with the failure (everything stayed encrypted). One short lead-in such as "This is what it
   should look like. On a brand-new Mac, it didn't:" lets the card set up the hook instead of sitting beside it.
5. **Date the news instead of "This month"** (goal 1): "In November 2026, researchers found…" keeps the opening true
   once the news is old.
6. **Raise the card's small text** (visuals, goal 4): at 400 px the subtitle and the footer title are at the edge of
   legible; one size up for both, or a shorter subtitle ("The repo is a Marauder's Map: ciphertext until the key
   says the words."), keeps the phone test comfortable.
7. **Try the card as the LinkedIn image once** (goal 5): it teaches on its own and matches the quote opening; an
   image post (`linkedin=image`, the link in the text) would test the series' link-vs-image question on its first
   post. Optional; the link card is fine.

## Variables (the `vars:` comment)

hook type: confession · cover style: series, terminal (Ghostty, focused), wink 🗺️ · images: 2 (cover, wink card:
diff) · LinkedIn format: link card, quote opening, no image · language: en · day/time: <author> · tags:
git,security,devops,productivity

<!-- reviewed: bb43556381fa71de -->
