#!/usr/bin/env bash
SHELL := /bin/bash

override VIM_LUA_PATH ?= $(VIM_PATH)/lua
override VIM_DATA_PATH ?= $(XDG_DATA_HOME)/nvim
override VIM_CACHE_PATH ?= $(XDG_CACHE_HOME)/nvim
override TREE_SITTERS ?= bash css dockerfile git_rebase gitattributes gitcommit gitignore go help json jsonc lua make markdown python ruby scss toml tsx typescript vim yaml
override VIM_DIRS ?= $(VIM_DATA_PATH) $(VIM_DATA_PATH)/ $(VIM_CACHE_PATH) $(VIM_CACHE_PATH)/session $(VIM_CACHE_PATH)/debug/log $(VIM_PATH)/plugin
override VIM_DATA_DIRS ?= backup shada site spell swap undo view lsp_servers
override VIM_DATA_FILES ?= rplugin.vim
override LANGS ?= bashls cssls lua_ls gradle_ls taplo jsonls tsserver eslint yamlls
override PERL_PACKAGES += MsgPack::Raw App::cpanminus Neovim::Ext
override VIM_PACKER_PATH ?= $(VIM_DATA_PATH)/site/pack/packer/start/packer.nvim

default:
	@make -s all

all:
	@make -s help | fzf --cycle | cut -d ' ' -f1 | xargs -r make

.PHONY: compile
compile: ## Build roalcantara/lua5.1 docker container
	rm -rf ~/.config/nvim/lua
	docker run --workdir /app/src -v ~/.config/nvim:/app --name lua5 -it --rm roalcantara/lua5.1 moonc -t /app/lua .

.PHONY: plug/bootstrap
plug/bootstrap: ## Compile Packer plugins
	nvim --headless +'sleep 1000m | qa'

.PHONY: plug/compile
plug/compile: plug/bootstrap ## Compile Packer plugins
	nvim --headless +'autocmd User PackerCompileDone qa' +PackerCompile

.PHONY: recompile
recompile: compile plug/compile ## Compile Packer plugins

.PHONY: plug/sync
plug/sync: plug/compile ## Sync Packer plugins
	nvim --headless +'autocmd User PackerComplete qa' +PackerSync

.PHONY: ts/sync
ts/sync: ## Sync Treesitters
	nvim --headless +"TSInstall! $(TREE_SITTERS) | sleep 12000m | qa"

.PHONY: lsp/install
lsp/install: ## Install LSPs
	nvim --headless +"LspInstall $(LANGS)" +qa

.PHONY: install
install: plug/sync ts/sync lsp/install ## Install plugins, treesitter and lsps

.PHONY: purge
purge: ## Purges all nvim files
	rm -rf ~/.config/nvim/plugin
	rm -rf ~/.local/state/nvim
	rm -rf ~/.local/share/nvim
	rm -rf ~/.cache/nvim

.PHONY: test
test: ## Runs busted tests
	docker run --workdir /app/src -v ~/.config/nvim:/app --name lua5 -it --rm roalcantara/lua5.1 busted --config-file=.busted --helper=spec/tools/spec_helper.lua

.PHONY: watch
watch: ## Start watchman to build the project
	fswatch -0 --recursive -ext docker run --workdir /app/src -v ~/.config/nvim:/app --name lua5 -it --rm roalcantara/lua5.1 moonc -t /app/lua .

.PHONY: watch/stop
watch/stop: ## Stop watchman
	watchman trigger-del ~/.config/nvim/src rebuild

.PHONY: help
help: ## Display available tasks
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z\-_0-9%:\/]+:.*?## / {printf "\033[36m%-30s→\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sed s/://

# $(VIM_PACKER_PATH):
# 	git clone --depth 1 https://github.com/wbthomason/packer.nvim $(VIM_PACKER_PATH)
