# Review: 2026-11-17-secrets-sops-age · 2026-11-16

**Verdict:** BLOCKED

## Must fix

1. **The opening's claim says more than its source.** "researchers found thousands of working credentials in
   public `.claude/settings.local.json` files" is not what the linked explainer says. It reports 1,122 of 104,185
   public copies of that file (about 1.1 %) holding a real secret, 2,539 distinct secrets across 1,994 repos once
   history and other files are counted, and it says plainly that Apiiro "did not test the credentials": the
   research "proves exposure, not compromise". Drop "working" and use the source's own number, for example "found
   real secrets in over a thousand public `.claude/settings.local.json` files on GitHub". The fix is one word and
   one number, but as it stands the first sentence of a security post overstates its evidence (goal 2 over 5).

## Cold read

- **The one point:** You can commit secrets to a public repo safely when a git clean/smudge filter encrypts them
  with SOPS + age: ciphertext in every commit, plain text on disk, the key outside the repo. Two things break it
  in practice: re-encryption makes every file look modified, and on a fresh Mac sops looks for the key somewhere
  else.
- **Would I save it, and why:** Yes. The "compare the plain texts and reuse the committed blob" trick and the
  `~/Library/Application Support` key path are the two things I'd otherwise have to find out the hard way.
- **Where I got lost:** "the setup task checks the filtered files out again" (which task? I don't have it), and
  then `git -c filter.sops.clean=cat checkout`: why turn off the *clean* filter to make a checkout decrypt? Before
  that, `$AGE_KEY_FILE` in the `export` line and `$hash_index`/`$enc_file` in the clean excerpt are never defined.

## Scores

| Check | Score | Note |
| --- | --- | --- |
| Cold read | 2 | One point found right away; would save it. Lost at the re-checkout step (see Cold read) |
| Information gain | 2 | Most SOPS-in-git guides stop at the filter; this one shows the two things that break it on a real machine, non-deterministic encryption making `git status` dirty (fixed by comparing plain texts in the clean filter) and sops on macOS looking for the age key in `~/Library/Application Support` (fixed with `SOPS_AGE_KEY_FILE`) |
| Layout | 2 | Opening (who this hits, news link, demo snippet), How I ran into it, The fix, Why not, What I (think I) learned, dots links, `---`, Corrections, DISCLAIMER, AI disclosure: all in order. Snippets for every setting and the check command with output |
| The hook | 2 | Lived (fresh Mac of 2026-11-06, PR #102 / dbe14bc), first person, one wink (Marauder's Map) echoed on the cover's 🗺️ and "mischief managed" |
| Lived or proven | 1 | IV / dirty status → getsops/sops#1137; manual SOPS → GitGuardian guide; git-crypt one key → comparison link; key path → lived + PR #102; counts 9 and 14 verified (`git ls-files ':(attr:filter=sops)'`, `git show HEAD:config/.env`). Weak: "thousands of working credentials" (Must fix); "Secrets leak from public repos every day" has no link (the `pick:` source is not in `sources:`) |
| RECIPE self-test | 1 | Followable for the core, but gaps a reader hits: `diff.sops.command '… %f'` is broken (see Consider 1); the `.gitattributes` snippet filters `config/ssh/keys/*.key` while the `.sops.yaml` snippet has only an `.env` rule, so encrypting a key fails with no matching creation rule; `$AGE_KEY_FILE` undefined in the snippet; the "setup task" is unnamed |
| STEPPS | 10/12 | Social currency 2 · Triggers 2 · Emotion 1 · Public 1 · Practical value 2 · Stories 2. Bars met (raw ≥ 6, Practical value 2, Stories 2) |
| Voice | 2 | hype words: none · mistake stated: yes (cloned before the key existed; key path mismatch; ":(") |
| LinkedIn hook | 1 | Opening 163 characters, 225 without the URL; dev.to URL in the post; 2 hashtags. But the opening is the wink and a general statement, not the lived moment in first person, there is no beat on why it mattered, and the title (the link card) states the what, not the insight |
| Images | 2 | Cover only. Phone test passes (`raw/00-cover-phone.png`: title, terminal and hashtags legible); LinkedIn crop keeps everything (`raw/00-cover-linkedin.png`); one point (ciphertext in git vs plain on disk); series look (Mocha, focused Ghostty, pill `dots #1`) |
| Goals 1–5 | 8/10 | 1 2 · 2 1 · 3 2 · 4 1 · 5 2 |
| Language | 2 | English throughout |
| Safety | ok | No secret, key, email, client or private repo. The age public key is elided (`age1…`); paths shown are tool conventions or public-repo globs; `roalcantara/dots` is PUBLIC (`gh repo view`); `SOPS_AGE_KEY_FILE` is sops's own setting, not a stored secret |
| AI disclosure | ok | Closing line present, last |
| `blog:check` | ok | 0 blocks, 0 warnings |

## Consider

1. **Goal 2 (RECIPE):** `git config --local diff.sops.command 'script/smudge.sops.sh %f'` doesn't do what it
   suggests. Git doesn't expand `%f` in a diff driver's `command`; it appends its seven external-diff arguments
   (checked here with a stub driver: it received `%f t.env /tmp/…/t.env <sha> 100644 t.env <sha> 100644`). So the
   smudge script gets `%f` as its path and reads stdin, and `git diff` on a changed secret fails or hangs. Use
   `diff.sops.textconv 'sops --decrypt'` (or a small wrapper that takes the file as `$1`), or drop the line and
   `diff=sops` from the snippet. Fix it in the repo too (`mise.toml` `setup:git:filters`). Readers will copy that
   line as written.
2. **Goal 2 (RECIPE):** make the two config snippets match. Either add a rule for `config/ssh/keys/.*\.key$`
   (`age: age1…`, no `encrypted_regex`) to the `.sops.yaml` snippet, or cut that line from the `.gitattributes`
   snippet. As they are now, a reader who copies both gets a failed commit on the first key file.
3. **Goal 2 (RECIPE, cold read):** in the key paragraph, define the variable in the snippet
   (`AGE_KEY_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt"` above the `export`). Name the setup task
   (`mise run setup:git:filters`, which `mise bootstrap` runs). Add one clause on the re-checkout: "`clean=cat` so
   git doesn't re-encrypt the file to compare it; the smudge filter, now with the key, writes it out plain". That
   is the exact place the cold read got lost.
4. **Goal 5 (LinkedIn, tone):** open with the lived moment in first person, then the wink, then a beat:
   `On a fresh Mac, my dotfiles showed me nothing but ciphertext.. "I solemnly swear that I am up to no good" didn't help; the age key did.` /
   `Secrets versioned, nothing readable in history.` / `Here is how:` + URL. That stays under 250 characters and
   follows the 2026-11-16 shape (moment, beat, pointer).
5. **Goal 5 (title):** the link card shows the title, and the title should state the insight. Consider
   `Secrets in git, encrypted on commit: the two things that broke it (SOPS + age)` or
   `My secrets live in git, encrypted. A fresh Mac broke it twice (SOPS + age)`. The cover can keep its two lines.
6. **Goal 2 (proof):** "Secrets leak from public repos every day" needs a link (GitGuardian's State of Secrets
   Sprawl, or the Help Net Security piece from the `pick:` comment, added as a `sources:` entry) or the softer "and
   it keeps happening". It would also help to say what the RECIPE leaves out: the key is a single point of failure
   (a lost password manager means lost secrets), and anyone with the key can read every past commit, so rotating a
   leaked key means re-encrypting.
7. **Goal 5 (visuals):** the cover's terminal reads `git show HEAD:.env` while the post uses `config/.env`. Matching
   them, and adding alt text in the front matter or the opening, would help. Optional: the wink runs in the
   opposite direction. "Mischief managed" is what *blanks* the map, so it fits the "ciphertext in git" side; if
   that's intended, it's a nice touch.

## Variables (the `vars:` comment)

hook type: confession · cover style: terminal (Ghostty, focused, 🗺️ wink) · images: 1 (cover only) · LinkedIn format: quote + pointer + link card, prose · language: en · day/time: <author> · tags: git, security, devops, productivity

`vars: hook=confession cover=terminal-ghostty-focused images=1-cover linkedin=quote-pointer-linkcard lang=en day=<author> tags=git,security,devops,productivity`

<!-- reviewed: 20daac9fb57cf96d -->
