# Release config: GitHub Releases as the changelog

Date: 2026-11-24 · Branch: `fix/release-config` · Size: a small change (short design)

## Intent

Make dots' releases follow semantic-release's recommended setup and close the gaps a review found, then record the
decision so the next person (or agent) knows why. The blog post due 2026-12-01 shows this config as its RECIPE, so the
post follows once this merges.

What the review found (evidence in git and the Actions logs):

- **A failed release duplicates the changelog.** `@semantic-release/git` pushes the `CHANGELOG.md` commit before the
  tag; run 41812976279 (2026-11-04) committed `6c4ae28` for 1.38.1, then `git push --tags` failed
  (`remote: fatal error in commit_refs`), and the next run committed 1.38.1 again (`fe874da`). `CHANGELOG.md` holds
  twelve `1.17.0` sections and two `1.38.1` sections.
- **Unpinned tooling next to a write token.** `npm install -g semantic-release …` takes the latest of everything
  (v26 arrived unnoticed on 2026-11-24) in the job that holds `GH_TOKEN`.
- **A second push to `main` can cancel a release halfway** (`cancel-in-progress: true`).
- **Squash merging is still enabled** (`COMMIT_OR_PR_TITLE`), the cause of 67 of 68 `feat`/`fix` commits missing from
  the changelog in Oct–Nov 2026.
- **Smaller:** the `conventionalcommits` preset is installed but unused (Angular rules apply); `actions/checkout@v4` and
  `actions/setup-node@v4` warn about Node 20; `node-version: 'lts/*'` meets v26's Node ≥ 26.13 only by luck;
  `id-token: write` is unused; the comment on `GH_TOKEN` gives the wrong reason (it's needed because `publish.yml`
  runs on `release: published`, which a `GITHUB_TOKEN` release would not trigger).

## Goals

1. **GitHub Releases are the changelog.** Drop `@semantic-release/changelog` and `@semantic-release/git`; nothing is
   committed back to `main`; delete `CHANGELOG.md` (all 87 tags already have a GitHub Release with full notes).
2. **Pinned release tooling:** exact versions (`semantic-release@26.0.1`, `conventional-changelog-conventionalcommits@10.4.1`;
   commit-analyzer, release-notes-generator and github ship with semantic-release).
3. **Releases queue, never cancel:** `cancel-in-progress: false`.
4. **`preset: conventionalcommits`** in `.releaserc.yml` (understands `feat!:`).
5. **Current actions and Node:** `actions/checkout` and `actions/setup-node` at their current majors in `release.yml`;
   `node-version: '26'`.
6. **Least privilege:** drop `id-token: write`; correct the `GH_TOKEN` comment.
7. **Squash merging off** in the repo settings (`allow_squash_merge=false`); merge commits and rebase stay.
8. **Document it:** `docs/adr/README.md` (the convention: when to write one, the format shared with lida and kbx,
   statuses, superseding, an index) and `docs/adr/0001-releases.md`; link `docs/adr/` from AGENTS.md (Layout and Docs);
   update DOCKER.md's release section and CONTRIBUTING.md (merge commits, no squash).
9. **The `documentation-and-adrs` skill**, installed by the author: review and commit it here (see below).

## Non-goals

- The same `@semantic-release/git` pattern in lida (its ADR 0001): a follow-up note on lida, not this branch.
- Bumping actions in the other workflows (`preview.yml`, `publish.yml`, `blog.yml`): listed as a follow-up.
- A PR-title check in CI (squash is off instead).
- Rewriting the 87 existing GitHub Releases.

## Anti-goals

- Losing any release notes.
- Breaking `publish.yml` (it must still run on each new release).
- A release that tags without a GitHub Release, or vice versa.

## Approaches

| Approach | Trade-off | Verdict |
| --- | --- | --- |
| Keep `CHANGELOG.md`, remove the duplicates once | Smallest change; the failure mode stays, and the next GitHub hiccup duplicates again | Rejected |
| **GitHub Releases as the changelog** (semantic-release's recommendation) | Nothing committed to `main`, no `chore(release)` commits; the repo has no `CHANGELOG.md` to browse offline | **Picked by the author** |
| Keep the commit, add a dry-run `plan` job first (lida's ADR 0001) | Catches some failures early; the commit still lands before the tag | Rejected |

ADR tooling: `docs/adr/README.md` as the project's reference plus addyosmani's `documentation-and-adrs` skill (its
"match the existing convention first" rule makes it follow the README). Picked by the author over the README alone or
`adr-drafting`. The installed `create-architectural-decision-record` (awesome-copilot) conflicts with the format;
removing it from the user skills is the author's call, outside this branch.

## The skill install (review before committing)

The author installed `documentation-and-adrs` globally and per project; the files sit uncommitted in the main checkout
(on the post branch) and move to this branch:

- `.agents/skills/documentation-and-adrs/SKILL.md`: identical to the upstream file reviewed on 2026-11-24.
- `skills-lock.json` (new, project) and `config/agents/skill-lock.json` (global): the global diff also adds `"fx"` to
  the installer's agent list; keep it only if the author meant to (ask).
- `.claude/skills` → `../.agents/skills/`: allowed by AGENTS.md (Claude Code reads `.claude/skills`); drop the trailing
  slash to match `.claude/commands`.
- Commit: `chore(agents): Add the documentation-and-adrs skill`.

## Constraints

- AGENTS.md hard rules: the SOPS git wrapper, named paths only, no push or PR unless asked.
- Commit types on this branch: `ci`, `docs`, `chore` release nothing, so the first run after the merge shows the new
  flow without cutting a version; the next `feat`/`fix` cuts the first release without a changelog commit.
- Merge before 2026-12-01, so the post can show the new config.

## Verification

- `npx semantic-release --dry-run --no-ci` locally with the pinned versions (token from `gh auth token`): it loads the
  plugins and the preset and computes the next version without publishing.
- `hk check --all` and `mise run test:specs` green; `grep -ri changelog` finds no stale reference outside history.
- After the merge: the release run on `main` succeeds with no commit pushed; at the next release, `publish.yml` runs.
- `gh api repos/roalcantara/dots -q .allow_squash_merge` prints `false`.

## The post, afterwards (on `feat/post-commit-conventions-release-notes`)

Update the RECIPE to the new `.releaserc.yml` and workflow (pinned install, `cancel-in-progress: false`, no
changelog/git plugins); the changelog link becomes the Releases page; keep the history as lived (67 of 68 commits never
reached `CHANGELOG.md`, which existed then); the "unpinned" limit becomes a fixed mistake. Then `/blog:gate` again.

## Left to the builder

The exact action majors (check the latest releases), whether to pin actions by SHA in `release.yml`, the ADR's wording,
and how DOCKER.md phrases the release steps.
