#!/usr/bin/env bash
override BRANCH 			:= main
override HOSTNAME 			:= NCC1701
override DOTS_REPO 			:= https://github.com/roalcantara/dots
override DOTS_TARGET 		:= $(HOME)/.git
override XDG_CONFIG_HOME 	:= $(HOME)/.config
override XDG_CONFIG_BAK 	:= $(HOME)/.config.bak

SHELL 						= /bin/bash
DOTS 	 					= $(/usr/bin/git --git-dir="$(DOTS_TARGET)" --work-tree="$(HOME)")
BACKUP 						= $(mkdir -p $(XDG_CONFIG_BAK) && $(DOTS) checkout 2>&1 | grep -E '\s+\.' | awk '{ print $1 }' | xargs -I{} mv {} $(XDG_CONFIG_BAK)/{})
SOFTWARE_UPDATE 			= $(softwareupdate -l | grep "\*.*Command Line" | tail -n 1 | sed 's/^[^C]* //')

is_darwin 					:= $(filter $(OSTYPE),darwin)
is_debian 					:= $(filter $(OSTYPE),linux-gnu)
is_alpine 					:= $(filter $(OSTYPE),linux-musl)
OS   						:= $(if $(is_darwin), darwin, $(if $(is_debian), debian, alpine))

.PHONY: default
default:
	@make -s all

.PHONY: all
all: ## List all available tasks
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z\-_0-9%:\/]+:.*?## / {printf "\033[36m%-30s→\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sed s/://

.PHONY: help
help: ## (Fuzzy) Display available tasks
	@make -s all | fzf --cycle | cut -d ' ' -f1 | xargs -r make

.PHONY: install
install: configure/$(OS) $(XDG_CONFIG_HOME) ## Install Dotfiles
	$(info "[install] ✔✔")

.PHONY: docker/build
docker/build: ## Buld Dockerfile
	docker build --target dots -t roalcantara/dots $(HOME)/.config

.PHONY: docker/run
docker/run: ## Run Docker Container roalcantara/dots
	docker run --rm -it roalcantara/dots

.PHONY: docker/serve
docker/serve: ## Run Docker Container roalcantara/dots (mounting $(HOME)/.config)
	docker run --rm -it -v $(HOME)/.config:/home/linuxbrew/.config roalcantara/dots

.PHONY: configure/debian
configure/debian: ## Ensure required dependencies
	$(info "[configure/debian] Ensuring required dependencies..")
	sudo apt-get update
	sudo apt-get install --no-install-recommends -y sudo ca-certificates build-essential curl make bash git
	sudo update-ca-certificates

.PHONY: configure/alpine
configure/alpine: ## Ensure required dependencies
	$(info "[configure/alpine] Ensuring required dependencies..")
	apk -U --no-cache add sudo curl make bash git

.PHONY: configure/darwin
configure/darwin: configure/darwin/xcode_tools ## Configure darwin defaults
	$(info "[configure/darwin] Configuring darwin..")
	defaults write -g ApplePressAndHoldEnabled -bool false
	defaults write -g InitialKeyRepeat -int 10
	defaults write -g KeyRepeat -int 1
	sudo scutil --set HostName $(HOSTNAME)
	sudo scutil --set LocalHostName $(HOSTNAME)
	sudo scutil --set ComputerName $(HOSTNAME)
	dscacheutil -flushcache
	sudo chown -R $(whoami) /usr/local/share/man/man8
	chmod u+w /usr/local/share/man/man8


.PHONY: configure/darwin/xcode_tools
configure/darwin/xcode_tools: ## Ensure Command Line Tools for Xcode is installed (https://developer.apple.com/forums/thread/698954)
ifeq ($(shell command -v xcode-select),)
	$(info "[configure/darwin/xcode_tools] Command Line Tools for Xcode Not found! Installing from softwareupdate..")
	# This temporary file prompts the 'softwareupdate' utility to list the Command Line Tools
	touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
	softwareupdate -ia "$(SOFTWARE_UPDATE)" --verbose;
endif

$(DOTS_TARGET):
	$(info "[Dots] Cloning '$(DOTS_REPO)'..")
	git clone --bare $(DOTS_REPO) $@

$(XDG_CONFIG_HOME): | $(DOTS_TARGET)
	$(info "[Dots] Checking out branch '$(BRANCH)'..")
	$(if $(DOTS) checkout "$(BRANCH)" && test $? -ne 0 ) $(and $(BACKUP) && $(DOTS) checkout "$(BRANCH)")
	$(DOTS) config status.showUntrackedFiles no
