# Release config: GitHub Releases as the changelog — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** dots releases through semantic-release with GitHub Releases as the changelog, pinned tooling, queued runs and
squash merging off, and the decision recorded as ADR 0001.

**Architecture:** semantic-release runs from a pinned, locked install in `.github/release/` (`npm ci`), reads
`.releaserc.yml` (`conventionalcommits` preset; commit-analyzer, release-notes-generator, github), tags and publishes
a GitHub Release, and commits nothing back to `main`. `publish.yml` keeps running on `release: published`, which is
why the job keeps the `GH_TOKEN` personal token. The why lives in `docs/adr/0001-releases.md`; the convention for
ADRs in `docs/adr/README.md`.

**Tech Stack:** GitHub Actions, Node 26, npm lockfile v3, semantic-release 26, actionlint, zizmor, hk, gh.

**Spec:** `docs/superpowers/specs/2026-11-24-release-config-design.md`

## Global Constraints

- Work in the worktree `/Users/roalcantara/.local/share/dots-release-config` (branch `fix/release-config`, from
  `origin/main` at `10d9709`).
- Every git command goes through the SOPS wrapper: `g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }`
  (a plain `git status` in this worktree fails on encrypted files; that's expected). Tools that call git themselves
  (`hk`, `mise run test:specs`) need the same through the environment:
  `export GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=filter.sops.clean GIT_CONFIG_VALUE_0=cat GIT_CONFIG_KEY_1=filter.sops.smudge GIT_CONFIG_VALUE_1=cat`
  (checked on 2026-11-24: `hk check --all` exits 0 with it, fails on `git status` without it).
- Stage named paths only; never `git add -A` or `git add .`.
- Commit subjects: Conventional Commits, capitalised description, ≤ 50 characters, imperative; body wrapped at 72;
  end every commit with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Commit types on this branch: `chore`, `ci`, `build`, `docs` only (they release nothing).
- Never push, never open a pull request; the author reviews first.
- Pinned versions: `semantic-release` `26.0.1`, `conventional-changelog-conventionalcommits` `10.4.1`;
  `actions/checkout` `3d3c42e5aac5ba805825da76410c181273ba90b1` (v7.0.1); `actions/setup-node`
  `949feb2413d6458794dcd2491c4babbbce0c15c1` (v7.1.0); `node-version: '26'`.
- No tests that pin config values (owner's rule): verify behaviour with the commands below, not with new specs.
- ADR format, copied from lida and kbx: file `docs/adr/NNNN-<slug>.md`; first line `# NNNN. <Title>`; then
  `- Status: <proposed|accepted|superseded by NNNN|deprecated>` and `- Date: YYYY-MM-DD`; then `## Context`,
  `## Decision`, `## Consequences`.

## Review Focus

1. **`publish.yml` must still fire on a new release.** A Release created with `GITHUB_TOKEN` starts no workflow; the
   job must keep `GH_TOKEN`. Task 2 checks the token line survives; Task 5 lists the post-merge check.
2. **Plugin and preset resolution in CI.** The preset must load from `.github/release/node_modules` when semantic-release
   runs from the repo root. Task 2's dry run (Step 8) uses the exact CI invocation and checks the preset loads.
3. **No write back to `main`.** After the change nothing pushes a commit; `contents: write` stays (tags and Releases).
   Task 2's dry run must show no `@semantic-release/git` or `@semantic-release/changelog` plugin.
4. **Stale references to `CHANGELOG.md`.** Task 2 and Task 5 grep for it outside history and the blog posts.
5. **The moved skill files.** They leave the main checkout (post branch) for this branch; the main checkout must end
   with a clean status and the global lock must not carry `"fx"`. Task 1 checks both.

---

### Task 1: Move and commit the documentation-and-adrs skill install

The author installed the skill in the main checkout (`/Users/roalcantara/.local/share/dots`, branch
`feat/post-commit-conventions-release-notes`). Its files are uncommitted there and belong on this branch.

**Files:**

- Create: `.agents/skills/documentation-and-adrs/SKILL.md` (moved, unchanged)
- Create: `skills-lock.json` (moved, unchanged)
- Create: `.claude/skills` (symlink → `../.agents/skills`, no trailing slash)
- Modify: `config/agents/skill-lock.json` (the author's diff: the `documentation-and-adrs` entry only)

**Interfaces:** Produces the skill for Task 4 (an agent writing the ADR may load it).

- [ ] **Step 1: Check the global lock diff in the main checkout**

Run: `cd /Users/roalcantara/.local/share/dots && g diff config/agents/skill-lock.json`
Expected: one hunk adding the `"documentation-and-adrs"` object (source `addyosmani/agent-skills`, commit
`e997ac5b9a74eab332d5e9793bb38a38c8cfdd74`); no `"fx"` line. If `"fx"` is there, stop and ask the author.

- [ ] **Step 2: Carry the diff and the files into the worktree**

Save the diff to the scratchpad, `g apply` it in the worktree, copy `SKILL.md` and `skills-lock.json` to the same
paths, and create the link with `ln -s ../.agents/skills .claude/skills` in the worktree.

- [ ] **Step 3: Verify the copy is byte-identical**

Run: `diff -r /Users/roalcantara/.local/share/dots/.agents/skills/documentation-and-adrs .agents/skills/documentation-and-adrs && cmp /Users/roalcantara/.local/share/dots/skills-lock.json skills-lock.json && readlink .claude/skills`
Expected: no diff output; `../.agents/skills`.

- [ ] **Step 4: Remove them from the main checkout**

In `/Users/roalcantara/.local/share/dots`: delete the two untracked files, the `.agents/skills/documentation-and-adrs`
folder and the `.claude/skills` link; `g checkout -- config/agents/skill-lock.json`.
Run: `g status --short` there. Expected: empty.

- [ ] **Step 5: Commit**

```bash
g add .agents/skills/documentation-and-adrs/SKILL.md skills-lock.json .claude/skills config/agents/skill-lock.json
g commit -m "chore(agents): Add the documentation-and-adrs skill"
```

Body: addyosmani/agent-skills at `e997ac5`, global and per project; `.claude/skills` links to `.agents/skills` because
Claude Code reads skills only there (AGENTS.md's `.agents` over `.claude` rule).

---

### Task 2: Release through a pinned install, with GitHub Releases as the changelog

**Files:**

- Create: `.github/release/package.json`, `.github/release/package-lock.json`
- Modify: `.releaserc.yml`, `.github/workflows/release.yml`, `.dockerignore:7`
- Delete: `CHANGELOG.md`

**Interfaces:**

- Produces: the CI invocation `npm ci --ignore-scripts --prefix .github/release` then
  `.github/release/node_modules/.bin/semantic-release` (run from the repo root); Task 4 documents it.

- [ ] **Step 1: Record the baseline findings**

Run: `mise x zizmor@1.32.0 -- zizmor --no-progress --offline .github/workflows/release.yml`
Expected now: `2 high` (`unpinned-uses` ×2) and `1 low` (`adhoc-packages`).

- [ ] **Step 2: Create the locked install**

`.github/release/package.json`: `"name": "dots-release"`, `"private": true`, `"description"` one line, and exact
`dependencies` `semantic-release` `26.0.1` and `conventional-changelog-conventionalcommits` `10.4.1`.
Generate the lock with `npm install --prefix .github/release --package-lock-only --save-exact`.
Run: `git check-ignore -v .github/release/node_modules/x` → matched by `.gitignore`'s `node_modules/`.

- [ ] **Step 3: Rewrite `.releaserc.yml`**

`branches: [main]`; `preset: conventionalcommits`; `plugins`: `@semantic-release/commit-analyzer`,
`@semantic-release/release-notes-generator`, `@semantic-release/github`. Nothing else (no changelog, no git).

- [ ] **Step 4: Rewrite the job in `release.yml`**

- `concurrency.cancel-in-progress: false`.
- Job permissions: `contents`, `issues`, `pull-requests` write; drop `id-token`.
- `actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1` (keep `fetch-depth: 0`,
  `persist-credentials: false`); `actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0` with
  `node-version: '26'`, `cache: npm`, `cache-dependency-path: .github/release/package-lock.json`.
- Install step: `npm ci --ignore-scripts --prefix .github/release`.
- Release step: `.github/release/node_modules/.bin/semantic-release`, env `GITHUB_TOKEN: ${{ secrets.GH_TOKEN }}`
  with this comment, replacing the branch-protection one:
  `# A personal token, not GITHUB_TOKEN: a release created with GITHUB_TOKEN starts no workflow, and publish.yml runs on release: published.`
- Keep the `push: main` and `repository_dispatch` triggers and the semantic-release docs URL at the top.

- [ ] **Step 5: Delete `CHANGELOG.md` and its `.dockerignore` line**

`g rm CHANGELOG.md`; remove line 7 (`CHANGELOG.md`) from `.dockerignore`.

- [ ] **Step 6: Commit** (now: the dry run in Step 8 clones the committed branch; if Steps 7–9 find something, fix forward
      with a second `ci(release):` commit, never amend)

```bash
g add .github/release/package.json .github/release/package-lock.json .releaserc.yml \
  .github/workflows/release.yml .dockerignore CHANGELOG.md
g commit -m "ci(release): Publish to GitHub Releases only"
```

Body: why (duplicated `1.38.1` after run 41812976279's failed tag push; twelve `1.17.0` sections), the pins, the queue,
the preset, the token comment; the ADR link comes with Task 4.

- [ ] **Step 7: Lint the workflow**

Run: `mise x actionlint@1.7.12 -- actionlint .github/workflows/release.yml` → exit 0.
Run: the Step 1 zizmor command → no `high` findings; `adhoc-packages` gone. Report any remaining finding in the
commit body rather than suppressing it.

- [ ] **Step 8: Dry-run the exact CI invocation**

semantic-release looks the release branch up on the remote, and this branch is not pushed, so run it in a throwaway
clone where this branch is `main` (it clones the commit from Step 6):

```bash
tmp=$(mktemp -d) && git clone -q /Users/roalcantara/.local/share/dots-release-config "$tmp/dots"
cd "$tmp/dots" && git checkout -q -B main origin/fix/release-config
npm ci --ignore-scripts --prefix .github/release
GITHUB_TOKEN=$(gh auth token) .github/release/node_modules/.bin/semantic-release \
  --dry-run --no-ci --repository-url https://github.com/roalcantara/dots.git
```

Expected in the output: `Loaded plugin "analyzeCommits" from "@semantic-release/commit-analyzer"`, the same for
`release-notes-generator` and `github`; no line mentioning `@semantic-release/changelog` or `@semantic-release/git`;
no error loading `conventional-changelog-conventionalcommits`; `Analysis of N commits complete: no release` (this
branch has only `chore`/`ci`/`build`/`docs` commits). Never run it without `--dry-run`. If it stops for a reason
outside the config (an up-to-date or permission check), copy the output into the hand-back and don't work around it.
Delete `$tmp` afterwards.

- [ ] **Step 9: Check nothing else points at the changelog**

Run: `g grep -n -i 'changelog' -- ':!docs/blog/posts' ':!docs/superpowers'`
Expected: only the commented example in `config/.markdownlint.yml` and unrelated hits in `config/agents/` and
`config/kodexb/`; nothing in `.github/`, `.releaserc.yml`, `.dockerignore`, `README.md` or `docs/*.md`.

---

### Task 3: Turn off squash merging, and say so in CONTRIBUTING

**Files:**

- Modify: `docs/CONTRIBUTING.md` (new `### Merging pull requests` under section 1, after `### Staging rules`)
- Repo setting: `allow_squash_merge=false` (the author approved this on 2026-11-24)

- [ ] **Step 1: Change the setting**

Run: `gh api -X PATCH repos/roalcantara/dots -F allow_squash_merge=false -q '.allow_squash_merge,.allow_merge_commit,.allow_rebase_merge'`
Expected: `false`, `true`, `true`.

- [ ] **Step 2: Write the section**

Three lines: merge with a merge commit (or rebase); squash merging is off because semantic-release reads only the
squash commit's title and the commits inside were lost (Oct–Nov 2026, 67 of 68 `feat`/`fix`); link
`docs/adr/0001-releases.md`.

- [ ] **Step 3: Lint and commit**

Run: `hk check --all` → exit 0.

```bash
g add docs/CONTRIBUTING.md
g commit -m "docs(contributing): Merge pull requests without squash"
```

---

### Task 4: ADR 0001 and the ADR convention

**Files:**

- Create: `docs/adr/README.md`, `docs/adr/0001-releases.md`
- Modify: `AGENTS.md` (Layout table `docs/` row; Docs list; Useful skills), `docs/DOCKER.md:125-131`

**Interfaces:** Consumes Task 2's invocation and Task 3's setting.

- [ ] **Step 1: Write `docs/adr/README.md`**

Sections: when to write one (a choice expensive to reverse, or one people keep re-asking; the skill
`documentation-and-adrs` lists more); the format from Global Constraints; statuses; changing a decision means a new
ADR that supersedes the old one, whose status becomes `superseded by NNNN` (never edit its decision, never delete
it); an index table `| ADR | Title | Status |` with the 0001 row.

- [ ] **Step 2: Write `docs/adr/0001-releases.md`** (`Status: accepted`, `Date: 2026-11-24`)

Context must state: Conventional Commits since 2025; semantic-release with `@semantic-release/git` committed
`CHANGELOG.md` before tagging; run 41812976279 (2026-11-04) left `6c4ae28` untagged after
`remote: fatal error in commit_refs`, and the next run committed 1.38.1 again (`fe874da`); twelve `1.17.0` sections;
lida's ADR 0001 records the same failure; unpinned installs beside a write token; squash merges lost 67 of 68
`feat`/`fix` commits. Decision: the Task 2 setup and Task 3 setting, and the three approaches from the spec with why
two were rejected. Consequences: Releases page is the changelog (`https://github.com/roalcantara/dots/releases`, all
87 earlier tags already have one); no `chore(release)` commits; upgrading semantic-release is a lockfile change; the
dry-run command from Task 2 Step 8 to preview a release; `publish.yml` needs the personal token.

- [ ] **Step 3: Point the docs at it**

`AGENTS.md`: the `docs/` Layout row mentions ADRs (`docs/adr/`); Docs list gains
``- [`docs/adr/`](docs/adr/README.md) — architecture decisions (ADRs): why things are the way they are.``; Useful
skills gains `documentation-and-adrs` — record a decision as an ADR (format in `docs/adr/README.md`).
`docs/DOCKER.md` section 3: "Automates SemVer versioning and GitHub Releases"; the steps say it installs the locked
tooling from `.github/release/`, publishes the notes as a GitHub Release, commits nothing back, and queues runs; link
the ADR.

- [ ] **Step 4: Lint and commit**

Run: `hk check --all` → exit 0.

```bash
g add docs/adr/README.md docs/adr/0001-releases.md AGENTS.md docs/DOCKER.md
g commit -m "docs(adr): Record the release decision as ADR 0001"
```

---

### Task 5: Gates and hand-back

- [ ] **Step 1: Run the gates**

Run: `hk check --all` → exit 0. Run: `mise run test:specs` → all domains pass (none of them reads `CHANGELOG.md`;
if one fails, stop and report it with its output).

- [ ] **Step 2: Check the branch**

Run: `g log --oneline origin/main..HEAD` → the spec/plan commit plus Tasks 1–4 (five or six commits, types
`chore`/`ci`/`docs` only). Run: `g status --short` → empty.

- [ ] **Step 3: Hand back**

Report to the author: each commit, the dry-run output lines from Task 2 Step 8, the zizmor result, and these checks for
after the merge (not to be run now): the release run on `main` succeeds and pushes no commit; at the next
`feat`/`fix`, a GitHub Release appears and `publish.yml` runs. Do not push.
