<!-- markdownlint-disable -->
# Reproducible agent skills from a versioned lock — design

## 1. Goal

Stop syncing `~/.agents` (635 skill folders, about 58 MB and 4,000 files) through the encrypted `dots-history`.
Restore skills on a new machine from a lock file kept in the dots repo, and keep the owner's own commands and
skills in the repo as plain files.

**Done when:**

1. `config/agents/skill-lock.json` is the global `skills` CLI lock on this Mac, and `skills add` or
   `skills update` changes it as a git diff.
2. Every installed skill is either in that lock with a confirmed source, linked from `config/agents/`, or listed
   in `config/agents/review.csv`.
3. In a fresh `devcontainer` container, `mise run skills:restore` installs every lock entry with a matching
   hash; a second run installs nothing; the committed lock is unchanged.
4. `[dotfiles]` no longer tracks `~/.agents`.

**Out of scope:** resolving the `review.csv` entries (the owner backs those folders up and decides later), the
`~/.claude/skills` links beyond what `skills add` creates for `lastSelectedAgents`, and skills in projects other
than the global scope.

## 2. Findings (2026-11-03)

| Finding | Evidence |
| --- | --- |
| The real global lock is `$XDG_STATE_HOME/skills/.skill-lock.json` | The CLI's `getSkillLockPath()` uses `XDG_STATE_HOME` when set, else `~/.agents/.skill-lock.json` |
| `~/.agents/.skill-lock.json` is a stale copy | 1 entry, written from a process without `XDG_STATE_HOME` |
| The real lock records 187 skills, all installed | `~/.local/state/skills/.skill-lock.json`, version 3 |
| A format bump empties the lock | `readSkillLock()`: `if (parsed.version < CURRENT_VERSION) return createEmptyLockFile()` |
| 448 installed skills have no lock entry | 635 folders minus 187 |
| `script/skills.csv` guesses a source for 263 of them | `fix:skills` output: the most-installed `skills find` match by name, not proof |
| 185 have neither | Mostly `google-*`, `gke-*`, `cloud-*`, `bigquery-*`, `apple-*`, `apollo-*`, `electrobun-*`, `superset-*`, `nx-*` |
| `skillFolderHash` is the folder's GitHub tree id | The CLI's `getSkillFolderHashFromTree()`; `git write-tree` of the local folder (without `.git` and `node_modules`) reproduces it for 169 of the 187 |
| 18 locked skills were edited here | Their tree ids differ: e.g. `brainstorming` and `writing-plans` carry a local Doctrine Check section |

## 3. Decisions

| Decision | Choice | Why |
| --- | --- | --- |
| Manifest | The CLI's own global lock | It already updates itself on `add` and `update`; a separate manifest drifts, which is how 448 went unrecorded |
| Where the lock lives | The public dots repo, `config/agents/skill-lock.json` | Diffs are reviewable; it holds only public repo names, paths and hashes |
| Own commands and skills | The public dots repo, `config/agents/` | New machines get them with the clone, before any history restore |
| Unconfirmed skills | Listed in `config/agents/review.csv`, not handled now | The owner backs them up and decides later |
| Rejected: `skills experimental_install` | — | Project scope only (`./.agents/skills`), experimental, and its `skills-lock.json` is not updated by global `add` |
| Rejected: a TOML manifest | — | Duplicates the lock and needs a manual edit after every `skills add` |

## 4. Components

### 4.1 `skills:audit`

A mise task, read-only unless given `--apply`.

1. **Self-check.** Compute the git tree id of each locked skill's folder and compare it with `skillFolderHash`.
   If fewer than 90% match, stop: the hashing method is wrong. Locked skills that differ are edited here, and a
   restore would replace them with upstream: they get the status `locked-differs`.
2. **Candidates.** For each installed folder without a lock entry, take its `script/skills.csv` source; failing
   that, any repo already in the lock or the CSV that has a folder of that name. Each repo's tree is fetched once
   with `gh api repos/<owner>/<repo>/git/trees/HEAD?recursive=1`.
3. **Classify** every folder:

   | Status | Meaning | `--apply` |
   | --- | --- | --- |
   | `confirmed` | The upstream folder's tree id equals the local one | `skills add <source> -s <names> -g -y`, so the CLI writes the lock entry |
   | `differs` | Same name upstream, different content | Row in `review.csv` |
   | `unknown` | No candidate | Row in `review.csv` |
   | `custom` | A link into `config/agents/skills/` or a local checkout (`cua-driver`, `recon`) | Skipped |
   | `locked` | In the lock, same tree id | Nothing |
   | `locked-differs` | In the lock, edited here | Row in `review.csv` |

4. Print the counts per status. `review.csv` columns: `name, status, candidate_source, local_hash,
   upstream_hash`.

### 4.2 `skills:restore`

A mise task run by new machines.

- **Guards:** refuse when the lock's `version` is not 3, or when it has fewer entries than the committed lock at
  `HEAD` (another silent wipe).
- **Idempotent:** skip every skill whose folder already exists, edited or not, so a restore never overwrites local
  edits.
- **Install:** one `skills add <sourceUrl> -s <names> -g -y` per source, for the lock's `lastSelectedAgents`.
- **Leaves the committed lock alone:** runs with `XDG_STATE_HOME` set to a temporary folder, so new machines do
  not rewrite `installedAt`/`updatedAt`. The owner's own `skills add` and `update` still write the real lock.
- **Failures:** a failing source warns and the run continues; a summary lists the failures and the task exits
  non-zero.
- **Callers:** `tasks.bootstrap` on the `desktop` and `container` profiles; the `devcontainer` profile skips
  it (about 60 clones), and tests run it by hand.

### 4.3 Layout

```
config/agents/
  skill-lock.json   the global lock; linked from ~/.local/state/skills/.skill-lock.json and ~/.agents/.skill-lock.json
  commands/         the owner's commands; ~/.agents/commands links here
  skills/<name>/    the owner's own skills; each linked into ~/.agents/skills (symlink-each), added with the first one
  review.csv        skills whose source is not confirmed
```

Both lock paths link to one file, so a CLI run without `XDG_STATE_HOME` (GUI apps, cron) writes the same lock.

## 5. Migration (this Mac, in order)

Nothing is untracked before everything it covers has another home.

1. Run `skills:audit --apply`; the owner backs up the folders listed in `review.csv`.
2. Copy `~/.local/state/skills/.skill-lock.json` to `config/agents/skill-lock.json`; add `[dotfiles]` links from
   both lock paths.
3. Scan `~/.agents/commands` for secret-looking content (the repo is public); move it to
   `config/agents/commands` and link it back.
4. Drop the `"~/.agents"` entry from `[dotfiles]` in `config/mise/config.toml` (its checkpoints stay in
   `dots-history`); delete the stale `~/.agents/.skill-lock.json`.
5. Delete `script/skills.csv` and the `fix:skills` task; call `skills:restore` from `tasks.bootstrap`.
6. Note the change in `assets/specs/mise-bootstrap/tasks-native.md` and the README's container playbook.

## 6. Testing

| Check | Expect |
| --- | --- |
| Audit self-check | At least 90% of locked skills match `skillFolderHash` (169 of 187 on 2026-11-03) |
| Restore in a fresh `devcontainer` container, run by hand | Every lock entry installed with a matching tree id |
| Restore again | Nothing installed |
| Guard | A lock with `version: 2`, or fewer entries than `HEAD`, is refused |
| `git status` after a restore | The committed lock is unchanged |
| `mise dot status` on this Mac | No `~/.agents` entry |

## 7. Risks

| Risk | Mitigation |
| --- | --- |
| `skillFolderHash` is not a plain git tree id | The self-check stops the audit before it classifies anything; then compare with the CLI's own hashing code |
| A CLI upgrade bumps the lock version and empties it on the next write | The restore guard refuses; `git checkout config/agents/skill-lock.json` recovers it |
| GitHub rate limits during audit or restore | `gh api` and the CLI both use the gh login (`GH_TOKEN`) |
| A command file holds private content | The scan in §5 step 3; anything private stays out of the repo |
