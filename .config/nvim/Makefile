#!/usr/bin/env bash
SHELL := /bin/bash

override VIM_LUA_PATH ?= $(VIM_PATH)/lua
override VIM_DATA_PATH ?= $(XDG_DATA_HOME)/nvim
override VIM_CACHE_PATH ?= $(XDG_CACHE_HOME)/nvim
override TREE_SITTERS ?= bash cmake python ruby lua css dockerfile go graphql html javascript jsdoc json scss toml typescript tsx yaml
override VIM_DIRS ?= $(VIM_DATA_PATH) $(VIM_DATA_PATH)/ $(VIM_CACHE_PATH) $(VIM_CACHE_PATH)/session $(VIM_CACHE_PATH)/debug/log $(VIM_PATH)/plugin
override VIM_DATA_DIRS ?= backup shada site spell swap undo view lsp_servers
override VIM_DATA_FILES ?= rplugin.vim
override LANGS ?= angularls ansiblels awk_ls bashls cmake cssls cucumber_language_server dockerls gopls grammarly graphql html jsonls kotlin_language_server pyright solargraph sorbet sumneko_lua tsserver vimls yamlls zk teal-language-server rust_analyzer taplo
override PERL_PACKAGES += MsgPack::Raw App::cpanminus Neovim::Ext

default:
	@make -s all

all:
	@make -s help | fzf --cycle | cut -d ' ' -f1 | xargs -r make

.PHONY: compile
compile: ## Build roalcantara/lua5.1 docker container
	docker run --workdir /app/src -v ~/.config/nvim:/app --name lua5 -it --rm roalcantara/lua5.1 moonc -t /app/lua .

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
