<!-- markdownlint-disable -->
# xc-portable-tools — Tasks

**Date:** 2026-05-20
**Status:** Ready for implementation (subagent-driven)
**Requires:** [requirements.md](./requirements.md), [design.md](./design.md)

**Orchestration:** One implementer subagent per task (T1→T8), then spec review, then code quality review. Do not parallelize implementers on the same repo.

**Skills (every task):**

```text
~/.claude/skills/bash-scripting/SKILL.md
~/.claude/skills/bun-development/SKILL.md
~/.claude/skills/test-driven-development/SKILL.md
~/.claude/skills/verification-before-completion/SKILL.md
```

**Out of this epic:** Scoped docopt help (`print --scope`, `preview`) — [xc-usage tasks](../xc-usage/tasks.md) Task 1b + [HANDOFF](../xc-usage/HANDOFF.md) Req-12.

**Task pattern:** Work items (checkboxes) → **ACCEPTANCE CRITERIA** with command, exit code, and observable output.

---

## TASK T1 — Dual-header documentation (`#?` + `##?`)

**Covers:** Req-5

- [ ] Document `#?` (license/metadata) vs `##?` (docopt help) in `config/bin/README.md`; cross-link [xc-usage design §5](../xc-usage/design.md)
- [ ] Verify or implement `xc-usage print --metadata [script]` (emit `#?` only)
- [ ] Verify default `xc-usage print [script]` never emits `#?` lines
- [ ] Verify `xc-usage validate` succeeds when both prefixes exist (fixture: `tests/fixtures/xc-usage/with-metadata.zsh`)
- [ ] Extend `tests/xc-usage.spec.ts` if any dual-header case is missing

### ACCEPTANCE CRITERIA _(Req-5)_

- `zsh config/bin/xc-usage validate config/zsh/etc/functions/dots` → exit **0**
- `zsh config/bin/xc-usage validate tests/fixtures/xc-usage/with-metadata.zsh` → exit **0**
- `zsh config/bin/xc-usage print --metadata config/bin/xc-puts` → exit **0**; stdout matches `#?` (e.g. contains `docopt.org`); stdout has **no** `##? Usage:` line
- `zsh config/bin/xc-usage print --no-help-footer config/bin/xc-puts` → exit **0**; stdout contains `Usage:`; stdout has **no** `License RIT` (or other `#?`-only license line)
- `mise run xc-usage:specs` → exit **0**

---

## TASK T2 — Migrate `puts` to `xc-puts`

**Covers:** Req-1, Req-6

- [ ] Ensure `config/bin/xc-puts` exists (Zsh shebang, `#?` + `##?`, `command xc-usage guard "${0:a}" "$@"`, legacy `puts` body)
- [ ] **Delete** `config/zsh/etc/functions/puts` if it still exists
- [ ] Replace interactive `puts` calls with `command xc-puts` under `config/` (e.g. `osx`, `dots`)
- [ ] Add or verify `xc-puts:specs` in `config/bin/mise.toml` → `bun test tests/xc-puts.spec.ts`
- [ ] Note migration in `config/zsh/README.md`

### ACCEPTANCE CRITERIA _(Req-1, Req-6)_

- `zsh config/bin/xc-puts -h` → exit **0**; stdout includes `xc-puts` and `Usage:`
- `command xc-puts --green test` → exit **0**; message `test` appears in green when gum/terminal supports it (plain text acceptable without gum)
- `test ! -f config/zsh/etc/functions/puts` → exit **0**
- `mise run xc-puts:specs` → exit **0**
- `rg '\bputs\b' config/zsh --glob '!**/xc-puts' -g '!*.md'` → no live `puts` invocations (comments OK; interpret manually for Req-8 row 4)

---

## TASK T3 — Migrate `toast` to `xc-toast`

**Covers:** Req-2, Req-6

- [ ] Ensure `config/bin/xc-toast` exists from legacy `toast` logic + full `##?` (Usage, Arguments, Options, Examples)
- [ ] Top of script: `command xc-usage guard "${0:a}" "$@"`
- [ ] **Delete** `config/zsh/etc/functions/toast` if it still exists
- [ ] Add or verify `tests/xc-toast.spec.ts` and `xc-toast:specs` in `mise.toml`
- [ ] Note migration in `config/zsh/README.md`

### ACCEPTANCE CRITERIA _(Req-2, Req-6)_

- `zsh config/bin/xc-toast -h` → exit **0**; stdout includes `xc-toast` and `Usage:`
- `zsh config/bin/xc-toast "hello"` → exit **0** (smoke; platform may require terminal notifier — test may skip on CI)
- `test ! -f config/zsh/etc/functions/toast` → exit **0**
- `mise run xc-toast:specs` → exit **0**

---

## TASK T4 — Flat `xc-git` + delete legacy layout

**Covers:** Req-3, Req-4

- [ ] **Layout:** one file `config/bin/xc-git` (sibling of `xc-fabric`);
- [ ] Inline merged logic from legacy `lib/xc-git/` and wrappers (behavior unchanged)
- [ ] `_xc_git_resolve_self` per [design.md §4.2](./design.md#42-xc-git-path-resolution) — flat paths only; drop `XC_GIT_ROOT` / `XC_GIT_LIB`
- [ ] `##?` dispatcher + subcommand blocks in same file (`### Subcommand help blocks` marker)
- [ ] **Delete:** `config/bin/lib/xc-git/`, `xc-git-branch-preview`, `xc-git-fixup-suggest`, `xc-git-log-fzf`
- [ ] Update `tests/xc-git.spec.ts`: `XC_GIT` = `config/bin/xc-git`; remove wrapper parity tests
- [ ] `gitx` fzf preview uses `xc-git branch-preview {}` (not wrapper name)
- [ ] Scoped `-h` via `xc-usage --scope` — follow-up in [xc-usage HANDOFF](../xc-usage/HANDOFF.md); until then `_xc_git_subhelp` or equivalent is acceptable

### ACCEPTANCE CRITERIA _(Req-3, Req-4)_

- `test ! -d config/bin/lib/xc-git` → exit **0**
- `test ! -e config/bin/xc-git-branch-preview && test ! -e config/bin/xc-git-fixup-suggest && test ! -e config/bin/xc-git-log-fzf` → exit **0**
- `shellcheck config/bin/xc-git` → exit **0**
- `zsh config/bin/xc-git -h` → exit **0**; stdout lists `branch-preview`, `fixup-suggest`, `log-fzf`
- `zsh config/bin/xc-git fixup-suggest -h` → exit **0**; stdout mentions `fixup-suggest`
- `zsh config/bin/xc-git branch-preview -h` → exit **0**; stdout mentions `branch-preview`
- `mise run xc-git:specs` → exit **0**
- `rg 'xc-git branch-preview' config/zsh/etc/functions/gitx` → at least one match

---

## TASK T5 — Symlinks and `config/bin/README.md`

**Covers:** Req-7

- [ ] Document install symlinks (flat `xc-git`):

  ```bash
  ln -sf "$HOME/.config/bin/xc-git" "${XDG_LOCAL_BIN_DIR:-$HOME/.local/bin}/xc-git"
  ln -sf "$HOME/.config/bin/xc-puts" "${XDG_LOCAL_BIN_DIR:-$HOME/.local/bin}/xc-puts"
  ln -sf "$HOME/.config/bin/xc-toast" "${XDG_LOCAL_BIN_DIR:-$HOME/.local/bin}/xc-toast"
  ln -sf "$HOME/.config/bin/xc-usage" "${XDG_LOCAL_BIN_DIR:-$HOME/.local/bin}/xc-usage"
  ```

- [ ] README: portable tools table, flat layout note, list of deleted paths (`puts`, `toast`, wrappers, `lib/xc-git`, `xc-git/` dir)

### ACCEPTANCE CRITERIA _(Req-7)_

- `rg 'ln -sf.*xc-git' config/bin/README.md` → match targets **file** `xc-git` (not `xc-git/xc-git`)
- `rg 'xc-puts|xc-toast|xc-git' config/bin/README.md` → portable tools documented
- After manual `ln -sf` in dev shell: `command -v xc-git xc-puts xc-toast xc-usage` → all four resolve

---

## TASK T6 — Spec cross-links

**Covers:** Req-7

- [ ] Add superseded note at top of `assets/specs/xc-git/HANDOFF.md` → this epic + flat `config/bin/xc-git`
- [ ] Update `assets/specs/xc-usage/tasks.md` §10.3 inventory note: `puts` / `toast` migrated to bin (T2/T3)

### ACCEPTANCE CRITERIA _(Req-7)_

- `rg 'xc-portable-tools' assets/specs/xc-git/HANDOFF.md` → superseded pointer present
- `config/zsh/README.md` mentions `xc-puts` and `xc-toast` (not autoload `puts`/`toast`)

---

## TASK T7 — Final verification (Req-8)

**Covers:** Req-8

Run from repository root. Tick every row in [requirements.md — Final verification table](./requirements.md#final-verification-table) (rows 1–25). Epic is **not** done until all pass.

- [ ] Rows **1–4** — `xc-puts`
- [ ] Rows **5–6** — `xc-toast`
- [ ] Rows **7–12** — flat `xc-git`, no legacy paths
- [ ] Rows **13–14** — `xc-usage` validate / print separation
- [ ] Rows **15–18** — all `mise run *:specs`
- [ ] Rows **19–21** — shellcheck, `rg` hygiene, `gitx` preview
- [ ] Rows **22–23** — `config/bin/README.md`, `config/zsh/README.md`
- [ ] Row **24** — root `README.md` (T8)
- [ ] Row **25** — PATH symlinks

### ACCEPTANCE CRITERIA _(Req-8)_

- Markdown report: each row **1–25** → `PASS` or `FAIL` + one-line note
- **Epic PASS** only if zero `FAIL` rows
- Optional automation (human still judges rows 4, 20, 21):

  ```bash
  set -euo pipefail
  cd "$(git rev-parse --show-toplevel)"

  zsh config/bin/xc-puts -h | head -1
  command xc-puts --green ok >/dev/null
  test ! -f config/zsh/etc/functions/puts
  zsh config/bin/xc-toast -h | head -1
  test ! -f config/zsh/etc/functions/toast
  zsh config/bin/xc-git -h | rg -q branch-preview
  zsh config/bin/xc-usage validate config/bin/xc-puts
  zsh config/bin/xc-usage print config/bin/xc-puts | rg -qv 'License RIT' || true
  mise run xc-puts:specs xc-toast:specs xc-git:specs xc-usage:specs
  shellcheck config/bin/xc-puts config/bin/xc-toast config/bin/xc-git
  echo "Automation OK — confirm Req-8 rows 4, 20, 21, 24, 25 manually"
  ```

---

## TASK T8 — Root `README.md` command table

**Covers:** Req-7, Req-8 row 24

- [ ] Under **USAGE → Terminal helpers**, add table of all `xc-*` tools (one-line purpose each)
- [ ] Second small table or list for `xc-git` subcommands
- [ ] Link [config/bin/README.md](../../README.md); point to `xc-<tool> -h` for full docopt help
- [ ] Use table content below (adjust if tools change)

### ACCEPTANCE CRITERIA _(Req-7, Req-8 row 24)_

- `rg 'xc-puts|xc-toast|xc-git' README.md` → all three appear in Terminal helpers section
- `rg 'xc-fabric|xc-skills|xc-usage' README.md` → launcher/tools table present
- Root README does **not** duplicate full `##?` blocks (only summaries + examples)

### Suggested table content

| Command     | Purpose                                                                      |
| ----------- | ---------------------------------------------------------------------------- |
| `xc-usage`  | Print `##?` docopt help; `guard` / `validate` for bin scripts                |
| `xc-puts`   | Colored / prefixed terminal messages (replaces Zsh `puts`)                   |
| `xc-toast`  | Short-lived terminal toasts (replaces Zsh `toast`)                           |
| `xc-git`    | Git helpers: `branch-preview`, `fixup-suggest`, `log-fzf`                    |
| `xc-fabric` | Interactive Fabric pattern runner (fzf/gum)                                  |
| `xc-skills` | Sync/collect skill symlinks across agent directories                         |
| `xc`        | Interactive launcher for other `xc-*` tools ([xc-launcher](../xc-launcher/)) |

---

## DEFINITION OF DONE

- Flat **`config/bin/xc-git`** on PATH via symlink (no `xc-git/` package directory)
- **`xc-puts`**, **`xc-toast`** on PATH; autoload **`puts`** / **`toast`** removed
- Legacy **xc-git** wrappers and **`lib/xc-git/`** removed
- **`#?` + `##?`** documented; **`mise run xc-usage:specs`** green
- **[Req-8](./requirements.md#requirement-8-final-acceptance-verification-epic-complete)** — all 25 verification rows **PASS** (T7)
- Root **[README.md](../../../README.md)** command overview (T8)
- Ready for conventional commit(s) per task area when user asks
