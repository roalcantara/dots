#!/usr/bin/env zsh

# Risky commands get the theme's warning colour while typed (docs/THEME.md). zsh-patina is this shell's highlighter
# and offers no pattern API, so this is a line-pre-redraw hook registered after it: zsh-patina removes only its own
# memo'd entries, so ours layer on top (michel-kraemer/zsh-patina#95).

# rm with both recursive and force, in any order or form (-rf, -fr, -Rf, -r -f, --recursive --force).
_dots_warn_rm() {
  emulate -L zsh
  local arg recursive=0 force=0
  for arg in "$@"; do
    case $arg in
      --recursive) recursive=1 ;;
      --force) force=1 ;;
      -[!-]*)
        [[ $arg == *[rR]* ]] && recursive=1
        [[ $arg == *f* ]] && force=1
        ;;
    esac
  done
  (( recursive && force ))
}

# git push --force, -f or --force-with-lease; git reset --hard; git clean -f….
_dots_warn_git() {
  emulate -L zsh
  (( $# )) || return 1 # a bare `git` has no subcommand to judge
  local sub=$1 arg
  shift
  case $sub in
    push)
      for arg in "$@"; do
        [[ $arg == --force || $arg == --force-with-lease || $arg == --force-with-lease=* ]] && return 0
        [[ $arg == -[!-]* && $arg == *f* ]] && return 0
      done
      ;;
    reset)
      for arg in "$@"; do [[ $arg == --hard ]] && return 0; done
      ;;
    clean)
      for arg in "$@"; do
        [[ $arg == --force || ( $arg == -[!-]* && $arg == *f* ) ]] && return 0
      done
      ;;
  esac
  return 1
}

# chmod -R 777.
_dots_warn_chmod() {
  emulate -L zsh
  local arg recursive=0 mode=0
  for arg in "$@"; do
    case $arg in
      --recursive) recursive=1 ;;
      -[!-]*) [[ $arg == *R* ]] && recursive=1 ;;
      777|[0-7]777) mode=1 ;;
    esac
  done
  (( recursive && mode ))
}

# dd … of=/dev/….
_dots_warn_dd() {
  emulate -L zsh
  local arg
  for arg in "$@"; do [[ $arg == of=/dev/* ]] && return 0; done
  return 1
}

# Token offsets in the buffer: reply=(start end) per word, 1-based and inclusive (0 when a token is not found). `(z)`
# keeps quotes, so every token can be searched for literally, in order.
_dots_warn_offsets() {
  emulate -L zsh
  local -a words starts ends
  words=( ${(z)1} )
  local pos=1 rest off token
  for token in "${words[@]}"; do
    rest=${1[pos,-1]}
    # (z) reports a newline as `;`; (i) returns past the end, not 0, when nothing matches.
    if [[ $token == ';' ]]; then off=${rest[(i)[;$'\n']]}; else off=${rest[(i)${(b)token}]}; fi
    if (( off <= ${#rest} )); then
      starts+=( $(( pos + off - 1 )) )
      ends+=( $(( pos + off + ${#token} - 2 )) )
      pos=$(( pos + off + ${#token} - 1 ))
    else
      starts+=( 0 )
      ends+=( 0 )
    fi
  done
  reply=( "${starts[@]}" "${ends[@]}" )
}

# reply=(start end) for the warning region: zle counts from 0, and the 1-based inclusive end doubles as the
# exclusive end.
_dots_warn_span() {
  reply=( $(( $1 - 1 )) $2 )
}

# True when the buffer starts a risky command; reply=(start end) covers the command and its flags, not its operands.
# Words are split as the shell parses them, so a separator resets the command position and a file name that merely
# mentions rm (cat rm-rf-notes.txt) never counts.
_dots_warn_risky() {
  emulate -L zsh
  [[ -n $1 ]] || return 1
  local -a words starts ends
  words=( ${(z)1} )
  local n=${#words}
  (( n )) || return 1
  _dots_warn_offsets "$1"
  starts=( "${(@)reply[1,$n]}" )
  ends=( "${(@)reply[$(( n + 1 )),-1]}" )

  local i=1 expect_cmd=1 is_sudo=0 w j k e
  while (( i <= n )); do
    w=${words[i]}
    case $w in
      ';' | '&&' | '||' | '|' | '|&' | '&')
        expect_cmd=1
        is_sudo=0
        ;;
      *)
        # Keywords, precommands and VAR=value only keep the command still to come; as arguments they are words.
        if (( expect_cmd )); then
          case $w in
            '(' | '{' | 'then' | 'do' | 'else' | '!' | 'command' | 'builtin' | 'exec' | 'nohup' | 'time' | [A-Za-z_]*=*)
              (( i++ ))
              continue
              ;;
            'sudo')
              is_sudo=1
              (( i++ ))
              continue
              ;;
          esac
          expect_cmd=0
          # The command's own words end at the next separator: a later command's flags never count for this one.
          for (( e = i + 1; e <= n; e++ )); do
            [[ ${words[e]} == (';'|'&&'|'||'|'|'|'|&'|'&') ]] && break
          done
          (( e-- ))
          case $w in
            rm)
              # sudo can do damage even without -rf, so any sudo rm is worth the cue.
              if (( is_sudo )); then
                _dots_warn_span "${starts[i]}" "${ends[i]}"
                return 0
              fi
              if _dots_warn_rm "${(@)words[i + 1, e]}"; then
                j=$i
                for (( k = i + 1; k <= e; k++ )); do
                  [[ ${words[k]} == -* ]] || break
                  j=$k
                done
                _dots_warn_span "${starts[i]}" "${ends[j]}"
                return 0
              fi
              ;;
            git)
              if _dots_warn_git "${(@)words[i + 1, e]}"; then
                j=$(( i + 1 ))
                for (( k = i + 1; k <= e; k++ )); do
                  [[ ${words[k]} == -* ]] && j=$k
                done
                _dots_warn_span "${starts[i]}" "${ends[j]}"
                return 0
              fi
              ;;
            chmod)
              if _dots_warn_chmod "${(@)words[i + 1, e]}"; then
                j=$i
                for (( k = i + 1; k <= e; k++ )); do
                  case ${words[k]} in
                    -*) j=$k ;;
                    777 | [0-7]777) j=$k; break ;;
                    *) break ;;
                  esac
                done
                _dots_warn_span "${starts[i]}" "${ends[j]}"
                return 0
              fi
              ;;
            dd)
              if _dots_warn_dd "${(@)words[i + 1, e]}"; then
                j=$i
                for (( k = i + 1; k <= e; k++ )); do
                  [[ ${words[k]} == of=/dev/* ]] && { j=$k; break; }
                done
                _dots_warn_span "${starts[i]}" "${ends[j]}"
                return 0
              fi
              ;;
            mkfs | mkfs.*)
              _dots_warn_span "${starts[i]}" "${ends[i]}"
              return 0
              ;;
          esac
        fi
        ;;
    esac
    (( i++ ))
  done
  return 1
}

# Paint the risky command; drop the previous entry first so the regions never accumulate. Always returns 0:
# add-zle-hook-widget stops at the first widget that fails, which would skip every pre-redraw hook after this one.
_dots_warn_highlight() {
  emulate -L zsh
  region_highlight=( "${region_highlight[@]:#*memo=dots-warn}" )
  [[ -n $BUFFER && -n $DOTS_WARN_STYLE ]] || return 0
  _dots_warn_risky "$BUFFER" || return 0
  region_highlight+=( "${reply[1]} ${reply[2]} ${DOTS_WARN_STYLE} memo=dots-warn" )
}

autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-pre-redraw _dots_warn_highlight
