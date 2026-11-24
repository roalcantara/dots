# Review: 2026-12-01-commit-conventions-release-notes · 2026-11-24

**Verdict:** PASS

## Must fix

<!-- Blocking only: safety, anti-goals, a missing or broken RECIPE, a failed blog:check. Empty means none. -->

## Cold read

- **The one point:** If I squash-merge and release with semantic-release, the PR title is the only commit it reads;
  a title without a type means no release and no changelog lines, and the job still goes green.
- **Would I save it, and why:** Yes. I squash-merge every day, and the one-liner that lists what the analyzer will
  skip since the last tag is something I'd paste into my own repo before the next release.
- **Where I got lost:** Step 1 says "With no preset configured", then step 3 installs
  `conventional-changelog-conventionalcommits`: I stopped to wonder whether I need a preset or not.

## Scores

| Check | Score | Note |
| --- | --- | --- |
| Cold read | 2 | One point found at once; would save it for the pre-release check |
| Layout | 2 | Opening (who it hits, the demo snippet, one line on it) → How I ran into it → The fix → Why not a commit-msg hook? → What I (think I) learned → dots links, `---`, Corrections, DISCLAIMER, AI line, in order. 972 words |
| The hook | 2 | Real moment, first person ("My commits were fine. My pull request titles weren't"), with the cost (67 of 68); the wink (Obliviate) lives only in the card |
| Lived or proven | 1 | Squash titled after the PR → GitHub docs; the feat/fix contract → semantic-release link; 133 commits, 68 feat/fix, 5 of 6 runs, run 41811286816 → `sources:` (nHqc), re-checked (133/68 recounted from the six squash bodies; the run log prints "There are no relevant changes"); 87 releases → 87 tags since v1.0.0 (2025-07-30); #96 (Nov 4), #102, #111 linked; v26/Node → releases link and run 45371260199. Weak: `perf` → patch and `BREAKING CHANGE:` → major have only the general semantic-release link, not commit-analyzer's default rules. Each fact once: yes (the wink card shows the body's feat lines, the opening the subject and the run) |
| Information gain | 2 | A green semantic-release run can silently drop every `feat` inside a squash merge, and no commit-msg hook can catch it because GitHub writes that commit; measured on a real repo at 67 of 68 features and fixes |
| RECIPE self-test | 2 | Format, `.releaserc.yml` and the workflow excerpt match the repo files; the merge choice is explicit; the check command ran on `origin/main` with no output (exit 1), and `--no-merges` makes it work with both merge styles. Only nit: the unexplained `conventional-changelog-conventionalcommits` install (Consider 2) |
| STEPPS | 9/12 | Social currency 2 · Triggers 2 · Emotion 1 · Public 1 · Practical value 2 · Stories 1. Bars met (raw ≥ 6, Practical value 2, Social currency 2) |
| Voice | 2 | hype words: "unlock" (blog:check warning) only inside a quoted squash subject (`Implement age-key unlock…`), the evidence, not the author's voice · mistake stated: yes ("I let a tool title the pull requests"; the unpinned install as a limit) |
| LinkedIn hook | 2 | Opening 191 characters, lived and standalone; 233 without the URL; `{devto.url}` in the post; the title states the insight. PT-BR as the task title requires; 3 English hashtags |
| Images | 2 | Cover: one point, series look, passes the LinkedIn crop (`raw/00-cover-linkedin.png`), window echoes the card's before/after. Wink card: real command and real output (verified: three `feat(backup)` lines in 84a8fc1's body, `grep -c` → 0), teaches without the text, no pop-culture line in the prose. Diagram `02-squash.png`: shows the mechanism the text can't (where the hook runs vs where the commit is written), readable at 400 px (`raw/02-squash-phone.png`), alt text describes it. Small captions sit near the 8 px floor at 400 px |
| Goals 1–5 | 8/10 | 1 2 · 2 2 · 3 2 · 4 1 · 5 1 |
| Language | 2 | English article; the PT-BR LinkedIn copy keeps commands, tool names and loanwords in English, "você"-free but first person, with the EN source kept below |
| Safety | ok | `roalcantara/dots` is PUBLIC (`gh repo view`). No secret, email, client or private repo. `secrets.GH_TOKEN` / `GITHUB_TOKEN` appear in the workflow excerpt: the generic names semantic-release's own docs use, already public in the linked workflow, not a gopass path or key file; judged not a token-name leak |
| `blog:check` | ok | No blocks; 1 warning (hype word "unlock", inside a quoted commit subject) |

## Consider

1. **Goal 2/4 — the in-between LinkedIn post points to the wrong article.** `linkedin.md`'s in-between (the `[A-Z]`
   collation bug on macOS `/bin/sh`) ends with "`[[:upper:]]` resolveu: {devto.url}", but this article never tells
   that story; it only shows `fix(hk): Detect lowercase subjects in any locale` as a format example. Link the fix
   commit (3149394) or the hk file instead, or add a short paragraph on it to the post.
2. **Goal 2 — explain or drop the preset install.** Step 1 says "With no preset configured", yet step 3 installs
   `conventional-changelog-conventionalcommits`, which `.releaserc.yml` never uses. Add "(installed, unused: the
   default angular rules apply)" or remove it from the excerpt and note the difference from the repo file.
3. **Goal 5 (Stories) — give the noticing moment one sentence.** "I only noticed afterwards" is the only scene;
   say what made you look (a missing version, a release log, the changelog) and when, so the story is a moment,
   not only numbers.
4. **Goal 3 — prove the default release rules.** Link
   [commit-analyzer's default release rules](https://github.com/semantic-release/commit-analyzer#releaserules) on
   "`feat` → minor, `fix` and `perf` → patch, `BREAKING CHANGE:` → major", or add it to the task's `sources:`.
5. **Goal 5 (visuals) — tighten the wink card and diagram.** In `wink.json`, `# third line trimmed` reads as if a
   line was removed; it is the third line's text that is cut: "# line 3 shortened". In `02-squash.png`, the bottom
   fifth is empty: crop it, or enlarge "a new commit, titled after the PR:" and the `dots #2` footer, which sit
   near the 8 px floor at 400 px wide.
6. **Goal 2 (tone/accuracy) — anchor the "presto".** "And **presto!** 87 releases since July 2025, and every line
   of the changelog is a commit subject I (or an agent) wrote" follows the fix, so it reads as the fix's result;
   the 87 releases span the broken week too. Try "Since #111, every new changelog line is a commit subject I (or an
   agent) wrote; 87 releases since July 2025."
7. **Goal 5 (tone) — the two-dot beat at a paragraph's end.** "That title is all semantic-release reads.." right
   before a code block reads as a typo on a cold read; the tic works best leading into a clause ("reads.. and
   nothing else"). Same for "não.. e" in the PT-BR LinkedIn post, which already does that and reads fine.

## Variables (the `vars:` comment)

hook type: confession · cover style: terminal-diff · images: 3 (cover + wink card + diagram) · LinkedIn format:
link · language: pt-br · day/time: <author> · tags: git, devops, github, productivity

`vars: hook=confession cover=terminal-diff images=3-cover+wink+diagram linkedin=link lang=pt-br day=<author> tags=git,devops,github,productivity`

<!-- reviewed: beba8a55af17e618 -->
