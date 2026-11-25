#!/usr/bin/env zsh

# ~/.zshrc
# Sourced for every interactive shell.
# http://zsh.sourceforge.net/Intro/intro_3.html
#
# This file is a manifest, not an implementation. Each step below is a
# zrc::<topic> function defined in opt/rc.d/*.zsh. Run `sys::bench` to measure
# startup, or read the #ABOUT header of a module to see what a step does.

# Each module is sourced immediately before the functions it declares, so the
# file that defines every step below is visible at the call site.
zrc=${ZDOTDIR:-$HOME/.config/zsh}/opt/rc.d

# Lig's popup: restart this terminal's shell inside Lig, once, before anything prints.
source $zrc/lig.zsh          # cached Lig integration (mise run zsh:lig); no lig process at startup

lig::pre

# Powerlevel10k instant prompt. Must stay near the top: anything that may
# require console input (password prompts, [y/n] confirmations) goes above it.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- before the framework ---------------------------------------------------
source $zrc/env.zsh          # shell identity, options, path, fpath, cdpath, manpath, brew, EDITOR, VISUAL, GIT_EDITOR, vim aliases, GUM_LOG_* styling
source $zrc/theme.zsh        # the active shell theme (dots theme): LS_COLORS, BAT_THEME, FZF_THEME_OPTS, …
source $zrc/term.zsh         # terminal detection and shell integration
source $zrc/sys.zsh          # API keys from gopass through fnox, private XDG_RUNTIME_DIR
source $zrc/zim.zsh          # powerlevel10k configuration, zprof teardown, drop the one-shot setup functions, Android SDK Tools.

unset zrc

# Last, after every other zle widget and hook: connect the line editor to Lig's popup.
lig::post
