#!/usr/bin/env zsh

# ~/.zshrc
# Sourced for every interactive shell.
# http://zsh.sourceforge.net/Intro/intro_3.html
#
# This file is a manifest, not an implementation. Each step below is a
# zrc::<topic> function defined in opt/rc.d/*.zsh. Run `sys::bench` to measure
# startup, or read the #ABOUT header of a module to see what a step does.

# Powerlevel10k instant prompt. Must stay near the top: anything that may
# require console input (password prompts, [y/n] confirmations) goes above it.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Each module is sourced immediately before the functions it declares, so the
# file that defines every step below is visible at the call site. Sourcing only
# defines functions; nothing runs until it is called.
zrc=${ZDOTDIR:-$HOME/.config/zsh}/opt/rc.d

# --- before the framework ---------------------------------------------------
source $zrc/env.zsh          # declares: env::* and _has_command
env::core                    # shell identity
env::options                 # shell options
env::paths                   # path, fpath, cdpath, manpath
env::homebrew                # brew shellenv and prefixes
env::editor                  # EDITOR, VISUAL, GIT_EDITOR, vim aliases

source $zrc/theme.zsh        # declares: theme::palette
theme::palette               # LS_COLORS, EXA_COLORS, syntax-highlight palette

source $zrc/term.zsh         # declares: term::profile, term::prompt
term::profile                # terminal detection and shell integration

source $zrc/sys.zsh          # declares: sys::dotenv, sys::runtime_dir, sys::profiling, sys::bench, sys::purge
sys::dotenv                  # secrets from ~/.config/.env
sys::fix_xdg_runtime_dir     # private XDG_RUNTIME_DIR

source $zrc/zim.zsh          # declares: zim::dumpfile, zim::load, zim::overrides
zim::dumpfile                # where ZIM writes .zcompdump
zim::load                    # bootstrap zimfw and source its generated init.zsh
zim::overrides               # settings that must outrank ZIM's modules

term::prompt                 # powerlevel10k configuration
sys::profiling               # zprof teardown (no-op unless z_prof is set)
sys::purge                   # drop the one-shot setup functions
unset zrc
