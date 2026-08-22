<!-- markdownlint-disable-file -->
# Design: Harden hk hooks — correct commit-msg validation and working linters

**Date:** 2026-08-22
**Status:** Proposed
**Scope:** `assets/specs/hk-hardening/`
**Supersedes parts of:** [`update-hooks/design.md`](../update-hooks/design.md) (commit `7ff584ea`)

---

## Background

Commit `7ff584ea` migrated git hooks from pre-commit + gitlint to [hk](https://hk.jdx.dev).
The migration landed, but the result does not work: commits require `--no-verify`,
and Conventional Commits rules are not applied to the project's history.

This design fixes the root causes and defines a configuration that is reusable
across other repositories.

## Diagnosis

Every finding below was reproduced, not inferred.

### D1 — The commit-msg rule rejects this repo's own dominant commit style

`hk.pkl:45` allows type `ref` but not `refactor`:

```
$ git commit -m "refactor(nvim): something here"
❌ Commit message does not follow Conventional Commits
```

History contains 13 `refactor(...)` commits, and the last 10 commits on this
branch are all `refactor(...)`. Every one was created with `--no-verify`.
This is the direct cause of "rules are not applied at all": the rule ran,
rejected valid-looking work, and was routed around.

### D2 — `shfmt` panics on `.zsh` files

```
$ shfmt -d config/zsh/opt/aliases/git.zsh
panic: LangAuto is not supported by the parser at this time
```

shfmt has no zsh parser; `.zsh` resolves to `LangAuto` and the binary aborts.
The step glob is `List("*.sh", "*.bash", "*.zsh")` and 26 tracked files match.
This is the direct cause of needing `--no-verify` for all commits.

**hk's own `Builtins.shfmt` has the same defect** — its glob is
`List("**/*.sh", "**/*.bash", "**/*.mksh", "**/*.bats", "**/*.zsh")`.
Adopting the builtin would not fix this.

`shellcheck` shares the problem for a different reason: it has no zsh support and
reports hard errors on zsh-only syntax (`SC2296`, `SC1058`, `SC1056`) in
`config/zsh/opt/plugins/*.zsh`.

### D3 — `hk.pkl` is not valid Pkl

```
$ pkl eval hk.pkl
–– Pkl Error ––  Unexpected token `[`. Expected `)`.
45 | pattern='^(feat|fix|...)(\([a-zA-Z0-9/_-]+\))?!?: .{1,}'
```

Inside a Pkl `"""…"""` string, `\(` opens **string interpolation**. hk's embedded
parser is lenient and accepts it, so `hk validate` passes and the script runs —
but the `pkl` CLI and `pkl-lsp` both reject the file. That is the LSP complaint,
and it is a latent break: any future hk release that tightens its parser breaks
the config.

Fix: raw string delimiters `#"""…"""#`, which disable escapes and interpolation.
Verified:

```
$ pkl eval p2.pkl
a = "pattern='^(feat)(\\([a-z]+\\))?!?: .{1,}'"
```

### D4 — `hk install` writes hooks that a second git on the machine silently ignores

`hk install` on Git 2.54+ writes **config-based hooks** (`hook.<name>.command`)
rather than `.git/hooks/` shims. Two git binaries are present here:

```
/usr/bin/git           git version 2.50.1 (Apple Git-155)   ← below 2.54
/opt/homebrew/bin/git  git version 2.55.0
```

Git 2.50.1 does not know the `hook.<name>.command` key. It does not warn —
it ignores it and commits proceed unvalidated. Reproduced with a controlled
PATH sweep against an identical repo:

| git used | Result for `bad message` |
| --- | --- |
| 2.55.0 (homebrew) | blocked |
| 2.50.1 (`/usr/bin/git`) | **accepted — hook never ran** |

`config/vscode/settings.json` sets no `git.path`, so any tool resolving git
from a default PATH gets Apple's 2.50.1 and silently loses every hook.

The current `.git/hooks/commit-msg` has a second, independent defect —
`exec hk run commit-msg` with hk installed only via mise fails outright
(`exec: hk: not found`) in any shell where mise is not activated.

**Both are fixed by one command:** `hk install --mise --legacy`, which writes

```sh
#!/bin/sh
test "${HK:-1}" = "0" || exec mise x -- hk run commit-msg --from-hook "$@"
```

Script shims run on every git version, `mise x` resolves hk without mise
activation, and the `HK=0` bypass is built in. Verified end-to-end under
Apple git 2.50.1 with hk absent from PATH: invalid messages blocked, valid
accepted, `HK=0` bypasses.

### D5 — Version drift changes behaviour

`hk.pkl` amends `v1.45.0`; mise has `1.54.0` installed; `latest` is `1.56.0`.
This is not cosmetic — `hk util check-conventional-commit` **rejects** `fixup!`
commits on 1.54.0 and **skips** them on 1.56.0.

### D6 — Both candidate engines block merges and reverts

`hk util check-conventional-commit` (1.56.0), 18 message shapes tested:

| Message | Result |
| --- | --- |
| `refactor(nvim): thing` | pass |
| `feat(a)!: breaking`, `chore(deps/npm): ok` | pass |
| `fixup! feat(x): ok` | pass on 1.56.0, **fail on 1.54.0** |
| `Merge branch 'side'` | **fail** |
| `Revert "feat(x): ok"` | **fail** |
| 100-char subject | pass — no length rule exists |

Confirmed end-to-end: `git merge --no-ff` aborts with
`Not committing merge; use 'git commit' to complete the merge.`

### D7 — The guides and the enforced tooling never agreed

[`GIT_COMMITS_GUIDE.md`](../../guides/GIT_COMMITS_GUIDE.md) requires subject ≤ 50
chars, capitalized, imperative. The deleted `.gitlint` enforced
`title-max-length = 80` and explicitly set `ignore=title-trailing-punctuation, T3, CC1`.
Reality followed the tooling:

| Guide rule | Last 300 commits |
| --- | --- |
| Subject ≤ 50 | 150 violate (median 50, p90 69, max 92) |
| Subject capitalized | 20 of last 20 are lowercase |

**Decision: the guides win.** The tooling is brought up to the documented
standard rather than the documentation being lowered to the tooling.

### D8 — Pre-existing repo-wide lint failures

`markdownlint` on generated `graphify-out/`; `taplo` on `config/tombi/config.toml`
(a multi-line inline table, legal only under its declared `toml-version = "v1.1.0"`,
which taplo does not implement); `yamllint` document-start on ~6 files; `hadolint`
`DL3064`/`DL3003`/`DL3025` on 4 Dockerfiles.
### D9 — `config/hk/hkrc.pkl` is invalid and was never installed

```
$ pkl eval config/hk/hkrc.pkl
–– Pkl Error ––  Cannot find property `settings` in module `hk.Config`.
3 | settings {
```

`settings {}` is not a property of `hk.Config`; `jobs` is top-level. Separately,
`config/hk/README.md` documents a symlink to `~/.config/hk/config.pkl`, but that
path does not exist on this machine. The distributed defaults have never been
active.

### D10 — Inline shell in `hk.pkl` is rendered through Tera

hk renders every step command through the Tera template engine before running it.
Shell's `${#var}` collides with Tera's `{#` comment opener:

```
error: Closing comment tag `#}` not found
 --> __tera_one_off:7:4
  | [ ${#subject} -gt 50 ] && { ... }
```

Any inline shell must be wrapped in `{% raw %}` / `{% endraw %}`, with hk's own
template variables placed outside the raw block. This is not documented and is
the main hazard of the inline approach.


---

## Options evaluated

Recorded so this configuration can be re-derived, and reused, without repeating
the investigation. Every verdict below was tested, not reasoned about.

### Where the configuration lives — global and per-repo

Both modes are supported, and they compose. hk **merges** the global config into
every project's `hk.pkl`; it does not replace it. Verified: with a global config
defining steps `global-a` and `global-b`, a repo whose `hk.pkl` adds `repo-c`
ran **all three**.

| Option | Verdict | Reasoning |
| --- | --- | --- |
| **Global `~/.config/hk/config.pkl`** | **Chosen as the default carrier** | Merged into every project. Verified: a repo whose `hk.pkl` contains zero mentions of `commit-msg` still had the rules enforced, and `hk install` created a `commit-msg` shim because it knew the hook existed. Zero per-repo files. |
| **Per-repo `hk.pkl` overrides** | **Also supported** | Three verified customization mechanisms — see the matrix below. Needed for repos with different conventions, and for repos shared with people who do not run these dotfiles. |
| Per-repo `hk.pkl` alone (self-contained) | **Supported fallback** | Everything the global config holds can be pasted into a repo's own `hk.pkl`. Required for repos whose contributors must get identical enforcement without installing `dots`. |
| Shared pkl module + `import` | Rejected as primary | Verified working — both `pkl eval` and hk's pklr resolve an absolute-path import, and per-repo `tests {}` layer onto the imported step. But it still needs an import line in every repo, which the global config does not. |
| Committed `.hk-hooks/` wrappers | **Rejected** | `hk install --mise --legacy` generates a byte-for-byte equivalent wrapper. Tracked copies are pure duplication. |
| Standalone `script/commit-style.sh` | **Rejected** | An extra file per repo for something the config expresses inline. |

### Hook installation

| Option | Verdict | Reasoning |
| --- | --- | --- |
| **`hk install --mise --legacy`** | **Chosen** | `--legacy` writes `.git/hooks/` shims, which every git version executes; `--mise` wraps in `mise x` so hk resolves without mise activation. Generated shim: `test "${HK:-1}" = "0" \|\| exec mise x -- hk run commit-msg --from-hook "$@"`. Verified under Apple git 2.50.1 with hk absent from PATH. |
| `hk install --global` (documented recommendation) | **Rejected** | hk's docs call this the recommended path, and it is elegant — one entry in `~/.gitconfig`, every repo covered. But it writes config-based hooks, which Apple's git 2.50.1 silently ignores (D4). Recommending it here would reintroduce the exact failure being fixed. |
| `hk install --mise` without `--legacy` | **Rejected** | Same silent no-op under git < 2.54. |
| Hand-written `.hk-hooks/` + `core.hooksPath` | Rejected | Works, but duplicates what `--legacy` generates. |

### Commit-message engine

| Option | Verdict | Reasoning |
| --- | --- | --- |
| **`cog verify` + shared `cog.toml`** | **Chosen** | Real parser. `ref = {...}` adds and `refactor = {}` disables (verified), giving exactly the guides' type set. `ignore_merge_commits` / `ignore_fixup_commits` close D6 declaratively. `cog --config <path>` is a **global** flag, so one shared `cog.toml` serves every repo — verified from a repo with no `cog.toml` of its own. |
| `hk util check-conventional-commit` | Rejected | `--allowed-types` can express the exact set, but it blocks `Merge` and `Revert` with no opt-out, and its fixup handling changed between 1.54.0 and 1.56.0 (D5). |
| Custom Pkl regex (status quo) | Rejected | A hand-maintained regex reimplementing a specification, in a Pkl string where `\(` already caused D3. |
| `commitlint` | Rejected | Node runtime plus a config package, in a repo with no other JS requirement. |
| `cog` changelog templates / filters | Not applicable | `simple`/`remote`/`fullhash` macros and the `unscoped`, `group_by_type`, `upper_first` filters apply only to `cog changelog` and cannot express a validation rule. Noted because our `changelog_title` feeds them if `cog changelog` is adopted later. |

### Style rules cog does not cover

| Option | Verdict | Reasoning |
| --- | --- | --- |
| **Inline step in the global pkl config** | **Chosen** | No file to distribute, no import line, and it lives beside the cog step it complements. Requires the Tera `{% raw %}` wrapping from D10. |
| Standalone shell script | Rejected | An extra artifact per repo for ~20 lines of shell. |
| Pkl-generated shell from structured rules | Rejected | Pkl can build the command string from a rule mapping, but the generated shell is harder to read and debug than the shell itself, for no behavioural gain. YAGNI. |
| `Builtins.harper_commit_message` | Rejected | Prose/grammar checker, not a format validator. Possible future addition. |

### `.zsh` handling

| Option | Verdict | Reasoning |
| --- | --- | --- |
| **Drop `.zsh` from shfmt/shellcheck; add `zsh -n`** | **Chosen** | The only tool that parses zsh. Native, no new dependency, returns 0 on every zsh file in the repo today. |
| `Builtins.shfmt` / `Builtins.shellcheck` | Rejected | `Builtins.shfmt`'s glob includes `**/*.zsh`, reproducing D2 exactly. |
| `.editorconfig` `ignore = true` + `--apply-ignore` | Rejected | The panic occurs inside shfmt's `propsOptions` while *reading* editorconfig properties, before any ignore decision — the stack trace confirms it. |
| `shfmt -ln bash` for `.zsh` | Rejected | Silences the panic by lying about the language; would reformat zsh syntax incorrectly. |

### Testing

| Option | Verdict | Reasoning |
| --- | --- | --- |
| **hk-native `tests {}` + `hk test`** | **Chosen** | Tests live next to the step they verify, with `write` for inline fixtures and `expect.code` / `expect.stderr`. Verified: 4 tests, ~10ms each. No test file, no bats dependency, and it travels with the config. |
| bats suite | Kept only for e2e | `hk test` does not provide `commit_msg_file` (available vars are `color, files, files_list, root, tmp`) and cannot drive real `git merge` / `git revert` / `git rebase --autosquash`. Those need a real repo, so a small bats suite remains for end-to-end coverage only. |

### Pre-existing lint failures

| Option | Verdict | Reasoning |
| --- | --- | --- |
| **Fix the offending files** | **Chosen** | Keeps yamllint and hadolint at full strictness; no suppressions to explain later. |
| Add suppression configs | Rejected | Silences warnings that are mostly legitimate. |
| Leave them | Rejected | `hk check --all` never goes green. |

---

## Decisions

| # | Decision | Rationale |
| --- | --- | --- |
| 1 | Commit rules ship in the **global** `~/.config/hk/config.pkl` by default, with per-repo `hk.pkl` override/disable/self-contained modes all supported | hk merges global into every project (verified); repos override per-property by redeclaring a step name |
| 2 | Hooks installed with `hk install --mise --legacy` | Only variant that survives Apple git 2.50.1 and an unactivated mise (D4) |
| 3 | `cog verify` with repo-first `cog.toml` resolution, falling back to the shared one | Real parser; exact guide type set; declarative merge/fixup exemptions; per-repo override without losing the baseline |
| 4 | Type set = the guides' set (`ref`, no `refactor`) | `ref` is shorter, leaving more of the 50-char budget for the subject |
| 5 | Style rules inline in the same global config, wrapped in `{% raw %}` | No extra artifact; D10 makes the wrapping mandatory |
| 6 | Body wrap exempts the git trailer block | `git interpret-trailers --parse` identifies it authoritatively |
| 7 | `zsh -n` replaces shfmt/shellcheck for `.zsh` | The only tool that parses zsh |
| 8 | Step behaviour tested with `hk test`; git integration with bats | Each tool used where it actually works |
| 9 | `config/hk/hkrc.pkl` rewritten and actually symlinked | It is currently invalid and inert (D9) |
| 10 | Scope is pre-commit + commit-msg | pre-push and CI are a follow-up |

---

## Architecture

Two layers, split along the axis that actually varies between repositories.
The upper layer is optional: a repo can supply everything itself.

```
 ~/.config/hk/config.pkl      ← distributed by dots; MERGED into every repo
 ~/.config/cog/cog.toml          commit-msg: cog verify + commit-style
        │                        (+ their hk-native tests)
        │  merge (per-property)
        ▼
 <repo>/hk.pkl                ← per-repo: linters, plus any override,
 <repo>/cog.toml (optional)      addition, or disable of the inherited steps
        ▼
 .git/hooks/{pre-commit,commit-msg}   ← generated by `hk install --mise --legacy`
   test "${HK:-1}" = "0" || exec mise x -- hk run <hook> --from-hook "$@"
```

| Layer | Varies per repo? | Contents |
| --- | --- | --- |
| Global hk config | No (overridable) | Commit-message policy — identical everywhere by default |
| Global `cog.toml` | No (overridable) | Allowed commit types |
| Repo `hk.pkl` | Yes | Linters for that repo's languages; optional commit-rule overrides |
| Repo `cog.toml` | Optional | Repo-specific commit types |
| Git hooks | No | Generated; never hand-edited, never committed |

In global mode a new repository needs **no commit-validation configuration at
all** — only `hk install --mise --legacy` and whatever linters it wants. In
self-contained mode it carries the same step definitions in its own `hk.pkl`.

### Per-repo customization

A repo customizes the inherited rules from its own `hk.pkl`. All four behaviours
were verified against a live global config.

| Intent | How | Verified result |
| --- | --- | --- |
| **Add** a repo-specific rule | Declare a new step under `["commit-msg"]` | Runs alongside the global steps |
| **Override** a global rule | Redeclare the step **by the same name** and set the properties to change | Repo's `check` wins; the global one does not also run |
| **Disable** a global rule | Redeclare by name with `step_condition = "false"` | Step does not run |
| **Disable conditionally** | Redeclare by name with `profiles = List("some-profile")` | Skipped unless that profile is enabled |

The merge is **per-property**, not per-step: a repo entry that sets only
`step_condition` inherits `check` from the global definition. That is what makes
override and disable one-liners.

```pkl
// <repo>/hk.pkl — relax the subject limit for one repo
hooks {
  ["commit-msg"] {
    steps {
      ["commit-style"] { step_condition = "false" }   // or override `check`
    }
  }
}
```

**cog gets the same escape hatch.** The global step resolves its config
repo-first:

```sh
cfg=cog.toml; [ -f "$cfg" ] || cfg="$HOME/.config/cog/cog.toml"
cog --config "$cfg" --quiet verify --file "$msg"
```

Verified: with no repo `cog.toml`, `ref` passes and `refactor` and `hotfix` fail
(global policy); after adding a repo `cog.toml` that declares `hotfix`, `hotfix`
passes while `refactor` still fails — the repo overrides without losing the
shared baseline.

**Self-contained mode.** A repo that cannot depend on the global config pastes
the two commit-msg steps into its own `hk.pkl` verbatim and, optionally, commits
its own `cog.toml`. The step definitions are identical in both modes — only their
location differs — so there is one thing to maintain, not two.

| | Global mode | Per-repo mode |
| --- | --- | --- |
| Files in the repo | none | `hk.pkl` (+ optional `cog.toml`) |
| New repo setup | `hk install --mise --legacy` | copy config, then install |
| Applies to contributors without `dots` | no | yes |
| Rule changes propagate | edit one file, all repos follow | edit each repo |
| Recommended for | your own repos across your machines | shared or public repos |

### Global commit-msg configuration

```pkl
amends "package://github.com/jdx/hk/releases/download/v1.56.0/hk@1.56.0#/Config.pkl"

jobs = 4

hooks {
  ["commit-msg"] {
    steps {
      ["conventional-commit"] {
        check = "cog --config {{cog_config}} --quiet verify --file {{commit_msg_file}}"
      }
      ["commit-style"] {
        check = #"""
          {% raw %}
          ... shell, with {% endraw %}{{ commit_msg_file | default(value=files) }}{% raw %} spliced in
          {% endraw %}
          """#
        tests { ... }
      }
    }
  }
}
```

Three mechanics make this work, all verified:

1. **`#"""…"""#` raw strings** — regexes and backslashes survive; `pkl eval` reports the file VALID, so the LSP stops complaining (D3).
2. **`{% raw %}` blocks** — shell `${#var}` no longer collides with Tera (D10). hk's own `{{…}}` variables are spliced in by closing and reopening the raw block.
3. **`{{ commit_msg_file | default(value=files) }}`** — the step reads the real message file under the hook, and falls back to `{{files}}` under `hk test`, so one definition is both hook-correct and testable.

### `cog.toml` (shared default)

```toml
ignore_merge_commits = true
ignore_fixup_commits = true

[commit_types]
ref = { changelog_title = "Refactoring" }
refactor = {}
```

Verified: `ref` accepted, `refactor` rejected, defaults intact, merges and
fixups skipped — from a repo with no `cog.toml` of its own, via `cog --config`.

### Style rules

| Rule | Source |
| --- | --- |
| Subject ≤ 50 chars | GIT_COMMITS_GUIDE rule 2 |
| Description ≥ 5 chars | deleted `.gitlint` `title-min-length` |
| Description capitalized | GIT_GUIDE §5.3 |
| No trailing period | GIT_GUIDE §5.3 |
| Blank line before body | GIT_COMMITS_GUIDE rule 1 |
| Body lines ≤ 72 | GIT_COMMITS_GUIDE rule 6 |
| No `wip` | deleted `.gitlint` |
| Skip `Merge`/`Revert`/`fixup!`/`squash!`/`amend!` | deleted `.gitlint` `ignore-*-commits` |

Body-wrap exemptions, in order: `#` comments stripped; fenced code blocks skipped;
lines matched by `git interpret-trailers --parse`; `BREAKING CHANGE:` (its token
contains a space, so git does not treat it as a trailer, and Conventional Commits
names it as the exception); lines with no internal whitespace (bare URLs).

### Guide amendment required

The `References:` + bullet-list block in `GIT_COMMITS_GUIDE.md` is not trailer
syntax — trailers are one `Token: value` per line in the final paragraph.
Confirmed: that block yields no output from `git interpret-trailers --parse`,
so its lines would be held to 72 chars. The template becomes `Reference: <url>`
lines. Documentation change only; no rule is relaxed.

### Linter changes in `hk.pkl`

| Step | Change |
| --- | --- |
| `shfmt` | glob `**/*.sh`, `**/*.bash`, `**/*.bats` — **`*.zsh` removed** (D2) |
| `shellcheck` | glob `**/*.sh`, `**/*.bash` — **`*.zsh` removed** (D2) |
| `zsh-syntax` | **new** — `zsh -n {{files}}` over `**/*.zsh` and zsh dotfiles |
| `markdownlint` | `graphify-out` moves to global `exclude` |
| `taplo` | exclude `config/tombi/config.toml` (TOML 1.1 vs taplo's 1.0) |
| `yamllint`, `hadolint` | unchanged — offending files fixed instead (D8) |

Plus: `amends`/`import` bumped to the installed hk version, `hk` pinned in
`mise.toml`, and every regex converted to `#"…"#`.

### `config/hk/hkrc.pkl` repair

Rewritten to the real schema (`jobs` is top-level; `settings {}` does not exist),
extended with the commit-msg hook above, and the symlink its README documents is
actually created by `mise run setup:hooks`.

---

## Error handling

| Condition | Behaviour |
| --- | --- |
| hk absent from PATH, mise present | `mise x` resolves it — verified |
| mise absent entirely | Hook fails loudly; `mise install` is the fix |
| Old git (2.50.1) | `--legacy` shims run normally — this is the D4 fix |
| `HK=0` set | Shim exits 0 before invoking hk — verified |
| Merge / revert / fixup / squash / amend | Both steps exit 0 |
| Global config missing on a fresh machine | Commit rules silently absent in global mode — mitigated by `mise run setup:hooks` creating the symlink, and covered by a bats test. Self-contained repos are unaffected. |
| Repo overrides a global step | Repo definition wins per-property; global step does not also run (verified) |
| A step fails | hk prints that step's stdout+stderr |

---

## Testing

| Suite | Mechanism | Covers |
| --- | --- | --- |
| Step behaviour | `hk test` (in-config `tests {}`) | Subject length/case/punctuation/min-length/wip; exemptions; body wrap; trailer exemption; BREAKING CHANGE; bare URLs; fenced code; comment stripping; every allowed type; `refactor`/`git`/uppercase rejected |
| Git integration | bats | Real `git merge --no-ff`, `git revert`, `git commit --fixup` + `git rebase --autosquash` |
| Environment matrix | bats | Commit under Apple git 2.50.1; hk absent from PATH; mise not activated; `HK=0` bypass |
| Config validity | bats | `pkl eval` on every pkl file (D3, D9), `hk validate`, `hk check --all` exit 0 |
| Layering | bats | Global-only repo inherits rules; repo `hk.pkl` add / override / `step_condition=false` disable; repo `cog.toml` takes precedence over the shared one; self-contained repo with no global config enforces identically |

Plus a recorded timing for `hk run pre-commit` on a representative staged set.

---

## Out of scope

pre-push hooks, branch protection, CI enforcement, and rewriting existing
non-conforming history. Hooks apply to new commits only; the 53 historical
`ref` commits and 13 `refactor` commits are left as they are.
