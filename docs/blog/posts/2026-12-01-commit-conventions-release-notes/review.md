# Review: 2026-12-01-commit-conventions-release-notes · 2026-11-24

**Verdict:** PASS

## Must fix

<!-- Blocking only: safety, anti-goals, a missing or broken RECIPE, a failed blog:check. Empty means none. -->

## Cold read

- **The one point:** If I squash-merge and let semantic-release cut versions, the PR title is the only commit it
  reads; a title without a type means no release and no changelog lines, and the job still goes green.
- **Would I save it, and why:** Yes. I squash-merge every day, and the one-liner that lists what the analyzer will
  skip since the last tag is something I'd paste into my own repo before the next release.
- **Where I got lost:** "it skips the `Merge pull request…` line" in step 4: I didn't know why, or whether the
  pre-release check below still works once I switch to merge commits (it doesn't; see Consider 1).

## Scores

| Check | Score | Note |
| --- | --- | --- |
| Cold read | 2 | One point found at once; would save it for the check command |
| Layout | 1 | Opening (who it hits + demo snippet) → How I ran into it → The fix → "Wouldn't a commit-msg hook have caught it?" → What I (think I) learned → closing in order (dots links, `---`, Corrections, DISCLAIMER, AI line). The alternatives heading doesn't start with "Why not", which is how layout headings are matched |
| The hook | 2 | Real moment, first person ("My commits were fine. My PR titles weren't"), with the 67-of-68 cost; the wink (Obliviate) lives only in the card, none in the prose |
| Lived or proven | 1 | Squash commit titled after the PR → GitHub docs link; feat/fix/changelog contract → semantic-release link; 67 of 68, 5 of 6 runs, 133 commits, 87 releases → `sources:` (nHqc), all re-checked against `gh pr view` and the tags; #96/#102/#111 linked; v26 and Node → releases link and run 45371260199 (26.0.1 on Node 26.13.1, verified). Weak: `perf` → patch and "it skips the `Merge pull request…` line" have no direct link. Each fact once: the wink card repeats the opening console block almost verbatim |
| Information gain | 2 | A green semantic-release run can silently drop every `feat` inside a squash merge, and no commit-msg hook can catch it because GitHub writes that commit, measured on a real repo at 67 of 68 features and fixes |
| RECIPE self-test | 1 | Steps 1–4 are redoable from the section alone, but the pre-release check uses `--first-parent`, so with merge commits (the post's own recommendation) it prints every `Merge pull request #…` line and never looks at the branch commits (ran it on `origin/main`: the first-parent log is all `Merge pull request` and `chore(release)`). The job installs `conventional-changelog-conventionalcommits` while the text says "no preset configured" |
| STEPPS | 9/12 | Social currency 2 · Triggers 2 · Emotion 1 · Public 1 · Practical value 2 · Stories 1. Bars met (raw ≥ 6, Practical value 2, Social currency 2) |
| Voice | 2 | hype words: "unlock" only inside a quoted squash subject (`Implement age-key unlock…`), the evidence itself, not the author's voice · mistake stated: yes ("I let a tool title the pull requests"; the unpinned install as a limit) |
| LinkedIn hook | 2 | Opening 191 characters, lived and standalone; 234 without the URL; `{devto.url}` in the post; the title states the insight. PT-BR as the task requires |
| Images | 2 | phone test passes for all three (`raw/*-phone.png`), cover passes the LinkedIn crop · one point each (cover: the swap; wink: real command and real output, verified; diagram: the hook runs locally, the squash commit is written on GitHub) · series look, alt text on both inline images |
| Goals 1–5 | 9/10 | 1 2 · 2 1 · 3 2 · 4 2 · 5 2 |
| Language | 2 | dev.to in English; the LinkedIn post in PT-BR, translated from the English source kept in the file, code and tool names in English, loanwords kept (commit, squash merge, changelog), 3 English hashtags |
| Safety | ok | No secret, email, client or private repo. `secrets.GH_TOKEN` is the release workflow's secret reference, already public in `.github/workflows/release.yml` and semantic-release's documented name; no value shown. `roalcantara/dots` is PUBLIC (`gh repo view`). Images show only public commit subjects and a run id |
| AI disclosure | ok | Closing line present |
| `blog:check` | ok | No blocks; 1 warning: hype word "unlock" (see Voice) |

## Consider

1. **Fix the pre-release check for merge commits (goal 2).** With `--first-parent`, a merge-commit history lists
   only `Merge pull request #…` and `chore(release)` lines, so the check always prints something and never inspects
   the branch commits. Either give two variants ("squash: `--first-parent`"; "merge commits: `--no-merges` instead
   of `--first-parent`"), or switch to `--no-merges` and say why. As written, "No output, no surprise" is not true
   for the flow the post recommends.
2. **Rename "## Wouldn't a commit-msg hook have caught it?" to "## Why not a commit-msg hook?" (goal 1).** Layout
   headings are matched by how they start; the content can stay as it is.
3. **Make the wink card add something instead of repeating the opening snippet (goal 5, visuals).** The card shows
   the same two commands and outputs as the first console block. Either cut the opening block to one line and let
   the card carry it, or put the three `feat(backup):` subjects from #93 in the card as `{del:}` lines above the
   squash subject, so the card shows what was forgotten (and the "inside: 3" comment becomes visible output).
4. **Reconcile the preset (goal 2).** The job installs `conventional-changelog-conventionalcommits`, yet the text
   says "With no preset configured, semantic-release uses its default rules". Either drop the package from the
   excerpt (and the workflow), or say it is unused; and link `perf` → patch to the commit-analyzer's default release
   rules.
5. **Say why the `Merge pull request…` line is skipped (goal 2).** "It has no type, so the analyzer finds nothing
   to release in it" makes it follow from step 1 instead of standing as an unlinked claim.
6. **Name the tool that titled the PRs, and how you noticed (goal 2, tone).** "A tool wrote them" reads as
   hedging next to the otherwise exact numbers; naming it (and the moment you saw the gap: a missing changelog
   line? a release that didn't come?) makes the confession land and the Stories driver a 2.
7. **One line on the repo setting (goal 1).** GitHub lets you set the squash commit's default message
   (PR title, or commit details) and disable squash merging; mentioning where in the RECIPE closes the loop for
   readers who can't change team habits.

## Variables (the `vars:` comment)

hook type: confession · cover style: terminal (diff before/after, 🪄) · images: 3 (cover, wink card terminal, diagram) · LinkedIn format: link · language: pt-br · day/time: <author> · tags: git,devops,github,productivity

<!-- reviewed: 834ae34b2b8d4b23 -->
