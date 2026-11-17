#  Custom cd command that uses fzf when no argument is provided
# ⌥ c Fuzzy find directory
__fzf_alt_c_command() {
  local dir
  dir=$(eza --color=always --classify --group-directories-first --long --header --icons --no-permissions --no-user -a . | \
    fzf --preview "file=\$(echo {} | awk '{print \$NF}'); \
        if [ -d \"\$file\" ]; then \
          eza --color=always --classify --group-directories-first --binary --long --header --icons --modified --time-style=iso -a --git \"\$file\"; \
        elif [[ \"\$file\" =~ \\.(jpg|jpeg|png|gif|bmp)\$ ]]; then \
          chafa -c 256 --size=40x40 \"\$file\"; \
        else \
          bat --style=header,numbers --language=sh --color=always --line-range :500 \"\$file\" 2>/dev/null || echo \"\$file\"; \
        fi" \
        --preview-window="right:45%" \
        --header '[^ Y] copy path into clipboard' \
        --bind="ctrl-y:execute-silent(echo {} | awk '{print \$NF}' | pbcopy)" \
        --bind="tab:accept" \
        --height=40% \
        --margin=1,1 \
        --prompt="❯ " \
        --pointer="▶" \
        --marker="✔" \
        --cycle \
        --ansi \
        --keep-right \
        --select-1 --exit-0 \
        --tiebreak=chunk | awk '{print $NF}')

  if [[ -n "$dir" ]]; then
    cd "$dir" 2>/dev/null || cd "$(dirname "$dir")" 2>/dev/null
    zle accept-line
  else
    zle redisplay
  fi
}

# Create widget for Alt+C
zle -N __fzf_alt_c_command
bindkey '^[c' __fzf_alt_c_command
