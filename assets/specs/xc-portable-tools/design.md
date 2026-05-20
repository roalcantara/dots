<!-- markdownlint-disable -->
# xc-portable-tools — Design

## 1. OVERVIEW

Move interactive helpers from **Zsh autoload files** to **`config/bin` executables** on
`$PATH` (`XDG_LOCAL_BIN_DIR`). Rationale: use from Makefiles, git hooks, non-Zsh shells, and
subprocesses without `autoload`.

**Related specs (do not contradict):**

| Spec                              | Role                                                              |
| --------------------------------- | ----------------------------------------------------------------- |
| [xc-usage](../xc-usage/design.md) | `##?` help extraction; `#?` not printed by default                |
| [xc-git](../xc-git/design.md)     | Subcommand behavior (this epic **changes layout** to inline file) |

---

## 2. BRAINSTORM — Approaches considered

### 2.1 `xc-git` packaging

| Approach                         | Pros                                                   | Cons                                          | Decision             |
| -------------------------------- | ------------------------------------------------------ | --------------------------------------------- | -------------------- |
| **A. Flat `config/bin/xc-git`**  | Same layout as `xc-fabric` / `xc-puts`; one PATH entry | Large file (~400+ lines)                      | **Chosen** (2026-05) |
| B. Package `xc-git/xc-git`       | Worked during first merge                              | Redundant folder; confuses mental model       | **Superseded** by A  |
| C. Package dir + `*.zsh` modules | Smaller files                                          | `XC_GIT_*` drift; agent struggled with layout | Rejected             |
| D. Bun + shell for fzf           | Typed fixup logic                                      | fzf/gitx still shell; PATH dep on Bun         | Rejected             |

### 2.2 `puts` / `toast`

| Approach                              | Pros                              | Cons                            | Decision   |
| ------------------------------------- | --------------------------------- | ------------------------------- | ---------- |
| **A. Zsh bin + delete autoload**      | Keeps `zparseopts`, gum, spectrum | Requires Zsh on shebang         | **Chosen** |
| B. Keep autoload, thin `xc-puts` exec | Less churn in osx                 | Two entrypoints forever         | Rejected   |
| C. Bash rewrite                       | POSIX                             | Loses `zparseopts` / `print -P` | Rejected   |

### 2.3 Path variable (`XC_GIT_*` → XDG)

User proposed `${XDG_LOCAL_BIN_DIR}/xc-git:-$XDG_CONFIG_HOME/zsh/etc/xc-git/`.

**Correction:** Use standard parameter expansion on **directories**, not `zsh/etc/xc-git`:

```zsh
${XDG_LOCAL_BIN_DIR:-$HOME/.local/bin}/xc-git          # symlink → flat executable
${XDG_CONFIG_HOME:-$HOME/.config}/bin/xc-git           # dev source (flat file)
```

`%x` remains last-resort when running from the repo without symlinks.

---

## 3. `xc-puts` and `xc-toast`

### 3.1 `xc-puts`

**Path:** `config/bin/xc-puts` (executable).

**Headers:**

```text
#? puts 0.1.0
#? License RIT …
#? http://docopt.org …

##? Formats and prints a message
##? Usage: …
```

**Top of script:**

```zsh
command xc-usage guard "${0:a}" "$@"
# zparseopts … (same as legacy puts function body)
```

**Delete:** `config/zsh/etc/functions/puts`.

**Call site migration:** replace `puts` with `command xc-puts` in `osx`, `dots`, etc.

### 3.2 `xc-toast`

**Path:** `config/bin/xc-toast`.

**API:** positional `message`, optional `duration` (default 3), optional `type` (info|success|error|warning).

**Delete:** `config/zsh/etc/functions/toast`.

---

## 4. `xc-git` inline monolith

### 4.1 File layout (target)

All `xc-*` tools are **sibling executables** under `config/bin/` (flat files). `xc` launcher
discovers them the same way as `xc-fabric`.

```tree
config/bin/
  xc                    ← launcher (separate spec; routes to siblings)
  xc-git                ← single file, subcommands inline
  xc-fabric
  xc-puts
  xc-toast
  xc-skills
  xc-usage
```

**Remove (legacy):**

```text
config/bin/xc-git/                   # package directory (entire tree)
config/bin/lib/xc-git/
config/bin/xc-git-branch-preview
config/bin/xc-git-fixup-suggest
config/bin/xc-git-log-fzf
```

### 4.2 `xc-git` path resolution

```zsh
_xc_git_resolve_self() {
  local local_bin="${XDG_LOCAL_BIN_DIR:-$HOME/.local/bin}/xc-git"
  if [[ -f "$local_bin" && -x "$local_bin" ]]; then
    REPLY="${local_bin:a}"
    return 0
  fi
  local config_bin="${XDG_CONFIG_HOME:-$HOME/.config}/bin/xc-git"
  if [[ -f "$config_bin" && -x "$config_bin" ]]; then
    REPLY="${config_bin:a}"
    return 0
  fi
  REPLY="${${(%):-%x}:a}"
}
```

Use `REPLY` as `"${0:a}"` equivalent for `xc-usage guard/print` calls inside the monolith.

**Symlink install:**

```bash
ln -sf "${XDG_CONFIG_HOME}/bin/xc-git" "${XDG_LOCAL_BIN_DIR}/xc-git"
```

### 4.3 Inline structure inside `config/bin/xc-git`

Single file sections (in order):

1. `#?` + `##?` dispatcher help
2. `_xc_git_xc_usage` helper (delegate to `command xc-usage`)
3. `_xc_git_has_gum` / `_xc_git_emit` (from `_common.zsh`)
4. `_xc_git_branch_preview` + `##?` block (or subcommand help via `xc-usage print` with line range — prefer **embedded `##?` only at top** + subcommand `##?` sections marked by convention OR separate validate targets; **simplest:** keep subcommand `##?` in same file, `xc-usage print "${0:a}"` prints entire file's `##?` — for subcommand-specific help use `grep` anchor or split files)

**Subcommand help:** For monolith, use:

```zsh
_xc_git_print_subhelp() {
  local tag="$1"  # e.g. fixup-suggest
  awk -v tag="$tag" '/^##\? xc-git '"$tag"'/ {p=1} p && /^##\?/ {print substr($0,4)} …'
}
```

**Or** duplicate minimal approach from current code: `grep '^##?'` between markers. **Normative for v1:** one `##?` block per subcommand at fixed line regions; implementer copies current per-file `##?` headers into the monolith contiguously; `xc-usage guard` on full path still works for top-level `-h`; subcommand `-h` uses `_xc_git_print_subhelp fixup-suggest` filtering lines starting with `##? xc-git fixup-suggest` through next blank `##?` only line — **simpler v1:** call `command xc-usage print "${REPLY}"` for all help (prints all `##?` in file) OR extract with sed range. **Recommended:** keep separate `##? xc-git fixup-suggest` header blocks; subcommand help:

```zsh
_xc_git_subhelp() {
  local sub="$1"
  grep '^##?' "${REPLY}" | sed 's/^##? \{0,1\}//' | awk -v s="$sub" '
    /^xc-git '"$sub"'/ {on=1}
    on && /^xc-git / && $0 !~ "^xc-git '"$sub"'"' {exit}
    on {print}
  '
}
```

Implementer: match behavior of today's per-module help output.

5. Dispatcher `case` subcommand → call `_xc_git_*` functions
6. Copy bodies from `lib/xc-git/*.zsh` (fixup algorithm unchanged)

### 4.4 Integration points

| Consumer              | Change                                               |
| --------------------- | ---------------------------------------------------- |
| `gitx` `_gitx_fzlog`  | `command xc-git log-fzf`                             |
| `gitx` fzb preview    | `'command xc-git branch-preview {}'`                 |
| `dots` git subcommand | already forwards to `xc-git`                         |
| fixup next-steps text | `xc-git fixup-suggest -q` not `xc-git-fixup-suggest` |

---

## 5. `xc-usage` and `#?` metadata

**Today:** `_xc_usage_emit` reads only `^##?`. Files with `#?` license (dots, gen, puts) are valid.

**Contract:**

| Prefix | Purpose                      | `xc-usage print` | `xc-usage validate` |
| ------ | ---------------------------- | ---------------- | ------------------- |
| `#?`   | Version, license, docopt URL | Ignored          | Ignored (no error)  |
| `##?`  | Docopt help                  | Emitted          | Required            |

**Optional enhancement (Task T1):** `xc-usage print --metadata FILE` prints `#?` lines only. If not implemented, document in `config/bin/README.md` that `#?` is author metadata.

**No change:** reject file with only `#?` and no `##?` (existing behavior).

---

## 6. Testing

| Task              | Spec file                                       | mise task        |
| ----------------- | ----------------------------------------------- | ---------------- |
| xc-usage metadata | extend `xc-usage.spec.ts` if `--metadata` added | `xc-usage:specs` |
| xc-puts           | `tests/xc-puts.spec.ts`                         | `xc-puts:specs`  |
| xc-toast          | `tests/xc-toast.spec.ts`                        | `xc-toast:specs` |
| xc-git            | `tests/xc-git.spec.ts`                          | `xc-git:specs`   |

Remove wrapper line-count tests; add monolith smoke: `xc-git fixup-suggest --dry-run` in repo root.

---

## 7. Documentation

- `config/bin/README.md` — portable tools table, symlinks, delete list
- `config/zsh/README.md` — remove `puts`/`toast` from autoload inventory; point to `xc-*`
- **`README.md` (repo root)** — brief table of every `xc-*` command (Task T8)
- Update `assets/specs/xc-git/design.md` §2 folder structure → **superseded by this doc §4.1** (note in xc-git HANDOFF)

---

## 8. Final acceptance verification

Normative checklist: [requirements.md Req-8 — Final verification table](./requirements.md#final-verification-table).
Executed in [tasks.md Task T7](./tasks.md#task-t7--final-verification-req-8-checklist).

---

## 9. Decision log

### Decision: Delete Zsh function files (not thin wrappers)

**Context:** User asked to remove `puts` and `toast` from `config/zsh/etc/functions`.

**Decision:** Delete files; migrate call sites to `xc-puts` / `xc-toast`.

### Decision: Flat `config/bin/xc-git` (no package directory)

**Context:** User mental model: every `xc-*` tool is one executable next to `xc-fabric` and
planned `xc` launcher. Nested `xc-git/xc-git` was migration residue, not a requirement.

**Decision:** Single flat file `config/bin/xc-git`; delete `config/bin/xc-git/` directory,
wrappers, and `lib/xc-git/`. Symlink `~/.local/bin/xc-git` → that file.

**Supersedes:** earlier decision “package dir + `xc-git/xc-git` executable inside.”

### Decision: Inline xc-git (no lib/, no wrappers)

**Context:** Agent struggled with split layout; user wants one script body.

**Decision:** All subcommands in the flat file; delete wrappers and `lib/xc-git/`.

### Decision: XDG path resolution replaces `XC_GIT_ROOT` / `XC_GIT_LIB`

**Context:** Portable discovery from `~/.local/bin`.

**Decision:** `_xc_git_resolve_self` + `REPLY`; drop `XC_GIT_*` readonly vars.
