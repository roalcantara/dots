# ZOXIDE | https://github.com/ajeetdsouza/zoxide
# A smarter cd command.
#
# Replaces the zim-zoxide module, which regenerated its init script by
# shelling out to `zoxide init` on every single shell start with no staleness
# guard. Cache it against the binary instead, the way zim-mise does.
#
# --cmd cd makes zoxide define cd() and cdi() directly; there is no z/zi.
# `cd!` (see opt/aliases/util.zsh) still reaches the real builtin.
if (( $+commands[zoxide] )); then
  () {
    local cachefile=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zoxide-init.zsh
    if [[ ! -e $cachefile || $cachefile -ot $commands[zoxide] ]]; then
      [[ -d ${cachefile:h} ]] || mkdir -p ${cachefile:h}
      $commands[zoxide] init zsh --cmd cd >| $cachefile
    fi
    source $cachefile
  }
fi
