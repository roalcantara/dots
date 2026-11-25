# Review: 2026-12-01-commit-conventions-release-notes · 2026-11-25

**Verdict:** PASS

## Must fix

<!-- Blocking only: safety, anti-goals, a missing or broken RECIPE, a failed blog:check. Empty means none. -->

## Cold read

- **The one point:** when you squash-merge and release with semantic-release, the pull request title is the only
  commit it reads, so a plain title quietly drops every `feat:`/`fix:` inside it, and the release job still goes
  green.
- **Would I save it, and why:** yes. "The PR title is the commit" is a rule I can take to my team today, and the
  `git log --no-merges … | grep -vE` check is a one-liner I'd paste into my own pre-release routine.
- **Where I got lost:** nowhere. The opening now says the body doesn't count, and the `84a8fc1` snippet plus "Three
  `feat(backup):` commits went into that pull request" makes it concrete at once.

## Scores

| Check | Score | Note |
| --- | --- | --- |
| Cold read | 2 | One point named at once; would save for the PR-title rule and the check command |
| Layout | 2 | Opening (who this hits, linked) + demo snippet → How I ran into it → The fix (4 numbered steps + check) → Why not a commit-msg hook? → What I (think I) learned → dots links, `---`, Corrections, DISCLAIMER, AI disclosure, in order. Every command and setting in a fenced block; no code line over 70 characters; ~1,090 words |
| The hook | 2 | Real moment, first person: a tool titled the PRs, six squash-merged in a week, noticed afterwards, with numbers. The Obliviate wink stays in the card; no pop-culture line in the prose |
| Lived or proven | 2 | Squash commit titled after the PR → GitHub docs. feat/fix bumps → Conventional Commits + semantic-release. `GITHUB_TOKEN` starts no other workflow → GitHub docs (now linked). Preset mapping → `.releaserc.yml`. v26 stable Nov 16 → releases page. Merge since #111, titles from #102, hook dropped in #96 → PRs linked. Numbers lived and reproducible: the six non-conventional first-parent subjects in `v1.36.0..v1.39.0` (re-ran: 6), 88 releases (`gh release list`: 88), pinned `semantic-release` 25.0.9 (`.github/release/package.json`). Each fact once |
| Information gain | 2 | Most Conventional Commits / semantic-release posts stop at "lint your commit messages"; this one shows, with real numbers, that a commit-msg hook can't catch it because the broken commit is written by GitHub's merge button, and gives one check that works for both merge styles |
| RECIPE self-test | 2 | Format, `.releaserc.yml`, the job (fetch-depth 0, pinned lockfile, personal token and why, concurrency), the merge choice and the check command: redoable from `## The fix…` alone. `<sha>` placeholders are fine; the linked workflow has the real pins |
| STEPPS | 9/12 | Social currency 2 · Triggers 2 · Emotion 1 · Public 1 · Practical value 2 · Stories 1 — bars met (raw ≥ 6, Practical value 2, Social currency 2) |
| Voice | 2 | hype words: none in the prose (`blog:check`'s "unlock" is inside real `git log` output, "Implement age-key unlock…") · mistake stated: yes (tool-written titles, unpinned semantic-release, duplicated changelog, tag-before-Release limit) |
| LinkedIn hook | 2 | 191 characters for the opening, 233 without the URL; lived, stands alone, specific (67 features and fixes); `{devto.url}` in the post; the title states the insight |
| Images | 2 | phone test: pass (cover terminal ~24 characters a line, wink and diagram text large) · one point each (cover: plain title replaces `feat`; wink: three feats in, zero in CHANGELOG.md; diagram: the hook runs locally, never at Squash and merge) · series look: Catppuccin, Ghostty window, cyan focus · wink output real · alt text on both inline images · cover now says "3 feats", matching the text |
| Goals 1–5 | 9/10 | 1 2 · 2 2 · 3 2 · 4 1 · 5 2 |
| Language | 2 | Article in English. LinkedIn in PT-BR with an English source block; code and tool names kept in English; natural loanwords (commit, squash merge, changelog, fixes); 3 English hashtags |
| Safety | ok | `roalcantara/dots` is PUBLIC (`gh repo view`). No secret, email, client or private repo. `secrets.GH_TOKEN` in the workflow excerpt is semantic-release's documented generic variable, already public in the linked workflow, not a gopass path or key file |
| `blog:check` | ok | 0 blocks; 1 warning: hype word "unlock" (real command output; see Voice) |

## Consider

<!-- At most 7, most valuable first; each names the goal it serves; visual and tone suggestions explicit. -->

1. **The in-between LinkedIn post points to an article that doesn't tell its story** (goals 2, 4). It is about the
   `[A-Z]` collation bug and ends "`[[:upper:]]` fixed it: {devto.url}", but `post.md` never mentions the locale
   bug; a reader who clicks finds nothing about it. Either add two lines on it under `## Why not a commit-msg
   hook?` (next to the dropped hook), or point the in-between post at the hk commit or a later gotchas post.
2. **Visuals: the wink card's "# third line trimmed" reads as if a line were removed** (goal 5). Three lines are
   shown; only the third is shortened with "…". "# third subject shortened" (or no comment at all, since the "…"
   already says it) removes the doubt.
3. **Say what the check's output means** (goal 2): after "No output, no surprise", add one line such as "each line
   printed is a commit the analyzer will skip", for a reader who lands on `## The fix…` from a link.
4. **Name what checks subjects now** (goal 3): the aside on the dropped hook says why it went (#96) but not whether
   anything replaced it. One clause (for example the hk step, if that is what runs now) tells a reader whether you
   still lint locally.
5. **Tone: Emotion and Stories are the weak STEPPS drivers** (goal 5). The cost is stated as numbers, not as a
   moment. If there was one (opening an empty Release, someone asking what changed), one first-person sentence in
   `## How I ran into it` lifts both. Only if it happened.
6. **Public: give the check a name people can repeat** (goal 5). A short label in bold before the command ("the
   skipped-commits check") makes it easier to quote in comments and link from other posts.

## Variables (the `vars:` comment)

hook type: confession · cover style: terminal-diff · images: 3 (cover + wink + diagram) · LinkedIn format: link ·
language: pt-br · day/time: <author> · tags: git, devops, github, productivity

<!-- reviewed: 400ee18cc6c5d971 -->
