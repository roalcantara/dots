#!/usr/bin/env bash
# Verification harness for the ZSH/ZIM restructure.
# See docs/superpowers/specs/2026-09-17-zsh-zim-restructure-design.md
set -euo pipefail

ZSH_BIN="${ZSH_BIN:-/opt/homebrew/bin/zsh}"
OUT="${ZSH_VERIFY_DIR:-${TMPDIR:-/tmp}/zsh-verify}"
ZDOT="$HOME/.config/zsh"

dump_script()
              {
  cat << 'EOF'
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
normalise()
            {
              sed -E 's/orig-s[0-9]+-r[0-9]+-/orig-SESSION-/g'
}

capture()
          { # capture <destdir>
  local dest=$1 ds
                    mkdir -p "$dest"
  ds="$dest/.dump.zsh"
                        dump_script > "$ds"
  local mode
  for mode in lic ic; do
    env -i HOME="$HOME" TERM=xterm-256color ZDOTDIR="$ZDOT" \
      "$ZSH_BIN" -"$mode" "source $ds" 2> /dev/null | normalise > "$dest/$mode.txt" || true
  done
  rm -f "$ds"
  printf 'captured %s: lic=%s lines, ic=%s lines\n' "$dest" \
    "$(wc -l < "$dest/lic.txt")" "$(wc -l < "$dest/ic.txt")"
}

cmd_baseline()
               {
                 capture "$OUT/baseline"
}

cmd_parity()
             {
  [[ -d $OUT/baseline ]] || {
                              echo "no baseline; run: $0 baseline" >&2
                                                                        exit 2
  }
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

cmd_bench()
            {
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

cmd_syntax()
             {
  local f rc=0
  for f in "$ZDOT"/.zshenv "$ZDOT"/.zprofile "$ZDOT"/.zshrc "$ZDOT"/.zimrc "$ZDOT"/.zlogin "$ZDOT"/.zlogout; do
    [[ -r $f ]] || continue
    if "$ZSH_BIN" -n "$f"; then echo "syntax OK    $f"; else
                                                             echo "syntax FAIL  $f"
                                                                                     rc=1
    fi
  done
  return $rc
}

case "${1:-}" in
  baseline) cmd_baseline ;;
  parity)   cmd_parity ;;
  bench)    cmd_bench ;;
  syntax)   cmd_syntax ;;
  *)
     echo "usage: $0 {baseline|parity|bench|syntax}" >&2
                                                          exit 2
                                                                 ;;
esac
