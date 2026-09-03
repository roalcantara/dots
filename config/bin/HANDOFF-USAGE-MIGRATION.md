<!-- markdownlint-disable-file -->

# HANDOFF: migrate `config/bin` scripts to usage CLI

Handoff for an implementation agent. Refactor eligible `config/bin/xc-*`
executables from the legacy **`##?` + `xc-usage` + manual/`zparseopts` parsing**
model to the **[usage CLI shebang](https://usage.jdx.dev/cli/scripts)** model.

**Canonical reference:** [`xc-toast`](xc-toast) (complete).

---

## Copy-paste prompt

```text
You are working in the dots repo at config/bin.

Migrate config/bin xc-* scripts to the usage CLI shebang pattern per
config/bin/HANDOFF-USAGE-MIGRATION.md.

Read first:
- config/bin/HANDOFF-USAGE-MIGRATION.md (this file)
- config/bin/xc-toast (reference implementation)
- https://usage.jdx.dev/cli/scripts
- config/zsh/.zshrc (completion-init already wired)
- AGENTS.md → dots-context skill

Rules:
- One script or tier per PR when possible; start with xc-md and xc-puts.
- Do NOT migrate xc-usage or xc launcher in the first pass.
- Do NOT use zparseopts when usage shebang parses all args.
- Invoke scripts directly in tests (not `zsh script` — that bypasses shebang).
- For every #USAGE example line, add an integration test or smoke assertion.
- Run: usage lint, bun test assets/integration/bin/<script>.spec.ts, shellcheck.

Acceptance: every #USAGE example for each migrated script must pass.
```

---

## Mission

Replace docopt `##?` headers and `xc-usage` help extraction with `#USAGE`
comments on a `usage` shebang. Gain auto-generated `--help`, argument parsing
via `usage_*` env vars, and zsh tab completion via existing `completion-init`.

---

## Reference implementation: `xc-toast`

**File:** [`config/bin/xc-toast`](xc-toast)

### Patterns to replicate

1. **Shebang:** `#!/usr/bin/env -S usage zsh` (use `usage bash` only for bash
   scripts such as `xc-skills`).
2. **Metadata:** keep `#?` license lines; add `#USAGE version`, `#USAGE about`.
3. **Args/flags in `#USAGE`:** not `##?` docopt.
4. **Flag + positional alias** when a value accepts both forms:

   ```zsh
   #USAGE arg "[duration_pos]" help="… (positional alternative to --duration)" default="3"
   #USAGE flag "-d --duration <duration>" help="…" default="3"
   ```

   Body:

   ```zsh
   local duration="${usage_duration_pos:-$usage_duration}"
   local type="${usage_type_pos:-$usage_type}"
   ```

5. **Choices:** `default` on the arg/flag line; `choices` inside `{ … }`.
6. **Examples:** one `#USAGE example "…"` per documented example — these become
   acceptance tests.
7. **Empty required input:** make the primary arg optional in the spec
   (`[message]`), enforce in the body:

   ```zsh
   if [[ -z "$usage_message" ]]; then
     usage zsh "${0:a}" --help >&2
     exit 1
   fi
   ```

8. **Do not use `zparseopts`** when the usage shebang parses everything.
9. **Remove:** `_xc_usage_find`, `xc-usage guard/print`, manual `-h|--help`
   cases, and `##?` blocks (for migrated scripts).

### Completion

Already enabled in [`config/zsh/.zshrc`](../zsh/.zshrc):

```zsh
source <(usage generate completion-init zsh)
```

No per-script `_xc-*` completion files needed for usage-shebang scripts.

### Prerequisite

`usage` on `$PATH` (mise: `usage = "latest"` in [`config/mise/config.toml`](../mise/config.toml)).

---

## Scope

### Migrate (recommended order)

| Tier | Script                   | Shell | Complexity                     | Integration spec                                                      |
| ---- | ------------------------ | ----- | ------------------------------ | --------------------------------------------------------------------- |
| 1    | [`xc-md`](xc-md)         | zsh   | Minimal (stdin pipe)           | [`xc-md.spec.ts`](../../assets/integration/bin/xc-md.spec.ts)         |
| 1    | [`xc-puts`](xc-puts)     | zsh   | Flat + many flags              | [`xc-puts.spec.ts`](../../assets/integration/bin/xc-puts.spec.ts)     |
| 2    | [`xc-toast`](xc-toast)   | zsh   | Positional & flags overlay     | [`xc-toast.spec.ts`](../../assets/integration/bin/xc-toast.spec.ts)   |
| 3    | [`xc-skills`](xc-skills) | bash  | Dispatcher (`sync`, `collect`) | [`xc-skills.spec.ts`](../../assets/integration/bin/xc-skills.spec.ts) |
| 3    | [`xc-git`](xc-git)       | zsh   | Large dispatcher + subcommands | [`xc-git.spec.ts`](../../assets/integration/bin/xc-git.spec.ts)       |
| 4    | [`xc-fabric`](xc-fabric) | zsh   | Largest dispatcher             | [`xc-fabric.spec.ts`](../../assets/integration/bin/xc-fabric.spec.ts) |

### Do NOT migrate in this pass

| Script                 | Reason                                                                               |
| ---------------------- | ------------------------------------------------------------------------------------ |
| [`xc-usage`](xc-usage) | Extracts `##?` from other scripts; migrate **last** or keep as compatibility shim    |
| [`xc`](xc)             | Launcher uses `xc-usage --preview` on `##?` blocks; update after bin scripts migrate |

---

## Dispatchers: `#USAGE cmd`

For multi-subcommand tools, use usage subcommands:

```zsh
#USAGE cmd "branch-preview <branch>" help="Preview branch" {
#USAGE   arg "<branch>" help="Branch name"
#USAGE   example "xc-git branch-preview main"
#USAGE }
```

Subcommand help: `xc-git branch-preview --help` (usage native). Replace scoped
`##?` sub-blocks and `xc-usage --scope sub:NAME`.

---

## Global acceptance criteria (every migrated script)

```bash
usage lint config/bin/<script>
<script> --help          # exit 0; stdout contains Usage + about text
<script>                 # if no args invalid: full help on stderr, exit 1
shellcheck config/bin/<script>   # where applicable
bun test assets/integration/bin/<script>.spec.ts
```

**Integration tests:** invoke scripts **directly** (`[scriptPath, …]`), **not**
`["zsh", scriptPath, …]` — the shebang must run.

**Per-example rule:** for every `#USAGE example "…"` line, add a test or smoke
command that runs the example (argv split) and asserts the documented exit code
(usually **0**). Parse examples from the script header; do not invent new ones
unless fixing broken ones.

---

## Progress

| Tier | Script | Status | Tests |
| ---- | ------ | ------ | ----- |
| 1 | `xc-md` | ✅ Done | 3/3 |
| 1 | `xc-puts` | ✅ Done | 8/8 |
| 2 | `xc-toast` | ✅ Done | 7/7 |
| 3 | `xc-skills` | ✅ Done | 38/38 |
| 3 | `xc-git` | ✅ Done | 13/13 |
| 4 | `xc-fabric` | ✅ Done | 22/22 |
| 5 | `xc` (launcher) | ✅ Done | 6/6 |

### Key findings during migration

- **`usage bash` does not set subcommand-specific env vars**: dispatch via `case "$1"` not `if [[ -n "$usage_sync" ]]`.
- **`$HOME` defaults in bash code** (not `#USAGE` flag defaults — usage preserves literal `$HOME`).
- **`#USAGE cmd` blocks before `#USAGE version/about`** — usage parser reads cmd blocks first.
- **No blank lines between `#USAGE cmd` blocks** — usage parser stops at blank lines.
- **`var "true"` not `var #true`** — `#` is KDL comment delimiter.
- **Subcommand --help exits 1** with usage CLI (help on stderr), not 0. Top-level --help exits 0 (stdout).
- **Repeatable flags with `usage bash`** only retain the last value — architecture limitation.
- **Direct exec**: tests invoke scripts directly (`[scriptPath, …]`), not `["zsh", scriptPath, …]`.

---
### `xc-toast` (complete — verify only)
## Implementation checklist (per script)

1. Read current `##?` block(s) and all examples.
2. Draft equivalent `#USAGE` header (flat or `cmd` blocks).
3. Change shebang to `usage zsh` / `usage bash`.
4. Replace parsing with `usage_*` variables; use `${usage_X_pos:-$usage_X}` for
   dual positional/flag.
5. Add empty-arg help guard where needed.
6. Delete `xc-usage` calls and `##?` blocks.
7. `usage lint config/bin/<script>`
8. Update or create `assets/integration/bin/<script>.spec.ts`:
   - Direct script invocation
   - One test per `#USAGE example` (`it.each` encouraged)
   - Help / no-args scenarios
9. Run `bun test assets/integration/bin/<script>.spec.ts`
10. Update [`README.md`](README.md) three-layer table when the batch is done

---

## Follow-up (out of scope for per-script PRs)

- Migrate [`xc`](xc) launcher preview from `xc-usage --preview` to usage help
- Migrate or retire [`xc-usage`](xc-usage) once nothing depends on `##?`
- Sync [`assets/specs/xc-portable-tools/requirements.md`](../../assets/specs/xc-portable-tools/requirements.md)
  and [`assets/specs/xc-usage/design.md`](../../assets/specs/xc-usage/design.md)
- Snippet reference: [`config/snippets/shellscript.json`](../snippets/shellscript.json)
  (`USAGE | Displaying Help…`)

---

## Suggested commit message

```gitcommit
ref(xc-<name>): Adopt usage CLI for help and completions

Replace docopt/xc-usage with usage shebang and #USAGE headers.
Add integration tests for each #USAGE example.
```
