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
  local sub=${1:-} arg
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

# True when the buffer starts a risky command. Words are split as the shell parses them, so a separator resets the
# command position and a file name that merely mentions rm (cat rm-rf-notes.txt) never counts.
_dots_warn_risky() {
  emulate -L zsh
  local -a words
  words=( ${(z)1} ) 2>/dev/null
  local n=${#words} i=1 expect_cmd=1 is_sudo=0 w
  while (( i <= n )); do
    w=${words[i]}
    case $w in
      ';' | '&&' | '||' | '|' | '(' | ')' | '{' | '}' | 'then' | 'do' | '!')
        expect_cmd=1
        is_sudo=0
        ;;
      'sudo')
        expect_cmd=1
        is_sudo=1
        ;;
      'command' | 'builtin' | 'exec' | 'nohup' | 'time')
        expect_cmd=1
        ;;
      [A-Za-z_]*=*)
        ;; # VAR=value before the command: the command is still to come
      *)
        if (( expect_cmd )); then
          expect_cmd=0
          case $w in
            rm)
              # sudo can do damage even without -rf, so any sudo rm is worth the cue.
              (( is_sudo )) && return 0
              _dots_warn_rm "${(@)words[i + 1, -1]}" && return 0
              ;;
            git) _dots_warn_git "${(@)words[i + 1, -1]}" && return 0 ;;
            chmod) _dots_warn_chmod "${(@)words[i + 1, -1]}" && return 0 ;;
            dd) _dots_warn_dd "${(@)words[i + 1, -1]}" && return 0 ;;
            mkfs | mkfs.*) return 0 ;;
          esac
        fi
        ;;
    esac
    (( i++ ))
  done
  return 1
}

# Paint the whole buffer; drop the previous entry first so the regions never accumulate.
_dots_warn_highlight() {
  emulate -L zsh
  region_highlight=( "${region_highlight[@]:#*memo=dots-warn}" )
  [[ -n $BUFFER && -n $DOTS_WARN_STYLE ]] || return
  _dots_warn_risky "$BUFFER" || return
  region_highlight+=( "0 ${#BUFFER} ${DOTS_WARN_STYLE} memo=dots-warn" )
}

autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-pre-redraw _dots_warn_highlight
