# Review: 2026-12-01-commit-conventions-release-notes · 2026-11-25

**Verdict:** PASS

## Must fix

<!-- Blocking only: safety, anti-goals, a missing or broken RECIPE, a failed blog:check. Empty means none. -->

## Cold read

- **The one point:** if you squash-merge and release with semantic-release, the pull request title becomes the only
  commit it analyses, so a plain title silently drops every `feat:`/`fix:` inside it, and the release job still
  goes green.
- **Would I save it, and why:** yes: the `git log … | grep -vE` pre-release check and the "the PR title is the
  commit" rule are things I'd paste into my own repo tomorrow, and the "green job that did nothing" is the kind of
  trap I'd want a link to when it bites a teammate.
- **Where I got lost:** "That title is all semantic-release reads.." in the opening: it ends on two dots right
  before a code block, and for a beat I wondered whether the body (where GitHub lists the squashed commits, as the
  wink card shows) is read too. The next sentence ("None of them made a release") settles it.

## Scores

| Check | Score | Note |
| --- | --- | --- |
| Cold read | 2 | One point named at once; would save for the check command and the PR-title rule |
| Layout | 2 | Opening on who this hits (with links) + demo snippet → How I ran into it → The fix (4 numbered steps + check) → Why not a commit-msg hook? → What I (think I) learned → dots links, `---`, Corrections, DISCLAIMER, AI disclosure, in order. Every command and setting has a fenced snippet; no code line over 70 characters; 1,084 words |
| The hook | 2 | Real moment, first person: a tool titled the PRs, six squashed in a week, noticed afterwards; backed by real numbers. The wink (Obliviate) stays in the card; no pop-culture line in the prose |
| Lived or proven | 2 | Squash commit titled after the PR → GitHub docs link. feat/fix bumps → Conventional Commits + semantic-release links. Preset mapping → `.releaserc.yml` linked. v26 stable Nov 16 → releases link. "A Release created with `GITHUB_TOKEN` starts no other workflow" → stated in the linked workflow and ADR 0001 (repo), no external source (see Consider). Numbers (6 titles, 133/68/67, 88 releases, two `1.38.1` sections) are lived, from the repo; the six titles and `84a8fc1` reproduce exactly. Each fact once |
| Information gain | 2 | Most Conventional Commits/semantic-release posts stop at "lint your commit messages"; this one shows, with real numbers, that a commit-msg hook can't help because the broken commit is written by GitHub's merge button, and gives a one-line pre-release check that works for both merge styles |
| RECIPE self-test | 2 | Format, `.releaserc.yml`, the job (fetch-depth, pinned lockfile, personal token and why), the merge choice and the check command: redoable from `## The fix…` alone. The `<sha>` placeholders are fine; the linked workflow has the real pins |
| STEPPS | 9/12 | Social currency 2 · Triggers 2 · Emotion 1 · Public 1 · Practical value 2 · Stories 1 — bars met (raw ≥ 6, Practical value 2, Social currency 2) |
| Voice | 2 | hype words: none in the prose (`blog:check`'s "unlock" is inside real `git log` output: "Implement age-key unlock…", fine) · mistake stated: yes (tool-written titles, unpinned semantic-release, duplicated changelog, the tag-before-Release limit) |
| LinkedIn hook | 2 | 191 characters for the opening, 231 without the URL; lived, stands alone, specific (67 features and fixes); dev.to URL in the post; title states the insight |
| Images | 2 | phone test: pass (wink and diagram text large; cover window lines ~24 characters) · one point each (cover: the squash swaps feat for a plain title; wink: three feats in, zero in CHANGELOG.md; diagram: hook runs locally, not at Squash and merge) · series look: Catppuccin, OmniWM window, cyan focus. Wink output is real (7 bullet lines in `84a8fc1`'s body, three `feat`, `grep -c` = 0), alt text present on both inline images |
| Goals 1–5 | 9/10 | 1 2 · 2 2 · 3 2 · 4 1 · 5 2 |
| Language | 2 | Article in English. LinkedIn in PT-BR per the task title, with an English source block; code/tool names kept in English; loanwords (commit, squash merge, changelog, fixes) natural; 3 English hashtags |
| Safety | ok | `roalcantara/dots` is PUBLIC (`gh repo view`). No secret, email, client or private repo. `secrets.GH_TOKEN` in the workflow excerpt is semantic-release's documented generic variable name, already public in the linked workflow, not a gopass path or key file |
| `blog:check` | ok | 0 blocks; 1 warning: hype word "unlock" (real command output; see Voice) |

## Consider

<!-- At most 7, most valuable first; each names the goal it serves; visual and tone suggestions explicit. -->

1. **The in-between LinkedIn post points to an article that doesn't contain its story** (goals 2, 4). It tells the
   `[A-Z]` collation bug and ends "`[[:upper:]]` fixed it: {devto.url}", but `post.md` never mentions the locale
   bug. A reader who clicks finds nothing about it. Either add two lines on it to `## Why not a commit-msg hook?`
   (the dropped hook is where it lived), or point the in-between post at the `hk` commit or a later gotchas post.
2. **Link the `GITHUB_TOKEN` rule to GitHub's docs** (goal 2): "a Release created with `GITHUB_TOKEN` starts no
   other workflow" is proven only by the repo's own comment and ADR. One link to GitHub's "Triggering a workflow
   from a workflow" page (or a `sources:` entry) makes it external proof, like the squash-title link in the opening.
3. **Tone: fix the "reads.." at the end of the opening's paragraph** (goal 2). The two-dot beat is the author's,
   but there it sits at a sentence's end before a code block and reads as a typo; it also invites the cold-read
   question of whether the body is read. "That title is all semantic-release reads: the commits listed in its body
   don't count." settles both.
4. **Visuals: the cover's window says "# 7 commits, one squash:" but shows one `feat` line** (goal 5). True (7
   bullets in `84a8fc1`), but the post and wink card both say "three feat"; "# 3 feats, one squash:" ties the cover
   to the text at a glance in the link card.
5. **Emotion and Stories are the weak STEPPS drivers** (goal 5): the cost is stated as numbers, not as a moment.
   If there was one (a user asking what changed in a version, an empty Release you opened), one first-person
   sentence in `## How I ran into it` would lift both. Only if it happened.
6. **Name the hook that was dropped** (goal 3): "(I had one anyway…)" says it broke commits where cog wasn't
   installed; one clause on what replaced it (if anything checks subjects now, for example the hk step in
   `sources:`) tells a reader whether you still lint locally.
7. **Say what the check's output means** (goal 2): after "No output, no surprise", one line such as "each line
   printed is a commit the analyzer will skip" helps a reader who lands on `## The fix…` from a link.

## Variables (the `vars:` comment)

hook type: confession · cover style: terminal-diff · images: 3 (cover + wink + diagram) · LinkedIn format: link ·
language: pt-br · day/time: <author> · tags: git, devops, github, productivity

<!-- reviewed: 7dd318fb2eb6b86d -->
