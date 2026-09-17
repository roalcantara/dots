# ZSH/ZIM restructure: correctness, DRY, and startup cost

**Date:** 2026-09-17
**Status:** Approved (design)
**Scope:** `config/zsh/` (`.zshenv`, `.zprofile`, `.zshrc`, `.zimrc`, `opt/`) and `config/.profile`

## Problem

Claude Code running in the VSCode integrated terminal intermittently reports `zsh: no such
file or directory` / "file exists" failures on `>` redirections. Separately, the startup
files carry terminal-detection logic spread across five sites, a large block of completion
configuration that is silently overwritten, and several latent bugs.

## Goals

1. Fix the `noclobber` failure reported by Claude Code.
2. Make the VSCode terminal fully functional (prompt, highlighting, autosuggestions).
3. Remove redundancy and dead configuration.
4. Reduce startup cost, measured rather than assumed.

## Non-goals

- Changing the plugin set or replacing ZIM.
- Restyling the prompt or `fast-syntax-highlighting` theme.
- Touching `opt/completions/` (vendored completion functions).

---

## Evidence

### Method

`hyperfine` 1.20.0, zsh 5.9.2 (aarch64-apple-darwin25.4.0), Darwin 27.0.0. Warm runs after
5 warmup iterations, 20-30 runs per case. Feature parity measured by dumping options,
exported names, all three alias kinds, functions, widgets, bindkeys, `path`, `fpath` and
hook arrays from a shell started under `env -i` (cold environment), then diffing. The
`fast-syntax-highlighting` saved-widget names embed a per-run counter and are normalised
before diffing.

### Baseline startup

| Context | Mean |
| --- | --- |
| `zsh -c exit` (Claude Bash tool; `.zshenv` only) | 4.8 ms ± 0.2 |
| Warp (config skipped entirely) | 7.9 ms ± 0.2 |
| `ZSH_MINIMAL_TERMINAL=1` | 90.2 ms ± 1.3 |
| plain tty, no `TERM_PROGRAM` | 101.5 ms ± 0.9 |
| ghostty | 101.9 ms ± 4.8 |
| **VSCode** | **181.3 ms ± 3.2** |
| **VSCode + Claude** (`VSCODE_INJECTION=1`) | **183.6 ms ± 1.7** |

### Subprocess cost during startup

| Command | Mean |
| --- | --- |
| `code --locate-shell-integration-path zsh` | **78.0 ms ± 1.0** |
| `brew shellenv` | 9.2 ms ± 0.3 |
| `mise activate zsh` | 8.6 ms ± 0.4 |
| `mise activate zsh --shims` | 8.0 ms ± 0.4 |
| `starship init zsh` | 3.3 ms ± 0.3 |

The entire ~80 ms VSCode penalty is one line (`.zshrc:300`): an Electron CLI boot to obtain
a path that never changes.

### `zprof` hot spots (plain tty)

`_mise_hook` 28.4 ms (46.7% of profiled time), zim-mise module 38.9 ms cumulative,
ZIM completion init 7.8 ms, zim-starship 5.4 ms, `compinit` 2.5 ms. `zprof` covers function
calls only; it does not account for top-level `eval`/`source` of command substitutions,
which is where the VSCode cost hides.

---

## Findings

### F1 — `noclobber` (the reported bug)

`setopt NO_CLOBBER` originates in ZIM's `environment` module
(`~/.local/state/zim/modules/environment/init.zsh:71`). Nothing in this repo sets it.
Confirmed present as `setopt noclobber` at line 10680 of a captured Claude Code shell
snapshot. Because ZIM loads late in `.zshrc`, any override must run *after* it.

### F2 — `setopt NO_RCS` disables the native startup chain

`.zshenv:40` sets `NO_RCS`, which suppresses `.zprofile`, `.zshrc`, `.zlogin` and
`.zlogout`. Demonstrated with a minimal `ZDOTDIR`:

```
with NO_RCS:     MARK zshenv
without NO_RCS:  MARK zshenv / .zprofile / .zshrc / .zlogin
```

The files are therefore hand-sourced (`.zshenv` -> `.zprofile` -> `.zshrc`) with guards
duplicated in both. `.zlogin` and `.zlogout` never execute.

### F3 — Terminal detection spread across five sites

`.zshenv:76` (Warp guard), `.zprofile:139-151` (`ZSH_MINIMAL_TERMINAL` computation, mise
shims, kiro), `.zshrc:292-301` (ghostty/vscode integration), `.zshrc:390-396` (final prompt
guard), plus four `--if '[[ -z "$ZSH_MINIMAL_TERMINAL" ]]'` conditions in `.zimrc`.

ZIM emits `--if` conditions as **runtime** `if` blocks in the generated `init.zsh`, so
`ZSH_MINIMAL_TERMINAL` need only be set before `.zshrc` sources `init.zsh`. It does not
need to live in `.zprofile`.

### F4 — Completion configuration silently overwritten

`.zshrc:191-229` runs before ZIM; ZIM's completion module then overrides much of it.
Verified live in a running shell:

| Setting | Intended | Effective |
| --- | --- | --- |
| `squeeze-slashes` | `no` | `true` |
| `menu` | `select=2` | `select` |
| `matcher-list` | user's two lines | ZIM's |
| `ZLE_RPROMPT_INDENT` | `0` | `1` (zim-starship) |

`.zshrc:199` is additionally dead on its own terms: line 200 overrides it before ZIM is
even reached.

### F5 — `dumpfile` zstyle is build-time only

`.zimrc:12` sets `zstyle ':zim:completion' dumpfile "$zdumpfile"`, but `.zimrc` executes
only when `zimfw` regenerates `init.zsh`. At runtime the style is unset, so ZIM falls back
to `${ZDOTDIR}/.zcompdump` — which is why compdumps are written into the git working tree
(`config/zsh/.zcompdump*`) in addition to `~/.cache/zsh/compcache/`. Two live dumps.

### F6 — Dead references to a removed directory

`config/zsh/etc/` was deleted in commit `56e9b9d`. Still referenced by `.zimrc:31-33` and
`.zimrc:39-41` (guards plus `/bin/ls` subprocesses at build time) and by
`config/.profile:28` (`ZDOTDIR_ETC`). `ZDOTDIR_OPT` (`.profile:29`) is exported and never
read.

### F7 — Latent bugs

| # | Location | Defect |
| --- | --- | --- |
| a | `.zshrc:13` | `_has_command` tests only `$1`; the call `_has_command sops age` never checks `age`. Confirmed: returns true with a bogus second argument. |
| b | `.zshrc:293` | `[[ -e GHOSTTY_RESOURCES_DIR"/..." ]]` missing `$`. The first Ghostty branch can never fire. |
| c | `.zshrc:233` | `export PROMPT` marks PROMPT exported; zim-starship then assigns the starship command substitution into it, so every child process inherits `PROMPT='$(/opt/homebrew/bin/starship prompt ...)'`. |
| d | `.zprofile:145` + zim-mise | In VSCode, mise is activated twice: `--shims` and the `_mise_hook_precmd` hook. Shims mode is intended to replace hook activation. |
| e | `opt/aliases/ls.zsh` | `alias lal='lal -Sa@ --color-scale'` is self-referential; `lax` and `lls` reference a non-existent `lla`. |
| f | `.zshenv` / `.zshrc` | The same mail-warning option is set five times (`no_mail_warning`, `NO_MAILWARN`, `NO_MAILWARNING`). |
| g | `.zshenv:29,31` | `export NO_GLOBAL_RCS=1` and `export ZIM_DISABLE_AUTOLOAD=1` are not read by anything; `NO_GLOBAL_RCS` is a shell option, not an environment variable. |

### F8 — Completion latency

`.zshrc:194` sets `completer _expand _complete _correct _approximate _expand_alias
_extensions _match`. `_approximate` and `_correct` each perform additional completion
passes. Not yet measured; flagged for follow-up rather than changed blind.

---

## Design

### Phase A — Restore the native startup chain

Remove `setopt NO_RCS` (retain `NO_GLOBAL_RCS`, which blocks `/etc/*` without blocking user
files). Delete the manual `source` lines in `.zshenv` and `.zprofile`.

Paired, mandatory change: the 129 lines of pure tool environment in `.zprofile` (LESS, MISE,
STARSHIP, NPM, RUBY, CARGO, PNPM, JQ, RIPGREP, BAT, GLOW, GOPASS, GITLINT, WAKATIME, GO,
PUPPETEER) move to `.zshenv`, because native zsh reads `.zprofile` only for login shells.
`GPG_TTY=${GPG_TTY:-"$(tty)"}` stays in `.zprofile`; it requires a controlling terminal.

Validated in a prototype `ZDOTDIR`:

| Path | Current | Restored | Verdict |
| --- | --- | --- | --- |
| `zsh -lic` plain | 103.8 ms ± 6.2 | 102.9 ms ± 1.0 | neutral |
| `zsh -lic` VSCode | 182.9 ms ± 2.0 | 184.6 ms ± 1.7 | neutral |
| `zsh -c` | 4.8 ms ± 0.2 | 5.9 ms ± 0.2 | **+1.1 ms** |
| parity `-lic`, cold env | — | — | byte-identical |
| parity `-ic`, cold env | — | — | byte-identical |

The +1.1 ms on `zsh -c` is the accepted cost of the environment move, and is what buys
non-login and non-interactive shells a correct tool environment. Without the move, `zsh -ic`
loses 43 exported variables — measured, not hypothesised.

`.zlogin` and `.zlogout` become live files again and must be reviewed for content.

### Phase B — Single terminal-profile block

One labelled block in `.zshrc`, immediately before the ZIM block, replacing F3's five sites.
It is **not** extracted to a separate file: with Phase A applied it has exactly one consumer,
and `opt/plugins/` is structurally unusable for it because ZIM sources `opt/plugins/init.zsh`
*after* the `ZSH_MINIMAL_TERMINAL` conditionals are evaluated.

Behaviour:

- `ZSH_MINIMAL_TERMINAL` applies to **Warp only** (native prompt, highlighting and
  suggestions genuinely conflict), plus an explicit user-set override.
- **VSCode becomes fully featured**: starship, fast-syntax-highlighting,
  zsh-history-substring-search, zsh-autosuggestions all load. Cost ~11 ms.
- Ghostty integration retains both branches with F7b fixed.
- mise is activated once (F7d).

### Phase C — VSCode shell integration

Replace `source "$(code --locate-shell-integration-path zsh)"` with:

1. If `VSCODE_INJECTION=1`, skip entirely — VSCode has already sourced the integration. The
   shipped `shellIntegration-rc.zsh` branches on this variable at its lines 21 and 26.
2. Otherwise read the path from a cache file keyed on the VSCode bundle, falling back to the
   real lookup on a miss and rewriting the cache.

Cached read measures 3.2 ms ± 0.3 against 77.9 ms ± 1.1 uncached.

### Phase D — Post-ZIM override block

A single block in `.zshrc` *after* `source $ZIM_HOME/init.zsh`, holding every setting that
must outrank ZIM:

- `setopt CLOBBER` — resolves F1. Restores zsh's default. Scripts wanting protection opt in
  locally with `set -o noclobber`.
- The F4 settings that are actually wanted: `squeeze-slashes no`, `menu select=2`, the
  intended `matcher-list`, `ZLE_RPROMPT_INDENT=0`.
- Settings that merely restate ZIM's defaults are deleted, not relocated.

`zstyle ':zim:completion' dumpfile` moves from `.zimrc` to `.zshrc` *before* the `init.zsh`
source, resolving F5 and stopping compdump churn in the working tree.

### Phase E — Cleanup

- Remove the `etc/` guards from `.zimrc` and `ZDOTDIR_ETC` / `ZDOTDIR_OPT` from `.profile` (F6).
- Fix F7a, F7b, F7c, F7e; collapse F7f to one setting; delete F7g.
- `PROMPT` is assigned without `export`.

---

## Verification

Re-run after every phase; a phase is complete only when both hold:

1. **Performance** — the hyperfine matrix (`zsh -c`, `-ic`, `-lic` x plain/ghostty/vscode/
   vscode+injection/warp), no regression beyond noise against the recorded baseline.
2. **Parity** — cold-environment (`env -i`) dump diff for `-lic` and `-ic` against the
   pre-change baseline. Expected differences are enumerated per phase and anything else is
   treated as a regression.

Additionally: `zsh -n` on every changed file, and one interactive smoke test per terminal
(VSCode, ghostty, Warp) covering prompt render, tab completion, history substring search,
autosuggestion and `>` redirection over an existing file.

### Measured result (post-implementation)

Measured as a **paired A/B in a single `hyperfine` invocation**: the pre-change
configuration was reconstructed from commit `3fc2c8f` into a temporary `ZDOTDIR` and
benchmarked interleaved with the current one. Both arms therefore see identical machine
state, which is the only way the deltas mean anything. 25 runs, 5 warmup.

| Context | Before | After | Change |
| --- | --- | --- | --- |
| `zsh -lic` plain | 102.0 ms ± 1.2 | 103.6 ms ± 2.2 | +1.6 ms (noise) |
| `zsh -lic` ghostty | 103.4 ms ± 2.2 | 104.0 ms ± 6.8 | +0.6 ms (noise) |
| `zsh -lic` vscode | 182.0 ms ± 3.2 | **106.7 ms ± 1.0** | **-75.3 ms** |
| `zsh -lic` vscode+inject | 183.5 ms ± 2.4 | **109.7 ms ± 6.3** | **-73.8 ms** |
| `zsh -lic` warp | 7.8 ms ± 0.2 | 94.4 ms ± 8.7 | +86.6 ms (by design) |
| `zsh -c` | 4.8 ms ± 0.2 | 5.9 ms ± 0.2 | +1.1 ms |

**Goal met and beaten.** VS Code came in at 106.7 ms against a ~115 ms projection, because
the cached-path branch costs less than the 3.2 ms budgeted. VS Code now sits ~3 ms above a
plain terminal while running four plugins it previously had switched off.

**Only one context got slower, and it was planned:** Warp previously short-circuited the
entire configuration (7.8 ms) and so had no aliases, functions or completions at all. It now
loads everything except the four plugins that conflict with its native UI. This is the
documented deviation in the plan, not a regression.

Plain and ghostty are unchanged within noise, as Phase A predicted.

> **Superseded measurement.** An earlier revision of this section reported plain at
> +24.2 ms and ghostty at +31.7 ms. Those figures came from two *separate* hyperfine runs
> taken at different times under different machine load — the "before" run measured plain at
> 207.9 ms where an unloaded machine measures 102 ms. Deltas across non-simultaneous runs on
> a contended machine are not comparable. The paired A/B above replaces them. Its `zsh -c`
> "before" of 5.9 ms was also not a baseline at all but this plan's *predicted* post-Task-3
> value.

### User-visible latency (zsh-bench)

Everything above measures *process* startup (`zsh -lic exit`). That is not what a human
feels, and it is structurally blind to recurring per-command cost. Re-measured with
[zsh-bench](https://github.com/romkatv/zsh-bench), 10 iterations, plain terminal:

| Metric | Before | After | Perceptual threshold |
| --- | --- | --- | --- |
| `first_prompt_lag_ms` | 178.6 | 176.6 | — |
| `first_command_lag_ms` | 182.6 | 180.7 | — |
| `command_lag_ms` | 67.2 | **65.6** | **10 ms** |
| `input_lag_ms` | 3.7 | 3.9 | 20 ms |
| `exit_time_ms` | 94.9 | 94.4 | — |

The restructure is neutral on all five in a plain terminal, as expected: its wins are in
VS Code, which zsh-bench does not simulate.

**The significant finding is pre-existing and was not addressed by this work.**
`command_lag_ms` of ~66 ms is roughly 6.5x zsh-bench's calibrated threshold of 10 ms, and it
is paid on *every* command, not once at startup. Cause is the per-prompt subprocess set:

| `precmd` hook | Standalone cost |
| --- | --- |
| `prompt_starship_precmd` (`starship prompt`) | 78.5 ms ± 0.5 |
| `_mise_hook_precmd` (`mise hook-env -s zsh`) | 24.5 ms ± 0.2 |

`exit_time_ms` of ~94 ms (the `zshexit` `fc -W` history write) is also worth a look.

This is a larger and more user-visible win than anything in this spec, and it is deliberately
left as follow-up rather than folded in here. Note the tension with Phase B: that phase
removed mise's `--shims` activation as redundant with the hook. Shims mode has no `precmd`
hook at all, so reversing that specific choice is the obvious lead for the ~24 ms share —
but shims and `hook-env` have different semantics and the swap needs its own evaluation.

## Risks

| Risk | Mitigation |
| --- | --- |
| Phase A changes which files run in unusual invocations | Cold-env parity diff for both `-lic` and `-ic`; `.zlogin`/`.zlogout` reviewed before they go live |
| VSCode cache goes stale after a VSCode upgrade | Cache keyed on the bundle; miss falls back to the real lookup |
| Re-enabling plugins in VSCode conflicts with its shell integration | Interactive smoke test in VSCode specifically |
| `setopt CLOBBER` removes an overwrite safety net | Deliberate, user-approved; matches zsh default |
| ZIM module updates reintroduce overridden settings | All overrides live in one post-ZIM block, so re-asserting them is a single edit |
