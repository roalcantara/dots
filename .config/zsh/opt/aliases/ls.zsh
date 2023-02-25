# EXA { 
# A modern replacement for ls
# https://the.exa.website/features/colours
if (($+commands[exa])); then
  alias ls='exa --color=always --classify --group-directories-first'                            # List non-hidden folders and files inline
  alias l='ls --oneline'                                                                        # List non-hidden folders and files in columns
  alias ll='ls --binary --icons --long --header --modified --created --group --time-style=iso'  # List non-hidden folders and files in columns (human readable)
  alias lt='ls --tree --level=2'                                                                # tree
  alias la='ll -a --git'                                                                       # List all files in columns
  alias lam='la --sort=modified'                                                                 # List all files, sorted by modified date
  alias lac='la --sort=created'                                                                  # List all files, sorted by created date
  alias lal='lal -Sa@ --color-scale'                                                            # List all files in columns (extended)

  alias llr='ll -R'                                                                             # Lists human readable sizes, recursively.
  alias lap='la | "$PAGER"'                                                                     # Lists human readable sizes, hidden files through pager.
  alias lax='lla --sort=Extension'                                                               # Lists sorted by extension (GNU only).
  alias lls='lla --sort=size -r'                                                                 # Lists sorted by size, largest last.
  alias ltm='la --sort=modified -r'                                                             # Lists sorted by date, most recent last.
  alias llc='ltm -m'                                                                             # Lists sorted by date, most recent last, shows change time.
  alias llv='ltm -u'                                                                             # Lists sorted by date, most recent last, shows access time.

  alias ls!='/bin/ls --color=auto'
  alias l!='ls! -l'
  alias ll!='ls! -lh'
  alias llg!='ls! -lh --git'
  alias lr!='ls! -lrt'
  alias la!='ls! -la'
  alias lm!='ls! -al | "$PAGER"'
  alias lx!='ls! -X'
  alias lk!='ls! -lSr'
  alias lt!='ls! -ltr'
  alias lc!='ls! -lcrt'
  alias lu!='ls! -lur'
  alias sl!='ls! -l'
else
  alias ls='/bin/ls --color=auto'
  alias l='ls -l'
  alias ll='ls -lh'
  alias llg='ls -lh --git'
  alias lr='ls -lrt'
  alias la='ls -la'
  alias lm='ls -al | "$PAGER"'
  alias lx='ls -X'
  alias lk='ls -lSr'
  alias lt='ls -ltr'
  alias lc='ls -lcrt'
  alias lu='ls -lur'
  alias sl='ls -l'
fi