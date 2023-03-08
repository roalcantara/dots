# Checks if the cached .zcompdump must be regenerated just once a day (https://bit.ly/3VECHfO)
# NOTES: For security reasons compinit also checks
#   if the completion system would use files that are:
#     - in directories that are world or group-writable
#     - not owned by root nor by the current user
#   In this case, compinit will ask if the completion system should really be used.
#
# ARGS:
#   -i => make compinit silently ignore all insecure files and directories
#   -u => avoid all tests and use all found files without asking
#   -d => name of the dumpfile
#   -C => only create the dumpfile if it doesnt exist, that is:
#       - If dumpfile exists, skips all security checks entirely.
#       - Ommits check performed to see if there are new functions.
autoload -Uz compinit
if [[ $(date +'%j') != $(stat -f '%Sm' -t '%j' ~/.cache/zsh/compcache/.zcompdump 2>/dev/null) ]]; then
  # Updates ZSH_COMPDUMP...
  compinit -u -i -d ~/.cache/zsh/compcache/.zcompdump
else
  # Creates ZSH_COMPDUMP...
  compinit -C -u -i -d ~/.cache/zsh/compcache/.zcompdump
fi

# Provides a menu list from where we can highlight and select completion results.
# Should be loaded before compinit (https://htr3n.github.io/2018/07/faster-zsh)
zmodload -i zsh/complist

[ -n "$z_prof" ] && zprof;
if [[ -n "$z_trace" || -n "$z_xtrace" ]]; then
  unsetopt XTRACE
fi

type source_file >/dev/null && unset -f source_file
