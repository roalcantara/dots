#!/usr/bin/env bash
SHELL := /bin/bash

override TREE_SITTERS ?= bash css dockerfile git_rebase gitattributes gitcommit gitignore go help json jsonc lua make markdown python ruby scss toml tsx typescript vim yaml

default:
	@make -s all

all:
	@make -s help | fzf --cycle | cut -d ' ' -f1 | xargs -r make

.PHONY: neovim/install
neovim/install: ## INSTALLS neovim
	brew install neovim

.PHONY: neovim/uninstall
neovim/uninstall: ## UNINSTALLS neovim
	brew uninstall neovim

.PHONY: clear
clear: ## Removes all nvim files
	rm -rf ~/.config/nvim/plugin ~/.local/state/nvim ~/.local/share/nvim ~/.cache/nvim

.PHONY: install
install: clear neovim/install plug/sync ## INSTALLS neovim and plugins

.PHONY: reinstall
reinstall: ## Clear Install and Compile Packer plugins
	rm -rf ~/.config/nvim/plugin ~/.local/state/nvim ~/.local/share/nvim ~/.cache/nvim
	nvim --headless +'autocmd User PackerCompileDone quitall' +'PackerSync'
	nvim --headless +'autocmd User PackerCompileDone quitall' +'PackerCompile'

.PHONY: plug/compile
plug/compile: ## Compile Packer plugins
	nvim --headless +'autocmd User PackerCompileDone quitall' +'PackerCompile'

.PHONY: plug/sync
plug/sync: ## Sync Packer plugins
	nvim --headless "+Lazy! sync" +qa

.PHONY: ts/sync
ts/sync: ## Sync Treesitters
	nvim --headless +":TSUpdate $(TREE_SITTERS) | sleep 12000m | qa"

.PHONY: help
help: ## Display available tasks
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z\-_0-9%:\/]+:.*?## / {printf "\033[36m%-30s→\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sed s/://
