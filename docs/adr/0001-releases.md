# 0001. GitHub Releases as the changelog

- Status: accepted
- Date: 2026-11-24

## Context

Dots has written Conventional Commits since April 2025 (the first is `chore(bootstrap): Create a dotfiles project`,
2025-04-23), and releases have gone through semantic-release: each run asks `@semantic-release/commit-analyzer` for
the next version and, until this decision, `@semantic-release/git` committed the regenerated `CHANGELOG.md` and pushed
it before the tag.

That order failed, and each failure left a permanent mark:

- Run 41812976279 (2026-11-04) committed `6c4ae28` for 1.38.1, then `git push --tags` failed with
  `remote: fatal error in commit_refs`. The next run read the same commits, decided 1.38.1 again and committed
  `fe874da`, so `CHANGELOG.md` ended with two 1.38.1 sections.
- The same re-run pattern left twelve identical 1.17.0 sections (2025-10-19 to 2025-10-23).
- lida's ADR 0001 records the same failure with the same plugin.

Three more issues compounded it:

- The release job ran `npm install -g semantic-release …`, taking the latest of everything next to a write token
  (`GH_TOKEN`); semantic-release 26 went stable on 2026-11-16 and the next release (2026-11-17) ran it unnoticed.
- `cancel-in-progress: true` let a second push to `main` cancel a release halfway.
- Squash merging was on, so 67 of 68 `feat`/`fix` commits from October to November 2026 never reached the changelog:
  semantic-release reads commits, and a squash keeps only the pull request title.

## Decision

GitHub Releases are the changelog; nothing is committed back to `main`.

- `.releaserc.yml` keeps `@semantic-release/commit-analyzer`, `@semantic-release/release-notes-generator` and
  `@semantic-release/github`, with the `conventionalcommits` preset. `@semantic-release/changelog` and
  `@semantic-release/git` are gone, and `CHANGELOG.md` with them.
- `.github/release/` pins the tooling (`semantic-release` 25.0.9, `conventional-changelog-conventionalcommits` 10.4.1)
  behind a lockfile, installed with `npm ci`. Not 26 yet: semantic-release 26.0.1 depends on beta plugins
  (`commit-analyzer` 14.0.0-beta.5, `release-notes-generator` 15.0.0-beta.4); 25.0.9 has only stable ones.
- `release.yml` never cancels a release in progress (a newer run waits; GitHub keeps one waiting run per group, and
  it releases every commit since the last tag), pins `actions/checkout` and `actions/setup-node` by SHA, runs
  Node 26, and keeps the personal `GH_TOKEN`: a release created with `GITHUB_TOKEN` starts no workflow.
- Squash merging is off; merge commits and rebase stay, so every commit reaches the release notes.

The alternatives lost for these reasons:

- **Keep `CHANGELOG.md` and remove the duplicates once.** The smallest change, but the failure mode stays: the commit
  still lands before the tag, and the next GitHub hiccup duplicates the file again.
- **Keep the commit and run a dry-run `plan` job first (lida's ADR 0001).** It catches some failures early, but the
  commit still lands before the tag, so a failed push still has to be cleaned up by hand.

## Consequences

- The changelog is <https://github.com/roalcantara/dots/releases>. All 87 earlier tags already have a release, so
  nothing is lost; there is no file to browse offline.
- No `chore(release)` commits.
- Upgrading semantic-release is a lockfile change under `.github/release/`, reviewed like any other dependency.
- The tag is still pushed before the release is created, and semantic-release can't make the two atomic
  ([semantic-release/github#1082](https://github.com/semantic-release/github/issues/1082)). A run that fails in
  between leaves a tag with no release, which later runs skip. Immutable releases are on, so the usual recovery
  (delete the tag, run again) is impossible
  ([semantic-release#4147](https://github.com/semantic-release/semantic-release/issues/4147)). Instead, each run
  first creates any missing release with `gh release create <tag> --verify-tag --generate-notes` and a note that it
  was repaired; that release still triggers `publish.yml`. Its notes are GitHub's (merged pull requests), not the
  commit-type sections.
- `failComment` is off: a failed release shows as a red run, not as an issue. Success comments and the released
  label on pull requests and issues stay. On a very large release (hundreds of commits) the success step can time
  out ([semantic-release/github#1017](https://github.com/semantic-release/github/issues/1017)); the release is
  already published by then, so only the run turns red.
- Previewing a release is a local dry run, with Node 24.10 or newer, in a throwaway clone where the branch is `main`:

  ```bash
  tmp=$(mktemp -d) && git clone -q . "$tmp/dots" && cd "$tmp/dots"
  git checkout -q -B main origin/<branch>
  export MISE_TRUSTED_CONFIG_PATHS="$PWD"   # mise refuses an untrusted clone
  npm ci --ignore-scripts --prefix .github/release
  GITHUB_TOKEN=$(gh auth token) .github/release/node_modules/.bin/semantic-release \
    --dry-run --no-ci --repository-url https://github.com/roalcantara/dots.git
  ```

- `publish.yml` keeps the personal token: it runs on `release: published`, which a release created with `GITHUB_TOKEN`
  would not trigger.
