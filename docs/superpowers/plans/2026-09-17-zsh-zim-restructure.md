# ZSH/ZIM Restructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the `noclobber` failure Claude Code hits, make the VSCode terminal fully featured, remove dead and duplicated configuration, and cut VSCode shell startup from ~181 ms to ~115 ms — with every phase gated on measured parity and performance.

**Architecture:** Five sequential phases against `config/zsh/`. Phase A restores zsh's native startup chain (currently disabled by `setopt NO_RCS`) and relocates pure environment from `.zprofile` to `.zshenv` so non-login shells keep parity. Phase B collapses terminal detection from five sites to one block in `.zshrc`. Phase C stops shelling out to the VSCode CLI on every startup. Phase D adds a post-ZIM override block that reclaims settings ZIM currently overwrites, including `setopt CLOBBER`. Phase E removes dead references and fixes latent bugs.

**Tech Stack:** zsh 5.9.2, ZIM (zimfw), starship, mise, Homebrew, `hyperfine` for timing, `bash`/`shellcheck` for the harness.

**Spec:** `docs/superpowers/specs/2026-09-17-zsh-zim-restructure-design.md`

---

## Critical context for the implementer

Read this before Task 1.

**`~/.config/zsh` is a symlink to `config/zsh/` in this repo.** Editing a file in the repo changes the live shell configuration immediately. There is no deploy step. This is why the harness captures a baseline *before* any edit.

**`~/.profile` is a symlink to `config/.profile`** and is sourced from `.zshenv`. It exports `ZDOTDIR`, so anything that overrides `ZDOTDIR` earlier is discarded.

**ZIM generates `~/.local/state/zim/init.zsh` from `.zimrc`.** Two different evaluation times matter:
- Plain shell code in `.zimrc` (the `if [[ -d ... ]]` guards, `zstyle` calls) runs **only when ZIM rebuilds** `init.zsh`. It has no effect at shell startup.
- `zmodule --if '<condition>'` is emitted into `init.zsh` as a **runtime** `if` block, so its condition is evaluated on every shell start.

This distinction is why `zstyle ':zim:completion' dumpfile` in `.zimrc` is dead (Task 8) but `--if '[[ -z "$ZSH_MINIMAL_TERMINAL" ]]'` is live (Task 5).

**`.zshrc` sources `$ZIM_HOME/init.zsh` at line ~321.** Anything that must beat ZIM goes before it; anything that must outrank ZIM goes after it. ZIM's `environment` module sets `NO_CLOBBER`, `SHARE_HISTORY`, `EXTENDED_GLOB` and others; its `completion` module sets many `zstyle ':completion:*'` values.

**Verification is not optional.** Every task ends with `mise run zsh:verify`. A task is complete only when the parity diff contains exactly the lines the task predicts — no more. An unexpected line is a regression, not an acceptable variance.

**If a phase cannot meet its gate, stop and report.** Do not proceed to the next phase with a failing gate, and do not adjust the gate to fit the result.

---

## File Structure

| File | Responsibility after this plan |
| --- | --- |
| `script/zsh-verify.sh` | **New.** Parity + benchmark + syntax harness. Sole verification entry point. |
| `mise.toml` | **Modify.** Adds `zsh:verify`, `zsh:bench`, `zsh:baseline` tasks. |
| `config/zsh/.zshenv` | Environment only. XDG (via `.profile`), all tool env vars, i18n, profiling hooks. No output, no tty, no subprocesses. |
| `config/zsh/.zprofile` | Login-only setup. After this plan it holds almost nothing; kept as the documented hook point. |
| `config/zsh/.zshrc` | Interactive config: terminal profile, options, completion styles, ZIM, post-ZIM overrides. |
| `config/zsh/.zimrc` | ZIM module list only. No dead-path guards. |
| `config/zsh/.zlogin` / `.zlogout` | Live again after Phase A; audited in Task 4. |
| `config/.profile` | XDG + zsh path exports. Dead exports removed. |

---

## Task 1: Verification harness

**Files:**
- Create: `script/zsh-verify.sh`
- Modify: `mise.toml` (append tasks)

- [ ] **Step 1: Create the harness**

Create `script/zsh-verify.sh`:

```bash
#!/usr/bin/env bash
# Verification harness for the ZSH/ZIM restructure.
# See docs/superpowers/specs/2026-09-17-zsh-zim-restructure-design.md
set -euo pipefail

ZSH_BIN="${ZSH_BIN:-/opt/homebrew/bin/zsh}"
OUT="${ZSH_VERIFY_DIR:-${TMPDIR:-/tmp}/zsh-verify}"
ZDOT="$HOME/.config/zsh"

dump_script() {
  cat <<'EOF'
{
  echo "### OPTIONS";     setopt | sort
  echo "### ENV";         export | sed 's/=.*//' | sort
  echo "### ALIASES";     alias    | sed 's/=.*//' | sort
  echo "### GLOBALALIAS"; alias -g | sed 's/=.*//' | sort
  echo "### SUFFIXALIAS"; alias -s | sed 's/=.*//' | sort
  echo "### FUNCTIONS";   print -l ${(ko)functions} | sort
  echo "### WIDGETS";     print -l ${(ko)widgets}   | sort
  echo "### BINDKEYS";    bindkey | sort
  echo "### PATH";        print -l $path
  echo "### FPATH";       print -l $fpath
  echo "### HOOKS";       print -l precmd:$precmd_functions preexec:$preexec_functions chpwd:$chpwd_functions
} 2>/dev/null
EOF
}

# Strip the per-run counter fast-syntax-highlighting bakes into saved widget names.
normalise() { sed -E 's/orig-s[0-9]+-r[0-9]+-/orig-SESSION-/g'; }

capture() { # capture <destdir>
  local dest=$1 ds; mkdir -p "$dest"
  ds="$dest/.dump.zsh"; dump_script > "$ds"
  local mode
  for mode in lic ic; do
    env -i HOME="$HOME" TERM=xterm-256color ZDOTDIR="$ZDOT" \
      "$ZSH_BIN" -"$mode" "source $ds" 2>/dev/null | normalise > "$dest/$mode.txt" || true
  done
  rm -f "$ds"
  printf 'captured %s: lic=%s lines, ic=%s lines\n' "$dest" \
    "$(wc -l < "$dest/lic.txt")" "$(wc -l < "$dest/ic.txt")"
}

cmd_baseline() { capture "$OUT/baseline"; }

cmd_parity() {
  [[ -d $OUT/baseline ]] || { echo "no baseline; run: $0 baseline" >&2; exit 2; }
  capture "$OUT/current"
  local mode rc=0
  for mode in lic ic; do
    if diff -u "$OUT/baseline/$mode.txt" "$OUT/current/$mode.txt" > "$OUT/$mode.diff"; then
      echo "PARITY OK    zsh -$mode"
    else
      echo "PARITY DIFF  zsh -$mode  ($(grep -c '^[+-][^+-]' "$OUT/$mode.diff") changed lines) -> $OUT/$mode.diff"
      rc=1
    fi
  done
  return $rc
}

cmd_bench() {
  mkdir -p "$OUT"
  local z="$ZSH_BIN" d="$ZDOT"
  hyperfine --warmup 5 --runs 25 --style basic --export-json "$OUT/bench.json" \
    -n 'zsh -c            (agent/non-interactive)' "env ZDOTDIR=$d $z -c exit" \
    -n 'zsh -ic           (interactive, non-login)' "env ZDOTDIR=$d $z -ic exit" \
    -n 'zsh -lic plain'                             "env -u TERM_PROGRAM ZDOTDIR=$d $z -lic exit" \
    -n 'zsh -lic ghostty'      "env TERM_PROGRAM=ghostty ZDOTDIR=$d $z -lic exit" \
    -n 'zsh -lic vscode'       "env TERM_PROGRAM=vscode ZDOTDIR=$d $z -lic exit" \
    -n 'zsh -lic vscode+inject' "env TERM_PROGRAM=vscode VSCODE_INJECTION=1 ZDOTDIR=$d $z -lic exit" \
    -n 'zsh -lic warp'         "env TERM_PROGRAM=WarpTerminal ZDOTDIR=$d $z -lic exit"
}

cmd_syntax() {
  local f rc=0
  for f in "$ZDOT"/.zshenv "$ZDOT"/.zprofile "$ZDOT"/.zshrc "$ZDOT"/.zimrc "$ZDOT"/.zlogin "$ZDOT"/.zlogout; do
    [[ -r $f ]] || continue
    if "$ZSH_BIN" -n "$f"; then echo "syntax OK    $f"; else echo "syntax FAIL  $f"; rc=1; fi
  done
  return $rc
}

case "${1:-}" in
  baseline) cmd_baseline ;;
  parity)   cmd_parity ;;
  bench)    cmd_bench ;;
  syntax)   cmd_syntax ;;
  *) echo "usage: $0 {baseline|parity|bench|syntax}" >&2; exit 2 ;;
esac
```

- [ ] **Step 2: Make it executable and lint it**

```bash
chmod +x script/zsh-verify.sh
shellcheck script/zsh-verify.sh
bash -n script/zsh-verify.sh
```

Expected: no output from `shellcheck`, no output from `bash -n`.

- [ ] **Step 3: Add mise tasks**

Append to `mise.toml`:

```toml
[tasks."zsh:baseline"]
description = "Capture the pre-change zsh parity baseline"
run = "./script/zsh-verify.sh baseline"

[tasks."zsh:verify"]
description = "Check zsh syntax and parity against the captured baseline"
run = ["./script/zsh-verify.sh syntax", "./script/zsh-verify.sh parity"]

[tasks."zsh:bench"]
description = "Benchmark zsh startup across terminal contexts"
run = "./script/zsh-verify.sh bench"
```

- [ ] **Step 4: Prove the harness detects a real regression**

This guards against a harness that silently passes everything.

```bash
mise run zsh:baseline
printf '\nalias __harness_canary=true\n' >> config/zsh/.zshrc
./script/zsh-verify.sh parity; echo "exit=$?"
```

Expected: `PARITY DIFF zsh -lic`, `PARITY DIFF zsh -ic`, `exit=1`, and `__harness_canary` present in the diff.

- [ ] **Step 5: Remove the canary and confirm parity returns**

```bash
sed -i '' '/__harness_canary/d' config/zsh/.zshrc
git diff --stat config/zsh/.zshrc   # expect: no changes, or only a trailing blank line
git checkout -- config/zsh/.zshrc   # guarantee a byte-identical restore
./script/zsh-verify.sh parity; echo "exit=$?"
```

Expected: `PARITY OK` for both modes, `exit=0`.

- [ ] **Step 6: Capture the authoritative baseline**

```bash
mise run zsh:baseline
mise run zsh:bench | tee /tmp/zsh-verify/baseline-bench.txt
```

Record the seven mean timings. These are the numbers every later task compares against. For reference, the values measured during design were: `zsh -c` 4.8 ms, `-lic` plain 101.5 ms, ghostty 101.9 ms, vscode 181.3 ms, vscode+inject 183.6 ms, warp 7.9 ms.

- [ ] **Step 7: Commit**

```bash
git add script/zsh-verify.sh mise.toml
git commit -m "test(zsh): Add startup parity and benchmark harness

Captures options, env, aliases, functions, widgets, bindkeys, path,
fpath and hooks from a cold environment for -lic and -ic, and runs a
hyperfine matrix across terminal contexts. Gates the ZSH/ZIM restructure.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 2: Phase A.1 — move tool environment into `.zshenv`

Native zsh reads `.zprofile` only for login shells. Before removing `NO_RCS` (Task 3), the pure environment must move, or non-login interactive shells lose 43 variables.

**Files:**
- Modify: `config/zsh/.zshenv`, `config/zsh/.zprofile`

- [ ] **Step 1: Move the tool-environment blocks**

Cut from `config/zsh/.zprofile` everything from the line `# LESS {` through the end of the `# PUPPETEER ... # }` block — that is, every block above the line `term_prog=${(L)TERM_PROGRAM}` — **except** the `GPG_TTY` line, which is handled in Step 2.

Paste the cut blocks into `config/zsh/.zshenv`, immediately before the `# Load XDG environment variables from .profile` comment, under this header:

```zsh
## 📦 TOOL ENVIRONMENT {
# Pure environment: no output, no tty access, no subprocesses.
# Lives here (not .zprofile) so non-login shells inherit it too.
```

Close it with `# }` after the pasted content.

The blocks to move are: LESS, MISE, STARSHIP, GNUPG (minus `GPG_TTY`), NPM, RUBY, CARGO, PNPM, JQ, RIPGREP, BAT, GLOW, GOPASS, GITLINT, WAKATIME, GO, PUPPETEER.

- [ ] **Step 2: Relocate `GPG_TTY` to `.zshrc`**

`GPG_TTY` runs `$(tty)`, a subprocess, and is only useful when a human is present for a gpg pinentry prompt. It belongs in `.zshrc` (interactive), not `.zshenv` (every shell, including `zsh -c`) and not `.zprofile` (login only, which would skip `zsh -ic`).

Delete this line from `config/zsh/.zprofile`:

```zsh
  export GPG_TTY=${GPG_TTY:-"$(tty)"}
```

Add to `config/zsh/.zshrc`, immediately after the `# SHELL {` block's closing `# }`:

```zsh
# GNUPG TTY {
  # gpg pinentry needs the controlling terminal. Interactive shells only:
  # $(tty) is a subprocess and is meaningless without a terminal.
  [[ -t 0 ]] && export GPG_TTY=${GPG_TTY:-"$(tty)"}
# }
```

This is a deliberate deviation from the spec, which placed `GPG_TTY` in `.zprofile`. Recorded in Deviations below.

- [ ] **Step 3: Check syntax**

```bash
./script/zsh-verify.sh syntax
```

Expected: `syntax OK` for all six files.

- [ ] **Step 4: Verify parity**

```bash
./script/zsh-verify.sh parity; echo "exit=$?"
```

Expected: `PARITY OK` for both `-lic` and `-ic`, `exit=0`.

Nothing has changed semantically yet — `.zshenv` still hand-sources `.zprofile`, so both files still run in both modes. A diff here means content was lost or duplicated during the move. If `-lic` shows `orig-SESSION-orig-SESSION-` entries, a file is being sourced twice.

- [ ] **Step 5: Commit**

```bash
git add config/zsh/.zshenv config/zsh/.zprofile config/zsh/.zshrc
git commit -m "ref(zsh): Move tool environment from .zprofile to .zshenv

Pure environment exports belong in .zshenv so non-login shells inherit
them. GPG_TTY moves to .zshrc instead: it spawns \$(tty) and is only
useful when a human is present.

Prepares removal of NO_RCS.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 3: Phase A.2 — restore the native startup chain

**Files:**
- Modify: `config/zsh/.zshenv`, `config/zsh/.zprofile`

- [ ] **Step 1: Remove `NO_RCS` and the dead exports**

In `config/zsh/.zshenv`, replace this block:

```zsh
## 🔒 PREVENT SYSTEM-WIDE RCS FILES FROM BEING SOURCED {
# 💡 compinit override removed; NO_RCS prevents system-wide files from loading
# It ensures only our user config is loaded, preventing compinit conflicts
setopt NO_RCS
setopt NO_MAILWARN
setopt NO_MAILWARNING
setopt NO_GLOBAL_RCS
# }
```

with:

```zsh
## 🔒 PREVENT SYSTEM-WIDE RCS FILES FROM BEING SOURCED {
# NO_GLOBAL_RCS blocks /etc/zprofile, /etc/zshrc and /etc/zlogin without
# blocking our own files. NO_RCS would additionally suppress .zprofile,
# .zshrc, .zlogin and .zlogout, which is why they used to be hand-sourced.
setopt NO_GLOBAL_RCS
# NO_MAILWARN and NO_MAILWARNING are aliases of the same option; set once
# in .zshrc alongside the other interactive options.
# }
```

In the block above it, delete these two lines — neither is read by anything, and `NO_GLOBAL_RCS` is a shell option, not an environment variable:

```zsh
export NO_GLOBAL_RCS=1
export ZIM_DISABLE_AUTOLOAD=1
```

- [ ] **Step 2: Remove the manual `.zprofile` sourcing**

Delete this block from the end of `config/zsh/.zshenv`:

```zsh
# if .zprofile exists, source it (after XDG setup so ZDOTDIR is available)
# Skip when non-interactive (e.g. `git branches` runs `zsh git-branches`) to avoid loading
# .zshrc/starship/ZIM in subprocesses — prevents flicker and keeps alias fast
if [[ (-o login || -o interactive) && $TERM_PROGRAM != "WarpTerminal" && -r "$ZDOTDIR/.zprofile" ]]; then
  source "$ZDOTDIR/.zprofile"
fi
```

- [ ] **Step 3: Remove the manual `.zshrc` sourcing**

Delete this block from the end of `config/zsh/.zprofile`:

```zsh
# if .zshrc exists, source it
if [[ $TERM_PROGRAM != "WarpTerminal" && -r "$ZDOTDIR/.zshrc" ]]; then
  source "$ZDOTDIR/.zshrc"
fi
```

The Warp guards disappear here. Warp is handled in Task 5 by `ZSH_MINIMAL_TERMINAL`, which skips the conflicting plugins rather than skipping the entire configuration.

- [ ] **Step 4: Confirm the chain fires correctly**

```bash
for f in .zshenv .zprofile .zshrc .zlogin; do
  printf '\nprint -u2 "MARK %s"\n' "$f" >> "$HOME/.config/zsh/$f"
done
/opt/homebrew/bin/zsh -lic exit 2>&1 | grep MARK
echo "--- non-login interactive ---"
/opt/homebrew/bin/zsh -ic exit 2>&1 | grep MARK
echo "--- non-interactive ---"
/opt/homebrew/bin/zsh -c exit 2>&1 | grep MARK || echo "(zshenv only, silent)"
for f in .zshenv .zprofile .zshrc .zlogin; do
  sed -i '' '/^print -u2 "MARK /d' "$HOME/.config/zsh/$f"
done
```

Expected:
- `-lic`: `MARK .zshenv`, `MARK .zprofile`, `MARK .zshrc`, `MARK .zlogin` — each exactly once
- `-ic`: `MARK .zshenv`, `MARK .zshrc`
- `-c`: `(zshenv only, silent)`

A repeated MARK means double-sourcing. Stop and fix before continuing.

- [ ] **Step 5: Verify parity**

```bash
./script/zsh-verify.sh syntax
./script/zsh-verify.sh parity; echo "exit=$?"
```

Expected — exactly these diffs and nothing else:
- `-lic`: one removed line, `norcs`
- `-ic`: two removed lines, `norcs` and `GPG_TTY`

`GPG_TTY` is absent from `-ic` because Task 2 Step 2 gated it on `[[ -t 0 ]]`, and the harness runs without a terminal. Confirm it still works interactively:

```bash
/opt/homebrew/bin/zsh -lic 'echo GPG_TTY=$GPG_TTY'
```

Expected: a real tty path such as `/dev/ttys004`, not empty.

- [ ] **Step 6: Benchmark**

```bash
mise run zsh:bench
```

Expected against the Task 1 baseline: interactive contexts unchanged within noise; `zsh -c` up roughly 1 ms (4.8 → ~5.9 ms) from the environment move. Any interactive context more than ~5 ms slower is a regression — stop and investigate.

- [ ] **Step 7: Commit**

```bash
git add config/zsh/.zshenv config/zsh/.zprofile
git commit -m "fix(zsh): Restore native zsh startup chain

setopt NO_RCS suppressed .zprofile, .zshrc, .zlogin and .zlogout, which
is why they were hand-sourced from .zshenv with duplicated guards. Switch
to NO_GLOBAL_RCS, which blocks /etc/* only, and drop the manual sourcing.

.zlogin and .zlogout now execute. Also removes two exports that nothing
reads (NO_GLOBAL_RCS, ZIM_DISABLE_AUTOLOAD).

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 4: Phase A.3 — audit the newly live `.zlogin` and `.zlogout`

These have not executed since `NO_RCS` was introduced. Task 3 brought them back to life; confirm their contents are safe.

**Files:**
- Modify (if needed): `config/zsh/.zlogin`, `config/zsh/.zlogout`

- [ ] **Step 1: Inspect both files**

```bash
cat -A config/zsh/.zlogin
cat -A config/zsh/.zlogout
```

Expected at time of writing: both contain only a shebang and comments. If that still holds, no change is needed — proceed to Step 3.

- [ ] **Step 2: Handle any active content**

If either file contains executable statements, evaluate each one: it has not run in the lifetime of the current setup, so it is unverified. Move anything still wanted into `.zshrc` (interactive) or `.zprofile` (login), and leave the file comment-only. Do not leave unverified code to run on every login.

- [ ] **Step 3: Fix the misleading `.zlogout` comment**

`config/zsh/.zlogout` currently says it is sourced "BEFORE `.zshrc`", which is wrong. Replace its comment block with:

```zsh
#!/usr/bin/env zsh

# ~/.zlogout
# Sourced when a login shell exits - AFTER all other startup files
# http://zsh.sourceforge.net/Intro/intro_3.html
```

- [ ] **Step 4: Verify**

```bash
./script/zsh-verify.sh syntax
./script/zsh-verify.sh parity; echo "exit=$?"
```

Expected: same two diffs as Task 3 Step 5 (`norcs`; `norcs` + `GPG_TTY`). The harness does not exercise logout, so a clean run here means nothing was broken.

- [ ] **Step 5: Confirm logout runs without error**

```bash
/opt/homebrew/bin/zsh -lic exit; echo "exit=$?"
```

Expected: `exit=0`, no error output.

- [ ] **Step 6: Commit**

```bash
git add config/zsh/.zlogin config/zsh/.zlogout
git commit -m "docs(zsh): Correct .zlogout comment and audit login files

.zlogin and .zlogout execute again now that NO_RCS is gone. .zlogout
claimed it was sourced before .zshrc; it runs when a login shell exits.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 5: Phase B — single terminal-profile block

Replaces detection at `.zshenv` (removed in Task 3), `.zprofile:139-151`, `.zshrc:292-301` and `.zshrc:388-396`.

**Files:**
- Modify: `config/zsh/.zprofile`, `config/zsh/.zshrc`

- [ ] **Step 1: Remove the detection block from `.zprofile`**

Delete from `config/zsh/.zprofile`:

```zsh
term_prog=${(L)TERM_PROGRAM}
if [[ -n "$ZSH_MINIMAL_TERMINAL" || "$term_prog" == "warp" || "$term_prog" == "warpterminal" || "$term_prog" == "vscode" || "$term_prog" == "vscode-insider" || -n "$VSCODE_INJECTION" || -n "$VSCODE_IPC_HOOK_CLI" || -n "$VSCODE_GIT_IPC_HANDLE" ]]; then
  export ZSH_MINIMAL_TERMINAL=1
  if [[ "$term_prog" == "vscode" || "$term_prog" == "vscode-insider" ]]; then
    # IDEs work better with shims than they do environment variable modifications. The simplest way is to add the mise shim directory to PATH.
    # https://mise.jdx.dev/ide-integration.html#adding-shims-to-path-default-shell
    eval "$(mise activate zsh --shims)"
  fi
else
  unset ZSH_MINIMAL_TERMINAL
fi

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
```

The `mise activate --shims` line goes away entirely: ZIM's `zim-mise` module already activates mise via `_mise_hook_precmd`, so VSCode was activating it twice. The `kiro` line moves to the new block in Step 3.

`.zprofile` now holds no active statements. Leave it in place with its header comment — it is the documented hook point for future login-only setup.

- [ ] **Step 2: Remove the old TERM block from `.zshrc`**

Delete from `config/zsh/.zshrc`:

```zsh
# TERM {
  if [ "$TERM_PROGRAM" = "ghostty" ]; then
    if [[ -e GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration" ]]; then
      source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
    elif [[ -e /Applications/Ghostty.app/Contents/Resources/ghostty/shell-integration/zsh/ghostty-integration ]]; then
      source /Applications/Ghostty.app/Contents/Resources/ghostty/shell-integration/zsh/ghostty-integration
    fi
    export SNACKS_GHOSTTY=true
  elif [[ "$TERM_PROGRAM" == "vscode" ]] && _has_command code; then
    source "$(code --locate-shell-integration-path zsh)"
  fi
  export TERM="${TERM:-xterm-256color}"
# }
```

- [ ] **Step 3: Add the terminal-profile block**

Insert into `config/zsh/.zshrc` immediately before the `# ZIM | https://zimfw.sh {` line. It must precede ZIM because `init.zsh` evaluates `[[ -z "$ZSH_MINIMAL_TERMINAL" ]]` at runtime.

The VSCode integration is intentionally left as a bare `:` placeholder here and filled in by Task 6, so the two changes can be verified separately.

```zsh
# TERMINAL PROFILE {
  # Single source of truth for terminal detection. Everything downstream
  # (ZIM module conditions, prompt, shell integration) reads from here.
  #
  # ZSH_MINIMAL_TERMINAL marks a terminal that provides its own prompt,
  # syntax highlighting and suggestions, and therefore conflicts with ours.
  # It is NOT a general "IDE" flag: VS Code has none of those and gets the
  # full experience. Set it yourself to force any terminal down.
  export TERM="${TERM:-xterm-256color}"
  typeset -g _zsh_term=${(L)TERM_PROGRAM}

  if [[ -n "$ZSH_MINIMAL_TERMINAL" || "$_zsh_term" == warp(|terminal) ]]; then
    export ZSH_MINIMAL_TERMINAL=1
  else
    unset ZSH_MINIMAL_TERMINAL
  fi

  case "$_zsh_term" in
    ghostty)
      for _zsh_ghostty in \
        "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration" \
        /Applications/Ghostty.app/Contents/Resources/ghostty/shell-integration/zsh/ghostty-integration
      do
        if [[ -r "$_zsh_ghostty" ]]; then source "$_zsh_ghostty"; break; fi
      done
      unset _zsh_ghostty
      export SNACKS_GHOSTTY=true
      ;;
    vscode|vscode-insider)
      : # shell integration wired up in the next task
      ;;
    kiro)
      _has_command kiro && source "$(kiro --locate-shell-integration-path zsh)"
      ;;
  esac
  unset _zsh_term
# }
```

Note: `warp(|terminal)` matches both `warp` and `warpterminal`. Alternation groups are plain
zsh pattern syntax and need no `extended_glob`; verified with
`zsh -fc '[[ warpterminal == warp(|terminal) ]]'`.

The `$GHOSTTY_RESOURCES_DIR` path is now correctly expanded, fixing the missing `$` (spec F7b). If the variable is unset the path simply fails `-r` and the loop falls through to the absolute path.

- [ ] **Step 4: Remove the final prompt guard**

Delete from the end of `config/zsh/.zshrc`:

```zsh
# FINAL PROMPT GUARD
# Keep VS Code/Warp terminals on a plain prompt even if prior hooks injected prompt code.
if [[ -n "$ZSH_MINIMAL_TERMINAL" ]]; then
  export _FLOX_SET_PROMPT=false
  setopt prompt_subst
  PROMPT='❯ '
  RPROMPT=''
  PS1="$PROMPT"
fi
```

This is replaced in Task 7 by an equivalent block that no longer exports `PROMPT`.

- [ ] **Step 5: Verify Warp still gets the minimal treatment**

```bash
env TERM_PROGRAM=WarpTerminal /opt/homebrew/bin/zsh -lic \
  'echo "minimal=${ZSH_MINIMAL_TERMINAL:-unset}"; echo "starship=${+functions[starship_precmd]}"'
env TERM_PROGRAM=vscode /opt/homebrew/bin/zsh -lic \
  'echo "minimal=${ZSH_MINIMAL_TERMINAL:-unset}"; echo "starship=${+functions[starship_precmd]}"'
```

Expected:
- Warp: `minimal=1`, `starship=0`
- VSCode: `minimal=unset`, `starship=1`

- [ ] **Step 6: Verify parity**

```bash
./script/zsh-verify.sh syntax
./script/zsh-verify.sh parity; echo "exit=$?"
```

The harness runs without `TERM_PROGRAM`, so the plain-terminal path is unaffected. Expected: the same two diffs as Task 3 Step 5 (`norcs`; `norcs` + `GPG_TTY`), plus removal of `_FLOX_SET_PROMPT` if it appears in the `ENV` section.

- [ ] **Step 7: Benchmark**

```bash
mise run zsh:bench
```

Expected: `warp` rises substantially — from ~7.9 ms to roughly plain-terminal minus the skipped plugins (~90 ms) — because Warp no longer skips the entire configuration, only the four conflicting plugins. This is intended: Warp previously got no aliases, functions or completions at all. VSCode is still ~181 ms; Task 6 addresses it.

- [ ] **Step 8: Commit**

```bash
git add config/zsh/.zprofile config/zsh/.zshrc
git commit -m "ref(zsh): Consolidate terminal detection into one block

Terminal logic lived in five places: .zshenv, .zprofile, two blocks in
.zshrc, and .zimrc conditions. Collapse to a single block in .zshrc
before the ZIM source, which is where the runtime conditions are read.

ZSH_MINIMAL_TERMINAL now means 'terminal supplies its own prompt,
highlighting and suggestions' and applies to Warp only. VS Code gets the
full experience. Fixes the missing \$ on GHOSTTY_RESOURCES_DIR and drops
the duplicate mise --shims activation.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 6: Phase C — stop shelling out to the VSCode CLI

`code --locate-shell-integration-path zsh` costs 78.0 ms ± 1.0 on every VSCode shell start and returns a constant path.

**Files:**
- Modify: `config/zsh/.zshrc`

- [ ] **Step 1: Replace the placeholder**

In the `TERMINAL PROFILE` block added in Task 5, replace:

```zsh
    vscode|vscode-insider)
      : # shell integration wired up in the next task
      ;;
```

with:

```zsh
    vscode|vscode-insider)
      # VSCODE_INJECTION=1 means VS Code already sourced its integration
      # (shellIntegration-rc.zsh branches on it), so there is nothing to do.
      if [[ "$VSCODE_INJECTION" != 1 ]] && _has_command code; then
        # `code --locate-shell-integration-path zsh` boots the Electron CLI
        # (~78ms) to return a constant path. Cache it against the app bundle.
        typeset -g _zsh_vsc_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/vscode-shell-integration"
        typeset -g _zsh_vsc_path=''
        [[ -r "$_zsh_vsc_cache" ]] && _zsh_vsc_path="$(<"$_zsh_vsc_cache")"
        if [[ ! -r "$_zsh_vsc_path" ]]; then
          _zsh_vsc_path="$(code --locate-shell-integration-path zsh 2>/dev/null)"
          if [[ -r "$_zsh_vsc_path" ]]; then
            mkdir -p "${_zsh_vsc_cache:h}"
            print -r -- "$_zsh_vsc_path" > "$_zsh_vsc_cache"
          fi
        fi
        [[ -r "$_zsh_vsc_path" ]] && source "$_zsh_vsc_path"
        unset _zsh_vsc_cache _zsh_vsc_path
      fi
      ;;
```

Cache invalidation is by existence: a VSCode upgrade that moves or removes the path fails the `-r` test, triggers a fresh lookup and rewrites the cache. Within a major version the path is stable, so the common case never spawns the CLI.

- [ ] **Step 2: Clear any stale cache and prime it**

```bash
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/vscode-shell-integration"
env TERM_PROGRAM=vscode /opt/homebrew/bin/zsh -lic exit
cat "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/vscode-shell-integration"
```

Expected: the cache file contains a path ending in
`.../vs/workbench/contrib/terminal/common/scripts/shellIntegration-rc.zsh`.

- [ ] **Step 3: Verify the integration actually loads**

```bash
env TERM_PROGRAM=vscode /opt/homebrew/bin/zsh -lic \
  'print -l $precmd_functions | grep -c __vsc_precmd'
env TERM_PROGRAM=vscode VSCODE_INJECTION=1 /opt/homebrew/bin/zsh -lic \
  'echo "injected path skips manual source: ok"'
```

Expected: `1` from the first command — VSCode's precmd hook is registered. The second prints its message without delay.

- [ ] **Step 4: Verify parity**

```bash
./script/zsh-verify.sh syntax
./script/zsh-verify.sh parity; echo "exit=$?"
```

Expected: unchanged from Task 5 Step 6. The harness runs without `TERM_PROGRAM`, so this path is not exercised — it confirms no collateral damage.

- [ ] **Step 5: Benchmark — the headline gate**

```bash
mise run zsh:bench
```

Expected: `vscode` drops from ~181 ms to roughly **115 ms**, and `vscode+inject` to roughly **114 ms**. Both should now sit slightly above `plain` (~101 ms).

If VSCode is still above ~140 ms, the cache is not being hit — check that the cache file exists and is readable, and that `_has_command code` succeeds.

Record the actual figures; they are reported in Task 10.

- [ ] **Step 6: Commit**

```bash
git add config/zsh/.zshrc
git commit -m "perf(zsh): Stop booting the VS Code CLI on every shell start

code --locate-shell-integration-path costs ~78ms and returns a constant
path. Skip it entirely when VSCODE_INJECTION=1 (VS Code has already
sourced the integration), otherwise read the path from a cache keyed on
readability, falling back to the real lookup.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 7: Phase D — post-ZIM override block

ZIM's `environment` module sets `NO_CLOBBER`; its `completion` module overwrites much of `.zshrc:191-229`. Settings that must win have to run after `init.zsh`.

**Files:**
- Modify: `config/zsh/.zshrc`, `config/zsh/.zimrc`

- [ ] **Step 1: Move the `dumpfile` zstyle to where it is read**

Delete from `config/zsh/.zimrc`:

```zsh
zstyle ':zim:completion' dumpfile "$zdumpfile" # Enables and configures smart and extensive tab completion.
```

`.zimrc` executes only when ZIM rebuilds `init.zsh`, so this style was never set at runtime and ZIM fell back to `${ZDOTDIR}/.zcompdump` — writing compdumps into the git working tree.

Add to `config/zsh/.zshrc` immediately before the `# ZIM | https://zimfw.sh {` line:

```zsh
# ZIM COMPLETION DUMP {
  # Read at runtime by ZIM's completion module, so it must be set here and
  # not in .zimrc (which only executes when ZIM rebuilds init.zsh).
  zstyle ':zim:completion' dumpfile "${zdumpfile:-${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache/.zcompdump}"
# }
```

- [ ] **Step 2: Delete the completion styles ZIM overwrites**

From the `ZSH COMPLETIONS SETTINGS` block in `config/zsh/.zshrc`, delete these five lines. Three are overwritten by ZIM, one is dead on arrival, and one duplicates a ZIM default:

```zsh
  zstyle ':completion:*' menu select=2                                                                         # Menu select
  zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'                                                    # Case insensitive tab completion
  zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'                # Case senstive correction and complete partial words
  zstyle ':completion:*' squeeze-slashes no                                                                    # Don't squeeze slashes
  zstyle ':completion:*' verbose true                                                                          # Verbose completion
```

The first `matcher-list` was already dead — the second overrode it before ZIM was reached.

- [ ] **Step 3: Add the post-ZIM override block**

Insert into `config/zsh/.zshrc` immediately **after** the ZIM block's closing `# }` (the one following `source $ZIM_HOME/init.zsh`):

```zsh
# POST-ZIM OVERRIDES {
  # ZIM's modules set options and completion styles as they load. Anything
  # we want to outrank them must run here, after init.zsh. Keep this block
  # as the single place where ZIM defaults are overridden.

  # ZIM's environment module sets NO_CLOBBER. It breaks `>` over an existing
  # file for every script and tool that assumes zsh's default, including
  # Claude Code. Scripts wanting protection opt in with `set -o noclobber`.
  setopt CLOBBER

  # Set once here; .zshenv previously set the same option three times.
  setopt no_mail_warning

  # Completion styles ZIM's completion module would otherwise win.
  zstyle ':completion:*' menu select=2
  zstyle ':completion:*' squeeze-slashes no
  zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

  # zim-starship sets this to 1; we want the right prompt flush to the edge.
  export ZLE_RPROMPT_INDENT=0

  # Terminals that draw their own prompt get a plain one. PROMPT is
  # deliberately NOT exported: zim-starship assigns a command substitution
  # into it, which would then leak into every child process.
  if [[ -n "$ZSH_MINIMAL_TERMINAL" ]]; then
    export _FLOX_SET_PROMPT=false
    setopt prompt_subst
    PROMPT='❯ '
    RPROMPT=''
    PS1="$PROMPT"
  fi
# }
```

- [ ] **Step 4: Verify the overrides actually win**

```bash
/opt/homebrew/bin/zsh -lic '
  setopt | grep -q "^noclobber$" && echo "FAIL: noclobber still set" || echo "OK: clobber restored"
  zstyle -L ":completion:*" squeeze-slashes
  zstyle -L ":completion:*" menu
  echo "ZLE_RPROMPT_INDENT=$ZLE_RPROMPT_INDENT"
' 2>&1 | grep -v "can't change option"
```

Expected:
- `OK: clobber restored`
- `zstyle ':completion:*' squeeze-slashes no`
- a `menu select=2` line
- `ZLE_RPROMPT_INDENT=0`

- [ ] **Step 5: Verify the reported bug is actually fixed**

```bash
/opt/homebrew/bin/zsh -lic '
  t=$(mktemp); echo one > $t && echo "first write ok"
  echo two > $t 2>&1 && echo "SECOND WRITE OK - noclobber fixed" || echo "FAIL: still blocked"
  rm -f $t
' 2>&1 | grep -v "can't change option"
```

Expected: `first write ok`, then `SECOND WRITE OK - noclobber fixed`.

- [ ] **Step 6: Confirm `PROMPT` no longer leaks**

```bash
/opt/homebrew/bin/zsh -lic 'export | grep -c "^PROMPT="' 2>&1 | grep -v "can't change"
```

Expected: `0`. Before this task it was `1`, carrying the full starship command substitution into every child process.

If it still reports `1`, `export PROMPT='❯ '` at `.zshrc:233` is still present — change it to `PROMPT='❯ '`.

- [ ] **Step 7: Verify parity**

```bash
./script/zsh-verify.sh syntax
./script/zsh-verify.sh parity; echo "exit=$?"
```

Expected diffs, in addition to the carried-over `norcs` / `GPG_TTY`:
- `-noclobber` (the fix)
- `-PROMPT` from the `ENV` section (no longer exported)

Anything else — particularly missing functions, widgets or `fpath` entries — is a regression.

- [ ] **Step 8: Confirm compdumps stopped churning in the repo**

```bash
rm -f config/zsh/.zcompdump*
/opt/homebrew/bin/zsh -lic exit
ls config/zsh/.zcompdump* 2>/dev/null && echo "FAIL: still written to repo" || echo "OK: repo clean"
ls -la "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache/.zcompdump"
```

Expected: `OK: repo clean`, and a fresh `.zcompdump` under the cache directory.

- [ ] **Step 9: Commit**

```bash
git add config/zsh/.zshrc config/zsh/.zimrc
git commit -m "fix(zsh): Add post-ZIM override block and restore CLOBBER

ZIM's environment module sets NO_CLOBBER, breaking '>' over an existing
file for Claude Code and any script assuming zsh defaults. Its completion
module also overwrote squeeze-slashes, menu and matcher-list, and
zim-starship overwrote ZLE_RPROMPT_INDENT.

Collect every ZIM override in one block after init.zsh. Move the
:zim:completion dumpfile style out of .zimrc, which only runs at rebuild
time, so compdumps stop landing in the working tree. Stop exporting
PROMPT, which leaked starship's command substitution to child processes.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 8: Phase E.1 — remove dead references

`config/zsh/etc/` was deleted in commit `56e9b9d` but is still referenced.

**Files:**
- Modify: `config/zsh/.zimrc`, `config/.profile`

- [ ] **Step 1: Confirm the directory is still absent**

```bash
ls -d config/zsh/etc 2>/dev/null && echo "EXISTS - stop, re-evaluate" || echo "absent, proceed"
```

Expected: `absent, proceed`. If it exists, someone recreated it; stop and ask before deleting references to a live path.

- [ ] **Step 2: Remove the dead guards from `.zimrc`**

Replace this block in `config/zsh/.zimrc`:

```zsh
# Zsh functions (guarded if non-empty)
if [[ -d "$HOME/.config/zsh/etc/functions" ]] && [[ -n "$(/bin/ls -A "$HOME/.config/zsh/etc/functions" 2>/dev/null)" ]]; then
  zmodule $HOME/.config/zsh/etc --fpath functions
fi
# Skip completion module if compinit was already initialized (e.g., by Flox)
if ! (( ${+functions[_main_complete]} )); then
  zmodule completion
fi
# Ensure that any other plugins that use compdef are loaded after zmodule completion.
if [[ -d "$HOME/.config/zsh/etc/functions" ]] && [[ -n "$(/bin/ls -A "$HOME/.config/zsh/etc/functions" 2>/dev/null)" ]]; then
  zmodule $HOME/.config/zsh/etc --autoload "$(/bin/ls $HOME/.config/zsh/etc/functions | tr '\n' ' ')"
fi
```

with:

```zsh
# Skip completion module if compinit was already initialized (e.g., by Flox)
if ! (( ${+functions[_main_complete]} )); then
  zmodule completion
fi
```

- [ ] **Step 3: Remove the dead exports from `config/.profile`**

Delete these two lines. `ZDOTDIR_ETC` points at the removed directory; `ZDOTDIR_OPT` is read by nothing (`opt/` is referenced by literal path in `.zimrc`):

```sh
export ZDOTDIR_ETC=$HOME/.config/zsh/etc
export ZDOTDIR_OPT=$HOME/.config/zsh/opt
```

- [ ] **Step 4: Rebuild ZIM and verify the module set is unchanged**

```bash
cp ~/.local/state/zim/init.zsh /tmp/init.zsh.before
/opt/homebrew/bin/zsh -lic 'zimfw build' 2>&1 | tail -3
diff /tmp/init.zsh.before ~/.local/state/zim/init.zsh && echo "IDENTICAL: no module changed"
```

Expected: `IDENTICAL`. The removed guards never fired, so the generated output must not change.

- [ ] **Step 5: Verify parity**

```bash
./script/zsh-verify.sh syntax
./script/zsh-verify.sh parity; echo "exit=$?"
```

Expected diffs: the carried-over set from Task 7, plus removal of `ZDOTDIR_ETC` and `ZDOTDIR_OPT` from the `ENV` section.

- [ ] **Step 6: Commit**

```bash
git add config/zsh/.zimrc config/.profile
git commit -m "ref(zsh): Remove references to the deleted etc/ directory

config/zsh/etc/ was removed in 56e9b9d, but .zimrc still guarded on it
(spawning /bin/ls at build time) and .profile still exported ZDOTDIR_ETC.
ZDOTDIR_OPT is likewise read by nothing.

Verified zimfw build produces a byte-identical init.zsh.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 9: Phase E.2 — latent bug fixes

**Files:**
- Modify: `config/zsh/.zshrc`, `config/zsh/opt/aliases/ls.zsh`

- [ ] **Step 1: Make `_has_command` accept multiple commands**

`_has_command sops age` currently checks only `sops`. Replace in `config/zsh/.zshrc`:

```zsh
  _has_command() {
    command -v "$1" >/dev/null 2>&1
  }
```

with:

```zsh
  # True only when every named command exists.
  _has_command() {
    local _c
    for _c in "$@"; do
      command -v "$_c" >/dev/null 2>&1 || return 1
    done
    return 0
  }
```

- [ ] **Step 2: Verify the fix**

```bash
/opt/homebrew/bin/zsh -lic '
  _has_command zsh && echo "single: ok"
  _has_command zsh definitely-not-real-xyz && echo "FAIL: bogus accepted" || echo "multi: correctly rejected"
' 2>&1 | grep -v "can.t change"
```

Expected: `single: ok`, `multi: correctly rejected`.

This makes the `sops`/`age` guard at `.zshrc:328` behave as written — previously only `sops`
was checked. Both binaries were confirmed present when this plan was written
(`/opt/homebrew/bin/age`, `/opt/homebrew/bin/sops`), so `$HOME/.config/.env` keeps loading.
Re-confirm before relying on it:

```bash
command -v age sops || echo "WARNING: missing - .env will now be skipped (previously sourced)"
```

- [ ] **Step 3: Fix the self-referential `ls` aliases**

In `config/zsh/opt/aliases/ls.zsh`, replace these three lines:

```zsh
  alias lal='lal -Sa@ --color-scale'                                                            # List all files in columns (extended)
  alias lax='lla --sort=Extension'                                                               # Lists sorted by extension (GNU only).
  alias lls='lla --sort=size -r'                                                                 # Lists sorted by size, largest last.
```

with:

```zsh
  alias lal='la -Sa@ --color-scale'                                                             # List all files in columns (extended)
  alias lax='la --sort=extension'                                                                # Lists sorted by extension
  alias lls='la --sort=size -r'                                                                  # Lists sorted by size, largest last
```

`lal` referenced itself, and `lax`/`lls` referenced `lla`, which is not defined anywhere. All three now build on `la`, which is defined directly above them. Note `eza` expects a lowercase `--sort=extension`.

- [ ] **Step 4: Verify the aliases resolve**

```bash
/opt/homebrew/bin/zsh -lic 'for a in lal lax lls la; do printf "%-5s " $a; alias $a; done' 2>&1 | grep -v "can.t change"
env ZDOTDIR=$HOME/.config/zsh /opt/homebrew/bin/zsh -lic 'lal >/dev/null && echo "lal runs"; lax >/dev/null && echo "lax runs"; lls >/dev/null && echo "lls runs"' 2>&1 | grep -v "can.t change"
```

Expected: all four aliases print a definition, and all three commands run without `command not found`.

- [ ] **Step 5: Remove the duplicated mail-warning options**

In `config/zsh/.zshrc`, delete these three lines from the `INPUT OUTPUT` block — the option is now set once in the post-ZIM block from Task 7:

```zsh
  # [SET BY ZIM!!] Reduces notification noise | Do not print a warning message if a mail file has been accessed => `mail` will not print a warning message if a mail file has been accessed
  setopt no_mail_warning
  setopt no_mailwarn
  setopt no_mailwarning
```

- [ ] **Step 6: Fix the misleading `transient_rprompt` comment**

In `config/zsh/.zshrc`, the `PROMPTING` block carries a copy-pasted mail-warning comment. Replace:

```zsh
  setopt transient_rprompt # Reduces notification noise | Do not print a warning message if a mail file has been accessed => `mail` will not print a warning message if a mail file has been accessed
```

with:

```zsh
  setopt transient_rprompt # Remove the right prompt from previous lines, keeping scrollback clean when copying commands
```

- [ ] **Step 7: Verify parity**

```bash
./script/zsh-verify.sh syntax
./script/zsh-verify.sh parity; echo "exit=$?"
```

Expected: the carried-over diffs from Task 8 and nothing new. `nomailwarning` must still be present in `OPTIONS` — it moved, it did not disappear.

- [ ] **Step 8: Commit**

```bash
git add config/zsh/.zshrc config/zsh/opt/aliases/ls.zsh
git commit -m "fix(zsh): Correct _has_command arity and self-referential aliases

_has_command tested only \$1, so '_has_command sops age' never checked
age. lal referenced itself and lax/lls referenced an undefined lla.
Also collapses the mail-warning option, previously set five times, and
corrects a copy-pasted comment on transient_rprompt.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 10: Final measurement and report

**Files:**
- Modify: `docs/superpowers/specs/2026-09-17-zsh-zim-restructure-design.md`

- [ ] **Step 1: Full verification**

```bash
./script/zsh-verify.sh syntax
./script/zsh-verify.sh parity; echo "parity exit=$?"
mise run zsh:bench | tee /tmp/zsh-verify/final-bench.txt
```

- [ ] **Step 2: Review the complete parity diff**

```bash
cat /tmp/zsh-verify/lic.diff
cat /tmp/zsh-verify/ic.diff
```

Every line must be explainable by the list below. Anything else is a regression to fix before finishing.

| Change | Origin |
| --- | --- |
| `-norcs` | Task 3 |
| `-noclobber` | Task 7 |
| `-PROMPT` (ENV) | Task 7 |
| `-GPG_TTY` (`-ic` only) | Task 2 |
| `-ZDOTDIR_ETC`, `-ZDOTDIR_OPT` | Task 8 |
| `-_FLOX_SET_PROMPT` (if present) | Task 5 |

- [ ] **Step 3: Interactive smoke test**

Automation cannot confirm rendering. Open each terminal and check by hand.

In **VSCode** and **ghostty**:
1. Prompt renders with starship.
2. Type `ech` — an autosuggestion appears in grey.
3. Type `echo foo` — `echo` is highlighted as a command.
4. Press Up — history substring search recalls a matching entry.
5. Press Tab after `cd ` — fzf-tab menu appears.
6. Run `t=$(mktemp); echo a > $t; echo b > $t; echo $?` — prints `0`.

In **Warp**:
1. Warp's own prompt renders; starship does not fight it.
2. Aliases work: `ll` produces output.
3. Completions work: `git che<Tab>` completes.

- [ ] **Step 4: Record the real numbers in the spec**

Replace the "Projected VSCode result" paragraph in the spec's Verification section with the measured results. Report what was measured, including any target that was missed. Use this shape:

```markdown
### Measured result (post-implementation)

| Context | Before | After | Change |
| --- | --- | --- | --- |
| `zsh -c` | 4.8 ms | <actual> | <delta> |
| `zsh -lic` plain | 101.5 ms | <actual> | <delta> |
| `zsh -lic` ghostty | 101.9 ms | <actual> | <delta> |
| `zsh -lic` vscode | 181.3 ms | <actual> | <delta> |
| `zsh -lic` vscode+inject | 183.6 ms | <actual> | <delta> |
| `zsh -lic` warp | 7.9 ms | <actual> | <delta> |

Notes: Warp rose deliberately — it previously skipped the entire
configuration and now loads everything except the four conflicting
plugins. <Record whether the ~115 ms VSCode projection held, and if not,
the actual figure and the reason.>
```

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/specs/2026-09-17-zsh-zim-restructure-design.md
git commit -m "docs(zsh): Record measured results of the ZSH/ZIM restructure

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Deviations from the spec

| Deviation | Reason |
| --- | --- |
| `GPG_TTY` moves to `.zshrc` (interactive), not `.zprofile` (login) as the spec stated | It spawns `$(tty)`. In `.zshenv` that would tax every `zsh -c`; in `.zprofile` it would miss `zsh -ic`. Interactive shells are exactly where gpg pinentry happens. Gated on `[[ -t 0 ]]`. |
| No `lib/terminal-profile.zsh` | With the native chain restored the detection has exactly one consumer, and `opt/plugins/` is unusable because ZIM sources it *after* the `ZSH_MINIMAL_TERMINAL` conditions are evaluated. A single block in `.zshrc` achieves the same consolidation without a new directory. |
| Warp startup gets slower | Warp previously skipped the entire config (7.9 ms) and so had no aliases, functions or completions. It now loads everything except the four conflicting plugins. This is a correctness fix; the cost is stated rather than hidden. |

## Not addressed

**Spec F8 — completion latency.** The `completer` list includes `_approximate` and `_correct`, which each run extra completion passes. Completion latency was never measured, so any change would be guesswork. Measuring it needs a PTY fixture, which is out of scope here. Left as a follow-up.
