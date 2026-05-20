<!-- markdownlint-disable -->
# REQUIREMENTS: xc-portable-tools

## OVERVIEW

Consolidate **PATH-first** executables under `config/bin/` so shell helpers work without
reloading Zsh functions. This epic covers:

1. **`xc-puts`** — migrate from `config/zsh/etc/functions/puts` (then **delete** that file).
2. **`xc-toast`** — migrate from `config/zsh/etc/functions/toast` (then **delete** that file).
3. **`xc-git`** — single **flat** executable `config/bin/xc-git` (same layout as `xc-fabric`,
   `xc-puts`); merge legacy wrappers; remove `lib/xc-git/`, `xc-git-*` scripts, and the old
   **`config/bin/xc-git/` package directory** (no nested `xc-git/xc-git`).
4. **`xc-usage`** — clarify dual header: `#?` metadata + `##?` docopt (see Req-4).

Normative design: [design.md](./design.md). Implementation order: [tasks.md](./tasks.md).

**Out of scope:** Bun-primary rewrite of `xc-git`; auto-generating full docopt from code (see
`assets/specs/xc-usage/design.md` §13).

---

## User Roles

- **Terminal user:** Runs `xc-puts`, `xc-toast`, `xc-git` from any shell with `~/.local/bin` on `PATH`.
- **Script author:** Keeps `#?` license block + `##?` help; uses `xc-usage guard` on bin scripts.
- **Maintainer:** Runs `mise run xc-puts:specs`, `xc-toast:specs`, `xc-git:specs`.

---

### REQUIREMENT 1: `xc-puts` on PATH

**User Story:** As a script author, I want `xc-puts` as a bin executable so shells without autoload can format messages.

**Acceptance Criteria:**

1. WHEN `config/bin/xc-puts` exists THEN it SHALL be executable Zsh with `#?` + `##?` headers per [design.md §3.1](./design.md#31-xc-puts).
2. WHEN `xc-puts -h` runs THEN `xc-usage` SHALL print `##?` help (exit 0).
3. WHEN `xc-puts --green 'ok'` runs with gum on PATH THEN output SHALL match legacy `puts` behavior.
4. WHEN `config/zsh/etc/functions/puts` existed THEN it SHALL be **removed** after call sites use `xc-puts`.
5. Call sites in `config/zsh/etc/functions/osx`, `dots`, and elsewhere SHALL invoke `command xc-puts` (or `xc-puts`).

---

### REQUIREMENT 2: `xc-toast` on PATH

**User Story:** As a user, I want terminal toasts via `xc-toast` without autoloading `toast`.

**Acceptance Criteria:**

1. WHEN `config/bin/xc-toast` exists THEN it SHALL preserve legacy positional API: `message [duration] [type]`.
2. WHEN `xc-toast -h` runs THEN help SHALL come from `##?` via `xc-usage`.
3. WHEN `config/zsh/etc/functions/toast` existed THEN it SHALL be **removed**.
4. Tests SHALL cover help and a non-interactive smoke path where feasible.

---

### REQUIREMENT 3: `xc-git` single inline executable

**User Story:** As a user, I want one `xc-git` binary with all subcommands inlined so deployment is one symlink.

**Acceptance Criteria:**

1. WHEN `xc-git` runs THEN implementation SHALL live in **one file** `config/bin/xc-git` at the
   same level as `xc-fabric` and `xc-puts` (no `source` of `lib/xc-git/*.zsh`, no package subfolder).
2. WHEN subcommands run THEN behavior SHALL match current `branch-preview`, `fixup-suggest`, `log-fzf`.
3. WHEN legacy wrappers existed (`xc-git-branch-preview`, etc.) THEN files SHALL be **deleted**; tests updated to call `xc-git <subcommand>` only.
4. WHEN `config/bin/lib/xc-git/` existed THEN directory SHALL be **removed**.
5. WHEN `config/bin/xc-git/` is a **directory** (legacy package layout) THEN it SHALL be **removed** after moving the script to flat `config/bin/xc-git`.

---

### REQUIREMENT 4: `xc-git` path resolution (XDG)

**User Story:** As a user with only `~/.local/bin` on PATH, I want `xc-git` to find itself without Zsh `%x` hacks in callers.

**Acceptance Criteria:**

1. WHEN resolving script path THEN logic SHALL use [design.md §4.2](./design.md#42-xc-git-path-resolution) order:
   - `${XDG_LOCAL_BIN_DIR:-$HOME/.local/bin}/xc-git` (symlink to flat executable)
   - `${XDG_CONFIG_HOME:-$HOME/.config}/bin/xc-git` (source tree, flat file)
   - `${(%):-%x}:a` fallback when executing from repo directly
2. WHEN `XDG_LOCAL_BIN_DIR` and `XDG_CONFIG_HOME` are unset THEN defaults SHALL match `config/.profile` / `config/zsh/.zshrc`.
3. SHALL NOT use path `zsh/etc/xc-git` (non-existent layout).

---

### REQUIREMENT 5: Dual script headers (`#?` + `##?`)

**User Story:** As an author, I want license/metadata in `#?` and docopt help in `##?` like `dots` and `gen`.

**Acceptance Criteria:**

1. WHEN a bin script has only `#?` lines for license THEN `xc-usage` SHALL still require `##?` for help (unchanged).
2. WHEN `xc-usage print` runs THEN output SHALL include **only** `##?` lines (not `#?`).
3. WHEN `xc-usage validate` runs THEN it SHALL NOT fail merely because `#?` exists.
4. Optional: `xc-usage print --metadata` MAY print `#?` lines (if implemented per design §5); otherwise document that `#?` is human metadata only.
5. New bins (`xc-puts`, `xc-toast`, `xc-git`) SHALL include both blocks where applicable.

---

### REQUIREMENT 6: Tests and mise tasks

**Acceptance Criteria:**

1. `tests/xc-puts.spec.ts`, `tests/xc-toast.spec.ts` SHALL exist with `mise run xc-puts:specs` / `xc-toast:specs`.
2. `tests/xc-git.spec.ts` SHALL be updated: no wrapper parity tests; `XC_GIT` → `config/bin/xc-git`.
3. Legacy `tests/xc-git-fixup-suggest.spec.ts` and `tests/xc-git-log-fzf.spec.ts` SHALL redirect or merge into `xc-git.spec.ts`.

---

### REQUIREMENT 7: Documentation and install

**Acceptance Criteria:**

1. `config/bin/README.md` SHALL document symlinks: `xc-puts`, `xc-toast`, `xc-git`.
2. `config/zsh/README.md` SHALL state `puts` / `toast` moved to `config/bin`; list `xc-puts` / `xc-toast`.
3. `gitx` fzb preview SHALL use `xc-git branch-preview {}` (not wrapper name).

---

### REQUIREMENT 8: Final acceptance verification (epic complete)

**User Story:** As a maintainer closing this epic, I want one checklist table so I can run every check in order and confirm the portable-tools migration is done.

**Acceptance Criteria:**

1. WHEN Task T7 runs THEN every row in the table below SHALL be executed; any failure SHALL block “epic complete”.
2. Rows marked **(epic)** SHALL pass after Tasks T1–T6; rows marked **(repo)** are whole-repo hygiene checks for this migration.
3. Commands assume repo root `dots/` and `config/bin` on PATH or invoked via `zsh config/bin/…`.

#### Final verification table

| #   | Verifies                       | Command                                                                                                                          | Pass when                                                                                                  |
| --- | ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| 1   | Req-1 · `xc-puts` help         | `zsh config/bin/xc-puts -h`                                                                                                      | Exit 0; stdout contains `Usage:` and `xc-puts`                                                             |
| 2   | Req-1 · `xc-puts` behavior     | `command xc-puts --green ok`                                                                                                     | Exit 0; prints styled line (or plain if no gum)                                                            |
| 3   | Req-1 · `puts` removed         | `test ! -f config/zsh/etc/functions/puts`                                                                                        | Exit 0                                                                                                     |
| 4   | Req-1 · no legacy `puts` calls | `rg '\bputs\b' config/zsh --glob '!**/puts' -g '!*.md'`                                                                          | No interactive `puts` calls (only `xc-puts` or comments)                                                   |
| 5   | Req-2 · `xc-toast` help        | `zsh config/bin/xc-toast -h`                                                                                                     | Exit 0; stdout contains `Usage:`                                                                           |
| 6   | Req-2 · `toast` removed        | `test ! -f config/zsh/etc/functions/toast`                                                                                       | Exit 0                                                                                                     |
| 7   | Req-3 · flat `xc-git` file     | `test -f config/bin/xc-git && test -x config/bin/xc-git && test ! -d config/bin/xc-git/`                                         | Exit 0; **file** at bin root, **no** package directory                                                     |
| 8   | Req-3 · wrappers gone          | `test ! -e config/bin/xc-git-branch-preview && test ! -e config/bin/xc-git-fixup-suggest && test ! -e config/bin/xc-git-log-fzf` | Exit 0                                                                                                     |
| 9   | Req-3 · no `lib/xc-git`        | `test ! -d config/bin/lib/xc-git`                                                                                                | Exit 0                                                                                                     |
| 10  | Req-3 · subcommands            | `zsh config/bin/xc-git -h`                                                                                                       | Exit 0; lists `branch-preview`, `fixup-suggest`, `log-fzf`                                                 |
| 11  | Req-3 · fixup help             | `zsh config/bin/xc-git fixup-suggest -h`                                                                                         | Exit 0; scoped help (not empty); mentions `fixup-suggest`                                                  |
| 12  | Req-4 · XDG resolve smoke      | `env -i HOME="$HOME" PATH="/usr/bin:/bin" zsh config/bin/xc-git -h`                                                              | Exit 0 when `XDG_CONFIG_HOME` points at repo config (or document symlink prerequisite)                     |
| 13  | Req-5 · dual header            | `zsh config/bin/xc-usage validate config/bin/xc-puts`                                                                            | Exit 0                                                                                                     |
| 14  | Req-5 · `#?` not in print      | `zsh config/bin/xc-usage print config/bin/xc-puts \| rg -q '^License'`                                                           | No match (license stays in `#?` only)                                                                      |
| 15  | Req-6 · puts tests             | `mise run xc-puts:specs`                                                                                                         | Exit 0                                                                                                     |
| 16  | Req-6 · toast tests            | `mise run xc-toast:specs`                                                                                                        | Exit 0                                                                                                     |
| 17  | Req-6 · git tests              | `mise run xc-git:specs`                                                                                                          | Exit 0                                                                                                     |
| 18  | Req-6 · usage tests            | `mise run xc-usage:specs`                                                                                                        | Exit 0                                                                                                     |
| 19  | (repo) · shellcheck            | `shellcheck config/bin/xc-puts config/bin/xc-toast config/bin/xc-git`                                                            | Exit 0                                                                                                     |
| 20  | (repo) · no `lib/xc-git`       | `rg 'lib/xc-git                                                                                                                  | xc-git-fixup-suggest                                                                                       | xc-git-log-fzf | xc-git-branch-preview' config --glob '!specs/**'` | No live references (specs/docs may mention historically) |
| 21  | (repo) · gitx preview          | `rg "xc-git branch-preview" config/zsh/etc/functions/gitx`                                                                       | At least one match                                                                                         |
| 22  | Req-7 · bin README             | `rg 'xc-puts\|xc-toast\|bin/xc-git' config/bin/README.md`                                                                        | Flat `xc-git` + symlinks documented                                                                        |
| 23  | Req-7 · zsh README             | `rg 'xc-puts\|xc-toast' config/zsh/README.md`                                                                                    | Notes migration from `puts`/`toast`                                                                        |
| 24  | Req-7 · root README            | `rg 'xc-puts\|xc-toast\|xc-git' README.md`                                                                                       | Command overview table present                                                                             |
| 25  | (epic) · PATH symlinks         | `command -v xc-git xc-puts xc-toast xc-usage`                                                                                    | All four resolve after `ln -sf` per [tasks.md T5](./tasks.md#task-t5--install-symlinks--configbinreadmemd) |

**Optional (after xc-usage Task 1b / separate epic):** `xc-fabric -h` vs `xc-fabric run -h` differ; not blocking portable-tools unless those bins were touched in this branch.

---

## Traceability

| Requirement  | Design sections | Task   |
| ------------ | --------------- | ------ |
| Req-1        | §3.1            | T2     |
| Req-2        | §3.2            | T3     |
| Req-4, Req-5 | §4, §5          | T1     |
| Req-3, Req-4 | §4.1–4.3        | T4     |
| Req-6        | §6              | T2–T5  |
| Req-7        | §7              | T6, T8 |
| Req-8        | §8 (this table) | T7     |
