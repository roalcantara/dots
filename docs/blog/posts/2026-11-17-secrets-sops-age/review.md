# Review: secrets-sops-age · 2026-11-16

**Verdict:** PASS

## Must fix

<!-- Blocking only: safety, anti-goals, a missing or broken RECIPE, a failed blog:check. Empty means none. -->

None.

## Cold read

- **The one point:** I can commit secrets on purpose if a git clean/smudge filter runs them through SOPS + age: git
  only stores ciphertext, my disk holds plain text, and the age key stays out of git. The author also shows the three
  ways it broke (a new IV each run made files look modified, a fresh Mac cloned before the key and looked for it in
  another folder, a copied diff setting hung `git diff`) and the fix for each.
- **Would I save it, and why:** Yes. Every step is a short snippet I can paste. The "always modified" trick and the
  "never cache textconv" warning are things I'd otherwise learn the hard way, and the closing check tells me when I'm
  done. The diff card under "How I ran into it" made the idea click before the fix.
- **Where I got lost:** Briefly at "My dotfiles commit theirs on purpose" ("theirs" means their own secrets, not the
  `.claude` file). After that, nowhere.

## Scores

| Check | Score | Note |
| --- | --- | --- |
| Cold read | 2 | Found the one point at once; would save it for the snippets and the three gotchas |
| Information gain | 2 | Beyond the usual clean/smudge how-to, it shows how the setup breaks in real use (new IVs mark files modified, a fresh Mac clones before the key and macOS sops looks for the key elsewhere, `diff.command` hangs `git diff`) and gives the fix for each |
| RECIPE self-test | 2 | `.gitattributes`, `.sops.yaml`, filter and textconv config, the key path, the re-checkout and the check all have snippets that match the repo (re-checked today: `check-attr` → `sops`, 9 filtered files, 14 `ENC[AES256_GCM` values in `HEAD:config/.env`). Small gaps for a stranger: no `age-keygen` line, and the textconv script is described, not shown |
| Layout | 2 | Opening (news, demo snippet, one line) → How I ran into it (wink card on top, then the moment) → The fix (snippets, then the check) → Why not → What I (think I) learned → links, `---`, Corrections, DISCLAIMER, AI disclosure, in order. All code lines ≤ 70 characters. The opening implies who this hits but doesn't say it |
| The hook | 2 | A real moment (the fresh Mac of 2026-11-06, PR #102 / dbe14bc), first person, with a cost (`Failed to get the data key`, ":("). The wink lives only in the card and the cover; `post.md` has no pop-culture line (no Marauder, mischief or solemnly) |
| Lived or proven | 2 | Leak count → dev.to explainer; IV / always modified → getsops/sops#1137; seven arguments → git's `GIT_EXTERNAL_DIFF` docs; textconv and never caching it → gitattributes docs and the task's `sources:`; key location → `install`, `.gitignore`; fresh-Mac key path → PR #102 and the scripts; clean/smudge → Red Hat; alternatives → GitGuardian, git-agecrypt and the comparison; global ignore → `config/git/ignore`. "Ten months" is lived (first person). "Ciphertext in git, plain on disk" now appears in the opening line, the wink card and the cover. STYLE.md allows the cover to echo the card, so this is not a duplicate in the text |
| STEPPS | 8/12 | Social currency 2 · Triggers 1 · Emotion 1 · Public 1 · Practical value 2 · Stories 1. Bars met (raw ≥ 6, Practical value 2, Social currency 2). The cover now shows the before/after in feeds and in the link card, which helps Public a little; it stays at 1 until an image post tests it |
| Voice | 2 | hype words: none ("presto" is the author's habit) · mistake stated: yes (cloned before the key; a copied line hung `git diff` for ten months) |
| LinkedIn hook | 2 | Opening paragraph 163 characters; 230 characters without the URL; `{devto.url}` is in the post; the title states the insight. The quote opening is the author's choice. The quote is a wink rather than the lived moment, but the second sentence carries the moment (fresh Mac, ciphertext, age key) |
| Images | 2 | Two images, series look, alt text on the card. **Cover (changed):** the window echoes the card's key lines (comment, red `-KEY=ENC[AES256_GCM,…]`, green `+KEY="mischief-managed"`), as STYLE.md's Cover row allows: 3 lines, generic dummy `KEY`, truncated ciphertext. The subtitle "sops + age, in a git filter 🗺️" no longer repeats the title and adds the how. Phone test: the title, the hashtags and the two diff lines are readable in `raw/00-cover-phone.png`; the grey comment line and the subtitle are small but legible. LinkedIn crop: nothing cut, though the window's right border sits at the edge of the safe area (x ≈ 880). **Wink card (unchanged):** a real command and the real shape of its output, dummy key and value (`APP_SECRET` is not in `config/.env`); it teaches without the text |
| Goals 1–5 | 8/10 | 1 2 · 2 2 · 3 2 · 4 1 · 5 1 |
| Language | 2 | English throughout; no PT-BR text |
| Safety | ok | No secret, key or private name. The cover's `KEY` and the card's `APP_SECRET` are dummies, absent from `config/.env`; ciphertext truncated (`…`, `9xQ…`); the recipient elided (`age1…`); `config/age/keys.txt`, `~/.config/sops/age/keys.txt` and `SOPS_AGE_KEY_FILE` are paths and sops' own variable, already public in the repo; the password manager is unnamed. The repo `roalcantara/dots` is PUBLIC |
| `blog:check` | ok | 0 blocks, 0 warnings |

## Consider

1. **Name the reader in the second sentence** (goal 5, tone): "My dotfiles commit theirs on purpose" still trips a
   cold reader, and the layout asks the opening to say who this hits. For example: "If your repo holds secrets, you
   can commit them on purpose instead: my dotfiles do, nine files run through a git filter…".
2. **Bridge the card to the moment** (visuals, tone, goal 2): the card shows the end state (plain on disk), but the
   text under it starts with the failure (everything stayed encrypted). A short lead-in such as "This is what it
   should look like. On a brand-new Mac, it didn't:" makes the card set up the hook instead of just sitting beside
   it.
3. **Give the cover's window a little more room** (visuals, goal 5): its right border sits on the LinkedIn safe-area
   edge (x ≈ 880 of 1000), and the grey `# in git vs on my disk` line is the faintest text at phone size. Move the
   window about 10–20 px left, or brighten the comment. Alternatively, swap the comment for the real command
   (`git show HEAD:config/.env`) so the cover shows the source of the red line.
4. **Show the textconv one-liner** (goal 2): show it as the smudge script is shown, so the diff step can be redone
   without opening the repo (`sops --decrypt "$1" 2>/dev/null || cat "$1"`). Optionally add
   `age-keygen -o config/age/keys.txt` before the `.sops.yaml` step, for a reader who has no key yet.
5. **Date the news instead of "This month"** (goal 1): "In November 2026, researchers found…" keeps the opening true
   once the news is old.
6. **Raise the card's small text** (visuals, goal 4): at 400 px the card's subtitle and footer title are at the edge
   of legible. Make both one size larger, or shorten the subtitle ("The repo is a Marauder's Map: ciphertext until
   the key says the words.").
7. **Try the card as the LinkedIn image once** (goal 5): the cover now carries the diff into the link card, which
   narrows the gap. Even so, an image post (`linkedin=image`, the link in the text) on the first post would start
   answering the series' link-vs-image question. Optional.

## Variables (the `vars:` comment)

hook type: confession · cover style: series, terminal (Ghostty, focused), window echoes the wink card's diff, wink 🗺️ ·
images: 2 (cover, wink card: diff) · LinkedIn format: link card, quote opening, no image · language: en · day/time:
<author> · tags: git,security,devops,productivity

<!-- reviewed: a6f12acd92502352 -->
