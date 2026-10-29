#!/usr/bin/env zsh
# Host and session concerns: secrets, runtime dir, profiling, benchmarking, cleanup.
# Loaded by .zshrc; defines functions only — nothing runs at load time.
#DECLARES sys::dotenv  sys::runtime_dir  sys::profiling  sys::bench  sys::purge

#ABOUT Source ~/.config/.env when it is present and not age-encrypted.
sys::dotenv() {
  # Only source if the file is not age-encrypted (does not contain 'BEGIN AGE ENCRYPTED FILE')
  if _has_command sops age && [[ -r $HOME/.config/.env ]] && ! grep -q 'BEGIN AGE ENCRYPTED FILE' "$HOME/.config/.env"; then
    set -a
    source "$HOME/.config/.env"
    set +a
  fi
}

#ABOUT Ensure XDG_RUNTIME_DIR exists and is private (0700).
#ORDER Anywhere before first use. Uses zsh/stat, so no subprocess on the happy path.
sys::fix_xdg_runtime_dir() {
  emulate -L zsh
  local dir=${XDG_RUNTIME_DIR:-}
  [[ -n $dir ]] || return 0
  [[ -d $dir ]] || command mkdir -p $dir 2>/dev/null || return 0

  # zsh/stat replaces the previous `stat --version` / /bin/stat probing, which
  # never worked on macOS (/bin/stat does not exist; BSD stat has no --version)
  # and so silently left the directory world-readable.
  zmodload -F zsh/stat b:zstat 2>/dev/null || return 0
  # zstat accepts only ONE +element per call, so query mode and uid separately.
  local -a mode uid
  zstat -A mode +mode -- $dir 2>/dev/null || return 0
  zstat -A uid  +uid  -- $dir 2>/dev/null || return 0

  # 8#NNN is required: with a leading zero zsh reads 0777 as DECIMAL 777.
  # BSD chmod/chown reject the -- separator, and $dir is always absolute here.
  (( (mode[1] & 8#777) == 8#700 )) || command chmod 700 $dir 2>/dev/null
  (( uid[1] == UID ))              || command chown $UID $dir 2>/dev/null
  return 0
}

#ABOUT Measure shell startup and interactive latency. Survives sys::purge.
#USAGE sys::bench [--startup|--latency|--modules]   (default: all available)
sys::bench() {
  emulate -L zsh
  setopt local_options no_unset
  local mode=${1:---all}
  local zdot=${ZDOTDIR:-$HOME/.config/zsh}
  local zsh_bin=${commands[zsh]:-/bin/zsh}

  if [[ $mode == (--all|--modules) ]]; then
    print -P "%B== rc.d module load cost ==%b"
    local f; local -F start fork total=0
    local -i reps=20
    zmodload zsh/datetime
    # Each module is sourced in a subshell so it cannot disturb this one. The
    # fork itself costs more than the parse, so measure and subtract it.
    start=$EPOCHREALTIME
    repeat $reps; do ( : ); done
    fork=$(( ($EPOCHREALTIME - start) * 1000 / reps ))
    for f in $zdot/opt/rc.d/*.zsh(N); do
      start=$EPOCHREALTIME
      repeat $reps; do ( source $f ) >/dev/null 2>&1; done
      local -F ms=$(( ($EPOCHREALTIME - start) * 1000 / reps - fork ))
      (( ms < 0 )) && ms=0
      total+=$ms
      printf '  %-18s %6.3f ms\n' ${f:t} $ms
    done
    printf '  %-18s %6.3f ms  (fork overhead %.3f ms, excluded)\n' TOTAL $total $fork
  fi

  if [[ $mode == (--all|--startup) ]]; then
    if (( $+commands[hyperfine] )); then
      print -P "\n%B== startup across terminal contexts ==%b"
      hyperfine --warmup 5 --runs 20 --style basic \
        -n 'non-interactive'  "env ZDOTDIR=$zdot $zsh_bin -c exit" \
        -n 'plain'            "env -u TERM_PROGRAM ZDOTDIR=$zdot $zsh_bin -lic exit" \
        -n 'vscode'           "env TERM_PROGRAM=vscode ZDOTDIR=$zdot $zsh_bin -lic exit" \
        -n 'warp'             "env TERM_PROGRAM=WarpTerminal ZDOTDIR=$zdot $zsh_bin -lic exit" \
        2>&1 | command grep -E 'Benchmark|Time '
    else
      print -u2 "sys::bench: hyperfine not installed - skipping startup matrix"
    fi
  fi

  if [[ $mode == (--all|--latency) ]]; then
    local zb
    for zb in $zdot/opt/zsh-bench/zsh-bench ~/zsh-bench/zsh-bench ${commands[zsh-bench]:-}; do
      if [[ -x $zb ]]; then
        print -P "\n%B== user-visible latency (zsh-bench) ==%b"
        $zb -i 10 2>/dev/null | command grep -E 'lag_ms|has_git_prompt'
        return 0
      fi
    done
    print -u2 "sys::bench: zsh-bench not found - clone https://github.com/romkatv/zsh-bench"
  fi
}

sys::dotenv                  # secrets from ~/.config/.env
sys::fix_xdg_runtime_dir     # private XDG_RUNTIME_DIR
