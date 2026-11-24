# Community post

- **Where:** r/git
- **Rules checked on:** <author: read r/git's sidebar rules and recent top posts before posting (self-promotion,
  link posts, flair); the drafting session could not fetch them. The Reddit runway task (7GvK) is still open.>
- **Title:** With squash merges, semantic-release only sees the PR title: 67 of my 68 feat/fix commits never made
  the changelog
- **Flair:** <author: the required flair, if any>

## Body

I release my dotfiles with semantic-release and write every commit as a Conventional Commit. For a week I
squash-merged pull requests whose titles a tool had written ("Enhance backup functionality and update
documentation"). With two or more commits in a PR, GitHub titles the squash commit after the PR, so that title was
the only commit semantic-release analyzed:

```console
$ gh run view 41811286816 --log | grep -o 'There are.*'
There are no relevant changes, so no new version is released.
```

Six squash merges held 133 commits, 68 of them `feat` or `fix`. 67 never reached `CHANGELOG.md`, and every release
job was green.

What I do now:

- Merge with a merge commit, so semantic-release reads every commit on the branch (it skips the merge line).
- When I squash, the PR title is written as a commit: `feat(backup): Back up an allowlist…`.
- Before a release, list what the analyzer will skip since the last tag:

```console
$ git log --no-merges --format=%s \
    "$(git describe --tags --abbrev=0)"..HEAD \
    | grep -vE '^[a-z]+(\(.+\))?!?: '
```

A local commit-msg hook wouldn't have helped: GitHub creates the squash commit on its side. I had one (global, via
hk + cog) and dropped it after it broke commits in every repo when cog wasn't on the PATH.

How do you handle this? A PR-title check in CI, merge commits, or rebase merges?

I wrote this up on dev.to, with the full config: {devto.url}
